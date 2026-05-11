clear;
warning off;
clc;

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(rootDir));

seed = 1;
rng(seed, 'twister');

config = build_biclr_refined_config('Caltech101-all', seed);
results = run_biclr_grid_search('Caltech101-all', config);
bestInfo = save_best_biclr_acc_result(results, config.saveDir); %#ok<NASGU>

fprintf(['Caltech101-all 精细搜索完成。固定随机种子=%d，按 ACC 选择的最优参数：' ...
    'beta=%g，lambda=%g，lambdaBIC=%g，minNodeSize=%d，ACC=%.4f\\n'], ...
    seed, results.best.beta, results.best.lambda, results.best.lambdaBIC, ...
    results.best.minNodeSize, results.best.metricsMean(1));
 
