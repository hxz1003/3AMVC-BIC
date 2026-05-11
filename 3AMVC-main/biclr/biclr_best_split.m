function splitInfo = biclr_best_split(Xnode, options)
%BICLR_BEST_SPLIT 为当前节点寻找最优 BIC-LR 二分候选。
%   SPLITINFO = BICLR_BEST_SPLIT(XNODE, OPTIONS) 在当前节点样本矩阵
%   XNODE 上生成确定性候选切分，并返回 BIC 正则化似然比得分最高的划分。
%
%   输入参数：
%   Xnode   : n*d 的实数矩阵，每一行为一个样本。
%   options : 结构体，至少包含以下字段：
%             - lambdaBIC   : BIC 惩罚系数。
%             - minNodeSize : 子节点最小样本数。
%             - tauSplit    : 分裂接受阈值。
%             - epsVar      : 方差保护项。
%
%   输出参数：
%   splitInfo : 结构体，字段包括：
%               - shouldSplit          : 是否接受最优划分。
%               - score                : 最优 BIC-LR 得分。
%               - leftIndices/rightIndices : 相对 Xnode 的左右子节点索引。
%               - splitPosition        : 排序后切分点位置。
%               - logL0/logL1          : 最优划分对应的对数似然。
%               - sseSingle/sseLeft/sseRight : SSE 统计量。
%               - stopReason           : 未分裂时的停止原因。
%
%   注意事项：
%   1. 投影方向仅用于生成候选划分，似然与 SSE 始终在原始特征空间计算。
%   2. 本函数为确定性实现，不依赖随机初始化。

validateattributes(Xnode, {'double', 'single'}, {'2d', 'nonempty', 'real'}, mfilename, 'Xnode', 1);
if any(~isfinite(Xnode(:)))
    error('biclr_best_split:InvalidData', 'Xnode 含有 NaN 或 Inf，请先清理数据。');
end
validate_biclr_options(options);

n = size(Xnode, 1);
d = size(Xnode, 2);
baseInfo = struct( ...
    'shouldSplit', false, ...
    'score', -inf, ...
    'leftIndices', [], ...
    'rightIndices', [], ...
    'splitPosition', [], ...
    'candidateCount', 0, ...
    'logL0', [], ...
    'logL1', [], ...
    'sseSingle', [], ...
    'sseLeft', [], ...
    'sseRight', [], ...
    'projectionDirection', [], ...
    'projectionThreshold', [], ...
    'stopReason', '');

if n < 2 * options.minNodeSize
    splitInfo = baseInfo;
    splitInfo.stopReason = '节点样本数不足，无法继续二分。';
    splitInfo.sseSingle = biclr_node_sse(Xnode);
    splitInfo.logL0 = biclr_loglik_single(n, d, splitInfo.sseSingle, options.epsVar);
    return;
end

Xcenter = bsxfun(@minus, Xnode, mean(Xnode, 1));
totalSSE = biclr_node_sse(Xnode);
logL0 = biclr_loglik_single(n, d, totalSSE, options.epsVar);

if totalSSE <= options.epsVar
    splitInfo = baseInfo;
    splitInfo.sseSingle = totalSSE;
    splitInfo.logL0 = logL0;
    splitInfo.stopReason = '节点方差过小，可直接作为锚点。';
    return;
end

[~, singularValues, V] = svd(Xcenter, 'econ');
if isempty(V) || isempty(singularValues) || singularValues(1, 1) <= 10 * eps(class(Xnode))
    splitInfo = baseInfo;
    splitInfo.sseSingle = totalSSE;
    splitInfo.logL0 = logL0;
    splitInfo.stopReason = '节点主方向退化，无法构造有效候选切分。';
    return;
end

direction = V(:, 1);
projection = Xcenter * direction;
[projectionSorted, order] = sort(projection, 'ascend');

tol = max(1, max(abs(projectionSorted))) * 1e-12;
gapMask = abs(diff(projectionSorted)) > tol;
candidatePos = options.minNodeSize:(n - options.minNodeSize);
candidatePos = candidatePos(gapMask(candidatePos));

if isempty(candidatePos)
    splitInfo = baseInfo;
    splitInfo.sseSingle = totalSSE;
    splitInfo.logL0 = logL0;
    splitInfo.projectionDirection = direction;
    splitInfo.stopReason = '所有合法候选切分都落在相同投影值处。';
    return;
end

Xsorted = Xnode(order, :);
prefixSum = cumsum(Xsorted, 1);
prefixSq = cumsum(sum(Xsorted.^2, 2), 1);
totalSum = prefixSum(end, :);
totalSq = prefixSq(end);

n1 = candidatePos(:);
n2 = n - n1;
sumLeft = prefixSum(candidatePos, :);
sqLeft = prefixSq(candidatePos);
sumRight = totalSum - sumLeft;
sqRight = totalSq - sqLeft;

W1 = sqLeft - sum(sumLeft.^2, 2) ./ n1;
W2 = sqRight - sum(sumRight.^2, 2) ./ n2;
W1 = max(real(W1), 0);
W2 = max(real(W2), 0);

logL1All = biclr_loglik_double(n1, n2, d, W1, W2, options.epsVar);
penalty = options.lambdaBIC * (d + 1) * log(max(n, 2));
scoreAll = 2 * (logL1All - logL0) - penalty;
[bestScore, bestLoc] = max(scoreAll);

bestPos = candidatePos(bestLoc);
leftIdx = order(1:bestPos);
rightIdx = order(bestPos + 1:end);

splitInfo = baseInfo;
splitInfo.shouldSplit = bestScore > options.tauSplit;
splitInfo.score = bestScore;
splitInfo.leftIndices = leftIdx(:);
splitInfo.rightIndices = rightIdx(:);
splitInfo.splitPosition = bestPos;
splitInfo.candidateCount = numel(candidatePos);
splitInfo.logL0 = logL0;
splitInfo.logL1 = logL1All(bestLoc);
splitInfo.sseSingle = totalSSE;
splitInfo.sseLeft = W1(bestLoc);
splitInfo.sseRight = W2(bestLoc);
splitInfo.projectionDirection = direction;
splitInfo.projectionThreshold = mean(projectionSorted(bestPos:bestPos + 1));
if splitInfo.shouldSplit
    splitInfo.stopReason = '接受最优 BIC-LR 划分。';
else
    splitInfo.stopReason = '最优 BIC-LR 得分未超过阈值。';
end
end

function validate_biclr_options(options)
requiredFields = {'lambdaBIC', 'minNodeSize', 'tauSplit', 'epsVar'};
for i = 1:numel(requiredFields)
    if ~isfield(options, requiredFields{i})
        error('biclr_best_split:MissingOption', '缺少必要参数字段 %s。', requiredFields{i});
    end
end

validateattributes(options.lambdaBIC, {'double', 'single'}, {'real', 'scalar', 'finite', 'nonnegative'}, mfilename, 'options.lambdaBIC');
validateattributes(options.minNodeSize, {'double', 'single'}, {'real', 'scalar', 'finite', 'integer', 'positive'}, mfilename, 'options.minNodeSize');
validateattributes(options.tauSplit, {'double', 'single'}, {'real', 'scalar', 'finite'}, mfilename, 'options.tauSplit');
validateattributes(options.epsVar, {'double', 'single'}, {'real', 'scalar', 'finite', 'nonnegative'}, mfilename, 'options.epsVar');
end
