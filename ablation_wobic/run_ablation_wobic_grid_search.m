function results = run_ablation_wobic_grid_search(datasetName, config)
%RUN_ABLATION_WOBIC_GRID_SEARCH 运行 w/o BIC 粗网格搜索。
%   RESULTS = RUN_ABLATION_WOBIC_GRID_SEARCH(DATASETNAME, CONFIG) 对指定数据集
%   执行“去掉 BIC 惩罚但保留 LR 建模”的粗筛实验，并按 best ACC 选出最优结果。
%
%   输入参数：
%   datasetName : 数据集名称，不带 .mat 后缀。
%   config      : 可选配置结构体，支持字段：
%                 - betaList / lambdaList / minNodeSizeList
%                 - anchorOptions / evalOptions
%                 - preprocessTag / useCache / saveDir / cacheDir
%                 - verbose / verboseAnchors / selectionMetricName
%
%   输出参数：
%   results : 结构体，包含所有参数组合记录、best ACC 结果和保存路径。

if nargin < 2
    config = struct();
end

[thisDir, coreDir] = resolve_dirs();
addpath(genpath(thisDir));
addpath(genpath(coreDir));
config = fill_grid_config(datasetName, config, thisDir);

[X, Y, meta] = load_biclr_dataset(datasetName, struct( ...
    'rootDir', coreDir, ...
    'preprocessTag', config.preprocessTag, ...
    'verbose', config.verbose, ...
    'removeClutter', config.removeClutter, ...
    'maxPerClass', config.maxPerClass));

k = meta.numClusters;
metrics = {'ACC', 'NMI', 'Purity', 'Fscore', 'Precision', 'Recall', 'AR', 'Entropy'};
totalComb = numel(config.betaList) * numel(config.lambdaList) * numel(config.minNodeSizeList);

records(totalComb, 1) = init_record_struct(metrics);
recordId = 0;
globalTimer = tic;

if config.verbose
    fprintf('===== w/o BIC 粗网格搜索开始 =====\n');
    fprintf('数据集=%s，组合数=%d\n', datasetName, totalComb);
end

for imin = 1:numel(config.minNodeSizeList)
    minNodeSize = config.minNodeSizeList(imin);
    anchorOptions = config.anchorOptions;
    anchorOptions.minNodeSize = minNodeSize;
    anchorOptions.lambdaBIC = 0;
    anchorOptions.verbose = config.verbose && config.verboseAnchors;

        [thetaall, ~, ~, qualityScores, targetView, infoAll, cacheInfo, anchorTime] = ...
            prepare_anchor_cache(X, Y, meta, anchorOptions, config);

    for ibeta = 1:numel(config.betaList)
        beta = config.betaList(ibeta);
        for ilambda = 1:numel(config.lambdaList)
            lambda = config.lambdaList(ilambda);
            recordId = recordId + 1;

            runTimer = tic;
            [U, ~, ~, iter, obj] = algo_qp(X, Y, thetaall, beta, lambda, targetView);
            [metricMean, metricStd] = myNMIACCwithmean(U, Y, k, config.evalOptions);
            algoTime = toc(runTimer);

            rec = init_record_struct(metrics);
            rec.methodName = 'wobic';
            rec.datasetName = datasetName;
            rec.beta = beta;
            rec.lambda = lambda;
            rec.lambdaBIC = 0;
            rec.minNodeSize = minNodeSize;
            rec.tauSplit = anchorOptions.tauSplit;
            rec.epsVar = anchorOptions.epsVar;
            rec.randomSeed = anchorOptions.randomSeed;
            rec.anchorCounts = cellfun(@(s) s.numAnchors, infoAll);
            rec.targetView = targetView;
            rec.anchorQuality = qualityScores;
            rec.iter = iter;
            rec.objFinal = obj(end);
            rec.metricsMean = metricMean;
            rec.metricsStd = metricStd;
            rec.metricNames = metrics;
            rec.algoTime = algoTime;
            rec.anchorTime = anchorTime;
            rec.totalTime = anchorTime + algoTime;
            rec.useCache = config.useCache;
            rec.cacheHit = cacheInfo.usedCache;
            rec.cacheKeys = cacheInfo.cacheKeys;
            rec.cacheFiles = cacheInfo.cacheFiles;
            rec.numRuns = config.evalOptions.numRuns;
            rec.kmeansReplicates = config.evalOptions.kmeansReplicates;
            rec.useParallel = config.evalOptions.useParallel;
            rec.objTrace = obj(:)';
            records(recordId) = rec;

            fprintf(['[w/o BIC][%d/%d] %s | beta=%g | lambda=%g | minNodeSize=%d | ' ...
                'anchors=%s | targetView=%d | ACC=%.4f | NMI=%.4f | ' ...
                'Purity=%.4f | Fscore=%.4f | algoTime=%.2fs | anchorTime=%.2fs\n'], ...
                recordId, totalComb, datasetName, beta, lambda, minNodeSize, ...
                mat2str(rec.anchorCounts'), targetView, metricMean(1), metricMean(2), ...
                metricMean(3), metricMean(4), algoTime, anchorTime);
        end
    end
end

bestIdx = select_best_record(records, config.selectionMetricName);
results = struct();
results.methodName = 'wobic';
results.datasetName = datasetName;
results.meta = meta;
results.config = config;
results.records = records;
results.best = records(bestIdx);
results.bestIndex = bestIdx;
results.selectionMetricName = config.selectionMetricName;
results.totalTime = toc(globalTimer);

if ~exist(config.saveDir, 'dir')
    mkdir(config.saveDir);
end

timestamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
savePath = fullfile(config.saveDir, sprintf('%s_wobic_grid_%s.mat', sanitize_key(datasetName), timestamp));
results.savePath = savePath;
save(savePath, 'results', '-v7.3');

fprintf('===== w/o BIC 粗网格搜索结束 =====\n');
fprintf(['按 %s 最高选择最优结果：beta=%g，lambda=%g，minNodeSize=%d，' ...
    'ACC=%.4f，NMI=%.4f，Purity=%.4f，Fscore=%.4f，总耗时=%.2fs\n'], ...
    config.selectionMetricName, results.best.beta, results.best.lambda, ...
    results.best.minNodeSize, results.best.metricsMean(1), ...
    results.best.metricsMean(2), results.best.metricsMean(3), ...
    results.best.metricsMean(4), results.totalTime);
fprintf('结果已保存到：%s\n', savePath);
end

function config = fill_grid_config(datasetName, config, thisDir)
defaultGrids = get_dataset_grid(datasetName);

defaultConfig = struct();
defaultConfig.betaList = defaultGrids.betaList;
defaultConfig.lambdaList = defaultGrids.lambdaList;
defaultConfig.minNodeSizeList = defaultGrids.minNodeSizeList;
defaultConfig.anchorOptions = struct( ...
    'lambdaBIC', 0, ...
    'minNodeSize', defaultGrids.minNodeSizeList(1), ...
    'tauSplit', 0, ...
    'epsVar', 1e-8, ...
    'maxAnchors', defaultGrids.maxAnchors, ...
    'verbose', false, ...
    'randomSeed', 1);
defaultConfig.evalOptions = struct( ...
    'numRuns', defaultGrids.numRuns, ...
    'kmeansReplicates', defaultGrids.kmeansReplicates, ...
    'useParallel', false, ...
    'baseSeed', 1);
defaultConfig.preprocessTag = 'raw';
defaultConfig.useCache = true;
defaultConfig.saveDir = fullfile(thisDir, 'res_coarse');
defaultConfig.cacheDir = fullfile(thisDir, 'cache');
defaultConfig.verbose = true;
defaultConfig.verboseAnchors = false;
defaultConfig.removeClutter = false;
defaultConfig.maxPerClass = [];
defaultConfig.selectionMetricName = 'ACC';

config = merge_defaults(defaultConfig, config);
config.anchorOptions = merge_defaults(defaultConfig.anchorOptions, config.anchorOptions);
config.evalOptions = merge_defaults(defaultConfig.evalOptions, config.evalOptions);
end

function grid = get_dataset_grid(datasetName)
switch lower(datasetName)
    case 'mfeat_2views'
        grid.betaList = [1 10 100];
        grid.lambdaList = [1e3 1e4 1e5];
        grid.minNodeSizeList = [10 20 40];
        grid.maxAnchors = 400;
        grid.numRuns = 4;
        grid.kmeansReplicates = 2;
    case 'reuters-1200'
        grid.betaList = [1 10 100];
        grid.lambdaList = [1e2 1e3 1e4];
        grid.minNodeSizeList = [8 16 32];
        grid.maxAnchors = 300;
        grid.numRuns = 4;
        grid.kmeansReplicates = 2;
    case 'caltech101-all'
        grid.betaList = [10 100];
        grid.lambdaList = [1e2 1e3 1e4];
        grid.minNodeSizeList = [40 80 160];
        grid.maxAnchors = 500;
        grid.numRuns = 3;
        grid.kmeansReplicates = 2;
    case 'wikifea'
        grid.betaList = [1 10 100];
        grid.lambdaList = [1e2 1e3 1e4];
        grid.minNodeSizeList = [10 20 40];
        grid.maxAnchors = 400;
        grid.numRuns = 4;
        grid.kmeansReplicates = 2;
    otherwise
        error('run_ablation_wobic_grid_search:UnsupportedDataset', ...
            '当前未为数据集 %s 预设粗搜索网格。', datasetName);
end
end

function [thetaall, objectAll, labelAll, qualityScores, targetView, infoAll, cacheInfo, totalAnchorTime] = ...
    prepare_anchor_cache(X, Y, meta, anchorOptions, config)
numViews = numel(X);
thetaall = cell(numViews, 1);
objectAll = cell(numViews, 1);
labelAll = cell(numViews, 1);
infoAll = cell(numViews, 1);
qualityScores = zeros(numViews, 1);
cacheKeys = cell(numViews, 1);
cacheFiles = cell(numViews, 1);
usedCache = false(numViews, 1);
totalAnchorTime = 0;

if config.useCache && ~exist(config.cacheDir, 'dir')
    mkdir(config.cacheDir);
end

for iv = 1:numViews
    cacheKey = sprintf('%s_%s_view%d_wobic_minNode%d_seed%d', ...
        sanitize_key(meta.datasetName), sanitize_key(meta.preprocessTag), iv, ...
        anchorOptions.minNodeSize, anchorOptions.randomSeed);
    cacheFile = fullfile(config.cacheDir, [cacheKey '.mat']);
    cacheKeys{iv} = cacheKey;
    cacheFiles{iv} = cacheFile;

    if config.useCache && exist(cacheFile, 'file')
        loaded = load(cacheFile);
        thetaall{iv} = loaded.theta;
        objectAll{iv} = loaded.object;
        labelAll{iv} = loaded.label_neighbor;
        infoAll{iv} = loaded.info;
        qualityScores(iv) = loaded.qualityScore;
        usedCache(iv) = true;
        continue;
    end

    anchorTimer = tic;
    [~, ~, label_neighbor, object, theta, ~, info] = Neighbor_BICLR_woBIC(X{iv}, Y, anchorOptions);
    elapsed = toc(anchorTimer);
    totalAnchorTime = totalAnchorTime + elapsed;

    qualityScore = sum(object);
    thetaall{iv} = theta;
    objectAll{iv} = object;
    labelAll{iv} = label_neighbor;
    infoAll{iv} = info;
    qualityScores(iv) = qualityScore;

    if config.useCache
        methodName = 'wobic';
        save(cacheFile, 'theta', 'object', 'label_neighbor', 'info', 'qualityScore', ...
            'anchorOptions', 'cacheKey', 'methodName');
    end
end

[~, targetView] = min(qualityScores);
cacheInfo = struct();
cacheInfo.usedCache = usedCache;
cacheInfo.cacheKeys = cacheKeys;
cacheInfo.cacheFiles = cacheFiles;
end

function rec = init_record_struct(metricNames)
rec = struct();
rec.methodName = '';
rec.datasetName = '';
rec.beta = [];
rec.lambda = [];
rec.lambdaBIC = [];
rec.minNodeSize = [];
rec.tauSplit = [];
rec.epsVar = [];
rec.randomSeed = [];
rec.anchorCounts = [];
rec.targetView = [];
rec.anchorQuality = [];
rec.iter = [];
rec.objFinal = [];
rec.metricsMean = zeros(1, numel(metricNames));
rec.metricsStd = zeros(1, numel(metricNames));
rec.metricNames = metricNames;
rec.algoTime = [];
rec.anchorTime = [];
rec.totalTime = [];
rec.useCache = false;
rec.cacheHit = [];
rec.cacheKeys = {};
rec.cacheFiles = {};
rec.numRuns = [];
rec.kmeansReplicates = [];
rec.useParallel = false;
rec.objTrace = [];
end

function out = merge_defaults(defaultStruct, inputStruct)
out = defaultStruct;
if isempty(inputStruct)
    return;
end
fieldNames = fieldnames(inputStruct);
for i = 1:numel(fieldNames)
    out.(fieldNames{i}) = inputStruct.(fieldNames{i});
end
end

function bestIdx = select_best_record(records, selectionMetricName)
metricNames = records(1).metricNames;
primaryIdx = find(strcmpi(metricNames, selectionMetricName), 1);
if isempty(primaryIdx)
    error('run_ablation_wobic_grid_search:UnknownMetric', '未找到指标 %s。', selectionMetricName);
end

metricMatrix = vertcat(records.metricsMean);
primaryScore = metricMatrix(:, primaryIdx);
nmiScore = get_metric_column(metricMatrix, metricNames, 'NMI');
fscoreScore = get_metric_column(metricMatrix, metricNames, 'Fscore');
purityScore = get_metric_column(metricMatrix, metricNames, 'Purity');
timeScore = [records.totalTime]';
stableIndex = (1:numel(records))';

[~, order] = sortrows([-primaryScore, -nmiScore, -fscoreScore, -purityScore, timeScore, stableIndex]);
bestIdx = order(1);
end

function score = get_metric_column(metricMatrix, metricNames, metricName)
idx = find(strcmpi(metricNames, metricName), 1);
if isempty(idx)
    score = zeros(size(metricMatrix, 1), 1);
else
    score = metricMatrix(:, idx);
end
end

function key = sanitize_key(textValue)
key = regexprep(char(textValue), '[^a-zA-Z0-9]+', '_');
key = regexprep(key, '_+', '_');
key = regexprep(key, '^_|_$', '');
end

function [thisDir, coreDir] = resolve_dirs()
thisDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(thisDir);
coreDir = fullfile(projectRoot, '3AMVC-main');
end
