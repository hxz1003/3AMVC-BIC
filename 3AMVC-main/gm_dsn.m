function M = gm_dsn(X)
%GM_DSN 对输入矩阵执行固定次数的双随机归一化近似。
%   M = GM_DSN(X) 对方阵 X 做 30 轮投影归一化，返回非负矩阵 M。
%
%   输入参数：
%   X : n*n 的实数矩阵。
%
%   输出参数：
%   M : 与 X 同尺寸的非负归一化矩阵。
%
%   注意事项：
%   本函数由 DSPFP 调用，用于投影固定点算法中的 Gamma 投影近似。

validateattributes(X, {'double', 'single'}, {'2d', 'square', 'nonempty', 'real'}, mfilename, 'X', 1);
if any(~isfinite(X(:)))
    error('gm_dsn:InvalidInput', '输入矩阵 X 中含有 NaN 或 Inf。');
end

n = size(X, 1);

for outerIter = 1:30
    rowMean = sum(X, 2)' / n;
    colMean = sum(X, 1) / n;

    X = X + 1 / n + sum(rowMean) / n;

    for rowIndex = 1:n
        X(rowIndex, :) = X(rowIndex, :) - colMean;
        X(:, rowIndex) = X(:, rowIndex) - rowMean';
    end

    X = (X + abs(X)) / 2;
end
M = X;
end
