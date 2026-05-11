function [label, object, theta, num_class, class, info] = WO_LR_HBNC(X0, options)
%WO_LR_HBNC 基于 SSE 改善量的递归二分生成自适应锚点。
%   [LABEL, OBJECT, THETA, NUM_CLASS, CLASS, INFO] = WO_LR_HBNC(X0, OPTIONS)
%   保留 BIC-LR 的递归二分结构、投影扫描候选和最小节点约束，但将分裂判据
%   替换为 DeltaSSE = W0 - (W1 + W2)，用于实现 w/o LR 消融实验。

if nargin < 2
    options = struct();
end

validateattributes(X0, {'double', 'single'}, {'2d', 'nonempty', 'real'}, mfilename, 'X0', 1);
if any(~isfinite(X0(:)))
    error('WO_LR_HBNC:InvalidData', '输入数据 X0 含有 NaN 或 Inf，请先完成清洗。');
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
        leafScores(nextLeafPos, 1) = -inf;
        leafReasons{nextLeafPos, 1} = '达到 maxAnchors 安全上限，停止继续分裂。';
        if options.verbose
            fprintf('[w/o LR] 节点样本数=%d，因达到锚点上限而停止。\n', numel(currentIdx));
        end
        continue;
    end

    splitInfo = wolr_best_split(X0(currentIdx, :), options);
    if splitInfo.shouldSplit
        acceptedSplits = acceptedSplits + 1;
        nextPendingPos = numel(pendingNodes) + 1;
        pendingNodes{nextPendingPos, 1} = currentIdx(splitInfo.rightIndices);
        pendingDepths(nextPendingPos, 1) = currentDepth + 1;
        nextPendingPos = numel(pendingNodes) + 1;
        pendingNodes{nextPendingPos, 1} = currentIdx(splitInfo.leftIndices);
        pendingDepths(nextPendingPos, 1) = currentDepth + 1;
        if options.verbose
            fprintf(['[w/o LR] 接受分裂：样本数=%d，深度=%d，DeltaSSE=%g，' ...
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
            fprintf('[w/o LR] 停止分裂：样本数=%d，深度=%d，原因=%s\n', ...
                numel(currentIdx), currentDepth, splitInfo.stopReason);
        end
    end
end

if isempty(leafNodes)
    error('WO_LR_HBNC:NoAnchor', '未生成任何锚点，请检查输入数据与参数设置。');
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
info.methodName = 'woLR';
info.numSamples = n;
info.featureDim = d;
info.numAnchors = class;
info.anchorSizes = num_class;
info.anchorSSE = object;
info.totalSSE = sum(object);
info.acceptedSplits = acceptedSplits;
info.rejectedSplits = rejectedSplits;
info.maxDepth = maxDepth;
info.leafDepths = leafDepths;
info.leafScores = leafScores;
info.stopReasons = leafReasons;
info.options = options;
end

function options = fill_default_options(options, n)
defaultOptions = struct();
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

validateattributes(options.minNodeSize, {'double', 'single'}, {'real', 'scalar', 'finite', 'integer', 'positive'}, mfilename, 'options.minNodeSize');
validateattributes(options.tauSplit, {'double', 'single'}, {'real', 'scalar', 'finite'}, mfilename, 'options.tauSplit');
validateattributes(options.epsVar, {'double', 'single'}, {'real', 'scalar', 'finite', 'nonnegative'}, mfilename, 'options.epsVar');
validateattributes(options.maxAnchors, {'double', 'single'}, {'real', 'scalar', 'finite', 'integer', 'positive'}, mfilename, 'options.maxAnchors');
validateattributes(options.verbose, {'logical', 'numeric'}, {'scalar'}, mfilename, 'options.verbose');
validateattributes(options.randomSeed, {'double', 'single'}, {'real', 'scalar', 'finite', 'integer', 'nonnegative'}, mfilename, 'options.randomSeed');
end
