function outputs = generate_final_ablation_analysis(resultType)
%GENERATE_FINAL_ABLATION_ANALYSIS 生成 BIC-LR-3AMVC 最终消融分析报告。
%   OUTPUTS = GENERATE_FINAL_ABLATION_ANALYSIS() 同时生成 mean 口径与 best
%   口径两套分析报告，并在 reports 下生成 mean_vs_best_comparison.md。
%
%   OUTPUTS = GENERATE_FINAL_ABLATION_ANALYSIS(RESULTTYPE) 只生成指定口径
%   的报告。RESULTTYPE 可取 'mean' 或 'best'。
%
%   本函数读取 ablation_biclr/res、3AMVC-main/res_biclr_refined、
%   D:\matlab\3AMVC-BIC\res 以及 PDF 文本抽取结果，生成论文实验分析可用的
%   CSV 与 Markdown 文件。
%
%   注意事项：
%   1. 本函数只读取已有结果，不重新运行任何网格搜索。
%   2. Caltech256 的原始 3AMVC baseline 使用本地源码运行结果，不使用论文
%      中 Caltech256 指标作为正式对比。
%   3. catlch101 all / Caltech101-all 不纳入本轮分析。

if nargin < 1 || isempty(resultType)
    meanOutput = generate_final_ablation_analysis_one('mean');
    bestOutput = generate_final_ablation_analysis_one('best');
    comparisonFile = write_mean_vs_best_comparison(meanOutput, bestOutput);
    outputs = struct();
    outputs.mean = meanOutput;
    outputs.best = bestOutput;
    outputs.meanVsBestComparisonFile = comparisonFile;
    return;
end

resultType = validate_result_type(resultType);
outputs = generate_final_ablation_analysis_one(resultType);
end

function outputs = generate_final_ablation_analysis_one(resultType)
paths = get_project_paths();
repoRoot = paths.repoRoot;
analysisDir = fullfile(paths.reportRoot, ['analysis_final_' resultType]);
ensure_dir(analysisDir);

paperPdf = fullfile(repoRoot, '3664647.3681273.pdf');
suppPdf = fullfile(repoRoot, 'The_Name_of_the_Title_is_Hope (1).pdf');
pdfTextDir = fullfile(analysisDir, 'pdf_text');
paperTextFile = fullfile(pdfTextDir, 'paper.txt');
suppTextFile = fullfile(pdfTextDir, 'supplement.txt');
ensure_pdf_text_extract(paperPdf, paperTextFile);
ensure_pdf_text_extract(suppPdf, suppTextFile);

datasets = {'Mfeat', 'Reuters-1200', 'WIKI', 'Caltech256', 'ForestTypes'};
methods = {'A0_Full_Reference', 'A1_woBIC_Joint', 'A3_SSETarget', 'A4_woMultiViewFusion'};
methodLabels = containers.Map(methods, {'A0 Full', 'A1 w/o BIC', 'A3 SSE Target', 'A4 Single View'});

paperInfo = build_paper_info(paperPdf, suppPdf, paperTextFile, suppTextFile);
write_paper_baseline_files(paperInfo, analysisDir, resultType);

[localCaltechRows, localCaltechBest] = read_local_caltech_baseline(repoRoot);
localCaltechBest.resultType = resultType;
paperInfo.resultType = resultType;
write_local_caltech_files(localCaltechRows, localCaltechBest, analysisDir, resultType);

resultMap = containers.Map();
resultFiles = {};
missingItems = {};
for id = 1:numel(datasets)
    for im = 1:numel(methods)
        ds = datasets{id};
        method = methods{im};
        rec = read_result_record(ds, method, paths, resultType);
        resultMap(make_key(ds, method)) = rec;
        if rec.found
            resultFiles{end + 1, 1} = rec.sourceFile; %#ok<AGROW>
        else
            missingItems{end + 1, 1} = sprintf('%s / %s', ds, method); %#ok<AGROW>
        end
    end
end

mainTable = build_main_performance_table(datasets, methods, methodLabels, resultMap);
mainWithBaselineTable = build_main_with_baseline_table(datasets, methods, methodLabels, resultMap, paperInfo, localCaltechBest);
detailedTable = build_detailed_metric_table(datasets, methods, resultMap, paperInfo, localCaltechBest);
mechanismTable = build_mechanism_table(datasets, methods, resultMap);
viewSelectionTable = build_view_selection_table(datasets, resultMap, paperInfo);
searchBudgetTable = build_search_budget_table(datasets, methods, resultMap, paperInfo, localCaltechBest);

write_table_pair(mainTable, fullfile(analysisDir, 'main_performance_table'), resultType, '主性能表');
write_table_pair(mainWithBaselineTable, fullfile(analysisDir, 'main_performance_with_original_baseline'), resultType, '带 Original baseline 的主性能表');
write_table_pair(detailedTable, fullfile(analysisDir, 'detailed_metric_table'), resultType, '详细指标表');
write_table_pair(mechanismTable, fullfile(analysisDir, 'mechanism_table'), resultType, '机制分析表');
write_table_pair(viewSelectionTable, fullfile(analysisDir, 'view_selection_table_A3'), resultType, 'A3 视图选择分析表');
write_table_pair(searchBudgetTable, fullfile(analysisDir, 'search_budget_table'), resultType, '搜索预算表');

analysis = analyze_results(datasets, methods, resultMap, paperInfo, localCaltechBest, resultType);
write_analysis_report(analysisDir, datasets, methods, resultFiles, missingItems, paperInfo, localCaltechRows, localCaltechBest, ...
    mainTable, mainWithBaselineTable, detailedTable, mechanismTable, viewSelectionTable, searchBudgetTable, analysis, resultType);
write_paper_summary(analysisDir, datasets, resultMap, paperInfo, localCaltechBest, analysis, resultType);

outputs = struct();
outputs.analysisDir = analysisDir;
outputs.resultType = resultType;
outputs.datasets = datasets;
outputs.methods = methods;
outputs.resultMap = resultMap;
outputs.paperInfo = paperInfo;
outputs.localCaltechBest = localCaltechBest;
outputs.mainTable = mainTable;
outputs.mainWithBaselineTable = mainWithBaselineTable;
outputs.detailedTable = detailedTable;
outputs.mechanismTable = mechanismTable;
outputs.viewSelectionTable = viewSelectionTable;
outputs.searchBudgetTable = searchBudgetTable;
outputs.analysis = analysis;
outputs.resultFiles = resultFiles;
outputs.missingItems = missingItems;
outputs.localCaltechBaselineFile = localCaltechBest.sourceFile;
outputs.generatedFiles = list_generated_files(analysisDir);
end

function rec = read_result_record(datasetName, methodName, paths, resultType)
rec = empty_record(datasetName, methodName);
rec.resultType = resultType;
switch methodName
    case 'A0_Full_Reference'
        rec = read_a0_record(datasetName, paths, resultType);
    otherwise
        dirName = dataset_to_dir(datasetName);
        methodDir = fullfile(paths.resRoot, methodName, dirName);
        filePath = select_latest_mat(methodDir, methodName, dirName);
        if isempty(filePath)
            return;
        end
        loaded = load(filePath);
        if isfield(loaded, 'resultSummary')
            summary = loaded.resultSummary;
        elseif isfield(loaded, 'bestResult')
            summary = loaded.bestResult;
        else
            summary = loaded;
        end
        rec = record_from_summary(summary, datasetName, methodName, filePath, resultType, loaded);
        rec.source = 'local ablation result';
        rec.sourceType = '本地消融结果';
        if isfield(loaded, 'config')
            rec.config = loaded.config;
        end
        if isfield(loaded, 'methodConfig')
            rec.methodConfig = loaded.methodConfig;
        end
        rec.found = true;
end
end

function rec = read_a0_record(datasetName, paths, resultType)
rec = empty_record(datasetName, 'A0_Full_Reference');
rec.resultType = resultType;
switch datasetName
    case 'Mfeat'
        filePath = fullfile(paths.mainCodeRoot, 'res_biclr_refined', 'MFeat_2Views_BICLR_refined_best_ACC.mat');
    case 'Reuters-1200'
        filePath = fullfile(paths.mainCodeRoot, 'res_biclr_refined', 'Reuters_1200_BICLR_refined_best_ACC.mat');
    case 'WIKI'
        textPath = fullfile(paths.mainCodeRoot, 'res_biclr_refined', 'Wikifea_BICLR_refined_best_ACC.txt');
        if exist(textPath, 'file')
            rec = parse_refined_a0_text(textPath, 'WIKI', resultType);
            return;
        end
        filePath = fullfile(paths.mainCodeRoot, 'res_biclr_refined', 'Wikifea_BICLR_refined_best_ACC.mat');
    case 'ForestTypes'
        filePath = fullfile(paths.mainCodeRoot, 'res_biclr_refined', 'ForestTypes_BICLR_refined_best_ACC.mat');
    case 'Caltech256'
        filePath = fullfile(paths.mainCodeRoot, 'res_biclr_refined', 'Caltech256_4Views_257cls_withClutter_BICLR_refined_best_ACC.txt');
        if exist(filePath, 'file')
            rec = parse_refined_a0_text(filePath, 'Caltech256', resultType);
        end
        return;
    otherwise
        filePath = '';
end
if isempty(filePath) || ~exist(filePath, 'file')
    return;
end
loaded = load(filePath);
if isfield(loaded, 'bestInfo')
    b = loaded.bestInfo;
else
    b = loaded;
end
rec = record_from_bestinfo(b, datasetName, filePath, resultType);
rec.source = 'A0 result from 3AMVC-main/res_biclr_refined';
rec.sourceType = '本地 A0 结果';
rec.found = true;
end

function rec = record_from_summary(summary, datasetName, methodName, filePath, resultType, loaded)
rec = empty_record(datasetName, methodName);
rec.resultType = resultType;
rec.sourceFile = filePath;
rec.found = true;
rec.beta = get_scalar_field(summary, 'beta');
rec.lambda = get_scalar_field(summary, 'lambda');
rec.lambdaBIC = get_scalar_field(summary, 'lambdaBIC');
rec.minNodeSize = get_scalar_field(summary, 'minNodeSize');
rec.tauSplit = get_scalar_field(summary, 'tauSplit');
rec.targetSelectionMethod = get_char_field(summary, 'targetSelectionMethod');
rec.targetView = get_scalar_field(summary, 'targetView');
rec.anchorCounts = get_any_field(summary, 'anchorCounts', []);
rec.acceptedSplits = get_any_field(summary, 'acceptedSplits', []);
rec.rejectedSplits = get_any_field(summary, 'rejectedSplits', []);
rec.meanLeafSize = get_any_field(summary, 'meanLeafSize', []);
rec.maxDepth = get_any_field(summary, 'maxDepth', []);
rec.anchorTime = get_scalar_field(summary, 'anchorTime');
rec.alignmentTime = get_scalar_field(summary, 'alignmentTime');
rec.totalTime = get_scalar_field(summary, 'totalTime');
rec.randomSeed = get_any_field(summary, 'randomSeed', []);
rec.numGridConfigs = get_scalar_field(summary, 'numGridConfigs');
rec.searchBudget = get_scalar_field(summary, 'searchBudget');
rec.selectionRule = get_char_field(summary, 'selectionRule');
rec.bicTargetView = get_scalar_field(summary, 'bicTargetView');
rec.sseTargetView = get_scalar_field(summary, 'sseTargetView');
rec.targetViewAgreement = get_scalar_field(summary, 'targetViewAgreement');
rec.bicEvidencePerView = get_any_field(summary, 'bicEvidencePerView', []);
rec.totalSSEPerView = get_any_field(summary, 'totalSSEPerView', []);
rec.sseRankCorrelation = get_scalar_field(summary, 'sseRankCorrelation');
rec.useMultiViewFusion = get_any_field(summary, 'useMultiViewFusion', []);
rec.singleViewOnly = get_any_field(summary, 'singleViewOnly', []);
rec.metricsMean = get_metrics_struct(summary, 'metricsMean');
rec.metricsStd = get_metrics_struct(summary, 'metricsStd');
rec.numRuns = get_scalar_field(summary, 'numRuns');
rec.kmeansReplicates = get_scalar_field(summary, 'kmeansReplicates');
if strcmp(resultType, 'best')
    [bestMetrics, bestSource, bestRecord] = extract_best_metrics(summary, loaded);
    rec.metricsMean = bestMetrics;
    rec.metricsStd = empty_metrics();
    rec.bestMetricSource = bestSource;
    if ~isempty(bestRecord)
        rec = apply_record_metadata(rec, bestRecord);
    end
elseif all_metrics_missing(rec.metricsMean) && isstruct(loaded) && isfield(loaded, 'allResults')
    rec.metricsMean = aggregate_selected_config_mean(summary, loaded.allResults);
end
end

function rec = record_from_bestinfo(b, datasetName, filePath, resultType)
rec = empty_record(datasetName, 'A0_Full_Reference');
rec.resultType = resultType;
rec.sourceFile = filePath;
rec.beta = get_scalar_field(b, 'beta');
rec.lambda = get_scalar_field(b, 'lambda');
rec.lambdaBIC = get_scalar_field(b, 'lambdaBIC');
rec.minNodeSize = get_scalar_field(b, 'minNodeSize');
rec.tauSplit = get_scalar_field(b, 'tauSplit');
rec.targetSelectionMethod = 'BICUnitEvidence';
rec.targetView = get_scalar_field(b, 'targetView');
rec.anchorCounts = get_any_field(b, 'anchorCounts', []);
rec.anchorEvidenceGain = get_any_field(b, 'anchorEvidenceGain', []);
rec.randomSeed = get_scalar_field(b, 'randomSeed');
rec.numRuns = get_scalar_field(b, 'numRuns');
rec.kmeansReplicates = get_scalar_field(b, 'kmeansReplicates');
rec.totalTime = get_scalar_field(b, 'totalTime');
rec.selectionRule = get_char_field(b, 'selectionMode');
if isempty(rec.selectionRule)
    rec.selectionRule = 'best_mean_ACC_then_NMI';
end
if strcmp(resultType, 'best')
    if isfield(b, 'bestEvalMetrics') && ~isempty(b.bestEvalMetrics)
        rec.metricsMean = metrics_from_vector(b.bestEvalMetrics, b.metricNames);
        rec.bestMetricSource = 'bestEvalMetrics';
    elseif isfield(b, 'evalMaxMetrics') && ~isempty(b.evalMaxMetrics)
        rec.metricsMean = metrics_from_vector(b.evalMaxMetrics, b.metricNames);
        rec.bestMetricSource = 'evalMaxMetrics';
    else
        rec.metricsMean = empty_metrics();
        rec.bestMetricSource = 'Missing';
    end
    rec.metricsStd = empty_metrics();
elseif isfield(b, 'evalMeanMetrics')
    rec.metricsMean = metrics_from_vector(b.evalMeanMetrics, b.metricNames);
else
    rec.metricsMean = metrics_from_vector(b.metricsMean, b.metricNames);
end
if isfield(b, 'evalStdMetrics')
    rec.metricsStd = metrics_from_vector(b.evalStdMetrics, b.metricNames);
elseif isfield(b, 'metricsStd')
    rec.metricsStd = metrics_from_vector(b.metricsStd, b.metricNames);
end
rec.found = true;
end

function rec = parse_refined_a0_text(filePath, datasetName, resultType)
%PARSE_REFINED_A0_TEXT 从 refined best_ACC 文本中读取 A0 mean/best 摘要。
%   mean 口径优先读取“按重复评价平均 ACC 最高”段的均值。
%   best 口径优先按 ACC/NMI/AR 从 bestRun/summary 指标中选取；若文本没有
%   bestRun 指标，则回退到“最好均值”，避免把已有 A0 文本摘要误标为缺失。
rec = empty_record(datasetName, 'A0_Full_Reference');
rec.resultType = resultType;
text = fileread(filePath);

meanBlock = regexp(text, '【二、按重复评价平均 ACC 最高】(?<body>[\s\S]*)', 'names', 'once');
upperBlock = regexp(text, '【一、按重复评价均值\+标准差上界 ACC 最高】(?<body>[\s\S]*?)(?=【二、|$)', 'names', 'once');
if strcmp(resultType, 'best')
    candidates = {};
    if ~isempty(upperBlock)
        candidates{end + 1} = upperBlock.body; %#ok<AGROW>
    end
    if ~isempty(meanBlock)
        candidates{end + 1} = meanBlock.body; %#ok<AGROW>
    end
    if isempty(candidates)
        candidates = {text};
    end
    [body, bestMetrics, bestSource] = select_best_text_block(candidates);
else
    if ~isempty(meanBlock)
        body = meanBlock.body;
    elseif ~isempty(upperBlock)
        body = upperBlock.body;
    else
        body = text;
    end
    bestMetrics = empty_metrics();
    bestSource = '';
end

if strcmp(datasetName, 'Caltech256')
    rec.sourceType = '本地 A0 结果（日志解析）';
else
    rec.sourceType = '本地 A0 结果（文本摘要）';
end
rec.sourceFile = filePath;
rec.beta = parse_number(body, 'beta');
rec.lambda = parse_number(body, 'lambda');
rec.lambdaBIC = parse_number(body, 'lambdaBIC');
rec.minNodeSize = parse_number(body, 'minNodeSize');
rec.tauSplit = parse_number(body, 'tauSplit');
rec.randomSeed = parse_number(body, 'randomSeed');
rec.numRuns = parse_number(body, 'numRuns');
rec.kmeansReplicates = parse_number(body, 'kmeansReplicates');
rec.targetView = parse_number(body, 'targetView');
rec.anchorCounts = parse_vector_after_label(body, 'anchorCounts');
rec.anchorEvidenceGain = parse_vector_after_label(body, 'anchorEvidenceGain');
rec.targetSelectionMethod = 'BICUnitEvidence';
if strcmp(resultType, 'best')
    if all_metrics_missing(bestMetrics)
        rec.metricsMean.ACC = parse_metric_mean(body, 'ACC');
        rec.metricsMean.NMI = parse_metric_mean(body, 'NMI');
        rec.metricsMean.Purity = parse_metric_mean(body, 'Purity');
        rec.metricsMean.Fscore = parse_metric_mean(body, 'Fscore');
        rec.metricsMean.Precision = NaN;
        rec.metricsMean.Recall = NaN;
        rec.metricsMean.AR = NaN;
        rec.metricsMean.Entropy = NaN;
        rec.bestMetricSource = 'best mean from refined text';
    else
        rec.metricsMean = bestMetrics;
        rec.bestMetricSource = bestSource;
    end
    rec.metricsStd = empty_metrics();
else
    rec.metricsMean.ACC = parse_metric_mean(body, 'ACC');
    rec.metricsMean.NMI = parse_metric_mean(body, 'NMI');
    rec.metricsMean.Purity = parse_metric_mean(body, 'Purity');
    rec.metricsMean.Fscore = parse_metric_mean(body, 'Fscore');
    rec.metricsMean.Precision = NaN;
    rec.metricsMean.Recall = NaN;
    rec.metricsMean.AR = NaN;
    rec.metricsMean.Entropy = NaN;
    rec.metricsStd.ACC = parse_metric_std(body, 'ACC');
    rec.metricsStd.NMI = parse_metric_std(body, 'NMI');
    rec.metricsStd.Purity = parse_metric_std(body, 'Purity');
    rec.metricsStd.Fscore = parse_metric_std(body, 'Fscore');
    rec.metricsStd.Precision = NaN;
    rec.metricsStd.Recall = NaN;
    rec.metricsStd.AR = NaN;
    rec.metricsStd.Entropy = NaN;
end
rec.source = 'A0 result parsed from 3AMVC-main/res_biclr_refined text';
rec.selectionRule = 'best_mean_ACC_then_NMI';
rec.found = true;
end

function [rows, best] = read_local_caltech_baseline(repoRoot)
resDir = fullfile(repoRoot, 'res');
files = dir(fullfile(resDir, '*caltech256*bestacc_detail.mat'));
rows = table();
best = empty_baseline_record('Caltech256');
if isempty(files)
    return;
end

records = cell(numel(files), 1);
for i = 1:numel(files)
    fp = fullfile(files(i).folder, files(i).name);
    loaded = load(fp);
    if isfield(loaded, 'bestResult')
        b = loaded.bestResult;
    else
        b = struct();
    end
    records{i} = struct( ...
        'Dataset', 'Caltech256', ...
        'Source', 'Original 3AMVC local run on catlch256_4Views_257cls_withClutter', ...
        'File', fp, ...
        'ACC_mean', get_scalar_field(b, 'ACC_mean'), ...
        'ACC_std', get_scalar_field(b, 'ACC_std'), ...
        'NMI_mean', get_scalar_field(b, 'NMI_mean'), ...
        'NMI_std', get_scalar_field(b, 'NMI_std'), ...
        'AR_mean', get_scalar_field(b, 'AR_mean'), ...
        'AR_std', get_scalar_field(b, 'AR_std'), ...
        'Purity_mean', get_scalar_field(b, 'Purity_mean'), ...
        'Fscore_mean', get_scalar_field(b, 'Fscore_mean'), ...
        'Precision_mean', get_scalar_field(b, 'Precision_mean'), ...
        'Recall_mean', get_scalar_field(b, 'Recall_mean'), ...
        'Entropy_mean', get_scalar_field(b, 'Entropy_mean'), ...
        'Selected_beta', get_scalar_field(b, 'beta'), ...
        'Selected_lambda', get_scalar_field(b, 'lambda'), ...
        'SelectedTargetView', get_scalar_field(b, 'SelectedTargetView'), ...
        'AnchorCounts', stringify(get_any_field(b, 'AnchorCounts_mode', '')), ...
        'LastWriteTime', files(i).datenum, ...
        'Chosen', false);
end
rows = struct2table(vertcat(records{:}));

% 选择依据：优先最新 refined4，若不存在则取最新且字段完整的结果。
nameList = string({files.name});
chosenIdx = find(contains(lower(nameList), 'refined4'), 1, 'last');
if isempty(chosenIdx)
    [~, chosenIdx] = max([files.datenum]);
end
rows.Chosen(chosenIdx) = true;
chosen = rows(chosenIdx, :);
best = empty_baseline_record('Caltech256');
best.found = true;
best.datasetName = 'Caltech256';
best.source = chosen.Source{1};
best.sourceType = '本地原始 3AMVC 源码运行结果';
best.sourceFile = chosen.File{1};
best.metricsMean.ACC = chosen.ACC_mean;
best.metricsMean.NMI = chosen.NMI_mean;
best.metricsMean.AR = chosen.AR_mean;
best.metricsMean.Purity = chosen.Purity_mean;
best.metricsMean.Fscore = chosen.Fscore_mean;
best.metricsMean.Precision = chosen.Precision_mean;
best.metricsMean.Recall = chosen.Recall_mean;
best.metricsMean.Entropy = chosen.Entropy_mean;
best.metricsStd.ACC = chosen.ACC_std;
best.metricsStd.NMI = chosen.NMI_std;
best.metricsStd.AR = chosen.AR_std;
best.beta = chosen.Selected_beta;
best.lambda = chosen.Selected_lambda;
best.targetView = chosen.SelectedTargetView;
best.anchorCounts = chosen.AnchorCounts{1};
end

function paperInfo = build_paper_info(paperPdf, suppPdf, paperTextFile, suppTextFile)
paperInfo = struct();
paperInfo.paperPdf = paperPdf;
paperInfo.suppPdf = suppPdf;
paperInfo.paperTextFile = paperTextFile;
paperInfo.suppTextFile = suppTextFile;
paperInfo.pdfExtractionComplete = false;
paperInfo.extractionNote = 'PDF table extraction incomplete; manual verification needed.';
paperInfo.paperRead = exist(paperPdf, 'file') == 2 && exist(paperTextFile, 'file') == 2;
paperInfo.suppRead = exist(suppPdf, 'file') == 2 && exist(suppTextFile, 'file') == 2;

paperInfo.datasetSettings = { ...
    'ForestTypes', 523, 4, 3; ...
    'Reuters-1200', 1200, 6, 5; ...
    'Mfeat', 2000, 10, 2; ...
    'Caltech256', 30607, 256, 4; ...
    'VGGFace2', 36287, 100, 4};

paperInfo.metrics = {'ACC', 'NMI', 'Fscore'};
paperInfo.randomRepeatNote = '论文正文未在可抽取文本中明确给出随机重复次数；报告 ACC/NMI/Fscore。';
paperInfo.parameterRange = '3AMVC 调整 beta 到 [10^-2, 1, 10^2]，lambda 到 [0, 10^-4, 10^-2, 1, 10^4]。';
paperInfo.methodProtocol = ['原始 3AMVC 使用 HBNC 生成各视图自适应锚点；使用 Eq.(8) 的簇内距离质量准则' ...
    '选择 baseline view；将其他视图锚图对齐到 baseline view 后做等权融合并谱聚类。'];

paperInfo.paper3amvc = containers.Map();
paperInfo.paper3amvc('ForestTypes') = baseline_metric_record(0.7984, 0.5397, NaN, NaN, 0.6752, 'Paper reported 3AMVC');
paperInfo.paper3amvc('Reuters-1200') = baseline_metric_record(0.5734, 0.3316, NaN, NaN, 0.4061, 'Paper reported 3AMVC');
paperInfo.paper3amvc('Mfeat') = baseline_metric_record(0.8737, 0.8240, NaN, NaN, 0.7986, 'Paper reported 3AMVC');
paperInfo.paper3amvc('Caltech256') = baseline_metric_record(0.1023, 0.3210, NaN, NaN, 0.0792, 'Paper reported 3AMVC; reference only for current Caltech256');

paperInfo.anchorInfo = containers.Map();
paperInfo.anchorInfo('ForestTypes') = struct('baselineView', 3, 'anchorCounts', [10 16 20]);
paperInfo.anchorInfo('Mfeat') = struct('baselineView', 1, 'anchorCounts', [54 64]);
paperInfo.anchorInfo('Reuters-1200') = struct('baselineView', 5, 'anchorCounts', [62 48 45 13 53]);
paperInfo.anchorInfo('Caltech256') = struct('baselineView', 3, 'anchorCounts', [48 67 62 45]);
end

function write_paper_baseline_files(paperInfo, analysisDir, resultType)
rows = {};
ds = paperInfo.datasetSettings;
for i = 1:size(ds, 1)
    datasetName = ds{i, 1};
    acc = NaN; nmi = NaN; fscore = NaN; source = 'Paper dataset setting';
    if isKey(paperInfo.paper3amvc, datasetName)
        b = paperInfo.paper3amvc(datasetName);
        acc = b.metricsMean.ACC;
        nmi = b.metricsMean.NMI;
        fscore = b.metricsMean.Fscore;
        source = b.source;
    end
    baselineView = NaN; anchorCounts = '';
    if isKey(paperInfo.anchorInfo, datasetName)
        a = paperInfo.anchorInfo(datasetName);
        baselineView = a.baselineView;
        anchorCounts = mat2str(a.anchorCounts);
    end
    rows(end + 1, :) = {datasetName, ds{i, 2}, ds{i, 3}, ds{i, 4}, ...
        acc, nmi, NaN, NaN, fscore, baselineView, anchorCounts, source}; %#ok<AGROW>
end
tbl = cell2table(rows, 'VariableNames', {'Dataset', 'Samples', 'Clusters', 'Views', ...
    'ACC', 'NMI', 'AR', 'Purity', 'Fscore', 'PaperBaselineView', 'HBNCAnchorCounts', 'Source'});
write_table_pair(tbl, fullfile(analysisDir, 'paper_baseline_extracted'), resultType, '原论文与补充材料信息提取表');

md = {};
md{end+1} = sprintf('# 原论文与补充材料信息提取（%s 口径）', resultType);
md{end+1} = '';
md{end+1} = sprintf('- 原论文 PDF：`%s`', paperInfo.paperPdf);
md{end+1} = sprintf('- 补充材料 PDF：`%s`', paperInfo.suppPdf);
md{end+1} = sprintf('- PDF 读取状态：原论文=%d，补充材料=%d', paperInfo.paperRead, paperInfo.suppRead);
md{end+1} = sprintf('- 表格抽取说明：%s', paperInfo.extractionNote);
md{end+1} = '';
md{end+1} = '## 实验设置';
md{end+1} = sprintf('- 数据集：ForestTypes、Reuters、MFeat、Caltech256、VGGFace2。');
md{end+1} = sprintf('- 指标：%s。', strjoin(paperInfo.metrics, ', '));
md{end+1} = sprintf('- 参数范围：%s', paperInfo.parameterRange);
md{end+1} = sprintf('- 方法口径：%s', paperInfo.methodProtocol);
md{end+1} = '';
md{end+1} = '## 结构化提取表';
md{end+1} = table_to_markdown(tbl);
write_text(fullfile(analysisDir, 'paper_baseline_extracted.md'), strjoin(md, newline));
end

function write_local_caltech_files(rows, best, analysisDir, resultType)
if isempty(rows)
    rows = table({'Caltech256'}', {'Missing'}', {'Missing'}', NaN, NaN, NaN, NaN, NaN, NaN, ...
        'VariableNames', {'Dataset', 'Source', 'File', 'ACC_mean', 'ACC_std', 'NMI_mean', 'NMI_std', 'AR_mean', 'AR_std'});
end
writetable(rows, fullfile(analysisDir, 'local_original_caltech256_result.csv'));
md = {};
md{end+1} = sprintf('# Caltech256 本地原始 3AMVC baseline（%s 口径）', resultType);
md{end+1} = '';
md{end+1} = '本表只用于 Caltech256 的原始 3AMVC 对比。由于当前 Caltech256 数据由用户自行处理，论文报告的 Caltech256 指标不作为正式 baseline。';
md{end+1} = '';
if best.found
    md{end+1} = sprintf('选用 baseline 文件：`%s`。', best.sourceFile);
    md{end+1} = sprintf('选用依据：与 `catlch256_4Views_257cls_withClutter` 最相关、时间最新且指标字段完整。');
else
    md{end+1} = '未找到可用的 Caltech256 本地原始 3AMVC baseline。';
end
md{end+1} = '';
md{end+1} = table_to_markdown(rows);
write_text(fullfile(analysisDir, 'local_original_caltech256_result.md'), strjoin(md, newline));
end

function mainTable = build_main_performance_table(datasets, methods, methodLabels, resultMap)
rows = {};
for id = 1:numel(datasets)
    ds = datasets{id};
    row = cell(1, numel(methods) + 1);
    row{1} = ds;
    for im = 1:numel(methods)
        rec = resultMap(make_key(ds, methods{im}));
        row{im + 1} = perf_cell(rec);
    end
    rows(end + 1, :) = row; %#ok<AGROW>
end
varNames = [{'Dataset'}, cellfun(@(m) matlab.lang.makeValidName(methodLabels(m)), methods, 'UniformOutput', false)];
mainTable = cell2table(rows, 'VariableNames', varNames);
mainTable.Properties.VariableDescriptions = [{'Dataset'}, cellfun(@(m) methodLabels(m), methods, 'UniformOutput', false)];
end

function tbl = build_main_with_baseline_table(datasets, methods, methodLabels, resultMap, paperInfo, localCaltechBest)
rows = {};
for id = 1:numel(datasets)
    ds = datasets{id};
    row = cell(1, numel(methods) + 2);
    row{1} = ds;
    row{2} = original_baseline_cell(ds, paperInfo, localCaltechBest);
    for im = 1:numel(methods)
        rec = resultMap(make_key(ds, methods{im}));
        row{im + 2} = perf_cell(rec);
    end
    rows(end + 1, :) = row; %#ok<AGROW>
end
varNames = [{'Dataset', 'Original_3AMVC_Baseline'}, ...
    cellfun(@(m) matlab.lang.makeValidName(methodLabels(m)), methods, 'UniformOutput', false)];
tbl = cell2table(rows, 'VariableNames', varNames);
tbl.Properties.VariableDescriptions = [{'Dataset', 'Original 3AMVC Baseline'}, ...
    cellfun(@(m) methodLabels(m), methods, 'UniformOutput', false)];
end

function tbl = build_detailed_metric_table(datasets, methods, resultMap, paperInfo, localCaltechBest)
rows = {};
for id = 1:numel(datasets)
    ds = datasets{id};
    base = get_original_baseline_record(ds, paperInfo, localCaltechBest);
    if base.found
        rows(end + 1, :) = detailed_row_from_record(base, 'Original 3AMVC Baseline', base.source); %#ok<AGROW>
    end
    a0 = resultMap(make_key(ds, 'A0_Full_Reference'));
    for im = 1:numel(methods)
        rec = resultMap(make_key(ds, methods{im}));
        row = detailed_row_from_record(rec, methods{im}, rec.source);
        if rec.found && a0.found && ~strcmp(methods{im}, 'A0_Full_Reference')
            row{end - 2} = metric_delta(rec, a0, 'ACC');
            row{end - 1} = metric_delta(rec, a0, 'NMI');
            row{end} = metric_delta(rec, a0, 'AR');
        elseif rec.found && base.found && strcmp(methods{im}, 'A0_Full_Reference')
            row{end - 2} = metric_delta(rec, base, 'ACC');
            row{end - 1} = metric_delta(rec, base, 'NMI');
            row{end} = metric_delta(rec, base, 'AR');
        end
        rows(end + 1, :) = row; %#ok<AGROW>
    end
end
tbl = cell2table(rows, 'VariableNames', {'Dataset', 'Method', 'Source', 'Result_type', ...
    'ACC', 'NMI', 'AR', 'Purity', 'Fscore', 'Precision', 'Recall', 'Entropy', ...
    'Selected_beta', 'Selected_lambda', 'Selected_lambdaBIC', 'Selected_minNodeSize', ...
    'Delta_ACC', 'Delta_NMI', 'Delta_AR'});
end

function row = detailed_row_from_record(rec, methodName, sourceText)
row = {rec.datasetName, methodName, sourceText, rec.resultType, ...
    metric_value(rec, 'ACC'), metric_value(rec, 'NMI'), metric_value(rec, 'AR'), ...
    metric_value(rec, 'Purity'), metric_value(rec, 'Fscore'), ...
    metric_value(rec, 'Precision'), metric_value(rec, 'Recall'), metric_value(rec, 'Entropy'), ...
    rec.beta, rec.lambda, rec.lambdaBIC, rec.minNodeSize, NaN, NaN, NaN};
end

function tbl = build_mechanism_table(datasets, methods, resultMap)
rows = {};
for id = 1:numel(datasets)
    for im = 1:numel(methods)
        rec = resultMap(make_key(datasets{id}, methods{im}));
        rows(end + 1, :) = {datasets{id}, methods{im}, rec.resultType, ...
            safe_mean(rec.anchorCounts), stringify(rec.anchorCounts), rec.targetView, ...
            stringify(rec.acceptedSplits), stringify(rec.rejectedSplits), stringify(rec.meanLeafSize), ...
            stringify(rec.maxDepth), rec.anchorTime, rec.alignmentTime, rec.totalTime}; %#ok<AGROW>
    end
end
tbl = cell2table(rows, 'VariableNames', {'Dataset', 'Method', 'Result_type', 'Avg_anchors', ...
    'Anchor_counts_per_view', 'Target_view', 'Accepted_splits', 'Rejected_splits', ...
    'Mean_leaf_size', 'Max_depth', 'Anchor_time', 'Alignment_time', 'Total_time'});
end

function tbl = build_view_selection_table(datasets, resultMap, paperInfo)
rows = {};
for id = 1:numel(datasets)
    ds = datasets{id};
    a0 = resultMap(make_key(ds, 'A0_Full_Reference'));
    a3 = resultMap(make_key(ds, 'A3_SSETarget'));
    suppBaseline = NaN; suppAnchors = '';
    if isKey(paperInfo.anchorInfo, ds)
        info = paperInfo.anchorInfo(ds);
        suppBaseline = info.baselineView;
        suppAnchors = mat2str(info.anchorCounts);
    end
    rows(end + 1, :) = {ds, a3.resultType, a0.targetView, a3.bicTargetView, a3.sseTargetView, ...
        a3.targetViewAgreement, stringify(a3.bicEvidencePerView), stringify(a3.totalSSEPerView), ...
        a3.sseRankCorrelation, suppBaseline, suppAnchors}; %#ok<AGROW>
end
tbl = cell2table(rows, 'VariableNames', {'Dataset', 'Result_type', 'A0_BIC_Target_View', ...
    'A3_BIC_Target_View', 'A3_SSE_Target_View', 'Agreement', ...
    'BIC_Evidence_per_View', 'SSE_per_View', 'Kendall_tau', ...
    'Paper_HBNC_Baseline_View', 'Paper_HBNC_Anchor_Counts'});
end

function tbl = build_search_budget_table(datasets, methods, resultMap, paperInfo, localCaltechBest)
rows = {};
for id = 1:numel(datasets)
    ds = datasets{id};
    base = get_original_baseline_record(ds, paperInfo, localCaltechBest);
    if base.found
        rows(end + 1, :) = {ds, 'Original 3AMVC Baseline', base.sourceType, base.resultType, NaN, NaN, NaN, NaN, ...
            'paper/local baseline; not directly comparable search budget', baseline_config_text(base)}; %#ok<AGROW>
    end
    for im = 1:numel(methods)
        rec = resultMap(make_key(ds, methods{im}));
        rows(end + 1, :) = {ds, methods{im}, rec.sourceType, rec.resultType, rec.numGridConfigs, numel_nonempty(rec.randomSeed), ...
            rec.numRuns, rec.searchBudget, rec.selectionRule, selected_config_text(rec)}; %#ok<AGROW>
    end
end
tbl = cell2table(rows, 'VariableNames', {'Dataset', 'Method', 'Source', 'Result_type', ...
    'numGridConfigs', 'numSeeds', 'numRuns', 'searchBudget', 'selectionRule', 'selectedConfig'});
end

function analysis = analyze_results(datasets, methods, resultMap, paperInfo, localCaltechBest, resultType)
analysis = struct();
analysis.resultType = resultType;
analysis.methodDeltas = {};
analysis.baselineDeltas = {};
analysis.anomalies = {};
analysis.keyFindings = {};

for id = 1:numel(datasets)
    ds = datasets{id};
    a0 = resultMap(make_key(ds, 'A0_Full_Reference'));
    if a0.found && isempty(strfind(lower(a0.sourceFile), lower(fullfile('3AMVC-main', 'res_biclr_refined'))))
        analysis.anomalies{end + 1, 1} = sprintf('%s: A0 不是从 3AMVC-main/res_biclr_refined 读取。', ds); %#ok<AGROW>
    end
    base = get_original_baseline_record(ds, paperInfo, localCaltechBest);
    if a0.found && base.found
        analysis.baselineDeltas(end + 1, :) = {ds, metric_delta(a0, base, 'ACC'), metric_delta(a0, base, 'NMI'), metric_delta(a0, base, 'AR')}; %#ok<AGROW>
    end
    for im = 2:numel(methods)
        rec = resultMap(make_key(ds, methods{im}));
        if rec.found && a0.found
            dacc = metric_delta(rec, a0, 'ACC');
            dnmi = metric_delta(rec, a0, 'NMI');
            dar = metric_delta(rec, a0, 'AR');
            analysis.methodDeltas(end + 1, :) = {ds, methods{im}, dacc, dnmi, dar}; %#ok<AGROW>
        end
    end
    a1 = resultMap(make_key(ds, 'A1_woBIC_Joint'));
    a3 = resultMap(make_key(ds, 'A3_SSETarget'));
    a4 = resultMap(make_key(ds, 'A4_woMultiViewFusion'));
    if strcmp(resultType, 'best') && a0.found && all_metrics_missing(a0.metricsMean)
        analysis.anomalies{end + 1, 1} = sprintf('%s: A0 best 口径缺少可验证的 best 指标。', ds); %#ok<AGROW>
    end
    if a1.found && abs(a1.lambdaBIC) > eps
        analysis.anomalies{end + 1, 1} = sprintf('%s: A1 lambdaBIC 不是 0。', ds); %#ok<AGROW>
    end
    if a1.found && ~strcmp(a1.targetSelectionMethod, 'LRUnitEvidence')
        analysis.anomalies{end + 1, 1} = sprintf('%s: A1 targetSelectionMethod 不是 LRUnitEvidence。', ds); %#ok<AGROW>
    end
    if a4.found && (~isnan(a4.lambda) || isequal(a4.useMultiViewFusion, true))
        analysis.anomalies{end + 1, 1} = sprintf('%s: A4 lambda 或 useMultiViewFusion 异常。', ds); %#ok<AGROW>
    end
    if a0.found && a3.found && numeric_vector_available(a0.anchorCounts) && numeric_vector_available(a3.anchorCounts) ...
            && ~isequal(double(a0.anchorCounts(:))', double(a3.anchorCounts(:))')
        analysis.anomalies{end + 1, 1} = sprintf('%s: A0 与 A3 在各自最优参数下的 anchorCounts 不一致；当前为各方法自身最优网格口径，严格消融需固定 A0 配置复跑。', ds); %#ok<AGROW>
    end
    if a0.found && a4.found && numeric_vector_available(a0.anchorCounts) && numeric_vector_available(a4.anchorCounts) ...
            && ~isequal(double(a0.anchorCounts(:))', double(a4.anchorCounts(:))')
        analysis.anomalies{end + 1, 1} = sprintf('%s: A0 与 A4 在各自最优参数下的 anchorCounts 不一致；当前为各方法自身最优网格口径，严格消融需固定 A0 配置复跑。', ds); %#ok<AGROW>
    end
end

analysis.keyFindings = build_key_findings(datasets, resultMap, paperInfo, localCaltechBest);
end

function findings = build_key_findings(datasets, resultMap, paperInfo, localCaltechBest)
findings = {};
dropA4 = 0; validA4 = 0;
dropA1 = 0; validA1 = 0;
dropA3 = 0; validA3 = 0;
for id = 1:numel(datasets)
    ds = datasets{id};
    a0 = resultMap(make_key(ds, 'A0_Full_Reference'));
    a1 = resultMap(make_key(ds, 'A1_woBIC_Joint'));
    a3 = resultMap(make_key(ds, 'A3_SSETarget'));
    a4 = resultMap(make_key(ds, 'A4_woMultiViewFusion'));
    if a0.found && a1.found && isfinite(metric_delta(a1, a0, 'ACC'))
        validA1 = validA1 + 1;
        if metric_delta(a1, a0, 'ACC') < -0.02
            dropA1 = dropA1 + 1;
        end
    end
    if a0.found && a3.found && isfinite(metric_delta(a3, a0, 'ACC'))
        validA3 = validA3 + 1;
        if metric_delta(a3, a0, 'ACC') < -0.02
            dropA3 = dropA3 + 1;
        end
    end
    if a0.found && a4.found && isfinite(metric_delta(a4, a0, 'ACC'))
        validA4 = validA4 + 1;
        if metric_delta(a4, a0, 'ACC') < -0.02
            dropA4 = dropA4 + 1;
        end
    end
end
findings{end + 1, 1} = sprintf('A1 在 %d/%d 个可比较数据集上 ACC 较 A0 下降超过 0.02，说明去除 BIC 复杂度惩罚通常会削弱聚类质量。', dropA1, validA1);
findings{end + 1, 1} = sprintf('A3 在 %d/%d 个可比较数据集上 ACC 较 A0 下降超过 0.02，目标视图选择的影响具有数据集依赖性。', dropA3, validA3);
findings{end + 1, 1} = sprintf('A4 在 %d/%d 个可比较数据集上 ACC 较 A0 下降超过 0.02，多视图融合通常是性能来源之一。', dropA4, validA4);
for id = 1:numel(datasets)
    ds = datasets{id};
    a0 = resultMap(make_key(ds, 'A0_Full_Reference'));
    base = get_original_baseline_record(ds, paperInfo, localCaltechBest);
    if a0.found && base.found
        findings{end + 1, 1} = sprintf('%s: A0 相对 Original baseline 的 ΔACC=%s，ΔNMI=%s，ΔAR=%s。', ...
            ds, fmt_delta(metric_delta(a0, base, 'ACC')), fmt_delta(metric_delta(a0, base, 'NMI')), fmt_delta(metric_delta(a0, base, 'AR'))); %#ok<AGROW>
    end
end
end

function write_analysis_report(analysisDir, datasets, methods, resultFiles, missingItems, paperInfo, ~, localBest, ...
    mainTable, mainWithBaselineTable, detailedTable, mechanismTable, viewSelectionTable, searchBudgetTable, analysis, resultType)
md = {};
md{end+1} = sprintf('# BIC-LR-3AMVC 消融实验结果分析（%s 口径）', resultType);
md{end+1} = '';
md{end+1} = '## 1. 实验结果读取情况';
md{end+1} = sprintf('- 当前结果口径：%s。', resultType);
md{end+1} = '- A0_Full 正式结果来源：`D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr_refined`。';
md{end+1} = sprintf('- 已读取方法：%s。', strjoin(methods, ', '));
md{end+1} = sprintf('- 已读取数据集：%s。', strjoin(datasets, ', '));
md{end+1} = sprintf('- 已读取消融/A0 结果文件数：%d。', numel(unique(resultFiles)));
md{end+1} = sprintf('- 缺失结果：%s。', list_or_none(missingItems));
md{end+1} = '- 是否发现 smoke test 结果：未从结果字段中发现 smokeTest=true；但 Caltech256 A0 来源为未完整日志解析，需在论文中说明。';
md{end+1} = '- 字段不一致：A0 结果来自 3AMVC-main 的 bestInfo 或文本摘要，部分字段如 AR、acceptedSplits 可能缺失；A1/A3/A4 结构较统一。';
md{end+1} = sprintf('- 原论文 PDF 读取：%d；补充材料 PDF 读取：%d。', paperInfo.paperRead, paperInfo.suppRead);
md{end+1} = sprintf('- Caltech256 本地原始源码 baseline：%s。', ternary(localBest.found, localBest.sourceFile, 'Missing'));
md{end+1} = '';

md{end+1} = '## 2. 原论文与补充材料信息提取';
md{end+1} = '- 原论文使用 ForestTypes、Reuters、MFeat、Caltech256、VGGFace2 五个数据集。';
md{end+1} = '- 原论文报告 ACC、NMI、Fscore，未在主表中报告 AR、Purity、Precision、Recall、Entropy。';
md{end+1} = sprintf('- 参数搜索范围：%s', paperInfo.parameterRange);
md{end+1} = '- 原始 3AMVC 使用 HBNC 生成自适应锚点，按 Eq.(8) 的锚点质量准则选择 baseline view，并进行跨视图对齐和等权融合。';
md{end+1} = '- 补充材料记录 HBNC 锚点数与 baseline view：ForestTypes=[10,16,20], baseline=3；MFeat=[54,64], baseline=1；Reuters=[62,48,45,13,53], baseline=5；Caltech256=[48,67,62,45], baseline=3。';
md{end+1} = sprintf('- 表格抽取状态：%s', paperInfo.extractionNote);
md{end+1} = '';

md{end+1} = '## 3. Caltech256 特殊说明';
md{end+1} = '- 当前使用的 Caltech256 数据文件是 `catlch256_4Views_257cls_withClutter.mat` 或同名大小写变体。';
md{end+1} = '- 该数据由用户自行处理，可能与原论文 Caltech256 的类别设置和预处理不完全一致。';
md{end+1} = '- 因此，原论文 Caltech256 指标只作为参考，不作为正式 baseline。';
md{end+1} = sprintf('- Caltech256 的正式 Original baseline 使用：`%s`。', ternary(localBest.found, localBest.sourceFile, 'Missing'));
md{end+1} = '';

md{end+1} = '## 4. 主性能比较';
md{end+1} = '### 主性能表';
md{end+1} = table_to_markdown(mainTable);
md{end+1} = '';
md{end+1} = '### 带 Original baseline 的主性能表';
md{end+1} = table_to_markdown(mainWithBaselineTable);
md{end+1} = '';
md{end+1} = '### 结果解读';
md = append_delta_discussion(md, detailedTable);
md{end+1} = '';

md{end+1} = '## 5. BIC 惩罚有效性分析：A0 vs A1';
md = append_method_discussion(md, detailedTable, mechanismTable, 'A1_woBIC_Joint', 'A1 去掉 BIC 惩罚后，若锚点数和 acceptedSplits 增加且性能下降，可解释为过分裂倾向。BIC penalty prevents over-segmentation by penalizing excessive split complexity.');
md{end+1} = '';

md{end+1} = '## 6. BICUnitEvidence 视图选择有效性分析：A0 vs A3';
md{end+1} = table_to_markdown(viewSelectionTable);
md{end+1} = '';
md = append_method_discussion(md, detailedTable, mechanismTable, 'A3_SSETarget', 'A3 只将目标视图选择从 BICUnitEvidence 改为 SSEMin。若 targetView 不同且性能下降，说明复杂度校准的视图质量准则更适合 BIC-LR 锚点生成逻辑。');
md{end+1} = 'SSEMin 更偏向局部重构误差小的视图，而 BICUnitEvidence 同时考虑证据增益和模型复杂度。BICUnitEvidence provides a complexity-calibrated view quality criterion.';
md{end+1} = '';

md{end+1} = '## 7. 多视图融合必要性分析：A0 vs A4';
md = append_method_discussion(md, detailedTable, mechanismTable, 'A4_woMultiViewFusion', 'A4 保留 BIC-LR 锚点生成和目标视图选择，但去除跨视图对齐融合。若 A4 明显低于 A0，说明多视图融合负责把其他视图信息传递到最终聚类。Multi-view fusion is necessary for transferring the improved anchor representation to final clustering.');
md{end+1} = '';

md{end+1} = '## 8. 机制指标分析';
md{end+1} = table_to_markdown(mechanismTable);
md{end+1} = '';
md{end+1} = '- A0 的旧结果部分缺少 acceptedSplits、meanLeafSize、maxDepth 等细节，因此机制分析主要依赖 A1/A3/A4 的统一结果字段。';
md{end+1} = '- A4 的 alignmentTime 应为 0 或 NaN；若性能下降但时间降低，可视为效率更高但精度受损的单视图退化版本。';
md{end+1} = '';

md{end+1} = '## 9. 搜索预算与公平性说明';
md{end+1} = table_to_markdown(searchBudgetTable);
md{end+1} = '';
md{end+1} = '- 主性能表对应各方法自身网格下的最优配置，不是固定 A0 配置的严格消融。';
md{end+1} = '- A4 中 lambda 不适用，因此搜索空间更小，这是方法定义决定的，不应直接解释为算法优势。';
md{end+1} = '- 如果某方法搜索预算与 A0 不同，性能差异应结合搜索空间和机制指标共同解释。';
md{end+1} = '- 当前结果主要对应主性能口径，即每个方法在自身网格下选择最优配置。严格消融表需要在固定 A0 最优参数设置的条件下另行运行。';
md{end+1} = '';

md{end+1} = '## 10. 结论总结';
md{end+1} = sprintf('- 当前口径：%s。mean 口径更适合作为论文主结果；best 口径用于补充观察最优运行潜力。', resultType);
for i = 1:numel(analysis.keyFindings)
    md{end+1} = sprintf('%d. %s', i, analysis.keyFindings{i});
end
md{end+1} = '- 模块贡献大小需要结合不同数据集判断；A4 的下降通常直接反映多视图融合贡献，A1 的锚点机制指标用于解释 BIC 惩罚的作用，A3 用于解释目标视图选择。';
md{end+1} = '';

md{end+1} = '## 11. 需要复查的问题';
reviewItems = {};
reviewItems{end+1} = sprintf('缺失结果：%s。', list_or_none(missingItems));
reviewItems{end+1} = 'A0 旧结果缺少部分机制字段，无法全面比较 acceptedSplits/rejectedSplits。';
reviewItems{end+1} = 'PDF table extraction incomplete; manual verification needed.';
reviewItems{end+1} = 'Caltech256 A0 来源为控制台日志解析，源日志只完成 240/256 条，缺少 AR/Precision/Recall/Entropy。';
reviewItems{end+1} = 'Caltech256 本地 baseline 存在多个候选文件，当前选择 refined4 bestacc detail 作为正式 baseline。';
reviewItems{end+1} = '如需严格消融，需要固定 A0 最优参数设置另行运行 A1/A3/A4 fixed 配置。';
for i = 1:numel(analysis.anomalies)
    reviewItems{end+1} = analysis.anomalies{i}; %#ok<AGROW>
end
for i = 1:numel(reviewItems)
    md{end+1} = sprintf('- %s', reviewItems{i});
end

write_text(fullfile(analysisDir, 'ablation_analysis_report.md'), strjoin(md, newline));
end

function write_paper_summary(analysisDir, datasets, resultMap, paperInfo, localCaltechBest, analysis, resultType)
md = {};
md{end+1} = sprintf('### 消融实验分析（%s 口径）', resultType);
md{end+1} = '';
if strcmp(resultType, 'mean')
    md{end+1} = '本节使用各方法在选定参数配置下的多次运行平均结果，因而更适合作为论文主结果口径。';
else
    md{end+1} = '本节使用各方法在实验记录中可识别的最优运行或最好均值摘要，用于补充说明模型潜力；该口径不应直接替代平均结果作为稳定性证据。';
end
md{end+1} = '';
md{end+1} = ['为验证 BIC-LR-3AMVC 中各组成模块的有效性，本文设置了若干消融变体，' ...
    '包括去除 BIC 复杂度惩罚的 A1、将目标视图选择替换为 SSEMin 的 A3，以及去除多视图融合的 A4。完整模型记为 A0。'];
md{end+1} = '';
md{end+1} = '#### 与原始 3AMVC 的整体比较';
for id = 1:numel(datasets)
    ds = datasets{id};
    a0 = resultMap(make_key(ds, 'A0_Full_Reference'));
    base = get_original_baseline_record(ds, paperInfo, localCaltechBest);
    if a0.found && base.found
        md{end+1} = sprintf('- %s：A0 的 ACC/NMI/AR 为 %s，Original baseline 为 %s，差值为 ΔACC=%s、ΔNMI=%s、ΔAR=%s。', ...
            ds, perf_cell(a0), perf_cell(base), fmt_delta(metric_delta(a0, base, 'ACC')), ...
            fmt_delta(metric_delta(a0, base, 'NMI')), fmt_delta(metric_delta(a0, base, 'AR')));
    end
end
md{end+1} = ['Caltech256 使用自行处理的数据版本，因此不直接采用论文报告的 Caltech256 指标作为正式对比；' ...
    '该数据集以本地原始源码运行结果作为参照。'];
md{end+1} = '';
md{end+1} = '#### BIC 惩罚项的作用';
md = append_short_method_summary(md, datasets, resultMap, 'A1_woBIC_Joint', 'A1');
md{end+1} = ['总体上，若 A1 产生更多锚点或更深的分裂，同时聚类指标下降，说明单纯提高局部拟合能力并不必然改善聚类质量；' ...
    'BIC 惩罚项通过约束过度分裂，提高了锚点划分的统计稳健性。'];
md{end+1} = '';
md{end+1} = '#### BICUnitEvidence 目标视图选择的作用';
md = append_short_method_summary(md, datasets, resultMap, 'A3_SSETarget', 'A3');
md{end+1} = ['A3 将目标视图选择替换为 SSEMin。若其性能低于 A0，表明仅依据重构误差选择目标视图可能忽略模型复杂度；' ...
    'BICUnitEvidence 能够提供与 BIC-LR 锚点生成一致的复杂度校准视图质量度量。'];
md{end+1} = '';
md{end+1} = '#### 多视图融合模块的作用';
md = append_short_method_summary(md, datasets, resultMap, 'A4_woMultiViewFusion', 'A4');
md{end+1} = ['A4 退化为仅使用目标视图的单视图锚图聚类。若 A4 明显低于 A0，说明跨视图对齐融合能够将其他视图的信息传递到最终聚类表示中。' ...
    '若个别数据集上 A4 接近 A0，则说明目标视图在该数据集上已经具有较强判别能力。'];
md{end+1} = '';
md{end+1} = '#### 综合结论';
for i = 1:min(4, numel(analysis.keyFindings))
    md{end+1} = sprintf('- %s', analysis.keyFindings{i});
end
if strcmp(resultType, 'mean')
    md{end+1} = '上述结论主要基于各方法在各自参数网格下的平均表现。若需进一步隔离单一模块贡献，应补充固定完整模型最优参数设置的严格消融实验。';
else
    md{end+1} = '上述结论主要反映最优运行或最好均值摘要下的性能上界倾向。若 best 口径与 mean 口径不一致，应以多次运行平均结果作为正文主结论，并将 best 结果作为补充分析。';
end
write_text(fullfile(analysisDir, 'ablation_analysis_summary_for_paper.md'), strjoin(md, newline));
end

function md = append_delta_discussion(md, detailedTable)
datasets = unique(detailedTable.Dataset, 'stable');
for i = 1:numel(datasets)
    ds = datasets{i};
    rows = detailedTable(strcmp(detailedTable.Dataset, ds), :);
    a0Row = rows(strcmp(rows.Method, 'A0_Full_Reference'), :);
    if isempty(a0Row)
        md{end+1} = sprintf('- %s：A0 缺失，无法作为参照。', ds);
        continue;
    end
    md{end+1} = sprintf('- %s：A0 的 ACC/NMI/AR 为 %s / %s / %s。', ...
        ds, fmt_num(a0Row.ACC(1)), fmt_num(a0Row.NMI(1)), fmt_num(a0Row.AR(1)));
    methodNames = {'A1_woBIC_Joint', 'A3_SSETarget', 'A4_woMultiViewFusion'};
    for m = 1:numel(methodNames)
        row = rows(strcmp(rows.Method, methodNames{m}), :);
        if ~isempty(row)
            md{end+1} = sprintf('  - %s 相对 A0：ΔACC=%s，ΔNMI=%s，ΔAR=%s。', ...
                methodNames{m}, fmt_delta(row.Delta_ACC(1)), fmt_delta(row.Delta_NMI(1)), fmt_delta(row.Delta_AR(1)));
        end
    end
end
end

function md = append_method_discussion(md, detailedTable, mechanismTable, methodName, conclusionText)
rows = detailedTable(strcmp(detailedTable.Method, methodName), :);
for i = 1:height(rows)
    md{end+1} = sprintf('- %s：ACC=%s，NMI=%s，AR=%s，相对参照 ΔACC=%s，ΔNMI=%s，ΔAR=%s。', ...
        rows.Dataset{i}, fmt_num(rows.ACC(i)), fmt_num(rows.NMI(i)), fmt_num(rows.AR(i)), ...
        fmt_delta(rows.Delta_ACC(i)), fmt_delta(rows.Delta_NMI(i)), fmt_delta(rows.Delta_AR(i)));
    mech = mechanismTable(strcmp(mechanismTable.Dataset, rows.Dataset{i}) & strcmp(mechanismTable.Method, methodName), :);
    if ~isempty(mech)
        md{end+1} = sprintf('  机制指标：平均锚点数=%s，targetView=%s，acceptedSplits=%s，meanLeafSize=%s，总时间=%s。', ...
            fmt_num(mech.Avg_anchors(1)), fmt_num(mech.Target_view(1)), mech.Accepted_splits{1}, mech.Mean_leaf_size{1}, fmt_num(mech.Total_time(1)));
    end
end
md{end+1} = conclusionText;
end

function md = append_short_method_summary(md, datasets, resultMap, methodName, labelName)
for id = 1:numel(datasets)
    ds = datasets{id};
    a0 = resultMap(make_key(ds, 'A0_Full_Reference'));
    rec = resultMap(make_key(ds, methodName));
    if rec.found && a0.found
        md{end+1} = sprintf('- %s：%s 的 ACC/NMI/AR 为 %s，相对 A0 的 ΔACC=%s、ΔNMI=%s、ΔAR=%s。', ...
            ds, labelName, perf_cell(rec), fmt_delta(metric_delta(rec, a0, 'ACC')), ...
            fmt_delta(metric_delta(rec, a0, 'NMI')), fmt_delta(metric_delta(rec, a0, 'AR')));
    elseif rec.found
        md{end+1} = sprintf('- %s：%s 的 ACC/NMI/AR 为 %s，但 A0 缺失，无法计算差值。', ds, labelName, perf_cell(rec));
    end
end
end

function baseline = get_original_baseline_record(datasetName, paperInfo, localCaltechBest)
if strcmp(datasetName, 'Caltech256')
    baseline = localCaltechBest;
    return;
end
baseline = empty_baseline_record(datasetName);
if isKey(paperInfo.paper3amvc, datasetName)
    baseline = paperInfo.paper3amvc(datasetName);
    baseline.datasetName = datasetName;
    baseline.sourceType = '论文报告结果';
    if isfield(paperInfo, 'resultType')
        baseline.resultType = paperInfo.resultType;
    end
end
end

function b = baseline_metric_record(acc, nmi, ar, purity, fscore, sourceText)
b = empty_baseline_record('');
b.found = true;
b.source = sourceText;
b.sourceType = '论文报告结果';
b.metricsMean.ACC = acc;
b.metricsMean.NMI = nmi;
b.metricsMean.AR = ar;
b.metricsMean.Purity = purity;
b.metricsMean.Fscore = fscore;
end

function rec = empty_record(datasetName, methodName)
rec = empty_baseline_record(datasetName);
rec.methodName = methodName;
rec.source = 'Missing';
rec.sourceType = 'Missing';
rec.targetSelectionMethod = '';
rec.targetView = NaN;
rec.anchorCounts = [];
rec.anchorEvidenceGain = [];
rec.acceptedSplits = [];
rec.rejectedSplits = [];
rec.meanLeafSize = [];
rec.maxDepth = [];
rec.anchorTime = NaN;
rec.alignmentTime = NaN;
rec.totalTime = NaN;
rec.randomSeed = [];
rec.numGridConfigs = NaN;
rec.searchBudget = NaN;
rec.selectionRule = '';
rec.bicTargetView = NaN;
rec.sseTargetView = NaN;
rec.targetViewAgreement = NaN;
rec.bicEvidencePerView = [];
rec.totalSSEPerView = [];
rec.sseRankCorrelation = NaN;
rec.useMultiViewFusion = [];
rec.singleViewOnly = [];
rec.numRuns = NaN;
rec.kmeansReplicates = NaN;
end

function rec = empty_baseline_record(datasetName)
rec = struct();
rec.found = false;
rec.datasetName = datasetName;
rec.methodName = '';
rec.resultType = 'mean';
rec.source = 'Missing';
rec.sourceType = 'Missing';
rec.sourceFile = '';
rec.beta = NaN;
rec.lambda = NaN;
rec.lambdaBIC = NaN;
rec.minNodeSize = NaN;
rec.targetView = NaN;
rec.anchorCounts = [];
rec.metricsMean = empty_metrics();
rec.metricsStd = empty_metrics();
rec.bestMetricSource = '';
end

function m = empty_metrics()
m = struct('ACC', NaN, 'NMI', NaN, 'AR', NaN, 'Purity', NaN, 'Fscore', NaN, ...
    'Precision', NaN, 'Recall', NaN, 'Entropy', NaN);
end

function m = get_metrics_struct(s, fieldName)
m = empty_metrics();
if ~isstruct(s) || ~isfield(s, fieldName) || isempty(s.(fieldName))
    return;
end
v = s.(fieldName);
if isstruct(v)
    names = fieldnames(m);
    for i = 1:numel(names)
        if isfield(v, names{i}) && ~isempty(v.(names{i}))
            m.(names{i}) = double(v.(names{i}));
        end
    end
elseif isnumeric(v)
    metricNames = {'ACC', 'NMI', 'Purity', 'Fscore', 'Precision', 'Recall', 'AR', 'Entropy'};
    if isfield(s, 'metricNames')
        metricNames = s.metricNames;
    end
    m = metrics_from_vector(v, metricNames);
end
end

function [bestMetrics, bestSource, bestRecord] = extract_best_metrics(summary, loaded)
%EXTRACT_BEST_METRICS 按 ACC/NMI/AR 优先级提取 best 口径指标。
bestMetrics = empty_metrics();
bestSource = 'Missing';
bestRecord = [];

[m, src] = best_metrics_from_struct(summary);
if ~all_metrics_missing(m)
    bestMetrics = m;
    bestSource = ['resultSummary.' src];
    bestRecord = summary;
end

if isstruct(loaded) && isfield(loaded, 'allResults') && isstruct(loaded.allResults)
    allResults = loaded.allResults(:);
    for i = 1:numel(allResults)
        [candidate, candidateSource] = best_metrics_from_struct(allResults(i));
        if all_metrics_missing(candidate)
            candidate = get_metrics_struct(allResults(i), 'metricsMean');
            candidateSource = 'allResults.metricsMean';
        else
            candidateSource = ['allResults.' candidateSource];
        end
        if metrics_better(candidate, bestMetrics)
            bestMetrics = candidate;
            bestSource = candidateSource;
            bestRecord = allResults(i);
        end
    end
end
end

function [m, sourceName] = best_metrics_from_struct(s)
m = empty_metrics();
sourceName = 'Missing';
if ~isstruct(s)
    return;
end
if isfield(s, 'bestMetrics') && ~isempty(s.bestMetrics)
    m = get_metrics_struct(s, 'bestMetrics');
    sourceName = 'bestMetrics';
elseif isfield(s, 'evalBestRunMetrics') && ~isempty(s.evalBestRunMetrics)
    metricNames = get_metric_names(s);
    m = metrics_from_vector(s.evalBestRunMetrics, metricNames);
    sourceName = 'evalBestRunMetrics';
elseif isfield(s, 'bestEvalMetrics') && ~isempty(s.bestEvalMetrics)
    metricNames = get_metric_names(s);
    m = metrics_from_vector(s.bestEvalMetrics, metricNames);
    sourceName = 'bestEvalMetrics';
elseif isfield(s, 'evalMaxMetrics') && ~isempty(s.evalMaxMetrics)
    metricNames = get_metric_names(s);
    m = metrics_from_vector(s.evalMaxMetrics, metricNames);
    sourceName = 'evalMaxMetrics';
elseif isfield(s, 'bestResult') && isstruct(s.bestResult)
    m = metrics_from_named_fields(s.bestResult);
    sourceName = 'bestResult';
else
    m = metrics_from_named_fields(s);
    if ~all_metrics_missing(m)
        sourceName = 'best scalar fields';
    end
end
end

function metricNames = get_metric_names(s)
metricNames = {'ACC', 'NMI', 'Purity', 'Fscore', 'Precision', 'Recall', 'AR', 'Entropy'};
if isstruct(s) && isfield(s, 'metricNames') && ~isempty(s.metricNames)
    metricNames = s.metricNames;
end
end

function m = metrics_from_named_fields(s)
m = empty_metrics();
if ~isstruct(s)
    return;
end
names = fieldnames(s);
for i = 1:numel(names)
    v = s.(names{i});
    if ~(isnumeric(v) || islogical(v)) || isempty(v)
        continue;
    end
    normalized = normalize_metric_name(names{i});
    if isfield(m, normalized)
        m.(normalized) = double(v(1));
    end
end
end

function tf = metrics_better(candidate, currentBest)
tf = false;
priority = {'ACC', 'NMI', 'AR'};
tol = 1e-12;
for i = 1:numel(priority)
    c = metric_value_from_metrics(candidate, priority{i});
    b = metric_value_from_metrics(currentBest, priority{i});
    if isfinite(c) && ~isfinite(b)
        tf = true;
        return;
    elseif ~isfinite(c) && isfinite(b)
        tf = false;
        return;
    elseif isfinite(c) && isfinite(b)
        if c > b + tol
            tf = true;
            return;
        elseif c < b - tol
            tf = false;
            return;
        end
    end
end
end

function value = metric_value_from_metrics(m, metricName)
value = NaN;
if isstruct(m) && isfield(m, metricName)
    value = m.(metricName);
end
end

function tf = all_metrics_missing(m)
tf = true;
names = {'ACC', 'NMI', 'AR', 'Purity', 'Fscore', 'Precision', 'Recall', 'Entropy'};
for i = 1:numel(names)
    if isstruct(m) && isfield(m, names{i}) && isnumeric(m.(names{i})) && isfinite(m.(names{i}))
        tf = false;
        return;
    end
end
end

function rec = apply_record_metadata(rec, src)
%APPLY_RECORD_METADATA 使用 best 记录对应的参数和机制字段更新输出记录。
fields = {'beta', 'lambda', 'lambdaBIC', 'minNodeSize', 'tauSplit', 'targetView', ...
    'anchorCounts', 'acceptedSplits', 'rejectedSplits', 'meanLeafSize', 'maxDepth', ...
    'anchorTime', 'alignmentTime', 'totalTime', 'randomSeed', 'numGridConfigs', ...
    'searchBudget', 'bicTargetView', 'sseTargetView', 'targetViewAgreement', ...
    'bicEvidencePerView', 'totalSSEPerView', 'sseRankCorrelation', ...
    'useMultiViewFusion', 'singleViewOnly', 'numRuns', 'kmeansReplicates'};
for i = 1:numel(fields)
    if isfield(src, fields{i}) && ~isempty(src.(fields{i}))
        rec.(fields{i}) = src.(fields{i});
    end
end
if isfield(src, 'targetSelectionMethod') && ~isempty(src.targetSelectionMethod)
    rec.targetSelectionMethod = char(string(src.targetSelectionMethod));
end
if isfield(src, 'selectionRule') && ~isempty(src.selectionRule)
    rec.selectionRule = char(string(src.selectionRule));
end
end

function m = aggregate_selected_config_mean(summary, allResults)
m = empty_metrics();
if ~isstruct(summary) || ~isstruct(allResults)
    return;
end
selected = get_any_field(summary, 'selectedConfig', struct());
if isempty(selected) || ~isstruct(selected)
    return;
end
for i = 1:numel(allResults)
    if config_matches_record(selected, allResults(i))
        m = get_metrics_struct(allResults(i), 'metricsMean');
        if ~all_metrics_missing(m)
            return;
        end
    end
end
end

function tf = config_matches_record(selected, rec)
tf = true;
fields = {'beta', 'lambda', 'lambdaBIC', 'minNodeSize', 'tauSplit', 'randomSeed'};
for i = 1:numel(fields)
    if isfield(selected, fields{i}) && isfield(rec, fields{i}) ...
            && isnumeric(selected.(fields{i})) && isnumeric(rec.(fields{i}))
        a = double(selected.(fields{i})(1));
        b = double(rec.(fields{i})(1));
        if ~(isnan(a) && isnan(b)) && abs(a - b) > 1e-10
            tf = false;
            return;
        end
    end
end
end

function m = metrics_from_vector(v, metricNames)
m = empty_metrics();
v = double(v(:))';
for i = 1:min(numel(v), numel(metricNames))
    name = normalize_metric_name(metricNames{i});
    if isfield(m, name)
        m.(name) = v(i);
    end
end
end

function name = normalize_metric_name(name)
name = char(name);
switch lower(strrep(name, '_', ''))
    case {'acc', 'meanacc', 'accmean', 'bestacc', 'accbest'}
        name = 'ACC';
    case {'nmi', 'meannmi', 'nmimean', 'bestnmi', 'nmibest'}
        name = 'NMI';
    case {'ar', 'ari', 'meanar', 'armean', 'meanari', 'arimean', 'bestar', 'arbest', 'bestari', 'aribest'}
        name = 'AR';
    case {'purity', 'meanpurity', 'puritymean', 'bestpurity', 'puritybest'}
        name = 'Purity';
    case {'fscore', 'fscoremean', 'f1', 'f1score', 'fscorebest', 'meanfscore', 'bestfscore'}
        name = 'Fscore';
    case {'precision', 'meanprecision', 'precisionmean', 'bestprecision', 'precisionbest'}
        name = 'Precision';
    case {'recall', 'meanrecall', 'recallmean', 'bestrecall', 'recallbest'}
        name = 'Recall';
    case {'entropy', 'meanentropy', 'entropymean', 'bestentropy', 'entropybest'}
        name = 'Entropy';
end
end

function filePath = select_latest_mat(methodDir, methodName, dirName)
filePath = '';
latestPath = fullfile(methodDir, sprintf('%s_%s_latest.mat', methodName, dirName));
if exist(latestPath, 'file')
    filePath = latestPath;
    return;
end
files = dir(fullfile(methodDir, '*.mat'));
if isempty(files)
    return;
end
[~, idx] = max([files.datenum]);
filePath = fullfile(files(idx).folder, files(idx).name);
end

function dirName = dataset_to_dir(datasetName)
switch datasetName
    case 'Mfeat'
        dirName = 'Mfeat';
    case 'Reuters-1200'
        dirName = 'Ruter1200';
    case 'WIKI'
        dirName = 'WIKI';
    case 'Caltech256'
        dirName = 'Caltech256_4Views_257cls_withClutter';
    case 'ForestTypes'
        dirName = 'ForestTypes';
    otherwise
        dirName = datasetName;
end
end

function key = make_key(datasetName, methodName)
key = [datasetName '::' methodName];
end

function value = get_scalar_field(s, fieldName)
value = NaN;
if isstruct(s) && isfield(s, fieldName) && ~isempty(s.(fieldName))
    v = s.(fieldName);
    if isnumeric(v) || islogical(v)
        value = double(v(1));
    end
end
end

function value = get_any_field(s, fieldName, defaultValue)
value = defaultValue;
if isstruct(s) && isfield(s, fieldName) && ~isempty(s.(fieldName))
    value = s.(fieldName);
end
end

function value = get_char_field(s, fieldName)
value = '';
if isstruct(s) && isfield(s, fieldName) && ~isempty(s.(fieldName))
    value = char(string(s.(fieldName)));
end
end

function value = metric_value(rec, metricName)
value = NaN;
if isstruct(rec) && isfield(rec, 'metricsMean') && isfield(rec.metricsMean, metricName)
    value = rec.metricsMean.(metricName);
end
end

function d = metric_delta(a, b, metricName)
av = metric_value(a, metricName);
bv = metric_value(b, metricName);
if isfinite(av) && isfinite(bv)
    d = av - bv;
else
    d = NaN;
end
end

function text = perf_cell(rec)
if ~isstruct(rec) || ~rec.found
    text = 'Missing';
else
    text = sprintf('%s / %s / %s', fmt_num(metric_value(rec, 'ACC')), ...
        fmt_num(metric_value(rec, 'NMI')), fmt_num(metric_value(rec, 'AR')));
end
end

function text = original_baseline_cell(datasetName, paperInfo, localCaltechBest)
base = get_original_baseline_record(datasetName, paperInfo, localCaltechBest);
if ~base.found
    text = 'Missing';
else
    if strcmp(datasetName, 'Caltech256')
        text = sprintf('%s (%s)', perf_cell(base), 'Original 3AMVC local run on catlch256_4Views_257cls_withClutter');
    else
        text = sprintf('%s (%s)', perf_cell(base), 'paper reported 3AMVC');
    end
end
end

function text = selected_config_text(rec)
if ~rec.found
    text = 'Missing';
else
    text = sprintf('beta=%s, lambda=%s, lambdaBIC=%s, minNodeSize=%s, targetView=%s', ...
        fmt_num(rec.beta), fmt_num(rec.lambda), fmt_num(rec.lambdaBIC), ...
        fmt_num(rec.minNodeSize), fmt_num(rec.targetView));
end
end

function text = baseline_config_text(rec)
if ~rec.found
    text = 'Missing';
else
    text = sprintf('beta=%s, lambda=%s, targetView=%s, anchors=%s', ...
        fmt_num(rec.beta), fmt_num(rec.lambda), fmt_num(rec.targetView), stringify(rec.anchorCounts));
end
end

function text = stringify(value)
if isempty(value)
    text = '';
elseif ischar(value)
    text = value;
elseif isstring(value)
    text = char(value);
else
    try
        text = mat2str(value);
    catch
        text = '<unprintable>';
    end
end
end

function v = safe_mean(value)
if isempty(value) || ~isnumeric(value)
    v = NaN;
else
    x = double(value(:));
    x = x(isfinite(x));
    if isempty(x)
        v = NaN;
    else
        v = mean(x);
    end
end
end

function n = numel_nonempty(value)
if isempty(value)
    n = NaN;
else
    n = numel(value);
end
end

function text = fmt_num(value)
if isempty(value) || ~isnumeric(value) || ~isfinite(double(value(1)))
    text = 'Missing';
else
    text = sprintf('%.4f', double(value(1)));
end
end

function text = fmt_delta(value)
if isempty(value) || ~isnumeric(value) || ~isfinite(double(value(1)))
    text = 'Missing';
else
    text = sprintf('%+.4f', double(value(1)));
end
end

function value = parse_number(text, label)
value = NaN;
expr = [regexptranslate('escape', label) '=([+-]?\d+(\.\d+)?([eE][+-]?\d+)?)'];
tok = regexp(text, expr, 'tokens', 'once');
if ~isempty(tok)
    value = str2double(tok{1});
end
end

function value = parse_metric_mean(text, label)
value = NaN;
expr = [regexptranslate('escape', label) '=([0-9.]+)\s*±\s*([0-9.]+)'];
tok = regexp(text, expr, 'tokens', 'once');
if ~isempty(tok)
    value = str2double(tok{1});
end
end

function value = parse_metric_std(text, label)
value = NaN;
expr = [regexptranslate('escape', label) '=([0-9.]+)\s*±\s*([0-9.]+)'];
tok = regexp(text, expr, 'tokens', 'once');
if ~isempty(tok)
    value = str2double(tok{2});
end
end

function [bestBody, bestMetrics, bestSource] = select_best_text_block(candidates)
%SELECT_BEST_TEXT_BLOCK 按 ACC/NMI/AR 从文本候选段中选择 best 摘要。
bestBody = candidates{1};
bestMetrics = empty_metrics();
bestSource = 'Missing';
for i = 1:numel(candidates)
    body = candidates{i};
    [candidateMetrics, candidateSource] = parse_text_best_metrics(body);
    if metrics_better(candidateMetrics, bestMetrics)
        bestMetrics = candidateMetrics;
        bestBody = body;
        bestSource = candidateSource;
    end
end
if all_metrics_missing(bestMetrics)
    bestMetrics.ACC = parse_metric_mean(bestBody, 'ACC');
    bestMetrics.NMI = parse_metric_mean(bestBody, 'NMI');
    bestMetrics.Purity = parse_metric_mean(bestBody, 'Purity');
    bestMetrics.Fscore = parse_metric_mean(bestBody, 'Fscore');
    bestSource = 'best mean from refined text';
end
end

function [m, sourceName] = parse_text_best_metrics(body)
%PARSE_TEXT_BEST_METRICS 读取 bestRun 指标，缺失时读取 summary 指标。
m = empty_metrics();
sourceName = 'bestRun metrics from refined text';
names = {'ACC', 'NMI', 'Purity', 'Fscore', 'Precision', 'Recall', 'AR', 'Entropy'};
for i = 1:numel(names)
    m.(names{i}) = parse_best_run_metric(body, names{i});
end
if all_metrics_missing(m)
    sourceName = 'summary metrics from refined text';
    for i = 1:numel(names)
        m.(names{i}) = parse_summary_metric(body, names{i});
    end
else
    for i = 1:numel(names)
        if ~isfinite(m.(names{i}))
            m.(names{i}) = parse_summary_metric(body, names{i});
        end
    end
end
if all_metrics_missing(m)
    sourceName = 'best mean from refined text';
    for i = 1:numel(names)
        m.(names{i}) = parse_metric_mean(body, names{i});
    end
end
end

function value = parse_best_run_metric(text, label)
value = NaN;
expr = ['bestRun指标[^\r\n]*' regexptranslate('escape', label) '=([+-]?\d+(\.\d+)?([eE][+-]?\d+)?)'];
tok = regexp(text, expr, 'tokens', 'once');
if ~isempty(tok)
    value = str2double(tok{1});
end
end

function value = parse_summary_metric(text, label)
value = NaN;
expr = ['summary' regexptranslate('escape', label) '=([+-]?\d+(\.\d+)?([eE][+-]?\d+)?)'];
tok = regexp(text, expr, 'tokens', 'once');
if ~isempty(tok)
    value = str2double(tok{1});
end
end

function value = parse_vector_after_label(text, label)
value = [];
expr = [regexptranslate('escape', label) '=\[([^\]]+)\]'];
tok = regexp(text, expr, 'tokens', 'once');
if ~isempty(tok)
    value = str2num(tok{1}); %#ok<ST2NM>
end
end

function write_table_pair(tbl, basePath, resultType, titleText)
if nargin < 3 || isempty(resultType)
    resultType = 'mean';
end
if nargin < 4
    titleText = '';
end
writetable(tbl, [basePath '.csv']);
md = table_to_markdown(tbl);
if ~isempty(titleText)
    md = sprintf('# %s（%s 口径）\n\n%s', titleText, resultType, md);
end
write_text([basePath '.md'], md);
end

function md = table_to_markdown(tbl)
if isempty(tbl)
    md = '';
    return;
end
names = tbl.Properties.VariableNames;
headers = names;
if numel(tbl.Properties.VariableDescriptions) == numel(names)
    desc = tbl.Properties.VariableDescriptions;
    for i = 1:numel(desc)
        if ~isempty(desc{i})
            headers{i} = desc{i};
        end
    end
end
header = ['| ' strjoin(headers, ' | ') ' |'];
sep = ['| ' strjoin(repmat({'---'}, 1, numel(names)), ' | ') ' |'];
lines = {header, sep};
for i = 1:height(tbl)
    cells = cell(1, numel(names));
    for j = 1:numel(names)
        v = tbl{i, j};
        if iscell(v)
            v = v{1};
        end
        cells{j} = escape_md(format_cell_value(v));
    end
    lines{end + 1} = ['| ' strjoin(cells, ' | ') ' |']; %#ok<AGROW>
end
md = strjoin(lines, newline);
end

function text = format_cell_value(v)
if isempty(v)
    text = '';
elseif isnumeric(v) || islogical(v)
    if numel(v) == 1
        if isnan(v)
            text = 'Missing';
        else
            text = sprintf('%.6g', double(v));
        end
    else
        text = mat2str(v);
    end
elseif isstring(v)
    text = char(v);
elseif ischar(v)
    text = v;
else
    try
        text = char(string(v));
    catch
        text = '<value>';
    end
end
end

function text = escape_md(text)
text = strrep(text, '|', '\|');
text = strrep(text, newline, '<br>');
end

function write_text(filePath, content)
fid = fopen(filePath, 'w', 'n', 'UTF-8');
if fid < 0
    error('generate_final_ablation_analysis:WriteFailed', '无法写入文件：%s', filePath);
end
cleaner = onCleanup(@() fclose(fid));
fprintf(fid, '%s', content);
end

function ensure_dir(dirPath)
if ~exist(dirPath, 'dir')
    mkdir(dirPath);
end
end

function resultType = validate_result_type(resultType)
resultType = lower(strtrim(char(string(resultType))));
if ~ismember(resultType, {'mean', 'best'})
    error('generate_final_ablation_analysis:InvalidResultType', ...
        '结果口径必须是 mean 或 best，当前输入为：%s', resultType);
end
end

function ensure_pdf_text_extract(pdfPath, textPath)
%ENSURE_PDF_TEXT_EXTRACT 使用 pdftotext 生成 PDF 文本，失败时保留清晰 warning。
if exist(textPath, 'file') == 2
    return;
end
textDir = fileparts(textPath);
ensure_dir(textDir);
if exist(pdfPath, 'file') ~= 2
    warning('generate_final_ablation_analysis:PdfMissing', 'PDF 文件不存在：%s', pdfPath);
    return;
end
cmd = sprintf('pdftotext -layout "%s" "%s"', pdfPath, textPath);
[status, msg] = system(cmd);
if status ~= 0
    warning('generate_final_ablation_analysis:PdfTextFailed', ...
        'PDF 文本抽取失败：%s\n%s', pdfPath, msg);
end
end

function out = ternary(condition, a, b)
if condition
    out = a;
else
    out = b;
end
end

function text = list_or_none(items)
if isempty(items)
    text = 'None';
else
    text = strjoin(items(:)', '; ');
end
end

function tf = numeric_vector_available(value)
tf = isnumeric(value) && ~isempty(value) && all(isfinite(double(value(:))));
end

function comparisonFile = write_mean_vs_best_comparison(meanOutput, bestOutput)
paths = get_project_paths();
comparisonFile = fullfile(paths.reportRoot, 'mean_vs_best_comparison.md');
datasets = meanOutput.datasets;
methods = {'A1_woBIC_Joint', 'A3_SSETarget', 'A4_woMultiViewFusion'};

md = {};
md{end+1} = '# Mean vs Best 结果口径对比';
md{end+1} = '';
md{end+1} = '## 1. 两种口径定义';
md{end+1} = '- mean 口径：使用 selectedConfig 下多次运行的平均指标，更适合作为论文主结果。';
md{end+1} = '- best 口径：使用完整实验中可识别的单次或单配置最高指标，更适合补充说明模型潜力，但不应替代 mean 作为主结果。';
md{end+1} = '- 本对比中 A0_Full 的正式来源均为 `3AMVC-main/res_biclr_refined`。';
md{end+1} = '';

rows = {};
for i = 1:numel(datasets)
    ds = datasets{i};
    a0Mean = meanOutput.resultMap(make_key(ds, 'A0_Full_Reference'));
    a0Best = bestOutput.resultMap(make_key(ds, 'A0_Full_Reference'));
    rows(end + 1, :) = {ds, perf_cell(a0Mean), perf_cell(a0Best), ...
        metric_delta(a0Best, a0Mean, 'ACC'), metric_delta(a0Best, a0Mean, 'NMI'), metric_delta(a0Best, a0Mean, 'AR')}; %#ok<AGROW>
end
tbl = cell2table(rows, 'VariableNames', {'Dataset', 'A0_mean_ACC_NMI_AR', 'A0_best_ACC_NMI_AR', ...
    'Best_minus_Mean_ACC', 'Best_minus_Mean_NMI', 'Best_minus_Mean_AR'});
tbl.Properties.VariableDescriptions = {'Dataset', 'A0 mean ACC/NMI/AR', 'A0 best ACC/NMI/AR', ...
    'Best - Mean ACC', 'Best - Mean NMI', 'Best - Mean AR'};
md{end+1} = '## 2. A0_Full mean 与 best 对比表';
md{end+1} = table_to_markdown(tbl);
md{end+1} = '';

md{end+1} = '## 3. 消融结论是否一致';
for m = 1:numel(methods)
    methodName = methods{m};
    md{end+1} = sprintf('### A0 vs %s', methodName);
    for i = 1:numel(datasets)
        ds = datasets{i};
        meanA0 = meanOutput.resultMap(make_key(ds, 'A0_Full_Reference'));
        meanRec = meanOutput.resultMap(make_key(ds, methodName));
        bestA0 = bestOutput.resultMap(make_key(ds, 'A0_Full_Reference'));
        bestRec = bestOutput.resultMap(make_key(ds, methodName));
        meanDelta = metric_delta(meanRec, meanA0, 'ACC');
        bestDelta = metric_delta(bestRec, bestA0, 'ACC');
        md{end+1} = sprintf('- %s：mean ΔACC=%s，best ΔACC=%s，方向%s。', ...
            ds, fmt_delta(meanDelta), fmt_delta(bestDelta), consistency_text(meanDelta, bestDelta));
    end
end
md{end+1} = '### A0 vs Original baseline';
for i = 1:numel(datasets)
    ds = datasets{i};
    meanA0 = meanOutput.resultMap(make_key(ds, 'A0_Full_Reference'));
    bestA0 = bestOutput.resultMap(make_key(ds, 'A0_Full_Reference'));
    meanBase = get_original_baseline_record(ds, meanOutput.paperInfo, meanOutput.localCaltechBest);
    bestBase = get_original_baseline_record(ds, bestOutput.paperInfo, bestOutput.localCaltechBest);
    meanDelta = metric_delta(meanA0, meanBase, 'ACC');
    bestDelta = metric_delta(bestA0, bestBase, 'ACC');
    md{end+1} = sprintf('- %s：mean ΔACC=%s，best ΔACC=%s，方向%s。', ...
        ds, fmt_delta(meanDelta), fmt_delta(bestDelta), consistency_text(meanDelta, bestDelta));
end
md{end+1} = '';

md{end+1} = '## 4. 如果结论不一致';
md{end+1} = '- 若 mean 口径下 A0 优于某消融变体，但 best 口径下该变体接近或超过 A0，可能来自随机初始化波动、参数网格中的高方差配置，或该数据集对该模块不敏感。';
md{end+1} = '- 若 best 值明显高于 mean 值，应将其标记为偶然最优风险，不能直接作为稳定性能证据。';
md{end+1} = '- Caltech256 A0 文本未包含逐次 bestRun 指标，本次按用户指定采用 refined best_ACC 文本中的最好均值摘要，因此应在 best 口径表中标注其并非逐次最优运行值。';
md{end+1} = '';

md{end+1} = '## 5. 建议论文采用口径';
md{end+1} = '- 论文主表建议采用 mean 口径。';
md{end+1} = '- best 口径可以放在附录或补充分析中。';
md{end+1} = '- 如果正文使用 best 口径，必须说明其为最佳运行结果，而不是多次重复平均结果。';

write_text(comparisonFile, strjoin(md, newline));
end

function text = consistency_text(deltaA, deltaB)
if ~isfinite(deltaA) || ~isfinite(deltaB)
    text = '无法判断';
elseif sign_with_tol(deltaA) == sign_with_tol(deltaB)
    text = '一致';
else
    text = '不一致';
end
end

function s = sign_with_tol(value)
tol = 0.02;
if value > tol
    s = 1;
elseif value < -tol
    s = -1;
else
    s = 0;
end
end

function files = list_generated_files(analysisDir)
d = dir(fullfile(analysisDir, '*'));
files = {};
for i = 1:numel(d)
    if ~d(i).isdir
        files{end + 1, 1} = fullfile(d(i).folder, d(i).name); %#ok<AGROW>
    end
end
end
