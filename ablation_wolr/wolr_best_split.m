function splitInfo = wolr_best_split(Xnode, options)
%WOLR_BEST_SPLIT 为当前节点寻找最优 SSE 改善型二分候选。
%   本函数保留投影排序扫描候选切分点，只将得分改为
%   DeltaSSE = W0 - (W1 + W2)，用于 w/o LR 消融实验。

validateattributes(Xnode, {'double', 'single'}, {'2d', 'nonempty', 'real'}, mfilename, 'Xnode', 1);
if any(~isfinite(Xnode(:)))
    error('wolr_best_split:InvalidData', 'Xnode 含有 NaN 或 Inf，请先清理数据。');
end
validate_options(options);

n = size(Xnode, 1);
baseInfo = struct( ...
    'shouldSplit', false, ...
    'score', -inf, ...
    'leftIndices', [], ...
    'rightIndices', [], ...
    'splitPosition', [], ...
    'candidateCount', 0, ...
    'sseSingle', [], ...
    'sseLeft', [], ...
    'sseRight', [], ...
    'projectionDirection', [], ...
    'projectionThreshold', [], ...
    'stopReason', '');

totalSSE = biclr_node_sse(Xnode);
if n < 2 * options.minNodeSize
    splitInfo = baseInfo;
    splitInfo.sseSingle = totalSSE;
    splitInfo.stopReason = '节点样本数不足，无法继续二分。';
    return;
end

if totalSSE <= options.epsVar
    splitInfo = baseInfo;
    splitInfo.sseSingle = totalSSE;
    splitInfo.stopReason = '节点方差过小，可直接作为锚点。';
    return;
end

Xcenter = bsxfun(@minus, Xnode, mean(Xnode, 1));
[~, singularValues, V] = svd(Xcenter, 'econ');
if isempty(V) || isempty(singularValues) || singularValues(1, 1) <= 10 * eps(class(Xnode))
    splitInfo = baseInfo;
    splitInfo.sseSingle = totalSSE;
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

scoreAll = totalSSE - (W1 + W2);
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
splitInfo.sseSingle = totalSSE;
splitInfo.sseLeft = W1(bestLoc);
splitInfo.sseRight = W2(bestLoc);
splitInfo.projectionDirection = direction;
splitInfo.projectionThreshold = mean(projectionSorted(bestPos:bestPos + 1));
if splitInfo.shouldSplit
    splitInfo.stopReason = '接受最优 DeltaSSE 划分。';
else
    splitInfo.stopReason = '最优 DeltaSSE 未超过阈值。';
end
end

function validate_options(options)
requiredFields = {'minNodeSize', 'tauSplit', 'epsVar'};
for i = 1:numel(requiredFields)
    if ~isfield(options, requiredFields{i})
        error('wolr_best_split:MissingOption', '缺少必要参数字段 %s。', requiredFields{i});
    end
end

validateattributes(options.minNodeSize, {'double', 'single'}, {'real', 'scalar', 'finite', 'integer', 'positive'}, mfilename, 'options.minNodeSize');
validateattributes(options.tauSplit, {'double', 'single'}, {'real', 'scalar', 'finite'}, mfilename, 'options.tauSplit');
validateattributes(options.epsVar, {'double', 'single'}, {'real', 'scalar', 'finite', 'nonnegative'}, mfilename, 'options.epsVar');
end
