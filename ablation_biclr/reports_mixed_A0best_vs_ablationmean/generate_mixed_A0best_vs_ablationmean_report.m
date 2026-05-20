function outputs = generate_mixed_A0best_vs_ablationmean_report()
%GENERATE_MIXED_A0BEST_VS_ABLATIONMEAN_REPORT 生成 A0-best vs ablation-mean 混合口径报告。
%   OUTPUTS = GENERATE_MIXED_A0BEST_VS_ABLATIONMEAN_REPORT() 只读取已有
%   A0 refined 结果、已有消融 latest 结果和已生成的 analysis_final 表格，
%   在当前目录输出混合口径报告、论文摘要和 CSV 表格。
%
%   注意事项：
%   本报告用于观察完整模型最优潜力与各消融变体平均表现之间的差异，
%   不是严格同口径、单变量因果消融比较。

thisDir = fileparts(mfilename('fullpath'));
ablationRoot = fileparts(thisDir);
repoRoot = fileparts(ablationRoot);
mainRoot = fullfile(repoRoot, '3AMVC-main');
resRoot = fullfile(ablationRoot, 'res');
reportRoot = fullfile(ablationRoot, 'reports');

datasets = {'Mfeat', 'Reuters-1200', 'WIKI', 'ForestTypes', 'Caltech256'};
methods = {'A0_Full_Reference', 'A1_woBIC_Joint', 'A3_SSETarget', 'A4_woMultiViewFusion'};
ablationMethods = methods(2:end);

bestDetail = readtable(fullfile(reportRoot, 'analysis_final_best', 'detailed_metric_table.csv'), ...
    'TextType', 'string', 'VariableNamingRule', 'preserve');
meanDetail = readtable(fullfile(reportRoot, 'analysis_final_mean', 'detailed_metric_table.csv'), ...
    'TextType', 'string', 'VariableNamingRule', 'preserve');
bestMech = readtable(fullfile(reportRoot, 'analysis_final_best', 'mechanism_table.csv'), ...
    'TextType', 'string', 'VariableNamingRule', 'preserve');
meanMech = readtable(fullfile(reportRoot, 'analysis_final_mean', 'mechanism_table.csv'), ...
    'TextType', 'string', 'VariableNamingRule', 'preserve');
bestBudget = readtable(fullfile(reportRoot, 'analysis_final_best', 'search_budget_table.csv'), ...
    'TextType', 'string', 'VariableNamingRule', 'preserve');
meanBudget = readtable(fullfile(reportRoot, 'analysis_final_mean', 'search_budget_table.csv'), ...
    'TextType', 'string', 'VariableNamingRule', 'preserve');

records = containers.Map();
sourceRows = {};
missingRows = {};
for id = 1:numel(datasets)
    ds = datasets{id};
    a0 = row_to_record(select_row(bestDetail, ds, 'A0_Full_Reference'), ds, 'A0_Full_Reference', 'best');
    a0 = attach_mechanism(a0, select_row(bestMech, ds, 'A0_Full_Reference'));
    a0 = attach_budget(a0, select_row(bestBudget, ds, 'A0_Full_Reference'));
    a0.sourceFile = a0_source_file(ds, mainRoot);
    a0.sourceType = "A0 refined best";
    records(make_key(ds, 'A0_Full_Reference')) = a0;
    sourceRows(end + 1, :) = {ds, 'A0_Full_Reference', a0.sourceFile, exists_text(a0.sourceFile)}; %#ok<AGROW>

    for im = 1:numel(ablationMethods)
        method = ablationMethods{im};
        rec = row_to_record(select_row(meanDetail, ds, method), ds, method, 'mean');
        rec = attach_mechanism(rec, select_row(meanMech, ds, method));
        rec = attach_budget(rec, select_row(meanBudget, ds, method));
        rec.sourceFile = ablation_source_file(ds, method, resRoot);
        rec.sourceType = "ablation latest mean";
        records(make_key(ds, method)) = rec;
        sourceRows(end + 1, :) = {ds, method, rec.sourceFile, exists_text(rec.sourceFile)}; %#ok<AGROW>
        if ~rec.found
            missingRows(end + 1, :) = {ds, method, '未在 analysis_final_mean 中找到记录'}; %#ok<AGROW>
        end
    end
end

mainCells = build_main_cells(datasets, methods, records);
deltaCells = build_delta_cells(datasets, ablationMethods, records);
mechanismCells = build_mechanism_cells(datasets, methods, records);
budgetCells = build_budget_cells(datasets, methods, records);
baselineCells = build_baseline_cells(datasets, records, bestDetail);

write_csv_cell(fullfile(thisDir, 'mixed_A0best_vs_ablationmean_main_table.csv'), mainCells);
write_csv_cell(fullfile(thisDir, 'mixed_A0best_vs_ablationmean_delta_table.csv'), deltaCells);
write_csv_cell(fullfile(thisDir, 'mixed_A0best_vs_ablationmean_mechanism_table.csv'), mechanismCells);

reportText = build_report_text(datasets, methods, ablationMethods, records, sourceRows, ...
    missingRows, mainCells, deltaCells, mechanismCells, budgetCells, baselineCells);
write_text(fullfile(thisDir, 'mixed_A0best_vs_ablationmean_report.md'), reportText);

summaryText = build_paper_summary(datasets, ablationMethods, records);
write_text(fullfile(thisDir, 'mixed_A0best_vs_ablationmean_summary_for_paper.md'), summaryText);

fairnessText = build_fairness_notes(sourceRows);
write_text(fullfile(thisDir, 'mixed_A0best_vs_ablationmean_fairness_notes.md'), fairnessText);

outputs = struct();
outputs.outputDir = thisDir;
outputs.mainTable = mainCells;
outputs.deltaTable = deltaCells;
outputs.mechanismTable = mechanismCells;
outputs.generatedFiles = { ...
    fullfile(thisDir, 'mixed_A0best_vs_ablationmean_report.md'); ...
    fullfile(thisDir, 'mixed_A0best_vs_ablationmean_summary_for_paper.md'); ...
    fullfile(thisDir, 'mixed_A0best_vs_ablationmean_main_table.csv'); ...
    fullfile(thisDir, 'mixed_A0best_vs_ablationmean_delta_table.csv'); ...
    fullfile(thisDir, 'mixed_A0best_vs_ablationmean_mechanism_table.csv'); ...
    fullfile(thisDir, 'mixed_A0best_vs_ablationmean_fairness_notes.md')};
fprintf('混合口径报告已生成到：%s\n', thisDir);
end

function row = select_row(tbl, datasetName, methodName)
mask = strcmp(string(tbl.Dataset), string(datasetName)) & strcmp(string(tbl.Method), string(methodName));
if any(mask)
    row = tbl(find(mask, 1, 'first'), :);
else
    row = table();
end
end

function rec = row_to_record(row, datasetName, methodName, resultType)
rec = empty_record(datasetName, methodName, resultType);
if isempty(row) || height(row) == 0
    return;
end
rec.found = true;
rec.ACC = get_table_number(row, 'ACC');
rec.NMI = get_table_number(row, 'NMI');
rec.AR = get_table_number(row, 'AR');
rec.Purity = get_table_number(row, 'Purity');
rec.Fscore = get_table_number(row, 'Fscore');
rec.beta = get_table_number(row, 'Selected_beta');
rec.lambda = get_table_number(row, 'Selected_lambda');
rec.lambdaBIC = get_table_number(row, 'Selected_lambdaBIC');
rec.minNodeSize = get_table_number(row, 'Selected_minNodeSize');
rec.source = get_table_text(row, 'Source');
end

function rec = empty_record(datasetName, methodName, resultType)
rec = struct();
rec.datasetName = string(datasetName);
rec.methodName = string(methodName);
rec.resultType = string(resultType);
rec.found = false;
rec.ACC = NaN;
rec.NMI = NaN;
rec.AR = NaN;
rec.Purity = NaN;
rec.Fscore = NaN;
rec.beta = NaN;
rec.lambda = NaN;
rec.lambdaBIC = NaN;
rec.minNodeSize = NaN;
rec.avgAnchors = NaN;
rec.anchorCounts = "";
rec.targetView = NaN;
rec.acceptedSplits = "";
rec.rejectedSplits = "";
rec.meanLeafSize = "";
rec.maxDepth = "";
rec.anchorTime = NaN;
rec.alignmentTime = NaN;
rec.totalTime = NaN;
rec.numGridConfigs = NaN;
rec.numSeeds = NaN;
rec.numRuns = NaN;
rec.searchBudget = NaN;
rec.selectionRule = "";
rec.selectedConfig = "";
rec.sourceFile = "";
rec.sourceType = "";
rec.source = "";
end

function rec = attach_mechanism(rec, row)
if isempty(row) || height(row) == 0
    return;
end
rec.avgAnchors = get_table_number(row, 'Avg_anchors');
rec.anchorCounts = get_table_text(row, 'Anchor_counts_per_view');
rec.targetView = get_table_number(row, 'Target_view');
rec.acceptedSplits = get_table_text(row, 'Accepted_splits');
rec.rejectedSplits = get_table_text(row, 'Rejected_splits');
rec.meanLeafSize = get_table_text(row, 'Mean_leaf_size');
rec.maxDepth = get_table_text(row, 'Max_depth');
rec.anchorTime = get_table_number(row, 'Anchor_time');
rec.alignmentTime = get_table_number(row, 'Alignment_time');
rec.totalTime = get_table_number(row, 'Total_time');
end

function rec = attach_budget(rec, row)
if isempty(row) || height(row) == 0
    return;
end
rec.numGridConfigs = get_table_number(row, 'numGridConfigs');
rec.numSeeds = get_table_number(row, 'numSeeds');
rec.numRuns = get_table_number(row, 'numRuns');
rec.searchBudget = get_table_number(row, 'searchBudget');
rec.selectionRule = get_table_text(row, 'selectionRule');
rec.selectedConfig = get_table_text(row, 'selectedConfig');
end

function value = get_table_number(row, fieldName)
if isempty(row) || ~ismember(fieldName, row.Properties.VariableNames)
    value = NaN;
    return;
end
raw = row.(fieldName);
if isnumeric(raw)
    value = double(raw(1));
elseif iscell(raw)
    value = str2double(string(raw{1}));
else
    value = str2double(string(raw(1)));
end
end

function value = get_table_text(row, fieldName)
if isempty(row) || ~ismember(fieldName, row.Properties.VariableNames)
    value = "";
    return;
end
raw = row.(fieldName);
if iscell(raw)
    value = string(raw{1});
elseif isnumeric(raw)
    if isnan(raw(1))
        value = "Missing";
    else
        value = string(raw(1));
    end
else
    value = string(raw(1));
end
if strlength(strtrim(value)) == 0 || strcmpi(value, "nan") || strcmpi(value, "<missing>")
    value = "Missing";
end
end

function cells = build_main_cells(datasets, methods, records)
cells = {'Dataset', 'A0-best', 'A1-mean', 'A3-mean', 'A4-mean'};
for id = 1:numel(datasets)
    ds = datasets{id};
    row = cell(1, numel(methods) + 1);
    row{1} = ds;
    for im = 1:numel(methods)
        row{im + 1} = perf_cell(records(make_key(ds, methods{im})));
    end
    cells(end + 1, :) = row; %#ok<AGROW>
end
end

function cells = build_delta_cells(datasets, ablationMethods, records)
cells = {'Dataset', 'Method', 'Delta ACC', 'Delta NMI', 'Delta AR'};
for id = 1:numel(datasets)
    ds = datasets{id};
    a0 = records(make_key(ds, 'A0_Full_Reference'));
    for im = 1:numel(ablationMethods)
        rec = records(make_key(ds, ablationMethods{im}));
        cells(end + 1, :) = {ds, ablationMethods{im}, ...
            delta_text(rec.ACC, a0.ACC), delta_text(rec.NMI, a0.NMI), delta_text(rec.AR, a0.AR)}; %#ok<AGROW>
    end
end
end

function cells = build_mechanism_cells(datasets, methods, records)
cells = {'Dataset', 'Method', 'ResultType', 'AvgAnchors', 'AnchorCounts', ...
    'TargetView', 'AcceptedSplits', 'RejectedSplits', 'MeanLeafSize', 'MaxDepth', ...
    'AnchorTime', 'AlignmentTime', 'TotalTime', 'beta', 'lambda', 'lambdaBIC', ...
    'minNodeSize', 'numRuns', 'numSeeds', 'numGridConfigs', 'searchBudget', ...
    'selectionRule', 'selectedConfig', 'sourceFile'};
for id = 1:numel(datasets)
    ds = datasets{id};
    for im = 1:numel(methods)
        rec = records(make_key(ds, methods{im}));
        cells(end + 1, :) = {ds, methods{im}, char(rec.resultType), ...
            fmt_num(rec.avgAnchors), text_or_missing(rec.anchorCounts), fmt_num(rec.targetView), ...
            text_or_missing(rec.acceptedSplits), text_or_missing(rec.rejectedSplits), ...
            text_or_missing(rec.meanLeafSize), text_or_missing(rec.maxDepth), ...
            fmt_num(rec.anchorTime), fmt_num(rec.alignmentTime), fmt_num(rec.totalTime), ...
            fmt_num(rec.beta), fmt_num(rec.lambda), fmt_num(rec.lambdaBIC), ...
            fmt_num(rec.minNodeSize), fmt_num(rec.numRuns), fmt_num(rec.numSeeds), ...
            fmt_num(rec.numGridConfigs), fmt_num(rec.searchBudget), ...
            text_or_missing(rec.selectionRule), text_or_missing(rec.selectedConfig), ...
            text_or_missing(rec.sourceFile)}; %#ok<AGROW>
    end
end
end

function cells = build_budget_cells(datasets, methods, records)
cells = {'Dataset', 'Method', 'numGridConfigs', 'numSeeds', 'numRuns', ...
    'searchBudget', 'selectionRule', 'selectedConfig'};
for id = 1:numel(datasets)
    ds = datasets{id};
    for im = 1:numel(methods)
        rec = records(make_key(ds, methods{im}));
        cells(end + 1, :) = {ds, methods{im}, fmt_num(rec.numGridConfigs), ...
            fmt_num(rec.numSeeds), fmt_num(rec.numRuns), fmt_num(rec.searchBudget), ...
            text_or_missing(rec.selectionRule), text_or_missing(rec.selectedConfig)}; %#ok<AGROW>
    end
end
end

function cells = build_baseline_cells(datasets, records, bestDetail)
cells = {'Dataset', 'Original 3AMVC baseline', 'A0-best', 'Delta ACC', 'Delta NMI', 'Delta AR', 'Note'};
for id = 1:numel(datasets)
    ds = datasets{id};
    baseRow = select_row(bestDetail, ds, 'Original 3AMVC Baseline');
    a0 = records(make_key(ds, 'A0_Full_Reference'));
    if isempty(baseRow) || height(baseRow) == 0
        baseText = 'Missing';
        dacc = 'Missing'; dnmi = 'Missing'; dar = 'Missing';
        note = '原论文或本地 baseline 中未找到该数据集。';
    else
        base = row_to_record(baseRow, ds, 'Original 3AMVC Baseline', 'best');
        baseText = perf_cell(base);
        dacc = delta_text(a0.ACC, base.ACC);
        dnmi = delta_text(a0.NMI, base.NMI);
        dar = delta_text(a0.AR, base.AR);
        if strcmp(ds, 'Caltech256')
            note = '使用本地原始源码 baseline；当前 Caltech256 为 257 类含 clutter 版本，不直接采用原论文 Caltech256 指标。';
        else
            note = '使用原论文报告的 Original 3AMVC 指标；WIKI 若缺失则不比较。';
        end
    end
    cells(end + 1, :) = {ds, baseText, perf_cell(a0), dacc, dnmi, dar, note}; %#ok<AGROW>
end
end

function text = build_report_text(datasets, ~, ablationMethods, records, sourceRows, ...
    missingRows, mainCells, deltaCells, mechanismCells, budgetCells, baselineCells)
lines = {};
lines{end + 1} = '# BIC-LR-3AMVC 消融实验分析：A0-best vs Ablation-mean';
lines{end + 1} = '';
lines{end + 1} = '## 1. 实验结果读取情况';
lines{end + 1} = '本报告读取 A0 完整模型在 `3AMVC-main/res_biclr_refined` 中的 best 结果，并读取 `ablation_biclr/res` 下 A1/A3/A4 的 latest 消融结果，消融组采用 mean 指标。';
lines{end + 1} = '';
lines{end + 1} = table_to_markdown([{'Dataset', 'Method', 'SourceFile', 'Status'}; sourceRows]);
if isempty(missingRows)
    lines{end + 1} = '';
    lines{end + 1} = '覆盖数据集：Mfeat、Reuters-1200、WIKI、ForestTypes、Caltech256；方法：A0_Full_Reference、A1_woBIC_Joint、A3_SSETarget、A4_woMultiViewFusion。未发现目标方法或目标数据集缺失。';
else
    lines{end + 1} = '';
    lines{end + 1} = '缺失项如下：';
    lines{end + 1} = table_to_markdown([{'Dataset', 'Method', 'Reason'}; missingRows]);
end
lines{end + 1} = '';
lines{end + 1} = 'A0 旧结果中 acceptedSplits、rejectedSplits、meanLeafSize、maxDepth、alignmentTime 等机制字段并不完整，因此机制分析主要依赖 A1/A3/A4 的统一结果字段。';
lines{end + 1} = '';
lines{end + 1} = '## 2. 对比口径说明';
lines{end + 1} = '- A0_Full_Reference 使用 `res_biclr_refined` 中的 best 值。';
lines{end + 1} = '- A1_woBIC_Joint、A3_SSETarget、A4_woMultiViewFusion 使用各自 latest 结果中的 mean 值。';
lines{end + 1} = '- 该结果不是严格同口径比较；它主要用于观察完整模型最优潜力与各消融变体平均性能之间的差异。';
lines{end + 1} = '- 不能直接写成严格单变量消融结论；严格因果归因需要固定 A0 最优参数后只改变一个模块重新运行。';
lines{end + 1} = '';
lines{end + 1} = '## 3. 主性能表';
lines{end + 1} = table_to_markdown(mainCells);
lines{end + 1} = '';
lines{end + 1} = '## 4. 相对 A0-best 的差值表';
lines{end + 1} = table_to_markdown(deltaCells);
lines{end + 1} = '';
lines{end + 1} = '## 5. A0-best 与 Original 3AMVC baseline 的比较';
lines{end + 1} = 'Mfeat、Reuters-1200 和 ForestTypes 使用原论文报告的 Original 3AMVC 结果；WIKI 未在原论文 baseline 中找到可比记录，标注为 Missing。Caltech256 使用本地原始源码 baseline，不直接采用原论文 Caltech256 指标，因为当前数据是用户自行处理的 257 类含 clutter 版本。';
lines{end + 1} = '';
lines{end + 1} = table_to_markdown(baselineCells);
lines{end + 1} = '';
lines{end + 1} = '## 6. A1 w/o BIC 分析';
lines = append_method_analysis(lines, datasets, records, 'A1_woBIC_Joint', ...
    'A1 去掉 BIC 复杂度惩罚后，若锚点数和 acceptedSplits 增加而性能下降，可视为过分裂风险的迹象。但由于这里是 A0-best vs A1-mean，A1 低于 A0 不一定全部来自 BIC 模块，口径差异和搜索空间差异也会影响数值。');
lines{end + 1} = '';
lines{end + 1} = '## 7. A3 SSE Target 分析';
lines = append_method_analysis(lines, datasets, records, 'A3_SSETarget', ...
    'A3 将目标视图选择从 BICUnitEvidence 换成 SSEMin。若 targetView 改变且性能下降，可以说明 BICUnitEvidence 在该数据集上更有利；若 A3 接近或高于 A0，则说明目标视图选择具有数据集依赖性，不能写成 BICUnitEvidence 在所有数据集上必然优于 SSEMin。');
lines{end + 1} = '';
lines{end + 1} = '## 8. A4 w/o Multi-view Fusion 分析';
lines = append_method_analysis(lines, datasets, records, 'A4_woMultiViewFusion', ...
    'A4 去掉跨视图对齐融合，只使用目标视图锚图进行最终聚类。该组通常是最稳定、最强的模块证据：若 ACC/NMI/AR 明显下降，说明多视图对齐融合对最终表示有关键贡献。WIKI 的下降较小，可能说明其目标视图本身已经较强。');
lines{end + 1} = '';
lines{end + 1} = '## 9. 机制指标分析';
mechBrief = mechanismCells(:, 1:13);
lines{end + 1} = table_to_markdown(mechBrief);
lines{end + 1} = '';
lines{end + 1} = '## 10. 搜索预算与公平性说明';
lines{end + 1} = table_to_markdown(budgetCells);
lines{end + 1} = '';
lines{end + 1} = '- A0-best 与 ablation-mean 是混合口径。';
lines{end + 1} = '- A0 与消融组来源不同，A0 来自 `res_biclr_refined`，消融组来自 `ablation_biclr/res`。';
lines{end + 1} = '- 不同方法搜索空间不同；A4 没有 lambda，因此搜索空间天然不同。';
lines{end + 1} = '- 当前报告适合作为补充观察，不适合作为严格单变量因果归因。';
lines{end + 1} = '';
lines{end + 1} = '## 11. 结论总结';
lines{end + 1} = build_conclusion(datasets, ablationMethods, records);
text = strjoin(lines, newline);
end

function lines = append_method_analysis(lines, datasets, records, methodName, closingText)
for id = 1:numel(datasets)
    ds = datasets{id};
    a0 = records(make_key(ds, 'A0_Full_Reference'));
    rec = records(make_key(ds, methodName));
    lines{end + 1} = sprintf('- %s：%s 的 ACC/NMI/AR=%s，相对 A0-best 的差值为 ACC=%s，NMI=%s，AR=%s；AvgAnchors=%s，anchorCounts=%s，targetView=%s，acceptedSplits=%s，meanLeafSize=%s。', ...
        ds, methodName, perf_cell(rec), delta_text(rec.ACC, a0.ACC), delta_text(rec.NMI, a0.NMI), ...
        delta_text(rec.AR, a0.AR), fmt_num(rec.avgAnchors), text_or_missing(rec.anchorCounts), ...
        fmt_num(rec.targetView), text_or_missing(rec.acceptedSplits), text_or_missing(rec.meanLeafSize)); %#ok<AGROW>
end
lines{end + 1} = closingText;
end

function text = build_conclusion(datasets, ablationMethods, records)
strongDrops = {};
smallDrops = {};
for id = 1:numel(datasets)
    ds = datasets{id};
    a0 = records(make_key(ds, 'A0_Full_Reference'));
    for im = 1:numel(ablationMethods)
        rec = records(make_key(ds, ablationMethods{im}));
        dacc = rec.ACC - a0.ACC;
        if isfinite(dacc) && dacc < -0.05
            strongDrops{end + 1} = sprintf('%s/%s(Delta ACC=%+.4f)', ds, ablationMethods{im}, dacc); %#ok<AGROW>
        elseif isfinite(dacc) && abs(dacc) <= 0.02
            smallDrops{end + 1} = sprintf('%s/%s(Delta ACC=%+.4f)', ds, ablationMethods{im}, dacc); %#ok<AGROW>
        end
    end
end
text = sprintf(['在该混合口径下，A0-best 相对消融均值的明显优势主要出现在：%s。' ...
    '多视图融合 A4 的下降最稳定，尤其在 Mfeat、Caltech256 和 ForestTypes 上较明显，是当前最强的消融证据。' ...
    'A1 和 A3 的证据更具数据集依赖性，WIKI、Caltech256 或 ForestTypes 上存在接近甚至高于 A0-best 的情况，应如实报告。' ...
    '后续需要运行 fixed-parameter strict ablation，以排除搜索空间、选优口径和来源差异的影响。'], ...
    join_or_missing(strongDrops));
if ~isempty(smallDrops)
    text = [text newline sprintf('接近 A0-best 的组合包括：%s。', join_or_missing(smallDrops))];
end
end

function text = build_paper_summary(datasets, ablationMethods, records)
lines = {};
lines{end + 1} = '# A0-best vs Ablation-mean 补充比较摘要';
lines{end + 1} = '';
lines{end + 1} = ['作为补充分析，我们将完整模型 A0 在 refined 搜索中的 best 结果与消融变体 A1/A3/A4 的 mean 结果进行比较。' ...
    '需要强调的是，该设置采用 A0-best vs ablation-mean 的混合口径，并非严格同口径、固定参数的单变量消融，因此结果主要反映完整模型最优潜力与各消融变体平均表现之间的差异，不能直接作为严格因果结论。'];
lines{end + 1} = '';
for im = 1:numel(ablationMethods)
    method = ablationMethods{im};
    parts = {};
    for id = 1:numel(datasets)
        ds = datasets{id};
        a0 = records(make_key(ds, 'A0_Full_Reference'));
        rec = records(make_key(ds, method));
        parts{end + 1} = sprintf('%s: Delta ACC=%s, Delta NMI=%s, Delta AR=%s', ...
            ds, delta_text(rec.ACC, a0.ACC), delta_text(rec.NMI, a0.NMI), delta_text(rec.AR, a0.AR)); %#ok<AGROW>
    end
    lines{end + 1} = sprintf('对于 %s，混合口径差值为：%s。', method, strjoin(parts, '；'));
end
lines{end + 1} = '';
lines{end + 1} = ['总体而言，A4 w/o Multi-view Fusion 在多数数据集上相对 A0-best 出现更稳定的下降，说明跨视图对齐融合是较强的性能来源。' ...
    'A1 w/o BIC 与 A3 SSE Target 的表现更依赖数据集和搜索口径，个别数据集可能接近或超过 A0-best，因此论文中应将该表述限定为补充观察，并配合 fixed-parameter strict ablation 给出更严格的单变量验证。'];
text = strjoin(lines, newline);
end

function text = build_fairness_notes(sourceRows)
lines = {};
lines{end + 1} = '# A0-best vs Ablation-mean 公平性限制说明';
lines{end + 1} = '';
lines{end + 1} = '本文件专门说明混合口径比较的限制。';
lines{end + 1} = '';
lines{end + 1} = '1. A0 使用 best 值，A1/A3/A4 使用 mean 值，因此该报告不是严格同口径比较。';
lines{end + 1} = '2. A0 来源于 `3AMVC-main/res_biclr_refined`，消融组来源于 `ablation_biclr/res`，结果结构和字段完整度不同。';
lines{end + 1} = '3. 各消融组此前采用各自网格选优，参数并未固定为 A0 best 配置。';
lines{end + 1} = '4. A4 不使用多视图融合，lambda 不参与计算，因此它的搜索空间天然不同。';
lines{end + 1} = '5. Caltech256 当前为 257 类含 clutter 的本地处理版本，不能直接采用原论文 Caltech256 指标作为正式 baseline。';
lines{end + 1} = '6. A0 旧结果中部分机制字段缺失，机制分析主要依赖 A1/A3/A4 的统一结果字段。';
lines{end + 1} = '';
lines{end + 1} = '因此，该报告只能作为完整模型最优潜力与消融变体平均表现之间的补充观察。严格单变量结论应以后续 fixed-parameter strict ablation 为准。';
lines{end + 1} = '';
lines{end + 1} = '## 读取文件';
lines{end + 1} = table_to_markdown([{'Dataset', 'Method', 'SourceFile', 'Status'}; sourceRows]);
text = strjoin(lines, newline);
end

function filePath = a0_source_file(datasetName, mainRoot)
switch datasetName
    case 'Mfeat'
        filePath = fullfile(mainRoot, 'res_biclr_refined', 'MFeat_2Views_BICLR_refined_best_ACC.mat');
    case 'Reuters-1200'
        filePath = fullfile(mainRoot, 'res_biclr_refined', 'Reuters_1200_BICLR_refined_best_ACC.mat');
    case 'WIKI'
        filePath = fullfile(mainRoot, 'res_biclr_refined', 'Wikifea_BICLR_refined_best_ACC.txt');
    case 'ForestTypes'
        filePath = fullfile(mainRoot, 'res_biclr_refined', 'ForestTypes_BICLR_refined_best_ACC.mat');
    case 'Caltech256'
        filePath = fullfile(mainRoot, 'res_biclr_refined', 'Caltech256_4Views_257cls_withClutter_BICLR_refined_best_ACC.txt');
    otherwise
        filePath = '';
end
end

function filePath = ablation_source_file(datasetName, methodName, resRoot)
dirName = dataset_to_dir(datasetName);
filePath = fullfile(resRoot, methodName, dirName, sprintf('%s_%s_latest.mat', methodName, dirName));
end

function dirName = dataset_to_dir(datasetName)
switch datasetName
    case 'Mfeat'
        dirName = 'Mfeat';
    case 'Reuters-1200'
        dirName = 'Ruter1200';
    case 'WIKI'
        dirName = 'WIKI';
    case 'ForestTypes'
        dirName = 'ForestTypes';
    case 'Caltech256'
        dirName = 'Caltech256_4Views_257cls_withClutter';
    otherwise
        dirName = datasetName;
end
end

function key = make_key(datasetName, methodName)
key = sprintf('%s__%s', datasetName, methodName);
end

function text = perf_cell(rec)
text = sprintf('%s / %s / %s', fmt_metric(rec.ACC), fmt_metric(rec.NMI), fmt_metric(rec.AR));
end

function text = delta_text(value, baseline)
if ~isfinite(value) || ~isfinite(baseline)
    text = 'Missing';
else
    text = sprintf('%+.4f', value - baseline);
end
end

function text = fmt_metric(value)
if ~isfinite(value)
    text = 'Missing';
else
    text = sprintf('%.4f', value);
end
end

function text = fmt_num(value)
if ~isfinite(value)
    text = 'Missing';
elseif abs(value - round(value)) < 1e-12
    text = sprintf('%.0f', value);
else
    text = sprintf('%.6g', value);
end
end

function text = text_or_missing(value)
value = string(value);
if ismissing(value) || strlength(strtrim(value)) == 0 || strcmpi(value, "nan") || strcmpi(value, "<missing>")
    text = 'Missing';
else
    text = char(value);
end
end

function text = exists_text(filePath)
if exist(filePath, 'file')
    text = 'Found';
else
    text = 'Missing';
end
end

function write_text(filePath, text)
fid = fopen(filePath, 'w');
if fid < 0
    error('generate_mixed_report:WriteFailed', '无法写入文件：%s', filePath);
end
cleanupObj = onCleanup(@() fclose(fid));
fprintf(fid, '%s', text);
end

function write_csv_cell(filePath, cells)
fid = fopen(filePath, 'w');
if fid < 0
    error('generate_mixed_report:WriteFailed', '无法写入 CSV：%s', filePath);
end
cleanupObj = onCleanup(@() fclose(fid));
for i = 1:size(cells, 1)
    parts = cell(1, size(cells, 2));
    for j = 1:size(cells, 2)
        parts{j} = csv_escape(cells{i, j});
    end
    fprintf(fid, '%s\n', strjoin(parts, ','));
end
end

function text = csv_escape(value)
text = char(string(value));
text = strrep(text, '"', '""');
if contains(text, ',') || contains(text, '"') || contains(text, newline)
    text = ['"' text '"'];
end
end

function md = table_to_markdown(cells)
if isempty(cells)
    md = '';
    return;
end
lines = cell(size(cells, 1) + 1, 1);
lines{1} = markdown_row(cells(1, :));
lines{2} = markdown_row(repmat({'---'}, 1, size(cells, 2)));
for i = 2:size(cells, 1)
    lines{i + 1} = markdown_row(cells(i, :));
end
md = strjoin(lines, newline);
end

function line = markdown_row(row)
parts = cell(1, numel(row));
for i = 1:numel(row)
    parts{i} = strrep(char(string(row{i})), '|', '\|');
end
line = ['| ' strjoin(parts, ' | ') ' |'];
end

function text = join_or_missing(parts)
if isempty(parts)
    text = 'Missing';
else
    text = strjoin(parts, '；');
end
end
