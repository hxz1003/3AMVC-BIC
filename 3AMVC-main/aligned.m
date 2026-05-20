function [S, T, info] = aligned(Z, c, target_view)
%ALIGNED 使用锚图列相似度加权对齐多视图锚图。
%   [S, T] = ALIGNED(Z, C, TARGET_VIEW) 使用 TARGET_VIEW 作为基准视图，
%   调用 DSPFP 学习硬匹配关系，再根据锚图列向量余弦相似度构造加权
%   对齐矩阵，返回融合锚图 S 与实际用于融合的加权匹配矩阵 T。
%
%   [S, T, INFO] = ALIGNED(...) 额外返回每个视图对齐过程的目标函数轨迹。
%   INFO.totalMaxObjectiveTrace 为补充材料 Eq.(2) 的跨视图汇总最大化目标，
%   可用于绘制收敛曲线。
%
%   输入参数：
%   Z           : cell 数组，每个单元为 m_v*n 的锚图矩阵。
%   C           : 对齐结构项权重，对应论文中的 lambda。
%   TARGET_VIEW : 基准视图编号。
%
%   输出参数：
%   S    : 融合后的锚图矩阵。
%   T    : 每个视图到基准视图的加权匹配矩阵 cell。
%   INFO : 对齐阶段诊断信息与目标函数轨迹。
%
%   注意事项：
%   1. 锚图列相似度在当前代码方向下等价于锚图行向量相似度，即每个
%      锚点对全部样本的关系向量之间的余弦相似度。
%   2. 当非基准视图锚点数不少于基准视图时，对映射到同一基准锚点的
%      非基准锚点按相似度做组内凸组合。
%   3. 当非基准视图锚点数少于基准视图时，为未覆盖的基准锚点补充最
%      相似的非基准锚点，并按非基准锚点的覆盖集合做相似度分配。
%   4. 每个非基准视图对齐后会重新执行列归一化，保证样本到锚点的关
%      系仍满足非负且列和为 1。

validateattributes(Z, {'cell'}, {'vector', 'nonempty'}, mfilename, 'Z', 1);
validateattributes(c, {'double', 'single'}, {'scalar', 'real', 'finite'}, mfilename, 'c', 2);
validateattributes(target_view, {'double', 'single'}, ...
    {'scalar', 'integer', 'positive', '<=', numel(Z)}, mfilename, 'target_view', 3);

numview = length(Z);
S = Z{target_view};
T = cell(numview, 1);
T{target_view} = eye(size(S, 1));
pairInfo = cell(numview, 1);
maxTraceList = cell(numview, 1);
lossTraceList = cell(numview, 1);

S1 = Z{target_view} * Z{target_view}';
for nv = 1:numview
    if nv ~= target_view
        K = Z{target_view} * Z{nv}';
        S2 = Z{nv} * Z{nv}';
        [hardMatch, pairInfo{nv}] = DSPFP(S1, S2, K, c);
        similarityMatrix = compute_anchor_graph_similarity(Z{target_view}, Z{nv}, K);
        [T{nv}, alignedGraph, weightedInfo] = build_weighted_alignment( ...
            Z{target_view}, Z{nv}, hardMatch, similarityMatrix, S1, S2, K, c);
        pairInfo{nv}.hardMatchMatrix = hardMatch;
        pairInfo{nv}.weightedAlignment = weightedInfo;
        maxTraceList{nv} = pairInfo{nv}.maxObjectiveTrace(:);
        lossTraceList{nv} = pairInfo{nv}.lossObjectiveTrace(:);
        S = S + alignedGraph;
    end
end
S = S / numview;
S = normalize_anchor_graph_columns(S);
assert_valid_anchor_graph(S, '融合锚图 S');

info = struct();
info.targetView = target_view;
info.lambda = c;
info.alignmentMethod = 'SimilarityWeightedAnchorGraphColumns';
info.weightDescription = ['先由 DSPFP 确定硬匹配关系，再按锚图列余弦相似度' ...
    '对多对一或一对多匹配边加权。'];
info.fusionNormalization = 'ColumnSimplexAfterEachAlignedViewAndFinalFusion';
info.pairInfo = pairInfo;
info.maxObjectiveTraceByView = maxTraceList;
info.lossObjectiveTraceByView = lossTraceList;
info.totalMaxObjectiveTrace = aggregate_trace(maxTraceList);
info.totalLossObjectiveTrace = aggregate_trace(lossTraceList);
info.objectiveName = 'SupplementEq2AlignmentMaxObjective';
info.lossName = 'SupplementEq1AlignmentLoss';
end

function similarityMatrix = compute_anchor_graph_similarity(baseGraph, viewGraph, K)
%COMPUTE_ANCHOR_GRAPH_SIMILARITY 计算锚图行向量间的余弦相似度。
%   K 为调用方已计算的 baseGraph * viewGraph'，避免重复矩阵乘法。
baseNorm = sqrt(sum(baseGraph.^2, 2));
viewNorm = sqrt(sum(viewGraph.^2, 2));
denom = bsxfun(@times, baseNorm, viewNorm');
denom = max(denom, eps(class(baseGraph)));
similarityMatrix = K ./ denom;
similarityMatrix(~isfinite(similarityMatrix)) = 0;
similarityMatrix = max(min(real(similarityMatrix), 1), -1);
end

function [weightMatrix, alignedGraph, weightedInfo] = build_weighted_alignment( ...
    baseGraph, viewGraph, hardMatch, similarityMatrix, baseStructure, viewStructure, K, c)
baseAnchorCount = size(baseGraph, 1);
viewAnchorCount = size(viewGraph, 1);
if ~isequal(size(hardMatch), [baseAnchorCount, viewAnchorCount])
    error('aligned:MatchSizeMismatch', 'hardMatch 的尺寸与锚点数量不一致。');
end
if ~isequal(size(similarityMatrix), [baseAnchorCount, viewAnchorCount])
    error('aligned:SimilaritySizeMismatch', 'similarityMatrix 的尺寸与锚点数量不一致。');
end

edgeMask = hardMatch > 0;
positiveSimilarity = max(similarityMatrix, 0);
addedCoverageEdges = 0;
if viewAnchorCount < baseAnchorCount
    uncoveredBase = find(sum(edgeMask, 2) == 0);
    for i = 1:numel(uncoveredBase)
        baseIndex = uncoveredBase(i);
        [~, bestViewAnchor] = max(similarityMatrix(baseIndex, :));
        edgeMask(baseIndex, bestViewAnchor) = true;
        addedCoverageEdges = addedCoverageEdges + 1;
    end
    % 当源视图锚点更少时，同一源锚点可能覆盖多个基准锚点；后续按该源锚点
    % 的覆盖集合归一化，使其关系质量在多个基准锚点之间分配。
    normalizationMode = 'oneToManyByViewAnchor';
else
    normalizationMode = 'manyToOneByBaseAnchor';
end

weightMatrix = zeros(size(hardMatch), class(hardMatch));
switch normalizationMode
    case 'oneToManyByViewAnchor'
        for viewIndex = 1:viewAnchorCount
            baseSet = find(edgeMask(:, viewIndex));
            if isempty(baseSet)
                continue;
            end
            weights = positiveSimilarity(baseSet, viewIndex);
            weights = normalize_edge_weights(weights);
            weightMatrix(baseSet, viewIndex) = weights;
        end
    case 'manyToOneByBaseAnchor'
        for baseIndex = 1:baseAnchorCount
            viewSet = find(edgeMask(baseIndex, :));
            if isempty(viewSet)
                continue;
            end
            weights = positiveSimilarity(baseIndex, viewSet);
            weights = normalize_edge_weights(weights);
            weightMatrix(baseIndex, viewSet) = weights;
        end
    otherwise
        error('aligned:UnknownNormalizationMode', '未知加权归一化模式：%s。', normalizationMode);
end

alignedGraph = weightMatrix * viewGraph;
alignedGraph = normalize_anchor_graph_columns(alignedGraph);
assert_valid_anchor_graph(alignedGraph, '单视图加权对齐锚图');

weightedInfo = struct();
weightedInfo.methodName = 'SimilarityWeightedAnchorGraphColumns';
weightedInfo.normalizationMode = normalizationMode;
weightedInfo.addedCoverageEdges = addedCoverageEdges;
weightedInfo.edgeCount = nnz(edgeMask);
weightedInfo.emptyBaseAnchorsAfterCoverage = sum(sum(edgeMask, 2) == 0);
weightedInfo.minWeight = min(weightMatrix(:));
weightedInfo.maxWeight = max(weightMatrix(:));
weightedInfo.meanPositiveSimilarity = mean(positiveSimilarity(edgeMask));
weightedInfo.hardMaxObjective = alignment_max_objective(baseStructure, viewStructure, K, c, hardMatch);
weightedInfo.weightedMaxObjective = alignment_max_objective(baseStructure, viewStructure, K, c, weightMatrix);
weightedInfo.weightedLossObjective = alignment_loss_objective(baseStructure, viewStructure, K, c, weightMatrix);
weightedInfo.note = ['weightedMaxObjective 用于诊断相似度加权后的连续匹配矩阵，' ...
    '不替代 DSPFP 的硬匹配收敛轨迹。'];
end

function weights = normalize_edge_weights(weights)
weights = real(weights(:));
weightSum = sum(weights);
if weightSum <= eps(class(weights)) || any(~isfinite(weights))
    weights = ones(size(weights), class(weights)) / numel(weights);
else
    weights = weights / weightSum;
end
end

function graph = normalize_anchor_graph_columns(graph)
graph = max(real(graph), 0);
columnSum = sum(graph, 1);
invalidColumns = columnSum <= eps(class(graph)) | ~isfinite(columnSum);
if any(invalidColumns)
    graph(:, invalidColumns) = 1 / size(graph, 1);
    columnSum = sum(graph, 1);
end
graph = bsxfun(@rdivide, graph, max(columnSum, eps(class(graph))));
end

function assert_valid_anchor_graph(graph, graphName)
if any(~isfinite(graph(:)))
    error('aligned:InvalidAlignedGraph', '%s 出现 NaN 或 Inf。', graphName);
end
if min(graph(:)) < -1e-10
    error('aligned:NegativeAlignedGraph', '%s 存在明显负值。', graphName);
end
columnError = max(abs(sum(graph, 1) - 1));
if columnError > 1e-8
    error('aligned:InvalidAlignedGraphSum', '%s 的列和不为 1。', graphName);
end
end

function value = alignment_max_objective(A1, A2, K, c, P)
featureTerm = sum(sum(K .* P));
structureTerm = trace(A1 * P * A2 * P');
value = featureTerm + c * structureTerm;
end

function value = alignment_loss_objective(A1, A2, K, c, P)
PAPt = P * A2 * P';
featureLoss = trace(A1) - 2 * sum(sum(K .* P)) + trace(PAPt);
structureResidual = A1 - PAPt;
structureLoss = sum(sum(structureResidual .^ 2));
value = featureLoss + c * structureLoss;
end

function totalTrace = aggregate_trace(traceList)
validMask = cellfun(@(x) ~isempty(x), traceList);
if ~any(validMask)
    totalTrace = [];
    return;
end

validTraces = traceList(validMask);
maxLen = max(cellfun(@numel, validTraces));
totalTrace = zeros(maxLen, 1);
for i = 1:numel(validTraces)
    traceVec = validTraces{i}(:);
    paddedTrace = zeros(maxLen, 1);
    paddedTrace(1:numel(traceVec)) = traceVec;
    if numel(traceVec) < maxLen
        paddedTrace(numel(traceVec) + 1:end) = traceVec(end);
    end
    totalTrace = totalTrace + paddedTrace;
end
end
