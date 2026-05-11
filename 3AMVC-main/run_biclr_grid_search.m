function results = run_biclr_grid_search(datasetName, config)
%RUN_BICLR_GRID_SEARCH 运行 BIC-LR + 3AMVC 的网格搜索。
%   RESULTS = RUN_BICLR_GRID_SEARCH(DATASETNAME, CONFIG) 针对指定数据集执行
%   BIC-LR 锚点选择和 3AMVC 主优化的网格搜索，可用于粗搜索或精细搜索。
%
%   输入参数：
%   datasetName : 数据集名，不带 .mat 后缀。
%   config      : 配置结构体，支持字段：
%                 - betaList / lambdaList / lambdaBICList / minNodeSizeList
%                 - anchorOptions : 工程参数结构体
%                 - evalOptions   : 评价参数结构体
%                 - preprocessTag : 预处理标签，默认 'raw'
%                 - useCache      : 是否启用锚点缓存，默认 true
%                 - saveDir       : 结果保存目录，默认 ./res_biclr
%                 - cacheDir      : 缓存目录，默认 ./cache
%                 - verbose       : 是否输出详细日志，默认 true
%                 - selectionMetricName : 选择最优结果时使用的指标名，默认 'ACC'
%
%   输出参数：
%   results : 结构体，包含数据集信息、所有网格记录、最优组合与保存路径。
%
%   注意事项：
%   1. 锚点缓存只按 dataset/preprocess/view/lambdaBIC/minNodeSize/seed/method 复用。
%   2. 本函数默认以 ACC 作为最优参数的主排序指标；若 ACC 相同，则依次参考
%      NMI、Fscore、Purity 和总耗时进行稳定选择。

if nargin < 2
    config = struct();
end

rootDir = fileparts(mfilename('fullpath'));
addpath(genpath(rootDir));
config = fill_grid_config(datasetName, config, rootDir);

[X, Y, meta] = load_biclr_dataset(datasetName, struct( ...
    'rootDir', rootDir, ...
    'preprocessTag', config.preprocessTag, ...
    'verbose', config.verbose, ...
    'removeClutter', config.removeClutter, ...
    'maxPerClass', config.maxPerClass));

k = meta.numClusters;
metrics = {'ACC', 'NMI', 'Purity', 'Fscore', 'Precision', 'Recall', 'AR', 'Entropy'};
totalComb = numel(config.betaList) * numel(config.lambdaList) ...
    * numel(config.lambdaBICList) * numel(config.minNodeSizeList);

records(totalComb, 1) = init_record_struct(metrics); %#ok<AGROW>
recordId = 0;
globalTimer = tic;

if config.verbose
    fprintf('===== BIC-LR 网格搜索开始 =====\n');
    fprintf('数据集=%s，组合数=%d\n', datasetName, totalComb);
end

for ibic = 1:numel(config.lambdaBICList)
    lambdaBIC = config.lambdaBICList(ibic);
    for imin = 1:numel(config.minNodeSizeList)
        minNodeSize = config.minNodeSizeList(imin);
        anchorOptions = config.anchorOptions;
        anchorOptions.lambdaBIC = lambdaBIC;
        anchorOptions.minNodeSize = minNodeSize;
        anchorOptions.verbose = config.verbose && config.verboseAnchors;

        [thetaall, objectAll, labelAll, qualityScores, targetView, infoAll, cacheInfo, anchorTime] = ...
            prepare_anchor_cache(X, Y, meta, anchorOptions, config);

        for ibeta = 1:numel(config.betaList)
            beta = config.betaList(ibeta);
            for ilambda = 1:numel(config.lambdaList)
                lambda = config.lambdaList(ilambda);
                recordId = recordId + 1;

                runTimer = tic;
                [U, A, Z, iter, obj] = algo_qp(X, Y, thetaall, beta, lambda, targetView);
                [metricMean, metricStd] = myNMIACCwithmean(U, Y, k, config.evalOptions);
                algoTime = toc(runTimer);

                rec = init_record_struct(metrics);
                rec.datasetName = datasetName;
                rec.beta = beta;
                rec.lambda = lambda;
                rec.lambdaBIC = lambdaBIC;
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
                if config.storeDetailedModel
                    rec.thetaall = thetaall;
                    rec.labelAll = labelAll;
                    rec.objectAll = objectAll;
                    rec.infoAll = infoAll;
                    rec.A = A;
                    rec.Z = Z;
                end

                records(recordId) = rec;

                fprintf(['[Grid][%d/%d] %s | beta=%g | lambda=%g | lambdaBIC=%g | ' ...
                    'minNodeSize=%d | anchors=%s | targetView=%d | ' ...
                    'ACC=%.4f | NMI=%.4f | Purity=%.4f | Fscore=%.4f | ' ...
                    'algoTime=%.2fs | anchorTime=%.2fs\n'], ...
                    recordId, totalComb, datasetName, beta, lambda, lambdaBIC, minNodeSize, ...
                    mat2str(rec.anchorCounts'), targetView, metricMean(1), metricMean(2), ...
                    metricMean(3), metricMean(4), algoTime, anchorTime);
            end
        end
    end
end

bestIdx = select_best_record(records, config.selectionMetricName);
results = struct();
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
savePath = fullfile(config.saveDir, sprintf('%s_BICLR_grid_%s.mat', sanitize_key(datasetName), timestamp));
results.savePath = savePath;
save(savePath, 'results', '-v7.3');

fprintf('===== BIC-LR 网格搜索结束 =====\n');
fprintf(['按 %s 最高选择最优结果：beta=%g，lambda=%g，lambdaBIC=%g，minNodeSize=%d，' ...
    'ACC=%.4f，NMI=%.4f，Purity=%.4f，Fscore=%.4f，总耗时=%.2fs\n'], ...
    config.selectionMetricName, results.best.beta, results.best.lambda, results.best.lambdaBIC, ...
    results.best.minNodeSize, results.best.metricsMean(1), ...
    results.best.metricsMean(2), results.best.metricsMean(3), ...
    results.best.metricsMean(4), results.totalTime);
fprintf('结果已保存到：%s\n', savePath);
end

function config = fill_grid_config(datasetName, config, rootDir)
defaultGrids = get_dataset_grid(datasetName);

defaultConfig = struct();
defaultConfig.betaList = defaultGrids.betaList;
defaultConfig.lambdaList = defaultGrids.lambdaList;
defaultConfig.lambdaBICList = defaultGrids.lambdaBICList;
defaultConfig.minNodeSizeList = defaultGrids.minNodeSizeList;
defaultConfig.anchorOptions = struct( ...
    'lambdaBIC', defaultGrids.lambdaBICList(1), ...
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
defaultConfig.saveDir = fullfile(rootDir, 'res_biclr');
defaultConfig.cacheDir = fullfile(rootDir, 'cache');
defaultConfig.verbose = true;
defaultConfig.verboseAnchors = false;
defaultConfig.removeClutter = false;
defaultConfig.maxPerClass = [];
defaultConfig.storeDetailedModel = false;
defaultConfig.selectionMetricName = 'ACC';

defaultFields = fieldnames(defaultConfig);
for i = 1:numel(defaultFields)
    name = defaultFields{i};
    if ~isfield(config, name) || isempty(config.(name))
        config.(name) = defaultConfig.(name);
    end
end

config.anchorOptions = merge_struct(defaultConfig.anchorOptions, config.anchorOptions);
config.evalOptions = merge_struct(defaultConfig.evalOptions, config.evalOptions);
end

function grid = get_dataset_grid(datasetName)
switch lower(datasetName)
    case 'mfeat_2views'
        grid.betaList = [1 10 100];
        grid.lambdaList = [1e3 1e4 1e5];
        grid.lambdaBICList = [0.5 1 2];
        grid.minNodeSizeList = [10 20 40];
        grid.maxAnchors = 400;
        grid.numRuns = 8;
        grid.kmeansReplicates = 3;
    case 'reuters-1200'
        grid.betaList = [1 10 100];
        grid.lambdaList = [1e2 1e3 1e4];
        grid.lambdaBICList = [0.5 1 2];
        grid.minNodeSizeList = [8 16 32];
        grid.maxAnchors = 300;
        grid.numRuns = 6;
        grid.kmeansReplicates = 3;
    case 'caltech101-all'
        grid.betaList = [10 100];
        grid.lambdaList = [1e2 1e3 1e4];
        grid.lambdaBICList = [1 2 4];
        grid.minNodeSizeList = [40 80 160];
        grid.maxAnchors = 500;
        grid.numRuns = 4;
        grid.kmeansReplicates = 2;
    case 'wikifea'
        grid.betaList = [1 10 100];
        grid.lambdaList = [1e2 1e3 1e4];
        grid.lambdaBICList = [0.5 1 2 4];
        grid.minNodeSizeList = [10 20 40];
        grid.maxAnchors = 400;
        grid.numRuns = 6;
        grid.kmeansReplicates = 3;
    otherwise
        error('run_biclr_grid_search:UnsupportedDataset', ...
            '当前未为数据集 %s 预设网格，请在 config 中手动指定。', datasetName);
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
    cacheKey = sprintf('%s_%s_view%d_BICLR_lamBIC%s_minNode%d_seed%d', ...
        sanitize_key(meta.datasetName), sanitize_key(meta.preprocessTag), iv, ...
        sanitize_numeric(anchorOptions.lambdaBIC), anchorOptions.minNodeSize, ...
        anchorOptions.randomSeed);
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
    [~, ~, label_neighbor, object, theta, ~, info] = Neighbor_BICLR(X{iv}, Y, anchorOptions);
    elapsed = toc(anchorTimer);
    totalAnchorTime = totalAnchorTime + elapsed;

    qualityScore = sum(object);
    thetaall{iv} = theta;
    objectAll{iv} = object;
    labelAll{iv} = label_neighbor;
    infoAll{iv} = info;
    qualityScores(iv) = qualityScore;

    if config.useCache
        methodName = 'BICLR'; %#ok<NASGU>
        labelField = meta.labelField; %#ok<NASGU>
        save(cacheFile, 'theta', 'object', 'label_neighbor', 'info', 'qualityScore', ...
            'anchorOptions', 'cacheKey', 'methodName', 'labelField');
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
rec.thetaall = {};
rec.labelAll = {};
rec.objectAll = {};
rec.infoAll = {};
rec.A = {};
rec.Z = [];
end

function out = merge_struct(defaultStruct, inputStruct)
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
if isempty(records)
    error('run_biclr_grid_search:EmptyRecords', 'records 为空，无法选择最优结果。');
end

metricNames = records(1).metricNames;
primaryIdx = find(strcmpi(metricNames, selectionMetricName), 1);
if isempty(primaryIdx)
    error('run_biclr_grid_search:UnknownMetric', '未找到指标 %s。', selectionMetricName);
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

function textValue = sanitize_numeric(value)
textValue = regexprep(sprintf('%.6g', value), '[^0-9a-zA-Z]+', 'p');
end
