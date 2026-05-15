function [res_neighbor, time_neighbor, label_neighbor, object, theta, class] = Neighbor(X0, Y, options)
%NEIGHBOR 原始 3AMVC 的单视图锚点生成入口。
%   [RES_NEIGHBOR, TIME_NEIGHBOR, LABEL_NEIGHBOR, OBJECT, THETA, CLASS]
%   = NEIGHBOR(X0, Y) 使用原始 HBNC 路径生成锚点。
%
%   [...] = NEIGHBOR(X0, Y, OPTIONS) 将 OPTIONS 传给 Pre_HBNC，当前主要
%   用于控制 OPTIONS.randomSeed，保证原始路径可复现。

if nargin < 3
    options = struct();
end
validateattributes(X0, {'double', 'single'}, {'2d', 'nonempty', 'real'}, mfilename, 'X0', 1);
validateattributes(Y, {'double', 'single'}, {'vector', 'nonempty', 'real'}, mfilename, 'Y', 2);
Y = Y(:);
if any(~isfinite(X0(:))) || any(~isfinite(Y(:)))
    error('Neighbor:InvalidInput', 'X0 或 Y 含有 NaN 或 Inf，请先检查数据。');
end
if size(X0, 1) ~= numel(Y)
    error('Neighbor:SizeMismatch', 'X0 的样本数与 Y 的长度不一致。');
end
if ~isfield(options, 'randomSeed')
    options.randomSeed = 1;
end

if ~isempty(options.randomSeed)
    rngState = rng;
    cleanupObj = onCleanup(@() rng(rngState));
    rng(options.randomSeed, 'twister');
end

preOptions = options;
preOptions.randomSeed = [];
 tic
 [label_pre,object_pre,~,~,~] = Pre_HBNC(X0, preOptions);
 [label,object,theta,~,class] = Impro_HBNC(X0,label_pre,object_pre);
%%  Organize label results

label_neighbor = label;
res_neighbor = Clustering8Measure(Y, label_neighbor);
time_neighbor = toc;

end
