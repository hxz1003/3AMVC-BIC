function [P, info] = DSPFP(A1, A2, K, c)
%DSPFP 使用投影固定点算法求解两个锚点集合的对齐矩阵。
%   P = DSPFP(A1, A2, K, C) 返回硬匹配矩阵 P。
%
%   [P, INFO] = DSPFP(...) 额外返回补充材料中 Eq.(2) 对应的 PFPA 目标函数
%   轨迹。当前代码中 P 的维度为 m_b*m_i，是论文中匹配矩阵的转置形式。
%
%   输入参数：
%   A1 : m_b*m_b 的基准视图锚点结构图 G_b。
%   A2 : m_i*m_i 的第 i 个视图锚点结构图 G_i。
%   K  : m_b*m_i 的跨视图锚图相似矩阵 Z_b*Z_i'。
%   C  : 对齐结构项权重，对应论文中的 lambda。
%
%   输出参数：
%   P    : m_b*m_i 的硬匹配矩阵。
%   INFO : 结构体，包含 relaxedP、maxObjectiveTrace、lossObjectiveTrace、
%          updateDeltaTrace 和迭代次数。
%
%   维度说明：
%   m_b 为基准视图锚点数，m_i 为当前非基准视图锚点数。
%
%   注意事项：
%   1. 补充材料 Eq.(2) 为最大化目标：
%        Tr(K'P) + lambda*Tr(G_b*P*G_i*P')
%      在本实现的转置记法下等价于 maxObjectiveTrace。
%   2. lossObjectiveTrace 记录 Eq.(1) 的等价最小化损失，仅用于诊断。

validateattributes(A1, {'double', 'single'}, {'2d', 'square', 'nonempty', 'real'}, mfilename, 'A1', 1);
validateattributes(A2, {'double', 'single'}, {'2d', 'square', 'nonempty', 'real'}, mfilename, 'A2', 2);
validateattributes(K, {'double', 'single'}, {'2d', 'nonempty', 'real'}, mfilename, 'K', 3);
validateattributes(c, {'double', 'single'}, {'scalar', 'real', 'finite'}, mfilename, 'c', 4);
if any(~isfinite(A1(:))) || any(~isfinite(A2(:))) || any(~isfinite(K(:)))
    error('DSPFP:InvalidInput', 'A1、A2 或 K 中含有 NaN 或 Inf。');
end

n1 = size(A1, 1);
n2 = size(A2, 1);
if ~isequal(size(K), [n1, n2])
    error('DSPFP:SizeMismatch', 'K 的尺寸必须为 size(A1,1)*size(A2,1)。');
end

X = ones(n1, n2) / (n1 * n2);
ep = inf;
index = 0;
maxIter = 50;
tol = 1e-6;
maxN = max(n1, n2);
Y = zeros(maxN, maxN);
alpha = 0.5;

maxObjectiveTrace = zeros(maxIter, 1);
lossObjectiveTrace = zeros(maxIter, 1);
updateDeltaTrace = zeros(maxIter, 1);

while ep >= tol && index < maxIter
    x = X;
    index = index + 1;

    % 补充材料 Eq.(3)：P(t+1) = (1-alpha)P(t) + alpha*Gamma(grad f(P(t)))。
    Y(:) = 0;
    Y(1:n1, 1:n2) = K + 2 * c * A1 * X * A2;
    Y = gm_dsn(Y);
    X = (1 - alpha) * X + alpha * Y(1:n1, 1:n2);
    scaleValue = max(max(abs(X)));
    if scaleValue > eps(class(X))
        X = X / scaleValue;
    end

    ep = max(max(abs(x - X)));
    updateDeltaTrace(index) = ep;
    maxObjectiveTrace(index) = alignment_max_objective(A1, A2, K, c, X);
    lossObjectiveTrace(index) = alignment_loss_objective(A1, A2, K, c, X);
end

maxObjectiveTrace = maxObjectiveTrace(1:index);
lossObjectiveTrace = lossObjectiveTrace(1:index);
updateDeltaTrace = updateDeltaTrace(1:index);

relaxedP = X;
P = X;
A = zeros(size(P));
for i = 1:size(P, 2)
    [~, j] = max(P(:, i));
    A(j, i) = 1;
end
P = A;

info = struct();
info.relaxedP = relaxedP;
info.iter = index;
info.maxObjectiveTrace = maxObjectiveTrace;
info.lossObjectiveTrace = lossObjectiveTrace;
info.updateDeltaTrace = updateDeltaTrace;
info.finalHardMaxObjective = alignment_max_objective(A1, A2, K, c, P);
info.finalHardLossObjective = alignment_loss_objective(A1, A2, K, c, P);
info.objectiveName = 'SupplementEq2AlignmentMaxObjective';
info.lossName = 'SupplementEq1AlignmentLoss';
%%%P=dis_greedy(X);
end

function value = alignment_max_objective(A1, A2, K, c, P)
featureTerm = sum(sum(K .* P));
structureTerm = trace(A1 * P * A2 * P');
value = featureTerm + c * structureTerm;
end

function value = alignment_loss_objective(A1, A2, K, c, P)
featureLoss = trace(A1) - 2 * sum(sum(K .* P)) + trace(P * A2 * P');
structureResidual = A1 - P * A2 * P';
structureLoss = sum(sum(structureResidual .^ 2));
value = featureLoss + c * structureLoss;
end
