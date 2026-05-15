function result = ablation_fill_missing_result_fields(result)
%ABLATION_FILL_MISSING_RESULT_FIELDS 补齐统一结果结构体字段。
%   RESULT = ABLATION_FILL_MISSING_RESULT_FIELDS(RESULT) 对不存在的字段用
%   NaN、空数组或空字符串占位，保证 A0/A1/A3/A4 结果结构一致。

defaults = struct();
defaults.methodName = '';
defaults.datasetName = '';
defaults.beta = NaN;
defaults.lambda = NaN;
defaults.lambdaBIC = NaN;
defaults.minNodeSize = NaN;
defaults.tauSplit = NaN;
defaults.targetSelectionMethod = '';
defaults.targetView = NaN;
defaults.anchorCounts = [];
defaults.anchorCountsStd = [];
defaults.acceptedSplits = [];
defaults.rejectedSplits = [];
defaults.splitDepthProfile = [];
defaults.anchorEvidenceGain = [];
defaults.totalSSEPerView = [];
defaults.meanLeafSize = [];
defaults.maxDepth = [];
defaults.metricsMean = ablation_metrics_to_struct([]);
defaults.metricsStd = ablation_metrics_to_struct([]);
defaults.totalTime = NaN;
defaults.anchorTime = NaN;
defaults.alignmentTime = NaN;
defaults.randomSeed = NaN;
defaults.numGridConfigs = NaN;
defaults.searchBudget = NaN;
defaults.selectedConfig = struct();
defaults.selectionMetric = 'ACC';
defaults.selectionRule = 'best_mean_ACC_then_NMI';
defaults.sourceMainCodeRoot = '';
defaults.resultSavePath = '';
defaults.bicTargetView = NaN;
defaults.sseTargetView = NaN;
defaults.targetViewAgreement = NaN;
defaults.bicEvidencePerView = [];
defaults.sseRankCorrelation = NaN;
defaults.useMultiViewFusion = true;
defaults.singleViewOnly = false;
defaults.source = '';
defaults.originalA0ResultPath = '';
defaults.cacheKeys = {};
defaults.cacheFiles = {};
defaults.cacheHit = [];
defaults.cacheSource = {};
defaults.numRuns = NaN;
defaults.kmeansReplicates = NaN;
defaults.useParallel = false;
defaults.evalSummaryMode = '';
defaults.metricNames = {'ACC', 'NMI', 'Purity', 'Fscore', 'Precision', 'Recall', 'AR', 'Entropy'};
defaults.iter = NaN;
defaults.objFinal = NaN;
defaults.objTrace = [];
defaults.alignmentMaxObjectiveTrace = [];
defaults.evalBestRunIndex = NaN;
defaults.evalBestRunSeed = NaN;
defaults.evalBestRunMetrics = [];
defaults.evalAllMetrics = [];

names = fieldnames(defaults);
for i = 1:numel(names)
    name = names{i};
    if ~isfield(result, name) || isempty(result.(name))
        result.(name) = defaults.(name);
    end
end
end
