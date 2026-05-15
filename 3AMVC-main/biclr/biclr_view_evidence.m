function viewEvidence = biclr_view_evidence(X, anchorSSE, anchorSizes, options)
%BICLR_VIEW_EVIDENCE 计算整视图锚点划分的 BIC 证据增益。
%   VIEWEVIDENCE = BICLR_VIEW_EVIDENCE(X, ANCHORSSE, ANCHORSIZES, OPTIONS)
%   将最终锚点划分视为共享方差的多分量球形高斯模型，并与整视图单簇
%   球形高斯模型比较，返回 BIC 正则化后的总体证据增益与单位证据增益。
%
%   输入参数：
%   X           : n*d 的单视图特征矩阵。
%   anchorSSE   : m*1 向量，每个锚点节点的簇内平方误差。
%   anchorSizes : m*1 向量，每个锚点节点的样本数。
%   options     : BIC-LR 参数结构体，至少可包含 lambdaBIC 和 epsVar。
%
%   输出参数：
%   viewEvidence : 结构体，包含 logL0、logLPartition、deltaBIC、
%                  unitGain、qualityScore、singleSSE、partitionSSE 等字段。
%
%   维度说明：
%   n 为样本数，d 为特征维度，m 为最终锚点数。
%
%   注意事项：
%   1. unitGain = deltaBIC / (2*n*d)，表示按高斯观测自由度归一的
%      单位 BIC 证据增益，与递归二分得分中的 2*logL 量纲一致。
%   2. qualityScore = -unitGain，用于兼容“质量分越小越好”的旧式接口；
%      选择基准视图时仍按 unitGain 最大进行。
%
%   See also BIC_LR_HBNC, biclr_select_target_view

if nargin < 4
    options = struct();
end

validateattributes(X, {'double', 'single'}, {'2d', 'nonempty', 'real'}, mfilename, 'X', 1);
validateattributes(anchorSSE, {'double', 'single'}, {'vector', 'nonempty', 'real', 'nonnegative'}, mfilename, 'anchorSSE', 2);
validateattributes(anchorSizes, {'double', 'single'}, {'vector', 'nonempty', 'real', 'integer', 'positive'}, mfilename, 'anchorSizes', 3);
if any(~isfinite(X(:))) || any(~isfinite(anchorSSE(:))) || any(~isfinite(anchorSizes(:)))
    error('biclr_view_evidence:InvalidInput', '输入 X、anchorSSE 或 anchorSizes 含有 NaN 或 Inf。');
end

anchorSSE = double(anchorSSE(:));
anchorSizes = double(anchorSizes(:));
if numel(anchorSSE) ~= numel(anchorSizes)
    error('biclr_view_evidence:SizeMismatch', 'anchorSSE 与 anchorSizes 的长度必须一致。');
end

[n, d] = size(X);
if sum(anchorSizes) ~= n
    error('biclr_view_evidence:SampleCountMismatch', ...
        'anchorSizes 的样本数总和为 %d，但 X 的样本数为 %d。', sum(anchorSizes), n);
end

lambdaBIC = get_option_scalar(options, 'lambdaBIC', 1);
epsVar = get_option_scalar(options, 'epsVar', 1e-8);
validateattributes(lambdaBIC, {'double', 'single'}, {'scalar', 'real', 'finite', 'nonnegative'}, mfilename, 'options.lambdaBIC');
validateattributes(epsVar, {'double', 'single'}, {'scalar', 'real', 'finite', 'nonnegative'}, mfilename, 'options.epsVar');

numAnchors = numel(anchorSizes);
singleSSE = biclr_node_sse(X);
partitionSSE = sum(anchorSSE);
logL0 = biclr_loglik_single(n, d, singleSSE, epsVar);
logLPartition = compute_partition_loglik(anchorSizes, d, partitionSSE, epsVar);

% 与递归二分的局部惩罚保持同量纲：m 个叶节点相对 1 个节点新增
% (m-1) 组均值/方差自由度，按 (d+1)log(n) 计入 BIC 正则项。
penalty = lambdaBIC * max(numAnchors - 1, 0) * (d + 1) * log(max(n, 2));
deltaBIC = 2 * (logLPartition - logL0) - penalty;
unitGain = deltaBIC / max(2 * n * d, 1);

viewEvidence = struct();
viewEvidence.methodName = 'BICUnitEvidenceGain';
viewEvidence.numSamples = n;
viewEvidence.featureDim = d;
viewEvidence.numAnchors = numAnchors;
viewEvidence.anchorSizes = anchorSizes;
viewEvidence.anchorSSE = anchorSSE;
viewEvidence.singleSSE = singleSSE;
viewEvidence.partitionSSE = partitionSSE;
viewEvidence.logL0 = logL0;
viewEvidence.logLPartition = logLPartition;
viewEvidence.penalty = penalty;
viewEvidence.deltaBIC = deltaBIC;
viewEvidence.unitGain = unitGain;
viewEvidence.relativeGain = unitGain;
viewEvidence.qualityScore = -unitGain;
viewEvidence.lambdaBIC = lambdaBIC;
viewEvidence.epsVar = epsVar;
end

function logL = compute_partition_loglik(anchorSizes, d, partitionSSE, epsVar)
n = sum(anchorSizes);
mixingWeights = anchorSizes ./ n;
mixingWeights = max(mixingWeights, realmin);
sigmaSq = partitionSSE ./ (n .* d) + epsVar;
logL = sum(anchorSizes .* log(mixingWeights)) ...
    - (n .* d ./ 2) .* (log(2 * pi .* sigmaSq) + 1);
logL = real(logL);
end

function value = get_option_scalar(options, fieldName, defaultValue)
if isstruct(options) && isfield(options, fieldName) && ~isempty(options.(fieldName))
    value = options.(fieldName);
else
    value = defaultValue;
end
end
