function [res_neighbor, time_neighbor, label_neighbor, object, theta, class, info] = Neighbor_BICLR(X0, Y, options)
%NEIGHBOR_BICLR 基于 BIC-LR 的单视图锚点生成与质量评估入口。
%   [RES_NEIGHBOR, TIME_NEIGHBOR, LABEL_NEIGHBOR, OBJECT, THETA, CLASS, INFO]
%   = NEIGHBOR_BICLR(X0, Y, OPTIONS) 对单视图特征 X0 生成 BIC-LR 锚点。
%
%   输入参数：
%   X0      : n*d 的单视图特征矩阵。
%   Y       : n*1 的真实标签向量；若为空，则跳过聚类质量评估。
%   options : BIC-LR 参数结构体，传递给 BIC_LR_HBNC。
%
%   输出参数：
%   res_neighbor   : 1*8 指标向量，[ACC nmi Purity Fscore Precision Recall AR Entropy]。
%                    若未提供 Y，则返回空数组。
%   time_neighbor  : 锚点生成耗时（秒）。
%   label_neighbor : n*1 向量，样本所属锚点节点标签。
%   object         : m*1 向量，每个锚点的簇内平方误差。
%   theta          : m*d 矩阵，每行为一个锚点中心。
%   class          : 最终锚点数量。
%   info           : 结构体，附带 BIC 证据校准质量、总 SSE 和配置参数。
%
%   See also BIC_LR_HBNC, Neighbor

if nargin < 2
    Y = [];
end
if nargin < 3
    options = struct();
end

ensure_biclr_support_path();

tic;
[label_neighbor, object, theta, ~, class, info] = BIC_LR_HBNC(X0, options);
time_neighbor = toc;

if isempty(Y)
    res_neighbor = [];
else
    validateattributes(Y, {'double', 'single'}, {'vector', 'nonempty', 'real'}, mfilename, 'Y', 2);
    Y = Y(:);
    if size(X0, 1) ~= numel(Y)
        error('Neighbor_BICLR:SizeMismatch', 'X0 的样本数与 Y 的长度不一致。');
    end
    res_neighbor = Clustering8Measure(Y, label_neighbor);
end

if ~isfield(info, 'viewEvidence') || ~isfield(info.viewEvidence, 'qualityScore')
    info.viewEvidence = biclr_view_evidence(X0, object, info.anchorSizes, info.options);
end
info.legacySSEQuality = info.totalSSE;
info.qualityMethod = 'BICUnitEvidenceGain';
info.qualityScore = info.viewEvidence.qualityScore;
info.unitBICEvidence = info.viewEvidence.unitGain;
info.relativeBICEvidence = info.viewEvidence.unitGain;
info.bicEvidenceGain = info.viewEvidence.deltaBIC;
info.timeNeighbor = time_neighbor;
end

function ensure_biclr_support_path()
persistent hasAddedPath;

if ~isempty(hasAddedPath) && hasAddedPath
    return;
end

thisDir = fileparts(mfilename('fullpath'));
biclrDir = fullfile(thisDir, 'biclr');
measureDir = fullfile(thisDir, 'measure');
if exist(biclrDir, 'dir')
    addpath(biclrDir);
end
if exist(measureDir, 'dir')
    addpath(measureDir);
end

hasAddedPath = true;
end
