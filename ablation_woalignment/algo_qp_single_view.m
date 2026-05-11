function [UU, A, Z, iter, obj] = algo_qp_single_view(X, Y, theta, beta)
%ALGO_QP_SINGLE_VIEW 基于单个基准视图执行锚图学习与谱嵌入。
%   [UU, A, Z, ITER, OBJ] = ALGO_QP_SINGLE_VIEW(X, Y, THETA, BETA)
%   保留 3AMVC 中单视图锚图学习的优化形式，但跳过跨视图对齐与融合，
%   用于 w/o alignment 消融实验。

validateattributes(X, {'double', 'single'}, {'2d', 'nonempty', 'real'}, mfilename, 'X', 1);
validateattributes(Y, {'double', 'single'}, {'vector', 'nonempty', 'real'}, mfilename, 'Y', 2);
validateattributes(theta, {'double', 'single'}, {'2d', 'nonempty', 'real'}, mfilename, 'theta', 3);
validateattributes(beta, {'double', 'single'}, {'scalar', 'real', 'finite', 'nonnegative'}, mfilename, 'beta', 4);

if any(~isfinite(X(:))) || any(~isfinite(Y(:))) || any(~isfinite(theta(:)))
    error('algo_qp_single_view:InvalidInput', '输入 X、Y 或 theta 含有 NaN 或 Inf。');
end

numsample = size(Y, 1);
if size(X, 1) ~= numsample
    error('algo_qp_single_view:SizeMismatch', 'X 的样本数与 Y 的长度不一致。');
end

maxIter = 50;
A = theta';
Xstd = mapstd(X', 0, 1);

M = A' * Xstd;
for ii = 1:numsample
    idx = 1:size(theta, 1);
    pp(idx, ii) = EProjSimplex_new(M(idx, ii)); %#ok<AGROW>
end
Z = pp;
clear pp;

flag = true;
iter = 0;
obj = [];

while flag
    iter = iter + 1;

    if size(A, 1) < size(A, 2)
        A = Xstd * Z' * pinv(Z * Z');
    else
        C = Xstd * Z';
        [Utmp, ~, Vtmp] = svd(C, 'econ');
        A = Utmp * Vtmp';
    end

    M = (A' * Xstd) / (1 + beta);
    for ii = 1:numsample
        idx = 1:size(theta, 1);
        pp(idx, ii) = EProjSimplex_new(M(idx, ii)); %#ok<AGROW>
    end
    Z = pp;
    clear pp;

    obj(iter) = norm(Xstd - A * Z, 'fro')^2 + beta * norm(Z, 'fro')^2; %#ok<AGROW>

    if (iter > 9) && (abs((obj(iter - 1) - obj(iter)) / max(obj(iter - 1), eps)) < 1e-6 || iter > maxIter || obj(iter) < 1e-10)
        assert(all(isfinite(Z(:))), '单视图锚图 Z 出现 NaN 或 Inf。');
        assert(max(abs(sum(Z, 1) - 1)) < 1e-8, '单视图锚图 Z 的列和不为 1。');
        assert(min(Z(:)) >= -1e-10, '单视图锚图 Z 存在明显负值。');
        [UU, ~, ~] = svd(Z', 'econ');
        flag = false;
    end
end
end
