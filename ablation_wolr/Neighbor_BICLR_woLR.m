function [res_neighbor, time_neighbor, label_neighbor, object, theta, class, info] = Neighbor_BICLR_woLR(X0, Y, options)
%NEIGHBOR_BICLR_WOLR 基于非似然 SSE 二分准则生成单视图锚点。
%   本函数用于 w/o LR 消融：保留递归二分、投影扫描和 minNodeSize，
%   但不使用单簇/双簇高斯似然比，而改用 SSE 改善量作为分裂得分。

if nargin < 2
    Y = [];
end
if nargin < 3
    options = struct();
end

ensure_core_path();

tic;
[label_neighbor, object, theta, ~, class, info] = WO_LR_HBNC(X0, options);
time_neighbor = toc;

if isempty(Y)
    res_neighbor = [];
else
    validateattributes(Y, {'double', 'single'}, {'vector', 'nonempty', 'real'}, mfilename, 'Y', 2);
    Y = Y(:);
    if size(X0, 1) ~= numel(Y)
        error('Neighbor_BICLR_woLR:SizeMismatch', 'X0 的样本数与 Y 的长度不一致。');
    end
    res_neighbor = Clustering8Measure(Y, label_neighbor);
end

info.methodName = 'woLR';
info.qualityScore = sum(object);
info.timeNeighbor = time_neighbor;
end

function ensure_core_path()
persistent hasAddedPath;

if ~isempty(hasAddedPath) && hasAddedPath
    return;
end

thisDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(thisDir);
coreDir = fullfile(projectRoot, '3AMVC-main');

addpath(genpath(coreDir));
hasAddedPath = true;
end
