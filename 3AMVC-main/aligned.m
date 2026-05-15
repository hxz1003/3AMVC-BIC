function [S, T, info] = aligned(Z, c, target_view)
%ALIGNED 对齐多视图锚图并记录补充材料中的 PFPA 目标函数轨迹。
%   [S, T] = ALIGNED(Z, C, TARGET_VIEW) 使用 TARGET_VIEW 作为基准视图，
%   调用 DSPFP 对齐其他视图的锚图，并返回融合锚图 S 与匹配矩阵 T。
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
%   T    : 每个视图到基准视图的匹配矩阵 cell。
%   INFO : 对齐阶段诊断信息与目标函数轨迹。

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

for nv = 1:numview
    if nv ~= target_view
        K = Z{target_view} * Z{nv}';
        S1 = Z{target_view} * Z{target_view}';
        S2 = Z{nv} * Z{nv}';
        [T{nv}, pairInfo{nv}] = DSPFP(S1, S2, K, c);
        maxTraceList{nv} = pairInfo{nv}.maxObjectiveTrace(:);
        lossTraceList{nv} = pairInfo{nv}.lossObjectiveTrace(:);
        S = S + T{nv} * Z{nv};
    end
end
S = S / numview;

info = struct();
info.targetView = target_view;
info.lambda = c;
info.pairInfo = pairInfo;
info.maxObjectiveTraceByView = maxTraceList;
info.lossObjectiveTraceByView = lossTraceList;
info.totalMaxObjectiveTrace = aggregate_trace(maxTraceList);
info.totalLossObjectiveTrace = aggregate_trace(lossTraceList);
info.objectiveName = 'SupplementEq2AlignmentMaxObjective';
info.lossName = 'SupplementEq1AlignmentLoss';
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
    trace = validTraces{i}(:);
    paddedTrace = zeros(maxLen, 1);
    paddedTrace(1:numel(trace)) = trace;
    if numel(trace) < maxLen
        paddedTrace(numel(trace) + 1:end) = trace(end);
    end
    totalTrace = totalTrace + paddedTrace;
end
end
