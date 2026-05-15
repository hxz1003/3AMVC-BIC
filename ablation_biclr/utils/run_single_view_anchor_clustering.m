function model = run_single_view_anchor_clustering(Xv, Y, theta, beta, options)
%RUN_SINGLE_VIEW_ANCHOR_CLUSTERING 运行目标视图的单视图锚图聚类。
%   MODEL = RUN_SINGLE_VIEW_ANCHOR_CLUSTERING(XV, Y, THETA, BETA, OPTIONS)
%   复用 3AMVC 中的锚图更新形式，仅对目标视图构造 Z 并从 Z' 的 SVD
%   得到谱嵌入。该函数用于 A4_woMultiViewFusion，不对未对齐多视图锚图
%   做平均。
%
%   输入参数：
%   XV      : n*d 的目标视图特征矩阵。
%   Y       : n*1 标签向量，仅用于确定样本数和类别数。
%   THETA   : m*d 的目标视图锚点矩阵。
%   BETA    : 锚图正则参数。
%   OPTIONS : 可选结构体，支持 maxIter 和 tol。
%
%   输出参数：
%   MODEL.U    : n*m 的谱嵌入。
%   MODEL.A    : d*m 的锚点投影矩阵。
%   MODEL.Z    : m*n 的单视图锚图。
%   MODEL.iter : 迭代次数。
%   MODEL.obj  : 单视图重构目标函数轨迹。
%
%   注意事项：
%   本函数关闭了跨视图对齐融合，因此 alignmentTime 在 A4 中记为 0。

if nargin < 5
    options = struct();
end
if ~isfield(options, 'maxIter') || isempty(options.maxIter)
    options.maxIter = 50;
end
if ~isfield(options, 'tol') || isempty(options.tol)
    options.tol = 1e-6;
end

validateattributes(Xv, {'double', 'single'}, {'2d', 'nonempty', 'real'}, mfilename, 'Xv', 1);
validateattributes(Y, {'double', 'single'}, {'vector', 'nonempty', 'real'}, mfilename, 'Y', 2);
validateattributes(theta, {'double', 'single'}, {'2d', 'nonempty', 'real'}, mfilename, 'theta', 3);
validateattributes(beta, {'double', 'single'}, {'scalar', 'real', 'finite', 'nonnegative'}, mfilename, 'beta', 4);
if any(~isfinite(Xv(:))) || any(~isfinite(theta(:)))
    error('run_single_view_anchor_clustering:InvalidInput', 'Xv 或 theta 含有 NaN/Inf。');
end
if size(Xv, 1) ~= numel(Y)
    error('run_single_view_anchor_clustering:SizeMismatch', 'Xv 样本数与 Y 长度不一致。');
end
if size(Xv, 2) ~= size(theta, 2)
    error('run_single_view_anchor_clustering:DimMismatch', 'Xv 维度与 theta 维度不一致。');
end

X = mapstd(double(Xv)', 0, 1);
numSamples = size(X, 2);
anchorCount = size(theta, 1);
A = double(theta)';
Z = zeros(anchorCount, numSamples);

for i = 1:numSamples
    Z(:, i) = EProjSimplex_new(A' * X(:, i));
end

obj = zeros(1, options.maxIter);
iter = 0;
while iter < options.maxIter
    iter = iter + 1;

    if size(A, 1) < size(A, 2)
        A = X * Z' * pinv(Z * Z');
    else
        C = X * Z';
        [U0, ~, V0] = svd(C, 'econ');
        A = U0 * V0';
    end

    M = (A' * X) / (1 + beta);
    for i = 1:numSamples
        Z(:, i) = EProjSimplex_new(M(:, i));
    end

    obj(iter) = norm(X - A * Z, 'fro')^2 + beta * norm(Z, 'fro')^2;
    if iter > 9
        prevScale = max(abs(obj(iter - 1)), eps);
        relChange = abs((obj(iter - 1) - obj(iter)) / prevScale);
        if relChange < options.tol || obj(iter) < 1e-10
            break;
        end
    end
end

obj = obj(1:iter);
if any(~isfinite(Z(:)))
    error('run_single_view_anchor_clustering:InvalidZ', '单视图锚图 Z 出现 NaN 或 Inf。');
end
if max(abs(sum(Z, 1) - 1)) > 1e-8
    error('run_single_view_anchor_clustering:InvalidZSum', '单视图锚图 Z 的列和不为 1。');
end
if min(Z(:)) < -1e-10
    error('run_single_view_anchor_clustering:NegativeZ', '单视图锚图 Z 存在明显负值。');
end

[U, ~, ~] = svd(Z', 'econ');
model = struct();
model.U = U;
model.A = A;
model.Z = Z;
model.iter = iter;
model.obj = obj;
model.traceInfo = struct('objectiveTraceForPlot', obj, ...
    'objectiveTraceType', 'SingleViewAnchorGraphObjective');
end
