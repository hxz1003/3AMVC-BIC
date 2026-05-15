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
            ['A2 is intentionally not implemented in this ablation framework. ' ...
             'It will be handled using the original 3AMVC GitHub code and the paper/supplement results.']);
    otherwise
        error('get_method_config:UnknownMethod', ...
            '未知消融方法：%s。当前仅支持 A0_Full_Reference、A1_woBIC_Joint、A3_SSETarget、A4_woMultiViewFusion。', ...
            methodName);
end
end
