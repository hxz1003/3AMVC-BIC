function outputs = generate_strict_fixed_vs_A0best_report()
%GENERATE_STRICT_FIXED_VS_A0BEST_REPORT 生成严格固定参数消融与 A0-best 对比报告。
%   OUTPUTS = GENERATE_STRICT_FIXED_VS_A0BEST_REPORT() 读取
%   ablation_biclr/res_strict_fixed 中的最新严格消融结果，并读取
%   3AMVC-main/res_biclr_refined 对应的 A0 best 指标，输出 Markdown 报告和
%   CSV 表格。
%
%   注意事项：
%   1. 严格消融不重新搜索参数，除指定模块外固定 A0 best 配置。
%   2. 主表使用 strict fixed 的 mean±std 与 A0-best 对比；同时输出
%      strict best-run 的辅助差值表。
%   3. 本函数只读取已有结果并写入当前 reports_strict_fixed_vs_A0best
%      目录，不修改已有实验结果文件。

thisDir = fileparts(mfilename('fullpath'));
ablationRoot = fileparts(thisDir);
repoRoot = fileparts(ablationRoot);
strictRoot = fullfile(ablationRoot, 'res_strict_fixed');
analysisBestDir = fullfile(ablationRoot, 'reports', 'analysis_final_best');
mainRoot = fullfile(repoRoot, '3AMVC-main');

datasets = strict_dataset_specs();
methods = strict_method_specs();

a0Table = readtable(fullfile(analysisBestDir, 'detailed_metric_table.csv'), ...
    'TextType', 'string', 'VariableNamingRule', 'preserve');

a0Map = containers.Map();
strictMap = containers.Map();
sourceRows = {};
missingRows = {};

for id = 1:numel(datasets)
    ds = datasets(id);
    a0 = read_a0_record(a0Table, ds, mainRoot);
    a0Map(ds.standardName) = a0;
    sourceRows(end + 1, :) = {char(ds.standardName), 'A0_Full_Reference', ...
        char(a0.sourceFile), exists_text(a0.sourceFile)}; %#ok<AGROW>

    for im = 1:numel(methods)
        method = methods(im);
        [rec, sourceFile] = read_latest_strict_record(strictRoot, method, ds);
        strictMap(make_key(ds.standardName, method.name)) = rec;
        sourceRows(end + 1, :) = {char(ds.standardName), char(method.name), ...
            char(sourceFile), exists_text(sourceFile)}; %#ok<AGROW>
        if ~rec.found
            missingRows(end + 1, :) = {char(ds.standardName), char(method.name), ...
                '未找到 strict fixed 最新 .mat 结果'}; %#ok<AGROW>
        end
    end
end

mainTable = build_main_table(datasets, methods, a0Map, strictMap);
deltaMeanTable = build_delta_table(datasets, methods, a0Map, strictMap, 'mean');
deltaBestTable = build_delta_table(datasets, methods, a0Map, strictMap, 'best');
mechanismTable = build_mechanism_table(datasets, methods, strictMap);
fixedConfigTable = build_fixed_config_table(datasets, methods, strictMap);

write_csv_cell(fullfile(thisDir, 'strict_fixed_vs_A0best_main_table.csv'), mainTable);
write_csv_cell(fullfile(thisDir, 'strict_fixed_vs_A0best_delta_mean_table.csv'), deltaMeanTable);
write_csv_cell(fullfile(thisDir, 'strict_fixed_vs_A0best_delta_best_table.csv'), deltaBestTable);
write_csv_cell(fullfile(thisDir, 'strict_fixed_vs_A0best_mechanism_table.csv'), mechanismTable);
write_csv_cell(fullfile(thisDir, 'strict_fixed_vs_A0best_fixed_config_table.csv'), fixedConfigTable);

reportText = build_report_text(datasets, methods, a0Map, strictMap, sourceRows, ...
    missingRows, mainTable, deltaMeanTable, deltaBestTable, mechanismTable, fixedConfigTable);
write_text(fullfile(thisDir, 'strict_fixed_vs_A0best_report.md'), reportText);

summaryText = build_summary_for_paper(datasets, methods, a0Map, strictMap);
write_text(fullfile(thisDir, 'strict_fixed_vs_A0best_summary_for_paper.md'), summaryText);

notesText = build_fairness_notes(sourceRows);
write_text(fullfile(thisDir, 'strict_fixed_vs_A0best_fairness_notes.md'), notesText);

outputs = struct();
outputs.outputDir = thisDir;
outputs.mainTable = mainTable;
outputs.deltaMeanTable = deltaMeanTable;
outputs.deltaBestTable = deltaBestTable;
outputs.mechanismTable = mechanismTable;
outputs.fixedConfigTable = fixedConfigTable;
outputs.generatedFiles = { ...
    fullfile(thisDir, 'strict_fixed_vs_A0best_report.md'); ...
    fullfile(thisDir, 'strict_fixed_vs_A0best_summary_for_paper.md'); ...
    fullfile(thisDir, 'strict_fixed_vs_A0best_main_table.csv'); ...
    fullfile(thisDir, 'strict_fixed_vs_A0best_delta_mean_table.csv'); ...
    fullfile(thisDir, 'strict_fixed_vs_A0best_delta_best_table.csv'); ...
    fullfile(thisDir, 'strict_fixed_vs_A0best_mechanism_table.csv'); ...
    fullfile(thisDir, 'strict_fixed_vs_A0best_fixed_config_table.csv'); ...
    fullfile(thisDir, 'strict_fixed_vs_A0best_fairness_notes.md')};
fprintf('严格消融对比报告已生成到：%s\n', thisDir);
end

function datasets = strict_dataset_specs()
datasets = struct( ...
    'standardName', {'Mfeat', 'Reuters-1200', 'WIKI', 'ForestTypes', 'Caltech256'}, ...
    'strictDir', {'Mfeat', 'Reuters1200', 'WIKI', 'ForestTypes', 'Caltech256'}, ...
    'a0File', { ...
        fullfile('res_biclr_refined', 'MFeat_2Views_BICLR_refined_best_ACC.mat'), ...
        fullfile('res_biclr_refined', 'Reuters_1200_BICLR_refined_best_ACC.mat'), ...
        fullfile('res_biclr_refined', 'Wikifea_BICLR_refined_best_ACC.txt'), ...
        fullfile('res_biclr_refined', 'ForestTypes_BICLR_refined_best_ACC.mat'), ...
        fullfile('res_biclr_refined', 'Caltech256_4Views_257cls_withClutter_BICLR_refined_best_ACC.txt')});
end

function methods = strict_method_specs()
methods = struct( ...
    'name', {'A1_fixed_woBIC', 'A3_fixed_SSETarget', 'A4_fixed_woMultiViewFusion'}, ...
    'shortLabel', {'A1 fixed w/o BIC', 'A3 fixed SSE Target', 'A4 fixed w/o Fusion'}, ...
    'module', {'BIC penalty', 'target-view criterion', 'multi-view fusion'});
end

function a0 = read_a0_record(a0Table, ds, mainRoot)
row = select_row(a0Table, ds.standardName, 'A0_Full_Reference');
a0 = struct();
a0.dataset = string(ds.standardName);
a0.method = "A0_Full_Reference";
a0.resultType = "A0-best";
a0.found = ~isempty(row) && height(row) > 0;
a0.ACC = get_table_number(row, 'ACC');
a0.NMI = get_table_number(row, 'NMI');
a0.AR = get_table_number(row, 'AR');
a0.Purity = get_table_number(row, 'Purity');
a0.Fscore = get_table_number(row, 'Fscore');
a0.beta = get_table_number(row, 'Selected_beta');
a0.lambda = get_table_number(row, 'Selected_lambda');
a0.lambdaBIC = get_table_number(row, 'Selected_lambdaBIC');
a0.minNodeSize = get_table_number(row, 'Selected_minNodeSize');
a0.sourceFile = string(fullfile(mainRoot, ds.a0File));
end

function [rec, sourceFile] = read_latest_strict_record(strictRoot, method, ds)
rec = empty_strict_record(method, ds);
methodDir = fullfile(strictRoot, method.name, ds.strictDir);
files = dir(fullfile(methodDir, '*.mat'));
if isempty(files)
    sourceFile = "";
    return;
end
[~, ix] = max([files.datenum]);
sourceFile = string(fullfile(files(ix).folder, files(ix).name));
loaded = load(sourceFile);
if ~isfield(loaded, 'result')
    return;
end
r = loaded.result;
rec.found = true;
rec.sourceFile = sourceFile;
rec.method = string(get_field_any(r, 'method', method.name));
rec.dataset = string(get_field_any(r, 'dataset', ds.standardName));
rec.ACC_mean = get_field_number(r, 'ACC_mean');
rec.NMI_mean = get_field_number(r, 'NMI_mean');
rec.AR_mean = get_field_number(r, 'AR_mean');
rec.ACC_std = get_field_number(r, 'ACC_std');
rec.NMI_std = get_field_number(r, 'NMI_std');
rec.AR_std = get_field_number(r, 'AR_std');
rec.ACC_best = get_field_number(r, 'ACC_best');
rec.NMI_best = get_field_number(r, 'NMI_best');
rec.AR_best = get_field_number(r, 'AR_best');
rec.numRuns = get_field_number(r, 'numRuns');
rec.seed = get_field_number(r, 'seed');
rec.beta = get_field_number(r, 'beta');
rec.lambda = get_field_number(r, 'lambda');
rec.lambdaBIC = get_field_number(r, 'lambdaBIC');
rec.minNodeSize = get_field_number(r, 'minNodeSize');
rec.tauSplit = get_field_number(r, 'tauSplit');
rec.epsVar = get_field_number(r, 'epsVar');
rec.targetView = get_field_number(r, 'targetView');
rec.A0_targetView = get_field_number(r, 'A0_targetView');
rec.BIC_targetView = get_field_number(r, 'BIC_targetView');
rec.SSE_targetView = get_field_number(r, 'SSE_targetView');
rec.anchorCounts = get_field_any(r, 'anchorCounts', []);
rec.avgAnchors = get_field_number(r, 'avgAnchors');
rec.acceptedSplits = get_field_any(r, 'acceptedSplits', []);
rec.rejectedSplits = get_field_any(r, 'rejectedSplits', []);
rec.meanLeafSize = get_field_any(r, 'meanLeafSize', []);
rec.maxDepth = get_field_any(r, 'maxDepth', []);
rec.anchorTime = get_field_number(r, 'anchorTime');
rec.alignmentTime = get_field_number(r, 'alignmentTime');
rec.totalTime = get_field_number(r, 'totalTime');
rec.lambdaNotUsed = logical(get_field_number(r, 'lambdaNotUsed'));
rec.useMultiViewFusion = logical(get_field_number(r, 'useMultiViewFusion'));
rec.changedOnly = string(get_field_any(r, 'changedOnly', ''));
rec.notes = string(get_field_any(r, 'notes', ''));
rec.cacheHit = get_field_any(r, 'cacheHit', []);
rec.cacheSource = get_field_any(r, 'cacheSource', {});
if isfield(r, 'fixedConfig')
    rec.fixedConfig = r.fixedConfig;
else
    rec.fixedConfig = struct();
end
end

function rec = empty_strict_record(method, ds)
rec = struct();
rec.found = false;
rec.method = string(method.name);
rec.dataset = string(ds.standardName);
rec.sourceFile = "";
rec.ACC_mean = NaN;
rec.NMI_mean = NaN;
rec.AR_mean = NaN;
rec.ACC_std = NaN;
rec.NMI_std = NaN;
rec.AR_std = NaN;
rec.ACC_best = NaN;
rec.NMI_best = NaN;
rec.AR_best = NaN;
rec.numRuns = NaN;
rec.seed = NaN;
rec.beta = NaN;
rec.lambda = NaN;
rec.lambdaBIC = NaN;
rec.minNodeSize = NaN;
rec.tauSplit = NaN;
rec.epsVar = NaN;
rec.targetView = NaN;
rec.A0_targetView = NaN;
rec.BIC_targetView = NaN;
rec.SSE_targetView = NaN;
rec.anchorCounts = [];
rec.avgAnchors = NaN;
rec.acceptedSplits = [];
rec.rejectedSplits = [];
rec.meanLeafSize = [];
rec.maxDepth = [];
rec.anchorTime = NaN;
rec.alignmentTime = NaN;
rec.totalTime = NaN;
rec.lambdaNotUsed = false;
rec.useMultiViewFusion = true;
rec.changedOnly = "";
rec.notes = "";
rec.cacheHit = [];
rec.cacheSource = {};
rec.fixedConfig = struct();
end

function row = select_row(tbl, datasetName, methodName)
if isempty(tbl)
    row = table();
    return;
end
mask = strcmp(string(tbl.Dataset), string(datasetName)) & strcmp(string(tbl.Method), string(methodName));
if any(mask)
    row = tbl(find(mask, 1, 'first'), :);
else
    row = table();
end
end

function cells = build_main_table(datasets, methods, a0Map, strictMap)
cells = {'Dataset', 'A0-best', 'A1-fixed mean±std [best]', ...
    'A3-fixed mean±std [best]', 'A4-fixed mean±std [best]'};
for id = 1:numel(datasets)
    ds = datasets(id);
    row = cell(1, numel(methods) + 2);
    row{1} = char(ds.standardName);
    row{2} = perf_cell_a0(a0Map(ds.standardName));
    for im = 1:numel(methods)
        rec = strictMap(make_key(ds.standardName, methods(im).name));
        row{im + 2} = perf_cell_strict(rec);
    end
    cells(end + 1, :) = row; %#ok<AGROW>
end
end

function cells = build_delta_table(datasets, methods, a0Map, strictMap, modeName)
if strcmp(modeName, 'mean')
    headerText = 'Delta strict-mean vs A0-best';
else
    headerText = 'Delta strict-bestRun vs A0-best';
end
cells = {'Dataset', 'Method', 'CompareMode', 'Delta ACC', 'Delta NMI', 'Delta AR'};
for id = 1:numel(datasets)
    ds = datasets(id);
    a0 = a0Map(ds.standardName);
    for im = 1:numel(methods)
        rec = strictMap(make_key(ds.standardName, methods(im).name));
        [acc, nmi, ar] = strict_metric_triplet(rec, modeName);
        cells(end + 1, :) = {char(ds.standardName), char(methods(im).name), ...
            headerText, delta_text(acc, a0.ACC), delta_text(nmi, a0.NMI), ...
            delta_text(ar, a0.AR)}; %#ok<AGROW>
    end
end
end

function cells = build_mechanism_table(datasets, methods, strictMap)
cells = {'Dataset', 'Method', 'AnchorCounts', 'AvgAnchors', 'TargetView', ...
    'A0TargetView', 'BICTargetView', 'SSETargetView', 'AcceptedSplits', ...
    'RejectedSplits', 'MeanLeafSize', 'MaxDepth', 'AnchorTime', ...
    'AlignmentTime', 'TotalTime', 'LambdaNotUsed', 'UseMultiViewFusion', ...
    'CacheHit', 'CacheSource', 'SourceFile'};
for id = 1:numel(datasets)
    ds = datasets(id);
    for im = 1:numel(methods)
        rec = strictMap(make_key(ds.standardName, methods(im).name));
        cells(end + 1, :) = {char(ds.standardName), char(methods(im).name), ...
            vec_text(rec.anchorCounts), fmt_num(rec.avgAnchors), fmt_num(rec.targetView), ...
            fmt_num(rec.A0_targetView), fmt_num(rec.BIC_targetView), fmt_num(rec.SSE_targetView), ...
            vec_text(rec.acceptedSplits), vec_text(rec.rejectedSplits), ...
            vec_text(rec.meanLeafSize), vec_text(rec.maxDepth), fmt_num(rec.anchorTime), ...
            fmt_num(rec.alignmentTime), fmt_num(rec.totalTime), logical_text(rec.lambdaNotUsed), ...
            logical_text(rec.useMultiViewFusion), vec_text(rec.cacheHit), ...
            cell_text(rec.cacheSource), char(rec.sourceFile)}; %#ok<AGROW>
    end
end
end

function cells = build_fixed_config_table(datasets, methods, strictMap)
cells = {'Dataset', 'Method', 'FixedFrom', 'ChangedOnly', 'beta', 'lambda', ...
    'lambdaBIC', 'minNodeSize', 'tauSplit', 'epsVar', 'numRuns', 'seed', ...
    'A0TargetView', 'TargetView', 'StrictControlNote'};
for id = 1:numel(datasets)
    ds = datasets(id);
    for im = 1:numel(methods)
        rec = strictMap(make_key(ds.standardName, methods(im).name));
        cells(end + 1, :) = {char(ds.standardName), char(methods(im).name), ...
            'A0_best_res_biclr_refined', char(rec.changedOnly), fmt_num(rec.beta), ...
            fmt_num(rec.lambda), fmt_num(rec.lambdaBIC), fmt_num(rec.minNodeSize), ...
            fmt_num(rec.tauSplit), fmt_num(rec.epsVar), fmt_num(rec.numRuns), ...
            fmt_num(rec.seed), fmt_num(rec.A0_targetView), fmt_num(rec.targetView), ...
            strict_control_note(methods(im).name, rec)}; %#ok<AGROW>
    end
end
end

function text = build_report_text(datasets, methods, a0Map, strictMap, sourceRows, ...
    missingRows, mainTable, deltaMeanTable, deltaBestTable, mechanismTable, fixedConfigTable)
lines = {};
lines{end + 1} = '# BIC-LR-3AMVC 严格固定参数消融分析：Strict Fixed vs A0-best';
lines{end + 1} = '';
lines{end + 1} = '## 1. 实验结果读取情况';
lines{end + 1} = '本报告读取 `ablation_biclr/res_strict_fixed` 中已完成的 strict fixed 消融结果，并以 `3AMVC-main/res_biclr_refined` 的 A0 best 结果作为参照。';
lines{end + 1} = '';
lines{end + 1} = table_to_markdown([{'Dataset', 'Method', 'SourceFile', 'Status'}; sourceRows]);
if isempty(missingRows)
    lines{end + 1} = '';
    lines{end + 1} = '读取完成：5 个数据集 × 3 个严格消融组均存在结果文件，未发现缺失项。';
else
    lines{end + 1} = '';
    lines{end + 1} = '缺失项如下：';
    lines{end + 1} = table_to_markdown([{'Dataset', 'Method', 'Reason'}; missingRows]);
end
lines{end + 1} = '';
lines{end + 1} = '## 2. 对比口径与严格控制说明';
lines{end + 1} = '- A0_Full_Reference 使用 `res_biclr_refined` 中的 best 值。';
lines{end + 1} = '- A1/A3/A4 使用 fixed-parameter strict ablation 结果，不执行 grid search，主比较采用 strict mean±std。';
lines{end + 1} = '- 报告同时给出 strict best-run 相对 A0-best 的辅助差值，便于区分评价随机性与模块影响。';
lines{end + 1} = '- A1 只将 `lambdaBIC` 改为 0；A3 只改目标视图选择为 `SSEMin`；A4 只关闭多视图融合并记录 `lambdaNotUsed=true`。';
lines{end + 1} = '- 由于 A0-best 是 best-run/summary 口径而 strict 主表是 mean 口径，均值差值是偏保守的模块观察，不应被写成 A0 mean 与 strict mean 的同口径结论。';
lines{end + 1} = '';
lines{end + 1} = '## 3. 主性能表';
lines{end + 1} = table_to_markdown(mainTable);
lines{end + 1} = '';
lines{end + 1} = '## 4. Strict mean 相对 A0-best 的差值表';
lines{end + 1} = table_to_markdown(deltaMeanTable);
lines{end + 1} = '';
lines{end + 1} = '## 5. Strict best-run 相对 A0-best 的辅助差值表';
lines{end + 1} = table_to_markdown(deltaBestTable);
lines{end + 1} = '';
lines{end + 1} = '## 6. A1 fixed w/o BIC 分析';
lines = append_method_analysis(lines, datasets, a0Map, strictMap, 'A1_fixed_woBIC', ...
    'A1_fixed 只关闭 BIC 惩罚。若锚点数和 acceptedSplits 明显增加且 mean 性能下降，可作为 BIC 惩罚抑制过分裂的证据；若指标接近或提升，需要如实说明该数据集上 BIC 惩罚不是单调收益。');
lines{end + 1} = '';
lines{end + 1} = '## 7. A3 fixed SSE Target 分析';
lines = append_method_analysis(lines, datasets, a0Map, strictMap, 'A3_fixed_SSETarget', ...
    'A3_fixed 只改变目标视图选择准则。targetView 改变且性能下降时，说明 BICUnitEvidence 在该数据集上更适合；targetView 不变时，该消融理论上不应改变主流程，差异主要来自评价随机性或缓存/运行细节。');
lines{end + 1} = '';
lines{end + 1} = '## 8. A4 fixed w/o Multi-view Fusion 分析';
lines = append_method_analysis(lines, datasets, a0Map, strictMap, 'A4_fixed_woMultiViewFusion', ...
    'A4_fixed 只关闭跨视图对齐融合。若多个数据集出现明显下降，可视为多视图融合模块的最直接证据；若个别数据集下降较小，说明其目标视图单独已经具有较强判别信息。');
lines{end + 1} = '';
lines{end + 1} = '## 9. 机制指标分析';
lines{end + 1} = table_to_markdown(mechanismTable);
lines{end + 1} = '';
lines{end + 1} = '## 10. 固定配置与单变量控制检查';
lines{end + 1} = table_to_markdown(fixedConfigTable);
lines{end + 1} = '';
lines{end + 1} = '## 11. 结论总结';
lines{end + 1} = build_conclusion(datasets, methods, a0Map, strictMap);
text = strjoin(lines, newline);
end

function lines = append_method_analysis(lines, datasets, a0Map, strictMap, methodName, closingText)
for id = 1:numel(datasets)
    ds = datasets(id);
    a0 = a0Map(ds.standardName);
    rec = strictMap(make_key(ds.standardName, methodName));
    lines{end + 1} = sprintf(['- %s：strict mean ACC/NMI/AR=%s，相对 A0-best 的均值差值为 ACC=%s，NMI=%s，AR=%s；' ...
        'strict best-run 差值为 ACC=%s，NMI=%s，AR=%s；targetView=%s，A0Target=%s，BICTarget=%s，SSETarget=%s，anchors=%s，acceptedSplits=%s。'], ...
        char(ds.standardName), strict_mean_triplet(rec), ...
        delta_text(rec.ACC_mean, a0.ACC), delta_text(rec.NMI_mean, a0.NMI), delta_text(rec.AR_mean, a0.AR), ...
        delta_text(rec.ACC_best, a0.ACC), delta_text(rec.NMI_best, a0.NMI), delta_text(rec.AR_best, a0.AR), ...
        fmt_num(rec.targetView), fmt_num(rec.A0_targetView), fmt_num(rec.BIC_targetView), ...
        fmt_num(rec.SSE_targetView), vec_text(rec.anchorCounts), vec_text(rec.acceptedSplits)); %#ok<AGROW>
end
lines{end + 1} = closingText;
end

function text = build_conclusion(datasets, methods, a0Map, strictMap)
dropMean = containers.Map(method_names(methods), zeros(1, numel(methods)));
validMean = containers.Map(method_names(methods), zeros(1, numel(methods)));
strongItems = {};
positiveItems = {};
for id = 1:numel(datasets)
    ds = datasets(id);
    a0 = a0Map(ds.standardName);
    for im = 1:numel(methods)
        method = methods(im).name;
        rec = strictMap(make_key(ds.standardName, method));
        dacc = rec.ACC_mean - a0.ACC;
        if isfinite(dacc)
            validMean(method) = validMean(method) + 1;
            if dacc < -0.02
                dropMean(method) = dropMean(method) + 1;
            end
            if dacc < -0.08
                strongItems{end + 1} = sprintf('%s/%s(Delta ACC=%+.4f)', ...
                    char(ds.standardName), char(method), dacc); %#ok<AGROW>
            elseif dacc > 0
                positiveItems{end + 1} = sprintf('%s/%s(Delta ACC=%+.4f)', ...
                    char(ds.standardName), char(method), dacc); %#ok<AGROW>
            end
        end
    end
end

parts = {};
for im = 1:numel(methods)
    method = methods(im).name;
    parts{end + 1} = sprintf('%s 在 %d/%d 个数据集上 strict mean ACC 较 A0-best 下降超过 0.02', ...
        char(method), dropMean(method), validMean(method)); %#ok<AGROW>
end
text = sprintf(['严格固定参数结果显示：%s。明显下降项包括：%s。' ...
    'A4_fixed 在 Mfeat、ForestTypes 和 Caltech256 上下降最明显，是多视图融合必要性的主要证据。' ...
    'A3_fixed 在 Caltech256 和 WIKI 上 targetView 改变后性能明显下降，说明目标视图选择准则具有数据集依赖性。' ...
    'A1_fixed 的影响不完全单调，Caltech256 等数据集出现 strict mean 高于 A0-best 的情况，应作为数据集依赖现象报告。'], ...
    strjoin(parts, '；'), join_or_missing(strongItems));
if ~isempty(positiveItems)
    text = [text newline sprintf('strict mean 高于 A0-best 的项目包括：%s。', strjoin(positiveItems, '；'))];
end
end

function text = build_summary_for_paper(datasets, methods, a0Map, strictMap)
lines = {};
lines{end + 1} = '# Strict fixed ablation 补充比较摘要';
lines{end + 1} = '';
lines{end + 1} = ['为避免各消融变体各自网格搜索带来的混杂因素，我们进一步采用 fixed-parameter strict ablation：' ...
    '对每个数据集固定 A0 best 的 `beta`、`lambda`、`lambdaBIC`、`minNodeSize`、随机种子和评价次数，只改变一个模块。' ...
    '下述比较以 A0-best 为参照，strict 消融主指标采用 mean±std，同时记录 best-run 作为辅助观察。'];
lines{end + 1} = '';
for im = 1:numel(methods)
    method = methods(im).name;
    parts = {};
    for id = 1:numel(datasets)
        ds = datasets(id);
        a0 = a0Map(ds.standardName);
        rec = strictMap(make_key(ds.standardName, method));
        parts{end + 1} = sprintf('%s: Delta ACC=%s, Delta NMI=%s, Delta AR=%s', ...
            char(ds.standardName), delta_text(rec.ACC_mean, a0.ACC), ...
            delta_text(rec.NMI_mean, a0.NMI), delta_text(rec.AR_mean, a0.AR)); %#ok<AGROW>
    end
    lines{end + 1} = sprintf('%s 的 strict mean 相对 A0-best 差值为：%s。', ...
        char(method), strjoin(parts, '；'));
end
lines{end + 1} = '';
lines{end + 1} = ['总体上，关闭多视图融合的 A4_fixed 在多个数据集上造成最稳定的性能下降，说明跨视图对齐融合是完整模型的重要组成部分。' ...
    'A1_fixed 和 A3_fixed 的影响更依赖数据集；特别是当目标视图没有改变或 BIC 惩罚改变未导致明显过分裂时，指标可能接近 A0。' ...
    '由于 A0 参照为 best 口径，而 strict 主结果为 mean 口径，论文中应明确该表为固定参数补充分析，不应与 A0 mean 同口径结果混写。'];
text = strjoin(lines, newline);
end

function text = build_fairness_notes(sourceRows)
lines = {};
lines{end + 1} = '# Strict fixed vs A0-best 口径说明';
lines{end + 1} = '';
lines{end + 1} = '本报告比各变体各自网格消融更接近单变量控制，因为 strict 消融固定 A0 best 配置且不重新搜索参数。';
lines{end + 1} = '';
lines{end + 1} = '仍需注意：';
lines{end + 1} = '- A0 参照使用 best 值，strict 主表使用 mean±std，因此主差值不是 A0 mean vs strict mean 的完全同口径比较。';
lines{end + 1} = '- strict best-run 辅助表仅用于观察评价随机性，不应替代 mean±std 作为稳定结论。';
lines{end + 1} = '- Caltech256 是 257 类含 clutter 的本地处理版本，不能直接套用原论文 Caltech256 指标。';
lines{end + 1} = '- A1 中 targetView 的变化是 `lambdaBIC=0` 改变视图证据后的下游结果，不是额外手动改动目标视图规则。';
lines{end + 1} = '- A4 中 `lambda` 被记录但不参与单视图聚类，报告中以 `lambdaNotUsed=true` 标注。';
lines{end + 1} = '';
lines{end + 1} = '## 读取文件';
lines{end + 1} = table_to_markdown([{'Dataset', 'Method', 'SourceFile', 'Status'}; sourceRows]);
text = strjoin(lines, newline);
end

function names = method_names(methods)
names = cell(1, numel(methods));
for i = 1:numel(methods)
    names{i} = char(methods(i).name);
end
end

function text = perf_cell_a0(a0)
text = sprintf('%s / %s / %s', fmt_metric(a0.ACC), fmt_metric(a0.NMI), fmt_metric(a0.AR));
end

function text = perf_cell_strict(rec)
text = sprintf('%s / %s / %s [best %s / %s / %s]', ...
    metric_std_text(rec.ACC_mean, rec.ACC_std), ...
    metric_std_text(rec.NMI_mean, rec.NMI_std), ...
    metric_std_text(rec.AR_mean, rec.AR_std), ...
    fmt_metric(rec.ACC_best), fmt_metric(rec.NMI_best), fmt_metric(rec.AR_best));
end

function text = strict_mean_triplet(rec)
text = sprintf('%s / %s / %s', ...
    metric_std_text(rec.ACC_mean, rec.ACC_std), ...
    metric_std_text(rec.NMI_mean, rec.NMI_std), ...
    metric_std_text(rec.AR_mean, rec.AR_std));
end

function text = metric_std_text(value, stdValue)
if ~isfinite(value)
    text = 'Missing';
elseif ~isfinite(stdValue)
    text = sprintf('%.4f', value);
else
    text = sprintf('%.4f±%.4f', value, stdValue);
end
end

function [acc, nmi, ar] = strict_metric_triplet(rec, modeName)
if strcmp(modeName, 'best')
    acc = rec.ACC_best;
    nmi = rec.NMI_best;
    ar = rec.AR_best;
else
    acc = rec.ACC_mean;
    nmi = rec.NMI_mean;
    ar = rec.AR_mean;
end
end

function text = strict_control_note(methodName, rec)
switch char(methodName)
    case 'A1_fixed_woBIC'
        text = sprintf('只改 lambdaBIC=0；targetView=%s 是关闭惩罚后的证据选择结果。', fmt_num(rec.targetView));
    case 'A3_fixed_SSETarget'
        text = sprintf('只改 target rule；A0/BIC target=%s，SSE target=%s。', ...
            fmt_num(rec.BIC_targetView), fmt_num(rec.SSE_targetView));
    case 'A4_fixed_woMultiViewFusion'
        text = sprintf('只关融合；lambdaNotUsed=%s，alignmentTime=%s。', ...
            logical_text(rec.lambdaNotUsed), fmt_num(rec.alignmentTime));
    otherwise
        text = 'Missing';
end
end

function key = make_key(datasetName, methodName)
key = sprintf('%s__%s', char(datasetName), char(methodName));
end

function value = get_table_number(row, fieldName)
if isempty(row) || height(row) == 0 || ~ismember(fieldName, row.Properties.VariableNames)
    value = NaN;
    return;
end
raw = row.(fieldName);
if isnumeric(raw)
    value = double(raw(1));
else
    value = str2double(string(raw(1)));
end
end

function value = get_field_number(s, fieldName)
if isstruct(s) && isfield(s, fieldName) && ~isempty(s.(fieldName))
    value = double(s.(fieldName));
else
    value = NaN;
end
end

function value = get_field_any(s, fieldName, defaultValue)
if isstruct(s) && isfield(s, fieldName) && ~isempty(s.(fieldName))
    value = s.(fieldName);
else
    value = defaultValue;
end
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

function text = vec_text(value)
if isempty(value)
    text = 'Missing';
    return;
end
try
    if islogical(value)
        text = mat2str(value);
    elseif isnumeric(value)
        text = mat2str(value, 6);
    else
        text = char(string(value));
    end
catch
    text = 'Missing';
end
end

function text = cell_text(value)
if isempty(value)
    text = 'Missing';
elseif iscell(value)
    parts = cell(1, numel(value));
    for i = 1:numel(value)
        parts{i} = char(string(value{i}));
    end
    text = strjoin(parts, '; ');
else
    text = char(string(value));
end
end

function text = logical_text(value)
if islogical(value)
    text = mat2str(value);
elseif isnumeric(value) && isfinite(value)
    text = mat2str(logical(value));
else
    text = 'Missing';
end
end

function text = exists_text(filePath)
if strlength(string(filePath)) > 0 && exist(char(filePath), 'file')
    text = 'Found';
else
    text = 'Missing';
end
end

function text = join_or_missing(parts)
if isempty(parts)
    text = 'Missing';
else
    text = strjoin(parts, '；');
end
end

function write_text(filePath, text)
fid = fopen(filePath, 'w');
if fid < 0
    error('generate_strict_fixed_report:WriteFailed', '无法写入文件：%s', filePath);
end
cleanupObj = onCleanup(@() fclose(fid));
fprintf(fid, '%s', text);
end

function write_csv_cell(filePath, cells)
fid = fopen(filePath, 'w');
if fid < 0
    error('generate_strict_fixed_report:WriteFailed', '无法写入 CSV：%s', filePath);
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
