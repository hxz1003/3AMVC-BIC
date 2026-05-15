function config = get_default_grid_config()
%GET_DEFAULT_GRID_CONFIG 返回消融实验通用默认配置。
%   CONFIG = GET_DEFAULT_GRID_CONFIG() 设置与 A0_Full 尽量一致的随机种子、
%   评价次数、缓存开关、选择规则和工程参数。
%
%   注意事项：
%   当前仓库 A0 相关脚本中可解析到的默认随机种子为 1，因此本框架默认
%   使用 seeds = 1。若后续需要多 seed 均值，请在此处显式修改。

paths = get_project_paths();

config = struct();
config.seeds = 1;
config.seedsSource = '已从 3AMVC-main 中 A0 相关脚本解析到 randomSeed/baseSeed=1。';
config.numRuns = 10;
config.kmeansReplicates = 4;
config.tauSplit = 0;
config.epsVar = 1e-8;
config.selectionMetric = 'ACC';
config.selectionRule = 'best_mean_ACC_then_NMI';
config.saveEveryConfig = true;
config.useCache = true;
config.smokeTest = false;
config.enableLargeDataset = false;
config.rerunA0 = false;
config.preprocessTag = 'raw';
config.removeClutter = false;
config.maxPerClass = [];
config.useParallel = false;
config.summaryMode = 'bestACC';
config.verbose = true;
config.verboseAnchors = false;
config.storeDetailedModel = false;
config.sourceMainCodeRoot = paths.mainCodeRoot;
config.resultRoot = paths.resRoot;
config.cacheRoot = paths.cacheRoot;
config.reportRoot = paths.reportRoot;

config.anchorOptions = struct();
config.anchorOptions.tauSplit = config.tauSplit;
config.anchorOptions.epsVar = config.epsVar;
config.anchorOptions.maxAnchors = 400;
config.anchorOptions.verbose = false;
config.anchorOptions.randomSeed = config.seeds(1);

config.evalOptions = struct();
config.evalOptions.numRuns = config.numRuns;
config.evalOptions.kmeansReplicates = config.kmeansReplicates;
config.evalOptions.useParallel = config.useParallel;
config.evalOptions.baseSeed = config.seeds(1);
config.evalOptions.summaryMode = config.summaryMode;
end
