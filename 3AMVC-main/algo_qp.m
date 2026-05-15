function [UU, A, Z, iter, obj, traceInfo] = algo_qp(X, Y, theta, beta, lambda, target_view)
%ALGO_QP 执行 3AMVC 主优化并在对齐阶段记录补充材料目标函数。
%   [UU, A, Z, ITER, OBJ] = ALGO_QP(X, Y, THETA, BETA, LAMBDA, TARGET_VIEW)
%   保持原始接口语义，OBJ 仍为主优化阶段的锚图重构目标。
%
%   [UU, A, Z, ITER, OBJ, TRACEINFO] = ALGO_QP(...) 额外返回对齐阶段
%   DSPFP/PFPA 的目标函数轨迹。TRACEINFO.alignmentMaxObjectiveTrace 对应
%   原 3AMVC 补充材料 Eq.(2)，适合绘制论文中的收敛曲线。
%
%   输入参数：
%   X           : cell 数组，每个单元为 n*d_i 的视图特征矩阵。
%   Y           : n*1 标签向量，仅用于确定聚类数。
%   THETA       : cell 数组，每个单元为 m_i*d_i 的锚点矩阵。
%   BETA        : 锚图正则化参数。
%   LAMBDA      : 对齐结构项权重。
%   TARGET_VIEW : 基准视图编号。
%
%   输出参数：
%   UU        : 融合锚图 SVD 后的嵌入矩阵。
%   A         : 每个视图的投影矩阵。
%   Z         : 融合后的锚图。
%   ITER      : 主优化阶段迭代次数。
%   OBJ       : 主优化阶段目标函数轨迹，保留向后兼容。
%   TRACEINFO : 对齐阶段补充材料目标函数轨迹与诊断信息。

%% initialize
maxIter = 50 ; % the number of iterations
numview = length(X);
numsample = size(Y,1);
M = cell(numview,1);
A = cell(numview, 1);
Zi = cell(numview, 1);

for i = 1:numview
    anchorCount = size(theta{i}, 1);
    A{i} = theta{i}';
    % 原始 3AMVC 主优化在视图内部执行标准化；锚点仅作为 A 的初始化，后续会在标准化空间更新。
    X{i} = mapstd(X{i}',0,1); % turn into d*n

    M{i} = A{i}' * X{i};
    pp = zeros(anchorCount, numsample);
    for ii = 1:numsample
        pp(:, ii) = EProjSimplex_new(M{i}(:, ii));
    end
    Zi{i} = pp;
end

flag = 1;
iter = 0;
obj = zeros(1, maxIter + 1);
traceInfo = struct();
%%
while flag
    iter = iter + 1;
    
    %% optimize A_i
    parfor ia = 1:numview
        if size(A{ia},1)<size(A{ia},2)
            A{ia} = X{ia}*Zi{ia}'*pinv(Zi{ia}*Zi{ia}');
        else
            C = X{ia}*Zi{ia}';      
            [U,~,V] = svd(C,'econ');
            A{ia} = U*V';
        end
    end
    
   %% optimize Z-i            

    for a=1:numview
        anchorCount = size(theta{a}, 1);
        M{a} = (A{a}'*X{a})/(1+beta);
        pp = zeros(anchorCount, numsample);
        for ii = 1:numsample
            pp(:, ii) = EProjSimplex_new(M{a}(:, ii));
        end
        Zi{a} = pp;
    end

    %%
    term1 = 0;
    term2 = 0;
    for iv = 1:numview
        term1 = term1 + norm(X{iv} - A{iv} * Zi{iv},'fro')^2;
        term2 = term2 + norm(Zi{iv},'fro')^2;
    end
    
    obj(iter) = term1+beta*term2;
    
    stopByRelativeChange = false;
    if iter > 9
        prevObjScale = max(abs(obj(iter - 1)), eps(class(obj)));
        relativeChange = abs((obj(iter - 1) - obj(iter)) / prevObjScale);
        stopByRelativeChange = relativeChange < 1e-6;
    end

    if (iter>9) && (stopByRelativeChange || iter>maxIter || obj(iter) < 1e-10)
        [Z, ~, alignmentInfo] = aligned(Zi, lambda, target_view);
        [UU,~,~]=svd(Z','econ');
        obj = obj(1:iter);
        traceInfo = build_trace_info(obj, alignmentInfo);
        flag = 0;
    end
end
end
         
         
function traceInfo = build_trace_info(graphObjTrace, alignmentInfo)
traceInfo = struct();
traceInfo.graphObjectiveTrace = graphObjTrace(:)';
traceInfo.alignmentInfo = alignmentInfo;
traceInfo.alignmentMaxObjectiveTrace = alignmentInfo.totalMaxObjectiveTrace(:)';
traceInfo.alignmentLossObjectiveTrace = alignmentInfo.totalLossObjectiveTrace(:)';
traceInfo.objectiveTraceForPlot = traceInfo.alignmentMaxObjectiveTrace;
traceInfo.objectiveTraceType = 'SupplementEq2AlignmentMaxObjective';
traceInfo.lossTraceType = 'SupplementEq1AlignmentLoss';
traceInfo.note = ['obj 保留原主优化锚图重构目标；objectiveTraceForPlot 使用' ...
    '补充材料 Eq.(2) 的对齐最大化目标。'];
end
    
