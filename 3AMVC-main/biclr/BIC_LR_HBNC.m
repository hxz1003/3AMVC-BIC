function [label, object, theta, num_class, class, info] = BIC_LR_HBNC(X0, options)
%BIC_LR_HBNC 基于 BIC 正则化似然比检验生成自适应锚点。
%   [LABEL, OBJECT, THETA, NUM_CLASS, CLASS, INFO] = BIC_LR_HBNC(X0, OPTIONS)
%   对单视图样本矩阵 X0 执行确定性递归二分，使用 BIC 正则化似然比检验
%   决定是否继续分裂，最终将每个停止节点中心作为锚点输出。
%
%   输入参数：
%   X0      : n*d 的实数矩阵，每行对应一个样本。
%   options : 参数结构体，支持字段：
%             - lambdaBIC   : BIC 惩罚系数，默认 1。
%             - minNodeSize : 子节点最小样本数，默认 10。
%             - tauSplit    : 分裂阈值，默认 0。
%             - epsVar      : 方差保护项，默认 1e-8。
%             - maxAnchors  : 锚点安全上限，默认 min(n, 500)。
%             - verbose     : 是否输出日志，默认 false。
%             - randomSeed  : 记录在日志与缓存中的随机种子，默认 1。
%
%   输出参数：
%   label     : n*1 向量，表示每个样本所属的最终节点编号。
%   object    : m*1 向量，每个锚点节点的簇内平方误差。
%   theta     : m*d 矩阵，每行为一个锚点中心。
%   num_class : m*1 向量，每个锚点节点包含的样本数。
%   class     : 标量，最终锚点数量 m。
%   info      : 结构体，记录锚点数量、深度、停止原因、BIC 证据质量和配置参数。
%
%   维度说明：
%   n 为样本数，d 为特征维度，m 为最终生成的锚点数。
%
%   注意事项：
%   1. 本实现为确定性候选划分，不使用随机初始化。
%   2. 函数不会修改原始数据，也不会依赖第三方工具箱。
%
%   See also biclr_best_split, Neighbor_BICLR

if nargin < 2
    options = struct();
end

validateattributes(X0, {'double', 'single'}, {'2d', 'nonempty', 'real'}, mfilename, 'X0', 1);
if any(~isfinite(X0(:)))
    error('BIC_LR_HBNC:InvalidData', '输入数据 X0 含有 NaN 或 Inf，请先完成清洗。');
end

[n, d] = size(X0);
options = fill_default_options(options, n);

leafNodes = {};
leafDepths = [];
leafScores = [];
leafReasons = {};

pendingNodes = {(1:n)'};
pendingDepths = 0;

acceptedSplits = 0;
rejectedSplits = 0;
maxDepth = 0;

while ~isempty(pendingNodes)
    currentIdx = pendingNodes{end};
    currentDepth = pendingDepths(end);
    pendingNodes(end) = [];
    pendingDepths(end) = [];
    maxDepth = max(maxDepth, currentDepth);

    currentLeafCount = numel(leafNodes) + numel(pendingNodes) + 1;
    if currentLeafCount >= options.maxAnchors
        nextLeafPos = numel(leafNodes) + 1;
        leafNodes{nextLeafPos, 1} = currentIdx;
        leafDepths(nextLeafPos, 1) = currentDepth;
        % 该节点未经过候选分裂评分，使用 NaN 区分“未评估”和“统计证据极弱”。
        leafScores(nextLeafPos, 1) = NaN;
        leafReasons{nextLeafPos, 1} = '达到 maxAnchors 安全上限，停止继续分裂。';
        if options.verbose
            fprintf('[BIC-LR] 节点样本数=%d，因达到锚点上限而停止。\n', numel(currentIdx));
        end
        continue;
    end

    splitInfo = biclr_best_split(X0(currentIdx, :), options);
    if splitInfo.shouldSplit
        acceptedSplits = acceptedSplits + 1;
        nextPendingPos = numel(pendingNodes) + 1;
        pendingNodes{nextPendingPos, 1} = currentIdx(splitInfo.rightIndices);
        pendingDepths(nextPendingPos, 1) = currentDepth + 1;
        nextPendingPos = numel(pendingNodes) + 1;
        pendingNodes{nextPendingPos, 1} = currentIdx(splitInfo.leftIndices);
        pendingDepths(nextPendingPos, 1) = currentDepth + 1;
        if options.verbose
            fprintf(['[BIC-LR] 接受分裂：样本数=%d，深度=%d，得分=%g，' ...
                '左右子节点=%d/%d。\n'], ...
                numel(currentIdx), currentDepth, splitInfo.score, ...
                numel(splitInfo.leftIndices), numel(splitInfo.rightIndices));
        end
    else
        rejectedSplits = rejectedSplits + 1;
        nextLeafPos = numel(leafNodes) + 1;
        leafNodes{nextLeafPos, 1} = currentIdx;
        leafDepths(nextLeafPos, 1) = currentDepth;
        leafScores(nextLeafPos, 1) = splitInfo.score;
        leafReasons{nextLeafPos, 1} = splitInfo.stopReason;
        if options.verbose
            fprintf('[BIC-LR] 停止分裂：样本数=%d，深度=%d，原因=%s\n', ...
                numel(currentIdx), currentDepth, splitInfo.stopReason);
        end
    end
end

if isempty(leafNodes)
    error('BIC_LR_HBNC:NoAnchor', '未生成任何锚点，请检查输入数据与参数设置。');
end

sortKey = cellfun(@min, leafNodes);
[~, sortOrder] = sort(sortKey, 'ascend');
leafNodes = leafNodes(sortOrder);
leafDepths = leafDepths(sortOrder);
leafScores = leafScores(sortOrder);
leafReasons = leafReasons(sortOrder);

class = numel(leafNodes);
label = zeros(n, 1);
theta = zeros(class, d);
object = zeros(class, 1);
num_class = zeros(class, 1);

for ic = 1:class
    idx = leafNodes{ic};
    label(idx) = ic;
    theta(ic, :) = mean(X0(idx, :), 1);
    num_class(ic, 1) = numel(idx);
    object(ic, 1) = biclr_node_sse(X0(idx, :));
end

info = struct();
info.methodName = 'BICLR';
info.numSamples = n;
info.featureDim = d;
info.numAnchors = class;
info.anchorSizes = num_class;
info.anchorSSE = object;
info.totalSSE = sum(object);
info.legacySSEQuality = info.totalSSE;
info.acceptedSplits = acceptedSplits;
info.rejectedSplits = rejectedSplits;
info.maxDepth = maxDepth;
info.leafDepths = leafDepths;
info.leafScores = leafScores;
info.stopReasons = leafReasons;
info.options = options;
info.viewEvidence = biclr_view_evidence(X0, object, num_class, options);
info.qualityMethod = 'BICUnitEvidenceGain';
info.qualityScore = info.viewEvidence.qualityScore;
info.unitBICEvidence = info.viewEvidence.unitGain;
info.relativeBICEvidence = info.viewEvidence.unitGain;
info.bicEvidenceGain = info.viewEvidence.deltaBIC;
end

function options = fill_default_options(options, n)
defaultOptions = struct();
defaultOptions.lambdaBIC = 1;
defaultOptions.minNodeSize = 10;
defaultOptions.tauSplit = 0;
defaultOptions.epsVar = 1e-8;
defaultOptions.maxAnchors = min(n, 500);
defaultOptions.verbose = false;
defaultOptions.randomSeed = 1;

fieldNames = fieldnames(defaultOptions);
for i = 1:numel(fieldNames)
    name = fieldNames{i};
    if ~isfield(options, name) || isempty(options.(name))
        options.(name) = defaultOptions.(name);
    end
end

validateattributes(options.lambdaBIC, {'double', 'single'}, {'real', 'scalar', 'finite', 'nonnegative'}, mfilename, 'options.lambdaBIC');
validateattributes(options.minNodeSize, {'double', 'single'}, {'real', 'scalar', 'finite', 'integer', 'positive'}, mfilename, 'options.minNodeSize');
validateattributes(options.tauSplit, {'double', 'single'}, {'real', 'scalar', 'finite'}, mfilename, 'options.tauSplit');
validateattributes(options.epsVar, {'double', 'single'}, {'real', 'scalar', 'finite', 'nonnegative'}, mfilename, 'options.epsVar');
validateattributes(options.maxAnchors, {'double', 'single'}, {'real', 'scalar', 'finite', 'integer', 'positive'}, mfilename, 'options.maxAnchors');
validateattributes(options.verbose, {'logical', 'numeric'}, {'scalar'}, mfilename, 'options.verbose');
validateattributes(options.randomSeed, {'double', 'single'}, {'real', 'scalar', 'finite', 'integer', 'nonnegative'}, mfilename, 'options.randomSeed');
end
