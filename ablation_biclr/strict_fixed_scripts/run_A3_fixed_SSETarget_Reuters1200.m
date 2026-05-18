% 本脚本是 fixed-parameter strict ablation。
% 参数来自 A0 best；不执行 grid search；只把目标视图选择准则改为 SSEMin；
% 其余参数保持 A0 best 配置不变。
strictRoot = fileparts(mfilename('fullpath'));
addpath(fullfile(strictRoot, 'helpers'));
result = run_strict_fixed_ablation_case('A3_fixed_SSETarget', 'Reuters-1200');
