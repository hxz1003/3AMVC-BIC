function resultSummary = run_one_biclr_ablation(methodName, datasetName, config)
%RUN_ONE_BICLR_ABLATION 运行一个 BIC-LR 消融实验。
%   RESULTSUMMARY = RUN_ONE_BICLR_ABLATION(METHODNAME, DATASETNAME, CONFIG)
%   负责定位项目、加载数据、按方法分支执行 A0/A1/A3/A4、遍历网格、
%   统一保存 allResults 与 resultSummary。
%
%   输入参数：
%   methodName  : 'A0_Full_Reference'、'A1_woBIC_Joint'、
%                 'A3_SSETarget' 或 'A4_woMultiViewFusion'。
%   datasetName : 数据集名称或别名。
%   config      : 配置结构体，可由 get_default_grid_config、
%                 get_dataset_grid_config、get_method_config 依次生成。
%
%   输出参数：
%   resultSummary : 当前方法和数据集的最优结果摘要。

if nargin < 3 || isempty(config)
    config = get_default_grid_config();
    config = get_dataset_grid_config(datasetName, config);
    config = get_method_config(methodName, config);
end

paths = get_project_paths();
addpath(genpath(paths.mainCodeRoot));
addpath(genpath(paths.ablationRoot));

datasetInfo = get_ablation_dataset_alias(datasetName);
config.datasetInfo = datasetInfo;
config = get_method_config(methodName, config);
methodConfig = config.methodConfig;

fprintf('[消融] repoRoot=%s\n', paths.repoRoot);
fprintf('[消融] mainCodeRoot=%s\n', paths.mainCodeRoot);
fprintf('[消融] method=%s, dataset=%s\n', methodName, datasetInfo.resultDirName);

if strcmp(methodName, 'A0_Full_Reference')
    [resultSummary, ~, sourcePath] = find_existing_a0_results(datasetName, config);
    if isempty(sourcePath)
        warning('run_one_biclr_ablation:A0NotFound', ...
            '未找到 %s 的 A0 已有结果，本次仅保存空引用摘要。', datasetInfo.resultDirName);
    else
        fprintf('[A0 引用] 已读取：%s\n', sourcePath);
    end
    return;
end

datasetInfo = ensure_dataset_available(datasetInfo, paths);
[X, Y, meta] = load_biclr_dataset(datasetInfo.canonicalName, struct( ...
    'rootDir', paths.mainCodeRoot, ...
    'preprocessTag', config.preprocessTag, ...
    'verbose', config.verbose, ...
    'removeClutter', config.removeClutter, ...
    'maxPerClass', config.maxPerClass));

k = meta.numClusters;
betaList = config.betaList(:)';
lambdaList = config.lambdaList(:)';
lambdaBICList = config.lambdaBICList(:)';
minNodeSizeList = config.minNodeSizeList(:)';
seeds = config.seeds(:)';
numGridConfigs = numel(betaList) * numel(lambdaList) * numel(lambdaBICList) * numel(minNodeSizeList);
searchBudget = numGridConfigs * numel(seeds) * config.evalOptions.numRuns;

metrics = {'ACC', 'NMI', 'Purity', 'Fscore', 'Precision', 'Recall', 'AR', 'Entropy'};
recordTemplate = ablation_fill_missing_result_fields(struct());
allResults = repmat(recordTemplate, numGridConfigs * numel(seeds), 1);
recordId = 0;
globalTimer = tic;

fprintf('[消融] 网格组合=%d，seeds=%s，评价 numRuns=%d\n', ...
    numGridConfigs, mat2str(seeds), config.evalOptions.numRuns);

for iseed = 1:numel(seeds)
    seed = seeds(iseed);
    rng(seed, 'twister');
    for ibic = 1:numel(lambdaBICList)
        lambdaBIC = lambdaBICList(ibic);
        for imin = 1:numel(minNodeSizeList)
            minNodeSize = minNodeSizeList(imin);

            anchorOptions = config.anchorOptions;
            anchorOptions.lambdaBIC = lambdaBIC;
            anchorOptions.minNodeSize = minNodeSize;
            anchorOptions.tauSplit = config.tauSplit;
            anchorOptions.epsVar = config.epsVar;
            anchorOptions.randomSeed = seed;
            anchorOptions.verbose = config.verbose && config.verboseAnchors;

            rng(seed, 'twister');
            anchorPack = prepare_biclr_ablation_anchors(X, Y, meta, datasetInfo, ...
                methodName, config, methodConfig, anchorOptions);
            targetInfo = select_ablation_target_view(anchorPack, methodConfig);

            for ibeta = 1:numel(betaList)
                beta = betaList(ibeta);
                for ilambda = 1:numel(lambdaList)
                    lambda = lambdaList(ilambda);
                    recordId = recordId + 1;
                    rng(seed, 'twister');

                    algoTimer = tic;
                    if methodConfig.useMultiViewFusion
                        [U, ~, ~, iter, obj, traceInfo] = algo_qp(X, Y, anchorPack.thetaall, beta, lambda, targetInfo.targetView);
                        algoTime = toc(algoTimer);
                        alignmentTime = algoTime;
                        singleViewOnly = false;
                    else
                        targetTheta = anchorPack.thetaall{targetInfo.targetView};
                        model = run_single_view_anchor_clustering(X{targetInfo.targetView}, Y, targetTheta, beta, struct());
                        U = model.U;
                        iter = model.iter;
                        obj = model.obj;
                        traceInfo = model.traceInfo;
                        algoTime = toc(algoTimer);
                        alignmentTime = 0;
                        singleViewOnly = true;
                        lambda = NaN;
                    end

                    evalOptions = config.evalOptions;
                    evalOptions.baseSeed = seed;
                    evalTimer = tic;
                    [metricSummary, metricStd, evalInfo] = myNMIACCwithmean(U, Y, k, evalOptions); %#ok<ASGLU>
                    evalTime = toc(evalTimer);

                    rec = build_result_record(methodName, datasetInfo, config, methodConfig, ...
                        beta, lambda, lambdaBIC, minNodeSize, seed, targetInfo, anchorPack, ...
                        evalInfo, metricStd, metrics, iter, obj, traceInfo, ...
                        algoTime, alignmentTime, evalTime, numGridConfigs, searchBudget, ...
                        paths, singleViewOnly);
                    allResults(recordId) = rec;

                    fprintf(['[消融][%d/%d] %s | %s | beta=%g | lambda=%g | lambdaBIC=%g | ' ...
                        'minNode=%d | seed=%d | target=%d | ACC=%.4f | NMI=%.4f | AR=%.4f | total=%.2fs\n'], ...
                        recordId, numel(allResults), methodName, datasetInfo.resultDirName, ...
                        beta, lambda, lambdaBIC, minNodeSize, seed, targetInfo.targetView, ...
                        rec.metricsMean.ACC, rec.metricsMean.NMI, rec.metricsMean.AR, rec.totalTime);
                end
            end
        end
    end
end

allResults = allResults(1:recordId);
bestIndex = select_best_ablation_result(allResults, config.selectionMetric);
resultSummary = allResults(bestIndex);
resultSummary.selectedConfig = build_selected_config(resultSummary);
resultSummary.totalTime = toc(globalTimer);
resultSummary.numGridConfigs = numGridConfigs;
resultSummary.searchBudget = searchBudget;
allResults(bestIndex).selectedConfig = resultSummary.selectedConfig;
resultSummary.resultSavePath = save_ablation_result(allResults, resultSummary, config, methodConfig, datasetInfo, paths);

fprintf('[消融] 最优配置：\n');
disp(resultSummary.selectedConfig);
fprintf('[消融] 结果已保存：%s\n', resultSummary.resultSavePath);
end

function datasetInfo = ensure_dataset_available(datasetInfo, paths)
canonicalFile = fullfile(paths.dataRoot, [datasetInfo.canonicalName '.mat']);
if exist(canonicalFile, 'file')
    return;
end
if ~isempty(datasetInfo.dataFile)
    [~, canonicalName] = fileparts(datasetInfo.dataFile);
    datasetInfo.canonicalName = canonicalName;
    return;
end

checked = {};
for idir = 1:numel(datasetInfo.possibleDataDirs)
    for ifile = 1:numel(datasetInfo.possibleFileNames)
        checked{end + 1, 1} = fullfile(datasetInfo.possibleDataDirs{idir}, datasetInfo.possibleFileNames{ifile}); %#ok<AGROW>
    end
end
error('run_one_biclr_ablation:DatasetNotFound', ...
    '未找到数据集 %s。已查找以下路径：\n%s\n请将数据文件放入：%s', ...
    datasetInfo.inputName, strjoin(checked, sprintf('\n')), paths.dataRoot);
end

function targetInfo = select_ablation_target_view(anchorPack, methodConfig)
targetInfo = struct();
targetInfo.bicTargetView = anchorPack.bicTargetView;
targetInfo.sseTargetView = NaN;
targetInfo.targetViewAgreement = NaN;
targetInfo.sseRankCorrelation = NaN;
targetInfo.bicEvidencePerView = anchorPack.bicUnitGains(:);
targetInfo.totalSSEPerView = anchorPack.totalSSEPerView(:);

switch methodConfig.targetSelectionMethod
    case {'BICUnitEvidence', 'LRUnitEvidence'}
        [~, targetInfo.targetView] = max(anchorPack.bicUnitGains);
    case 'SSEMin'
        [~, targetInfo.sseTargetView] = min(anchorPack.totalSSEPerView);
        targetInfo.targetView = targetInfo.sseTargetView;
        targetInfo.targetViewAgreement = double(anchorPack.bicTargetView == targetInfo.sseTargetView);
        targetInfo.sseRankCorrelation = compute_rank_kendall_tau_safe(anchorPack.bicUnitGains, -anchorPack.totalSSEPerView);
    otherwise
        error('run_one_biclr_ablation:UnknownTargetSelection', ...
            '未知目标视图选择方法：%s', methodConfig.targetSelectionMethod);
end

if strcmp(methodConfig.targetSelectionMethod, 'SSEMin')
    targetInfo.bicTargetView = anchorPack.bicTargetView;
else
    targetInfo.bicTargetView = targetInfo.targetView;
end
if isnan(targetInfo.sseTargetView)
    [~, targetInfo.sseTargetView] = min(anchorPack.totalSSEPerView);
end
end

function rec = build_result_record(methodName, datasetInfo, config, methodConfig, ...
    beta, lambda, lambdaBIC, minNodeSize, seed, targetInfo, anchorPack, ...
    evalInfo, metricStd, metrics, iter, obj, traceInfo, ...
    algoTime, alignmentTime, evalTime, numGridConfigs, searchBudget, paths, singleViewOnly)

rec = struct();
rec.methodName = methodName;
rec.datasetName = datasetInfo.resultDirName;
rec.beta = beta;
rec.lambda = lambda;
rec.lambdaBIC = lambdaBIC;
rec.minNodeSize = minNodeSize;
rec.tauSplit = config.tauSplit;
rec.targetSelectionMethod = methodConfig.targetSelectionMethod;
rec.targetView = targetInfo.targetView;
rec.anchorCounts = anchorPack.anchorCounts(:)';
rec.anchorCountsStd = zeros(size(rec.anchorCounts));
rec.acceptedSplits = anchorPack.acceptedSplits(:)';
rec.rejectedSplits = anchorPack.rejectedSplits(:)';
rec.splitDepthProfile = anchorPack.leafDepths;
rec.anchorEvidenceGain = anchorPack.bicUnitGains(:)';
rec.totalSSEPerView = anchorPack.totalSSEPerView(:)';
rec.meanLeafSize = anchorPack.meanLeafSize(:)';
rec.maxDepth = anchorPack.maxDepth(:)';
rec.metricsMean = ablation_metrics_to_struct(evalInfo.meanMetrics);
rec.metricsStd = ablation_metrics_to_struct(metricStd);
rec.totalTime = anchorPack.anchorTime + algoTime + evalTime;
rec.anchorTime = anchorPack.anchorTime;
rec.alignmentTime = alignmentTime;
rec.randomSeed = seed;
rec.numGridConfigs = numGridConfigs;
rec.searchBudget = searchBudget;
rec.selectedConfig = struct();
rec.selectionMetric = config.selectionMetric;
rec.selectionRule = config.selectionRule;
rec.sourceMainCodeRoot = paths.mainCodeRoot;
rec.resultSavePath = '';
rec.bicTargetView = targetInfo.bicTargetView;
rec.sseTargetView = targetInfo.sseTargetView;
rec.targetViewAgreement = targetInfo.targetViewAgreement;
rec.bicEvidencePerView = targetInfo.bicEvidencePerView(:)';
rec.sseRankCorrelation = targetInfo.sseRankCorrelation;
rec.useMultiViewFusion = methodConfig.useMultiViewFusion;
rec.singleViewOnly = singleViewOnly;
rec.source = 'ablation_biclr_generated';
rec.originalA0ResultPath = '';
rec.cacheKeys = anchorPack.cacheKeys;
rec.cacheFiles = anchorPack.cacheFiles;
rec.cacheHit = anchorPack.cacheHit;
rec.cacheSource = anchorPack.cacheSource;
rec.numRuns = config.evalOptions.numRuns;
rec.kmeansReplicates = config.evalOptions.kmeansReplicates;
rec.useParallel = config.evalOptions.useParallel;
rec.evalSummaryMode = evalInfo.summaryMode;
rec.metricNames = metrics;
rec.iter = iter;
rec.objFinal = obj(end);
rec.objTrace = obj(:)';
if isfield(traceInfo, 'objectiveTraceForPlot')
    rec.alignmentMaxObjectiveTrace = traceInfo.objectiveTraceForPlot(:)';
else
    rec.alignmentMaxObjectiveTrace = [];
end
rec.evalBestRunIndex = evalInfo.bestRunIndex;
rec.evalBestRunSeed = evalInfo.bestRunSeed;
rec.evalBestRunMetrics = evalInfo.bestRunMetrics;
rec.evalAllMetrics = evalInfo.allMetrics;
rec = ablation_fill_missing_result_fields(rec);
end

function bestIndex = select_best_ablation_result(allResults, selectionMetric)
if isempty(allResults)
    error('run_one_biclr_ablation:EmptyResults', '没有可选择的网格结果。');
end
primary = zeros(numel(allResults), 1);
nmi = zeros(numel(allResults), 1);
stable = (1:numel(allResults))';
for i = 1:numel(allResults)
    primary(i) = get_metric_value(allResults(i).metricsMean, selectionMetric);
    nmi(i) = get_metric_value(allResults(i).metricsMean, 'NMI');
end
[~, order] = sortrows([-primary, -nmi, stable]);
bestIndex = order(1);
end

function value = get_metric_value(metrics, name)
if isstruct(metrics) && isfield(metrics, name)
    value = metrics.(name);
else
    value = NaN;
end
end

function selectedConfig = build_selected_config(resultSummary)
selectedConfig = struct();
selectedConfig.beta = resultSummary.beta;
selectedConfig.lambda = resultSummary.lambda;
selectedConfig.lambdaBIC = resultSummary.lambdaBIC;
selectedConfig.minNodeSize = resultSummary.minNodeSize;
selectedConfig.tauSplit = resultSummary.tauSplit;
selectedConfig.randomSeed = resultSummary.randomSeed;
selectedConfig.targetSelectionMethod = resultSummary.targetSelectionMethod;
selectedConfig.targetView = resultSummary.targetView;
end

function savePath = save_ablation_result(allResults, resultSummary, config, methodConfig, datasetInfo, paths)
saveDir = fullfile(paths.resRoot, resultSummary.methodName, datasetInfo.resultDirName);
if ~exist(saveDir, 'dir')
    mkdir(saveDir);
end
timestamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
savePath = fullfile(saveDir, sprintf('%s_%s_grid_%s.mat', ...
    resultSummary.methodName, datasetInfo.resultDirName, timestamp));
latestPath = fullfile(saveDir, sprintf('%s_%s_latest.mat', resultSummary.methodName, datasetInfo.resultDirName));

repoRoot = paths.repoRoot; %#ok<NASGU>
mainCodeRoot = paths.mainCodeRoot; %#ok<NASGU>
ablationRoot = paths.ablationRoot; %#ok<NASGU>
methodName = resultSummary.methodName; %#ok<NASGU>
resultSummary.resultSavePath = savePath;

save(savePath, 'allResults', 'resultSummary', 'config', 'methodConfig', ...
    'datasetInfo', 'timestamp', 'repoRoot', 'mainCodeRoot', 'ablationRoot', 'methodName', '-v7.3');
save(latestPath, 'allResults', 'resultSummary', 'config', 'methodConfig', ...
    'datasetInfo', 'timestamp', 'repoRoot', 'mainCodeRoot', 'ablationRoot', 'methodName', '-v7.3');
end
