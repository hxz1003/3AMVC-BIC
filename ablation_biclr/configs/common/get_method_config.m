function config = get_method_config(methodName, config)
%GET_METHOD_CONFIG 按消融方法修正配置。
%   CONFIG = GET_METHOD_CONFIG(METHODNAME, CONFIG) 设置 A0/A1/A3/A4 的方法
%   开关、目标视图选择规则和特殊参数。
%
%   当前框架不实现 A2_woLR_OriginalHBNC_Bridge。若传入 A2，会直接报错。

if nargin < 2 || isempty(config)
    config = get_default_grid_config();
end
if isstring(methodName)
    methodName = char(methodName);
end
validateattributes(methodName, {'char'}, {'row', 'nonempty'}, mfilename, 'methodName', 1);

config.methodName = methodName;
config.methodConfig = struct();
config.methodConfig.methodName = methodName;

switch methodName
    case 'A0_Full_Reference'
        config.rerunA0 = false;
        config.methodConfig.targetSelectionMethod = 'BICUnitEvidence';
        config.methodConfig.useBICPenalty = true;
        config.methodConfig.useBICLRAnchor = true;
        config.methodConfig.useMultiViewFusion = true;
        config.methodConfig.singleViewOnly = false;
    case 'A1_woBIC_Joint'
        config.lambdaBICList = 0;
        config.methodConfig.targetSelectionMethod = 'LRUnitEvidence';
        config.methodConfig.useBICPenalty = false;
        config.methodConfig.useBICLRAnchor = true;
        config.methodConfig.useMultiViewFusion = true;
        config.methodConfig.singleViewOnly = false;
    case 'A3_SSETarget'
        config.methodConfig.targetSelectionMethod = 'SSEMin';
        config.methodConfig.useBICPenalty = true;
        config.methodConfig.useBICLRAnchor = true;
        config.methodConfig.useMultiViewFusion = true;
        config.methodConfig.singleViewOnly = false;
        config.methodConfig.preferA0AnchorCache = true;
    case 'A4_woMultiViewFusion'
        config.lambdaList = NaN;
        config.methodConfig.targetSelectionMethod = 'BICUnitEvidence';
        config.methodConfig.useBICPenalty = true;
        config.methodConfig.useBICLRAnchor = true;
        config.methodConfig.useMultiViewFusion = false;
        config.methodConfig.singleViewOnly = true;
        config.methodConfig.preferA0AnchorCache = true;
    case 'A2_woLR_OriginalHBNC_Bridge'
        error('get_method_config:A2NotImplemented', ...
            ['A2 当前不在消融框架中实现，将使用原始 3AMVC 代码及论文/补充材料结果处理。']);
    otherwise
        error('get_method_config:UnknownMethod', ...
            '未知消融方法：%s。当前仅支持 A0_Full_Reference、A1_woBIC_Joint、A3_SSETarget、A4_woMultiViewFusion。', ...
            methodName);
end

config = apply_caltech256_reduced_ablation_grid(config);
end

function config = apply_caltech256_reduced_ablation_grid(config)
%APPLY_CALTECH256_REDUCED_ABLATION_GRID 为 Caltech256 消融设置约 40 组网格。
%   已有 Caltech256 日志显示，在完成的 240/256 组中，最优区域位于
%   beta=200、lambda=1000、lambdaBIC=3、minNodeSize=120 附近。本函数
%   对 A1/A3/A4 按方法收缩搜索空间，避免再次使用 256 组完整大网格。

if ~isfield(config, 'datasetInfo') || isempty(config.datasetInfo)
    return;
end
if ~strcmp(config.datasetInfo.resultDirName, 'Caltech256_4Views_257cls_withClutter')
    return;
end
if isfield(config, 'smokeTest') && config.smokeTest
    return;
end

switch config.methodName
    case 'A1_woBIC_Joint'
        % A1 固定 lambdaBIC=0。去掉 BIC 惩罚后更容易过分裂，因此保留
        % minNodeSize=80/120/160 来观察锚点数与性能的折中。
        config.betaList = [100 150 200];
        config.lambdaList = [500 1000 3000 10000];
        config.lambdaBICList = 0;
        config.minNodeSizeList = [80 120 160];
        config.caltech256ReducedGridSize = numel(config.betaList) ...
            * numel(config.lambdaList) * numel(config.lambdaBICList) ...
            * numel(config.minNodeSizeList);
        config.gridSource = [config.gridSource '；A1 Caltech256 消融网格按已有结果收缩为 36 组。'];
    case 'A3_SSETarget'
        % A3 只改目标视图选择，锚点生成仍应覆盖 A0 最优及相邻 BIC 参数。
        config.betaList = [100 150 200];
        config.lambdaList = [500 1000 3000 10000];
        config.lambdaBICList = [3 4];
        config.minNodeSizeList = [80 120];
        config.caltech256ReducedGridSize = numel(config.betaList) ...
            * numel(config.lambdaList) * numel(config.lambdaBICList) ...
            * numel(config.minNodeSizeList);
        config.gridSource = [config.gridSource '；A3 Caltech256 消融网格按已有结果收缩为 48 组。'];
    case 'A4_woMultiViewFusion'
        % A4 关闭多视图融合，lambda 固定为 NaN；保留 beta 和锚点生成参数。
        config.betaList = [80 100 150 200];
        config.lambdaList = NaN;
        config.lambdaBICList = [3 4 5];
        config.minNodeSizeList = [80 120 160];
        config.caltech256ReducedGridSize = numel(config.betaList) ...
            * numel(config.lambdaList) * numel(config.lambdaBICList) ...
            * numel(config.minNodeSizeList);
        config.gridSource = [config.gridSource '；A4 Caltech256 消融网格按已有结果收缩为 36 组。'];
    otherwise
        % A0_Full_Reference 及其他方法不收缩网格，保持原始完整搜索空间。
end
end
