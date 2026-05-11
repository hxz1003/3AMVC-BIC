clear;
warning off;
clc;

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(rootDir));

seed = 1;
rng(seed, 'twister');

config = build_biclr_refined_config('MFeat_2Views', seed);
results = run_biclr_grid_search('MFeat_2Views', config);
bestInfo = save_best_biclr_acc_result(results, config.saveDir); %#ok<NASGU>

fprintf(['MFeat_2Views 精细搜索完成。固定随机种子=%d，按 ACC 选择的最优参数：' ...
    'beta=%g，lambda=%g，lambdaBIC=%g，minNodeSize=%d，ACC=%.4f\\n'], ...
    seed, results.best.beta, results.best.lambda, results.best.lambdaBIC, ...
    results.best.minNodeSize, results.best.metricsMean(1));
