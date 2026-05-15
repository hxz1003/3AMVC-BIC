clear; clc;
thisFile = mfilename('fullpath');
ablationRoot = fileparts(fileparts(fileparts(thisFile)));
repoRoot = fileparts(ablationRoot);
mainCodeRoot = fullfile(repoRoot, '3AMVC-main');
addpath(genpath(mainCodeRoot));
addpath(genpath(ablationRoot));

methodName = 'A4_woMultiViewFusion';
datasetName = 'Catlch101All';
config = get_default_grid_config();
config = get_dataset_grid_config(datasetName, config);
config = get_method_config(methodName, config);
resultSummary = run_one_biclr_ablation(methodName, datasetName, config);
disp(resultSummary.selectedConfig);
fprintf('结果保存路径：%s\n', resultSummary.resultSavePath);
fprintf('ACC/NMI/AR = %.4f / %.4f / %.4f\n', resultSummary.metricsMean.ACC, resultSummary.metricsMean.NMI, resultSummary.metricsMean.AR);
