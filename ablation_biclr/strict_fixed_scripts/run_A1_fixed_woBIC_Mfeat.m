% 本脚本是 fixed-parameter strict ablation。
% 参数来自 A0 best；不执行 grid search；只关闭 BIC 复杂度惩罚；
% 其余参数保持 A0 best 配置不变。
strictRoot = fileparts(mfilename('fullpath'));
addpath(fullfile(strictRoot, 'helpers'));
result = run_strict_fixed_ablation_case('A1_fixed_woBIC', 'Mfeat');
