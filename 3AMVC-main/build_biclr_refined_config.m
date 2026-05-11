function config = build_biclr_refined_config(datasetName, randomSeed)
%BUILD_BICLR_REFINED_CONFIG 为指定数据集构造 BIC-LR 精细搜索配置。
%   CONFIG = BUILD_BICLR_REFINED_CONFIG(DATASETNAME, RANDOMSEED) 根据已有
%   粗搜索敏感度分析结果，为指定数据集返回精细搜索配置。
%
%   输入参数：
%   datasetName : 数据集名称，不带 .mat 后缀。
%   randomSeed  : 固定随机种子，用于评价阶段复现；若省略，则默认 1。
%
%   输出参数：
%   config : 可直接传给 RUN_BICLR_GRID_SEARCH 的配置结构体。
%
%   注意事项：
%   1. 本函数默认按 ACC 选择最优组合。
%   2. 各数据集的 lambda 网格被有意压缩，因为前一轮敏感度分析表明
%      lambda 对 ACC 的影响显著小于 beta、lambdaBIC 和 minNodeSize。

if nargin < 2 || isempty(randomSeed)
    randomSeed = 1;
end

if isstring(datasetName)
    datasetName = char(datasetName);
end
validateattributes(datasetName, {'char'}, {'row', 'nonempty'}, mfilename, 'datasetName', 1);
validateattributes(randomSeed, {'double', 'single'}, {'scalar', 'integer', 'nonnegative', 'finite'}, mfilename, 'randomSeed', 2);

rootDir = fileparts(mfilename('fullpath'));
config = struct();

switch lower(datasetName)
    case 'mfeat_2views'
        config.betaList = [80 100 120 160];
        config.lambdaList = [1e3 3e3 1e4];
        config.lambdaBICList = [0.5 0.75 1 1.5 2];
        config.minNodeSizeList = [24 32 40 48];
        maxAnchors = 400;
        numRuns = 10;
        kmeansReplicates = 4;
        removeClutter = false;
    case 'reuters-1200'
        config.betaList = [50 75 100 125];
        config.lambdaList = [1e2 3e2 1e3];
        config.lambdaBICList = [0.5 0.75 1 1.25];
        config.minNodeSizeList = [8 10 12 16];
        maxAnchors = 300;
        numRuns = 8;
        kmeansReplicates = 4;
        removeClutter = false;
    case 'caltech101-all'
        config.betaList = [5 10 15 20];
        config.lambdaList = [3e2 1e3 3e3];
        config.lambdaBICList = [1 1.5 2];
        config.minNodeSizeList = [40 60 80 120 160];
        maxAnchors = 500;
        numRuns = 6;
        kmeansReplicates = 3;
        removeClutter = false;
    case 'wikifea'
        config.betaList = [80 100 120 160];
        config.lambdaList = [1e2 3e2 1e3];
        config.lambdaBICList = [2 2.5 3 3.5 4];
        config.minNodeSizeList = [20 30 40 50];
        maxAnchors = 400;
        numRuns = 8;
        kmeansReplicates = 4;
        removeClutter = false;
    otherwise
        error('build_biclr_refined_config:UnsupportedDataset', '未为数据集 %s 预设精细搜索网格。', datasetName);
end

config.anchorOptions = struct( ...
    'tauSplit', 0, ...
    'epsVar', 1e-8, ...
    'maxAnchors', maxAnchors, ...
    'verbose', false, ...
    'randomSeed', randomSeed);

config.evalOptions = struct( ...
    'numRuns', numRuns, ...
    'kmeansReplicates', kmeansReplicates, ...
    'useParallel', false, ...
    'baseSeed', randomSeed);

config.preprocessTag = 'raw';
config.useCache = true;
config.verbose = true;
config.verboseAnchors = false;
config.removeClutter = removeClutter;
config.selectionMetricName = 'ACC';
config.storeDetailedModel = false;
config.saveDir = fullfile(rootDir, 'res_biclr_refined');
config.cacheDir = fullfile(rootDir, 'cache');
end
