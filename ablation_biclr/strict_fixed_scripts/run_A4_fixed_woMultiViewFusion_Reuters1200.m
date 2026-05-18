% 本脚本是 fixed-parameter strict ablation。
% 参数来自 A0 best；不执行 grid search；只关闭多视图对齐融合；
% lambda 记录但不参与计算，其余参数保持 A0 best 配置不变。
strictRoot = fileparts(mfilename('fullpath'));
addpath(fullfile(strictRoot, 'helpers'));
result = run_strict_fixed_ablation_case('A4_fixed_woMultiViewFusion', 'Reuters-1200');
