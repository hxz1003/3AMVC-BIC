function [targetView, qualityScores, unitGains] = biclr_select_target_view(infoAll)
%BICLR_SELECT_TARGET_VIEW 按单位 BIC 证据增益选择基准视图。
%   [TARGETVIEW, QUALITYSCORES, UNITGAINS] = BICLR_SELECT_TARGET_VIEW(INFOALL)
%   从每个视图的 BIC-LR INFO 结构体中读取单位 BIC 证据增益，并选择
%   unitGain 最大的视图作为 3AMVC 跨视图对齐的基准视图。
%
%   输入参数：
%   infoAll : v*1 或 1*v 的 cell 数组，每个单元为 Neighbor_BICLR 返回的
%             info 结构体。
%
%   输出参数：
%   targetView    : 基准视图编号，若多个视图并列则选择编号最小者。
%   qualityScores : v*1 向量，定义为 -unitGains，兼容旧式“越小越好”质量分。
%   unitGains     : v*1 向量，每个视图的单位 BIC 证据增益，越大表示锚点
%                   划分相对单簇模型的统计证据越强。
%
%   注意事项：
%   本函数不引入 rho、tauS 或质量加权融合，只负责选择原始 3AMVC 等权
%   融合流程中的 target_view。
%
%   See also biclr_view_evidence, Neighbor_BICLR

validateattributes(infoAll, {'cell'}, {'vector', 'nonempty'}, mfilename, 'infoAll', 1);

numViews = numel(infoAll);
unitGains = zeros(numViews, 1);
for iv = 1:numViews
    info = infoAll{iv};
    if isempty(info) || ~isstruct(info)
        error('biclr_select_target_view:InvalidInfo', '第 %d 个视图的 info 不是有效结构体。', iv);
    end
    unitGains(iv) = extract_unit_gain(info, iv);
end

if any(~isfinite(unitGains))
    error('biclr_select_target_view:InvalidUnitGain', '单位 BIC 证据增益中出现 NaN 或 Inf。');
end

qualityScores = -unitGains;
[~, targetView] = max(unitGains);
end

function unitGain = extract_unit_gain(info, viewIndex)
if isfield(info, 'viewEvidence') && isstruct(info.viewEvidence) ...
        && isfield(info.viewEvidence, 'unitGain') && ~isempty(info.viewEvidence.unitGain)
    unitGain = info.viewEvidence.unitGain;
elseif isfield(info, 'unitBICEvidence') && ~isempty(info.unitBICEvidence)
    unitGain = info.unitBICEvidence;
elseif isfield(info, 'relativeBICEvidence') && ~isempty(info.relativeBICEvidence)
    unitGain = info.relativeBICEvidence;
elseif isfield(info, 'qualityScore') && ~isempty(info.qualityScore)
    unitGain = -info.qualityScore;
else
    error('biclr_select_target_view:MissingUnitGain', ...
        '第 %d 个视图缺少 unitGain、unitBICEvidence 或 qualityScore 字段。', viewIndex);
end

validateattributes(unitGain, {'double', 'single'}, {'scalar', 'real', 'finite'}, mfilename, 'unitGain');
unitGain = double(unitGain);
end
