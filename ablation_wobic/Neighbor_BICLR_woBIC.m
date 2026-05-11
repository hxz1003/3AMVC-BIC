function [res_neighbor, time_neighbor, label_neighbor, object, theta, class, info] = Neighbor_BICLR_woBIC(X0, Y, options)
%NEIGHBOR_BICLR_WOBIC 基于去除 BIC 惩罚的 BIC-LR 变体生成单视图锚点。
%   [RES_NEIGHBOR, TIME_NEIGHBOR, LABEL_NEIGHBOR, OBJECT, THETA, CLASS, INFO]
%   = NEIGHBOR_BICLR_WOBIC(X0, Y, OPTIONS) 在保留似然比建模和投影扫描的前提下，
%   强制将 lambdaBIC 固定为 0，用于实现 w/o BIC 消融实验。
%
%   输入参数：
%   X0      : n*d 的单视图特征矩阵。
%   Y       : n*1 的真实标签向量；若为空，则跳过预评价。
%   options : 结构体参数，支持 minNodeSize、tauSplit、epsVar、maxAnchors、
%             verbose、randomSeed 等字段；其中 lambdaBIC 会被强制覆写为 0。
%
%   输出参数：
%   res_neighbor   : 1*8 聚类指标向量；若未提供 Y，则返回空数组。
%   time_neighbor  : 锚点生成耗时（秒）。
%   label_neighbor : n*1 样本所属锚点标签。
%   object         : m*1 每个锚点节点的 SSE。
%   theta          : m*d 锚点中心矩阵。
%   class          : 锚点数量。
%   info           : 附加信息结构体。
%
%   注意事项：
%   1. 本函数只用于 w/o BIC 消融，不应作为当前主方法入口。
%   2. 本函数会自动补充 3AMVC-main 的核心路径。

if nargin < 2
    Y = [];
end
if nargin < 3
    options = struct();
end

ensure_core_path();
options.lambdaBIC = 0;

tic;
[label_neighbor, object, theta, ~, class, info] = BIC_LR_HBNC(X0, options);
time_neighbor = toc;

if isempty(Y)
    res_neighbor = [];
else
    validateattributes(Y, {'double', 'single'}, {'vector', 'nonempty', 'real'}, mfilename, 'Y', 2);
    Y = Y(:);
    if size(X0, 1) ~= numel(Y)
        error('Neighbor_BICLR_woBIC:SizeMismatch', 'X0 的样本数与 Y 的长度不一致。');
    end
    res_neighbor = Clustering8Measure(Y, label_neighbor);
end

info.methodName = 'BICLR_woBIC';
info.lambdaBIC = 0;
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
