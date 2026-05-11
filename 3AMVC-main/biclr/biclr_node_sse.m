function sse = biclr_node_sse(X)
%BICLR_NODE_SSE 计算当前节点的簇内平方误差。
%   SSE = BICLR_NODE_SSE(X) 返回样本矩阵 X 的簇内平方误差。
%
%   输入参数：
%   X : n*d 的实数矩阵，每一行为一个样本。
%
%   输出参数：
%   sse : 标量，定义为 sum_i ||x_i - mean(X)||_2^2。
%
%   维度说明：
%   n 为样本数，d 为特征维度。
%
%   注意事项：
%   1. 本函数假设 X 中不包含 NaN 或 Inf。
%   2. 当 n=1 时，返回 0。

validateattributes(X, {'double', 'single'}, {'2d', 'nonempty', 'real'}, mfilename, 'X', 1);
if any(~isfinite(X(:)))
    error('biclr_node_sse:InvalidData', '输入矩阵 X 含有 NaN 或 Inf，请先检查数据预处理。');
end

n = size(X, 1);
if n == 1
    sse = 0;
    return;
end

sumX = sum(X, 1);
sumSq = sum(sum(X.^2, 2), 1);
sse = sumSq - sum(sumX.^2, 2) / n;
sse = max(real(sse), 0);
end
