function analysis = analyze_biclr_sensitivity(resDir, outputDir)
%ANALYZE_BICLR_SENSITIVITY 分析 BIC-LR 网格搜索结果的超参数敏感度。
%   ANALYSIS = ANALYZE_BICLR_SENSITIVITY() 默认读取当前仓库下 res_biclr
%   目录中的 .mat 结果文件，自动选择每个数据集记录数最多的完整网格结果，
%   并输出原始结果表、边际敏感度表、Top 组合表和中文摘要。
%
%   ANALYSIS = ANALYZE_BICLR_SENSITIVITY(RESDIR) 指定结果目录。
%
%   ANALYSIS = ANALYZE_BICLR_SENSITIVITY(RESDIR, OUTPUTDIR) 指定分析输出目录。
%
%   输入参数：
%   resDir    : 字符串或字符向量，结果目录，目录下需包含 results 结构体的 .mat 文件。
%   outputDir : 字符串或字符向量，分析结果输出目录。
%
%   输出参数：
%   analysis : 结构体，字段包括：
%              - selectedFiles      : 每个数据集选中的完整结果文件
%              - rawTable           : 原始参数组合结果表
%              - marginalTable      : 单参数边际敏感度表
%              - topConfigTable     : 每个数据集 Top 组合表
%              - summaryLines       : 中文摘要文本
%              - outputDir          : 输出目录
%
%   注意事项：
%   1. 若同一数据集存在多个结果文件，本函数优先选记录数最多者；若记录数相同，则选时间较新的文件。
%   2. 本分析以 ACC 为主指标，同时保留 NMI、Purity、Fscore 供交叉参考。

if nargin < 1 || isempty(resDir)
    rootDir = fileparts(fileparts(mfilename('fullpath')));
    resDir = fullfile(rootDir, 'res_biclr');
end
if nargin < 2 || isempty(outputDir)
    outputDir = fullfile(resDir, 'analysis');
end

if isstring(resDir)
    resDir = char(resDir);
end
if isstring(outputDir)
    outputDir = char(outputDir);
end

validateattributes(resDir, {'char'}, {'row', 'nonempty'}, mfilename, 'resDir', 1);
validateattributes(outputDir, {'char'}, {'row', 'nonempty'}, mfilename, 'outputDir', 2);

if ~exist(resDir, 'dir')
    error('analyze_biclr_sensitivity:MissingDir', '结果目录不存在：%s', resDir);
end
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

files = dir(fullfile(resDir, '*.mat'));
if isempty(files)
    error('analyze_biclr_sensitivity:EmptyDir', '目录 %s 下未找到 .mat 结果文件。', resDir);
end

meta = struct('datasetName', {}, 'records', {}, 'dateNum', {}, 'filePath', {}, 'fileName', {}, 'results', {});
for i = 1:numel(files)
    filePath = fullfile(files(i).folder, files(i).name);
    loaded = load(filePath, 'results');
    if ~isfield(loaded, 'results')
        continue;
    end
    meta(end + 1).datasetName = loaded.results.datasetName; %#ok<AGROW>
    meta(end).records = numel(loaded.results.records);
    meta(end).dateNum = files(i).datenum;
    meta(end).filePath = filePath;
    meta(end).fileName = files(i).name;
    meta(end).results = loaded.results;
end

if isempty(meta)
    error('analyze_biclr_sensitivity:NoValidResult', '未找到包含 results 结构体的合法结果文件。');
end

datasetNames = unique(string({meta.datasetName}));
paramNames = {'beta', 'lambda', 'lambdaBIC', 'minNodeSize'};

selectedRows = {};
marginalRows = {};
topRows = {};
summaryLines = {};

for d = 1:numel(datasetNames)
    datasetName = char(datasetNames(d));
    idx = find(strcmp({meta.datasetName}, datasetName));
    ranking = [[meta(idx).records]' [meta(idx).dateNum]'];
    [~, order] = sortrows(ranking, [-1 -2]);
    chosen = meta(idx(order(1)));
    selectedRows(end + 1, :) = {datasetName, chosen.fileName, chosen.records}; %#ok<AGROW>

    records = chosen.results.records;
    numRecords = numel(records);
    acc = arrayfun(@(s) s.metricsMean(1), records);
    nmi = arrayfun(@(s) s.metricsMean(2), records);
    accMean = arrayfun(@(s) get_eval_mean_metric(s, 1), records);
    nmiMean = arrayfun(@(s) get_eval_mean_metric(s, 2), records);
    purityMean = arrayfun(@(s) get_eval_mean_metric(s, 3), records);
    fscoreMean = arrayfun(@(s) get_eval_mean_metric(s, 4), records);
    accStd = arrayfun(@(s) get_eval_std_metric(s, 1), records);
    nmiStd = arrayfun(@(s) get_eval_std_metric(s, 2), records);
    purityStd = arrayfun(@(s) get_eval_std_metric(s, 3), records);
    fscoreStd = arrayfun(@(s) get_eval_std_metric(s, 4), records);
    beta = arrayfun(@(s) s.beta, records);
    lambda = arrayfun(@(s) s.lambda, records);
    lambdaBIC = arrayfun(@(s) s.lambdaBIC, records);
    minNodeSize = arrayfun(@(s) s.minNodeSize, records);
    anchorTotal = arrayfun(@(s) sum(s.anchorCounts), records);
    targetView = arrayfun(@(s) s.targetView, records);
    iter = arrayfun(@(s) s.iter, records);
    algoTime = arrayfun(@(s) s.algoTime, records);
    anchorTime = arrayfun(@(s) s.anchorTime, records);
    totalTime = arrayfun(@(s) s.totalTime, records);

    acc = acc(:);
    nmi = nmi(:);
    accMean = accMean(:);
    nmiMean = nmiMean(:);
    purityMean = purityMean(:);
    fscoreMean = fscoreMean(:);
    accStd = accStd(:);
    nmiStd = nmiStd(:);
    purityStd = purityStd(:);
    fscoreStd = fscoreStd(:);
    accUpper = accMean + accStd;
    beta = beta(:);
    lambda = lambda(:);
    lambdaBIC = lambdaBIC(:);
    minNodeSize = minNodeSize(:);
    anchorTotal = anchorTotal(:);
    targetView = targetView(:);
    iter = iter(:);
    algoTime = algoTime(:);
    anchorTime = anchorTime(:);
    totalTime = totalTime(:);

    rawDatasetTable = table( ...
        repmat(string(datasetName), numRecords, 1), ...
        beta, lambda, lambdaBIC, minNodeSize, ...
        accMean, accStd, nmiMean, nmiStd, purityMean, purityStd, fscoreMean, fscoreStd, acc, ...
        anchorTotal, targetView, iter, algoTime, anchorTime, totalTime, ...
        'VariableNames', {'dataset', 'beta', 'lambda', 'lambdaBIC', 'minNodeSize', ...
        'ACC', 'ACCStd', 'NMI', 'NMIStd', 'Purity', 'PurityStd', 'Fscore', 'FscoreStd', ...
        'summaryACC', 'anchorTotal', 'targetView', 'iter', 'algoTime', 'anchorTime', 'totalTime'});

    rawTablePath = fullfile(outputDir, sprintf('%s_raw_results.csv', sanitize_key(datasetName)));
    writetable(rawDatasetTable, rawTablePath);

    [accSorted, accOrder] = sort(acc, 'descend');
    [~, accUpperOrder] = sort(accUpper, 'descend');
    [~, accMeanOrder] = sort(accMean, 'descend');
    topK = min(5, numel(accOrder));
    for k = 1:topK
        s = records(accOrder(k));
        topRows(end + 1, :) = {datasetName, k, get_eval_mean_metric(s, 1), get_eval_std_metric(s, 1), ...
            get_eval_mean_metric(s, 2), get_eval_std_metric(s, 2), ...
            get_eval_mean_metric(s, 3), get_eval_std_metric(s, 3), ...
            get_eval_mean_metric(s, 4), get_eval_std_metric(s, 4), s.metricsMean(1), ... %#ok<AGROW>
            s.beta, s.lambda, s.lambdaBIC, s.minNodeSize, sum(s.anchorCounts), mat2str(s.anchorCounts')};
    end

    bestAcc = accSorted(1);
    nearOptMask = acc >= 0.95 * bestAcc;
    nearBeta = unique(beta(nearOptMask));
    nearLambda = unique(lambda(nearOptMask));
    nearLambdaBIC = unique(lambdaBIC(nearOptMask));
    nearMinNode = unique(minNodeSize(nearOptMask));

    rangeRows = zeros(numel(paramNames), 1);
    bestLevels = cell(numel(paramNames), 1);
    for p = 1:numel(paramNames)
        values = get_param_vector(records, paramNames{p});
        levels = unique(values);
        meanAccList = zeros(numel(levels), 1);
        stdAccList = zeros(numel(levels), 1);
        maxAccList = zeros(numel(levels), 1);
        meanNmiList = zeros(numel(levels), 1);
        meanAnchorList = zeros(numel(levels), 1);
        minAnchorList = zeros(numel(levels), 1);
        maxAnchorList = zeros(numel(levels), 1);
        nearOptRatioList = zeros(numel(levels), 1);
        for i = 1:numel(levels)
            mask = values == levels(i);
            meanAccList(i) = mean(acc(mask));
            stdAccList(i) = std(acc(mask), 1);
            maxAccList(i) = max(acc(mask));
            meanNmiList(i) = mean(nmi(mask));
            meanAnchorList(i) = mean(anchorTotal(mask));
            minAnchorList(i) = min(anchorTotal(mask));
            maxAnchorList(i) = max(anchorTotal(mask));
            nearOptRatioList(i) = mean(nearOptMask(mask));
            marginalRows(end + 1, :) = {datasetName, paramNames{p}, levels(i), meanAccList(i), stdAccList(i), ... %#ok<AGROW>
                maxAccList(i), meanNmiList(i), meanAnchorList(i), minAnchorList(i), maxAnchorList(i), nearOptRatioList(i)};
        end
        rangeRows(p) = max(meanAccList) - min(meanAccList);
        [~, bestLevelLoc] = max(meanAccList);
        bestLevels{p} = levels(bestLevelLoc);
    end

    [sortedRange, sortedIdx] = sort(rangeRows, 'descend');
    summaryLines{end + 1} = sprintf('数据集 %s：使用文件 %s（%d 组参数）。', datasetName, chosen.fileName, chosen.records); %#ok<AGROW>
    bestUpperRecord = records(accUpperOrder(1));
    summaryLines{end + 1} = sprintf(['按 ACC 均值+标准差最高：ACC=%.4f±%.4f（summaryACC=%.4f），对应 beta=%g, lambda=%g, ' ...
        'lambdaBIC=%g, minNodeSize=%d，总锚点数=%d，NMI=%.4f±%.4f。'], ...
        get_eval_mean_metric(bestUpperRecord, 1), get_eval_std_metric(bestUpperRecord, 1), bestUpperRecord.metricsMean(1), ...
        bestUpperRecord.beta, bestUpperRecord.lambda, bestUpperRecord.lambdaBIC, bestUpperRecord.minNodeSize, ...
        sum(bestUpperRecord.anchorCounts), get_eval_mean_metric(bestUpperRecord, 2), get_eval_std_metric(bestUpperRecord, 2)); %#ok<AGROW>
    bestMeanRecord = records(accMeanOrder(1));
    summaryLines{end + 1} = sprintf(['按重复评价平均 ACC 最高：ACC=%.4f±%.4f（summaryACC=%.4f），对应 beta=%g, lambda=%g, ' ...
        'lambdaBIC=%g, minNodeSize=%d，总锚点数=%d，NMI=%.4f±%.4f。'], ...
        get_eval_mean_metric(bestMeanRecord, 1), get_eval_std_metric(bestMeanRecord, 1), bestMeanRecord.metricsMean(1), ...
        bestMeanRecord.beta, bestMeanRecord.lambda, bestMeanRecord.lambdaBIC, bestMeanRecord.minNodeSize, ...
        sum(bestMeanRecord.anchorCounts), get_eval_mean_metric(bestMeanRecord, 2), get_eval_std_metric(bestMeanRecord, 2)); %#ok<AGROW>
    summaryLines{end + 1} = sprintf(['95%% 最优 ACC 区间内共有 %d/%d 组参数；' ...
        'beta 候选=%s，lambda 候选=%s，lambdaBIC 候选=%s，minNodeSize 候选=%s。'], ...
        sum(nearOptMask), numRecords, mat2str(nearBeta(:)'), mat2str(nearLambda(:)'), ...
        mat2str(nearLambdaBIC(:)'), mat2str(nearMinNode(:)')); %#ok<AGROW>
    summaryLines{end + 1} = sprintf('边际敏感度排序：1) %s(%.4f, 最优=%g) 2) %s(%.4f, 最优=%g) 3) %s(%.4f, 最优=%g) 4) %s(%.4f, 最优=%g)。', ...
        paramNames{sortedIdx(1)}, sortedRange(1), bestLevels{sortedIdx(1)}, ...
        paramNames{sortedIdx(2)}, sortedRange(2), bestLevels{sortedIdx(2)}, ...
        paramNames{sortedIdx(3)}, sortedRange(3), bestLevels{sortedIdx(3)}, ...
        paramNames{sortedIdx(4)}, sortedRange(4), bestLevels{sortedIdx(4)}); %#ok<AGROW>
    summaryLines{end + 1} = ' '; %#ok<AGROW>
end

selectedFilesTable = cell2table(selectedRows, 'VariableNames', {'dataset', 'selectedFile', 'numRecords'});
marginalTable = cell2table(marginalRows, 'VariableNames', {'dataset', 'parameter', 'level', 'meanACC', 'stdACC', ...
    'maxACC', 'meanNMI', 'meanAnchorTotal', 'minAnchorTotal', 'maxAnchorTotal', 'nearOptimalRatio'});
topConfigTable = cell2table(topRows, 'VariableNames', {'dataset', 'rank', 'ACC', 'ACCStd', 'NMI', 'NMIStd', ...
    'Purity', 'PurityStd', 'Fscore', 'FscoreStd', 'summaryACC', ...
    'beta', 'lambda', 'lambdaBIC', 'minNodeSize', 'anchorTotal', 'anchorCountByView'});

rawCombinedTable = collect_all_raw_tables(outputDir);

writetable(selectedFilesTable, fullfile(outputDir, 'selected_complete_results.csv'));
writetable(marginalTable, fullfile(outputDir, 'biclr_marginal_sensitivity.csv'));
writetable(topConfigTable, fullfile(outputDir, 'biclr_top_configs.csv'));
writetable(rawCombinedTable, fullfile(outputDir, 'biclr_all_selected_raw_results.csv'));

summaryPath = fullfile(outputDir, 'biclr_sensitivity_summary.txt');
fid = fopen(summaryPath, 'w');
if fid < 0
    error('analyze_biclr_sensitivity:WriteFailed', '无法写入摘要文件：%s', summaryPath);
end
cleanupObj = onCleanup(@() fclose(fid));
fprintf(fid, 'BIC-LR 超参数敏感度分析摘要\n');
fprintf(fid, '分析时间：%s\n\n', char(datetime('now'))); 
for i = 1:numel(summaryLines)
    fprintf(fid, '%s\n', summaryLines{i});
end

analysis = struct();
analysis.selectedFiles = selectedFilesTable;
analysis.rawTable = rawCombinedTable;
analysis.marginalTable = marginalTable;
analysis.topConfigTable = topConfigTable;
analysis.summaryLines = summaryLines(:);
analysis.outputDir = outputDir;

fprintf('===== BIC-LR 超参数敏感度分析完成 =====\n');
fprintf('输出目录：%s\n', outputDir);
fprintf('原始表：%s\n', fullfile(outputDir, 'biclr_all_selected_raw_results.csv'));
fprintf('边际表：%s\n', fullfile(outputDir, 'biclr_marginal_sensitivity.csv'));
fprintf('Top 表：%s\n', fullfile(outputDir, 'biclr_top_configs.csv'));
fprintf('摘要：%s\n', summaryPath);
end

function values = get_param_vector(records, paramName)
switch paramName
    case 'beta'
        values = arrayfun(@(s) s.beta, records);
    case 'lambda'
        values = arrayfun(@(s) s.lambda, records);
    case 'lambdaBIC'
        values = arrayfun(@(s) s.lambdaBIC, records);
    case 'minNodeSize'
        values = arrayfun(@(s) s.minNodeSize, records);
    otherwise
        error('analyze_biclr_sensitivity:UnknownParam', '未知参数名：%s', paramName);
end
values = values(:);
end

function value = get_eval_mean_metric(record, metricIndex)
if isfield(record, 'evalMeanMetrics') && numel(record.evalMeanMetrics) >= metricIndex
    value = record.evalMeanMetrics(metricIndex);
else
    value = record.metricsMean(metricIndex);
end
end

function value = get_eval_std_metric(record, metricIndex)
if isfield(record, 'evalStdMetrics') && numel(record.evalStdMetrics) >= metricIndex
    value = record.evalStdMetrics(metricIndex);
else
    value = record.metricsStd(metricIndex);
end
end

function key = sanitize_key(textValue)
key = regexprep(char(textValue), '[^a-zA-Z0-9]+', '_');
key = regexprep(key, '_+', '_');
key = regexprep(key, '^_|_$', '');
end

function rawCombinedTable = collect_all_raw_tables(outputDir)
rawFiles = dir(fullfile(outputDir, '*_raw_results.csv'));
rawCombinedTable = table();
for i = 1:numel(rawFiles)
    rawTable = readtable(fullfile(rawFiles(i).folder, rawFiles(i).name));
    rawCombinedTable = [rawCombinedTable; rawTable]; %#ok<AGROW>
end
end
