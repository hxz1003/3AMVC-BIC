function summaryTables = summarize_ablation_results()
%SUMMARIZE_ABLATION_RESULTS 汇总 A0/A1/A3/A4 的消融结果。
%   SUMMARYTABLES = SUMMARIZE_ABLATION_RESULTS() 读取 ablation_biclr/res 下
%   四个方法、四个数据集的 latest 结果，输出主性能表、机制分析表、搜索
%   预算表和 A3 视图选择分析表。
%
%   输出文件：
%   reports/main_tables/*.csv, *.mat
%   reports/mechanism/*.csv, *.mat
%   reports/view_selection/*.csv, *.mat

paths = get_project_paths();
methods = {'A0_Full_Reference', 'A1_woBIC_Joint', 'A3_SSETarget', 'A4_woMultiViewFusion'};
methodLabels = {'A0 Reference', 'A1 w/o BIC', 'A3 SSE Target', 'A4 Single View'};
datasets = {'Mfeat', 'Ruter1200', 'WIKI', 'Catlch101All', ...
    'ForestTypes', 'Caltech256_4Views_257cls_withClutter'};

mainRows = {};
mechanismRows = {};
budgetRows = {};
viewRows = {};

for id = 1:numel(datasets)
    datasetName = datasets{id};
    perfCells = cell(1, numel(methods));
    for im = 1:numel(methods)
        methodName = methods{im};
        resultSummary = load_latest_summary(paths, methodName, datasetName);
        perfCells{im} = format_perf_cell(resultSummary);

        mechanismRows(end + 1, :) = {datasetName, methodName, ...
            safe_mean(resultSummary.anchorCounts), mat2str_safe(resultSummary.anchorCounts), ...
            resultSummary.targetView, mat2str_safe(resultSummary.acceptedSplits), ...
            mat2str_safe(resultSummary.rejectedSplits), resultSummary.anchorTime, resultSummary.totalTime}; %#ok<AGROW>

        budgetRows(end + 1, :) = {datasetName, methodName, resultSummary.numGridConfigs, ...
            numel_safe(resultSummary.randomSeed), resultSummary.numRuns, resultSummary.searchBudget, ...
            resultSummary.selectionRule, selected_config_text(resultSummary.selectedConfig)}; %#ok<AGROW>

        if strcmp(methodName, 'A3_SSETarget')
            viewRows(end + 1, :) = {datasetName, resultSummary.bicTargetView, resultSummary.sseTargetView, ...
                resultSummary.targetViewAgreement, mat2str_safe(resultSummary.bicEvidencePerView), ...
                mat2str_safe(resultSummary.totalSSEPerView), resultSummary.sseRankCorrelation}; %#ok<AGROW>
        end
    end
    mainRows(end + 1, :) = [{datasetName}, perfCells]; %#ok<AGROW>
end

mainTable = cell2table(mainRows, 'VariableNames', [{'Dataset'}, methodLabels]);
mechanismTable = cell2table(mechanismRows, 'VariableNames', ...
    {'Dataset', 'Method', 'AvgAnchors', 'AnchorCountsPerView', 'TargetView', ...
     'AcceptedSplits', 'RejectedSplits', 'AnchorTime', 'TotalTime'});
budgetTable = cell2table(budgetRows, 'VariableNames', ...
    {'Dataset', 'Method', 'numGridConfigs', 'numSeeds', 'numRuns', ...
     'searchBudget', 'selectionRule', 'selectedConfig'});
viewSelectionTable = cell2table(viewRows, 'VariableNames', ...
    {'Dataset', 'BICTargetView', 'SSETargetView', 'Agreement', ...
     'BICEvidencePerView', 'SSEPerView', 'KendallTau'});

if ~exist(fullfile(paths.reportRoot, 'main_tables'), 'dir')
    mkdir(fullfile(paths.reportRoot, 'main_tables'));
end
if ~exist(fullfile(paths.reportRoot, 'mechanism'), 'dir')
    mkdir(fullfile(paths.reportRoot, 'mechanism'));
end
if ~exist(fullfile(paths.reportRoot, 'view_selection'), 'dir')
    mkdir(fullfile(paths.reportRoot, 'view_selection'));
end

writetable(mainTable, fullfile(paths.reportRoot, 'main_tables', 'biclr_ablation_main_performance.csv'));
writetable(mechanismTable, fullfile(paths.reportRoot, 'mechanism', 'biclr_ablation_mechanism.csv'));
writetable(budgetTable, fullfile(paths.reportRoot, 'main_tables', 'biclr_ablation_search_budget.csv'));
writetable(viewSelectionTable, fullfile(paths.reportRoot, 'view_selection', 'biclr_ablation_A3_view_selection.csv'));

summaryTables = struct();
summaryTables.mainTable = mainTable;
summaryTables.mechanismTable = mechanismTable;
summaryTables.budgetTable = budgetTable;
summaryTables.viewSelectionTable = viewSelectionTable;

save(fullfile(paths.reportRoot, 'main_tables', 'biclr_ablation_main_tables.mat'), ...
    'mainTable', 'budgetTable');
save(fullfile(paths.reportRoot, 'mechanism', 'biclr_ablation_mechanism.mat'), 'mechanismTable');
save(fullfile(paths.reportRoot, 'view_selection', 'biclr_ablation_A3_view_selection.mat'), 'viewSelectionTable');
end

function resultSummary = load_latest_summary(paths, methodName, datasetName)
latestPath = fullfile(paths.resRoot, methodName, datasetName, sprintf('%s_%s_latest.mat', methodName, datasetName));
if ~exist(latestPath, 'file')
    warning('summarize_ablation_results:MissingLatest', '未找到 latest 结果：%s', latestPath);
    resultSummary = ablation_fill_missing_result_fields(struct('methodName', methodName, 'datasetName', datasetName));
    return;
end
loaded = load(latestPath);
if isfield(loaded, 'resultSummary')
    resultSummary = ablation_fill_missing_result_fields(loaded.resultSummary);
else
    resultSummary = ablation_fill_missing_result_fields(struct('methodName', methodName, 'datasetName', datasetName));
end
end

function textValue = format_perf_cell(resultSummary)
if isempty(resultSummary) || ~isstruct(resultSummary) || ~isfield(resultSummary, 'metricsMean')
    textValue = 'NaN / NaN / NaN';
    return;
end
m = resultSummary.metricsMean;
textValue = sprintf('%.4f / %.4f / %.4f', get_metric(m, 'ACC'), get_metric(m, 'NMI'), get_metric(m, 'AR'));
end

function value = get_metric(metrics, fieldName)
if isstruct(metrics) && isfield(metrics, fieldName)
    value = metrics.(fieldName);
else
    value = NaN;
end
end

function value = safe_mean(x)
if isempty(x) || all(~isfinite(double(x(:))))
    value = NaN;
else
    value = mean(double(x(isfinite(double(x(:))))));
end
end

function textValue = mat2str_safe(value)
if isempty(value)
    textValue = '';
else
    try
        textValue = mat2str(value);
    catch
        textValue = '<unprintable>';
    end
end
end

function n = numel_safe(value)
if isempty(value)
    n = 0;
else
    n = numel(value);
end
end

function textValue = selected_config_text(selectedConfig)
if isempty(selectedConfig) || ~isstruct(selectedConfig)
    textValue = '';
    return;
end
fields = {'beta', 'lambda', 'lambdaBIC', 'minNodeSize', 'tauSplit', 'randomSeed', 'targetView'};
parts = {};
for i = 1:numel(fields)
    name = fields{i};
    if isfield(selectedConfig, name)
        parts{end + 1} = sprintf('%s=%s', name, mat2str_safe(selectedConfig.(name))); %#ok<AGROW>
    end
end
textValue = strjoin(parts, ', ');
end
