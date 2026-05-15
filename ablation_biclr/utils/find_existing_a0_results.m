function [resultSummary, allResults, sourcePath] = find_existing_a0_results(datasetName, config)
%FIND_EXISTING_A0_RESULTS 查找并引用 3AMVC-main 中已有 A0 结果。
%   [RESULTSUMMARY, ALLRESULTS, SOURCEPATH] = FIND_EXISTING_A0_RESULTS(DATASETNAME, CONFIG)
%   在 res_biclr、res_biclr_refined、analysis 等目录中搜索 A0_Full 结果，
%   并转换为 ablation_biclr 的统一 resultSummary 格式。
%
%   注意事项：
%   本函数只读取和复制引用摘要，不移动、不覆盖 3AMVC-main 下的原始结果。

if nargin < 2 || isempty(config)
    config = get_default_grid_config();
end

paths = get_project_paths();
datasetInfo = get_ablation_dataset_alias(datasetName);
sourcePath = '';
allResults = [];

candidateFiles = collect_a0_candidate_files(paths.mainCodeRoot, datasetInfo);
if isempty(candidateFiles)
    warning('find_existing_a0_results:NotFound', ...
        '未找到数据集 %s 的 A0 结果。已搜索 3AMVC-main 下 res_biclr/res_biclr_refined/analysis/grid/cache 等目录。', ...
        datasetInfo.displayName);
    resultSummary = make_empty_a0_summary(datasetInfo, config, paths, '');
    return;
end

[sourcePath, loaded] = load_first_valid_candidate(candidateFiles);
if isempty(sourcePath)
    warning('find_existing_a0_results:Unreadable', ...
        '找到候选 A0 文件但无法识别结果结构：%s。', strjoin(candidateFiles, '; '));
    resultSummary = make_empty_a0_summary(datasetInfo, config, paths, '');
    return;
end

[resultSummary, allResults] = convert_loaded_a0_result(loaded, datasetInfo, config, paths, sourcePath);

saveDir = fullfile(paths.resRoot, 'A0_Full_Reference', datasetInfo.resultDirName);
if ~exist(saveDir, 'dir')
    mkdir(saveDir);
end
timestamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
repoRoot = paths.repoRoot; %#ok<NASGU>
mainCodeRoot = paths.mainCodeRoot; %#ok<NASGU>
ablationRoot = paths.ablationRoot; %#ok<NASGU>
methodName = 'A0_Full_Reference'; %#ok<NASGU>
methodConfig = struct('methodName', methodName, ...
    'targetSelectionMethod', 'BICUnitEvidence', ...
    'useBICPenalty', true, ...
    'useBICLRAnchor', true, ...
    'useMultiViewFusion', true, ...
    'singleViewOnly', false); %#ok<NASGU>
resultSummary.resultSavePath = fullfile(saveDir, ...
    sprintf('A0_Full_Reference_%s_grid_%s.mat', datasetInfo.resultDirName, timestamp));
save(resultSummary.resultSavePath, 'allResults', 'resultSummary', 'config', ...
    'methodConfig', 'datasetInfo', 'timestamp', 'repoRoot', 'mainCodeRoot', 'ablationRoot', 'methodName');
latestPath = fullfile(saveDir, sprintf('A0_Full_Reference_%s_latest.mat', datasetInfo.resultDirName));
save(latestPath, 'allResults', 'resultSummary', 'config', ...
    'methodConfig', 'datasetInfo', 'timestamp', 'repoRoot', 'mainCodeRoot', 'ablationRoot', 'methodName');
end

function candidateFiles = collect_a0_candidate_files(mainCodeRoot, datasetInfo)
searchDirs = { ...
    fullfile(mainCodeRoot, 'res_biclr_refined'), ...
    fullfile(mainCodeRoot, 'res_biclr'), ...
    fullfile(mainCodeRoot, 'analysis'), ...
    fullfile(mainCodeRoot, 'grid_biclr_refined'), ...
    fullfile(mainCodeRoot, 'grid_biclr'), ...
    fullfile(mainCodeRoot, 'cache')};
tokens = unique({ ...
    lower(ablation_sanitize_key(datasetInfo.canonicalName)), ...
    lower(ablation_sanitize_key(datasetInfo.resultDirName)), ...
    lower(ablation_sanitize_key(strrep(datasetInfo.canonicalName, '-', '_'))), ...
    lower(ablation_sanitize_key(strrep(datasetInfo.canonicalName, '_', '-')))});

candidateFiles = {};
for idir = 1:numel(searchDirs)
    if ~exist(searchDirs{idir}, 'dir')
        continue;
    end
    files = recursive_mat_files(searchDirs{idir});
    for i = 1:numel(files)
        [~, baseName] = fileparts(files{i});
        baseLower = lower(baseName);
        if isempty(strfind(baseLower, 'biclr')) %#ok<STREMP>
            continue;
        end
        matched = false;
        for t = 1:numel(tokens)
            if ~isempty(tokens{t}) && ~isempty(strfind(baseLower, tokens{t})) %#ok<STREMP>
                matched = true;
                break;
            end
        end
        if matched
            candidateFiles{end + 1, 1} = files{i}; %#ok<AGROW>
        end
    end
end

if ~isempty(candidateFiles)
    [~, order] = sort(lower(candidateFiles));
    candidateFiles = candidateFiles(order);
    refinedMask = ~cellfun('isempty', strfind(lower(candidateFiles), lower('res_biclr_refined')));
    candidateFiles = [candidateFiles(refinedMask); candidateFiles(~refinedMask)];
end
end

function files = recursive_mat_files(rootDir)
entries = dir(rootDir);
files = {};
for i = 1:numel(entries)
    name = entries(i).name;
    if strcmp(name, '.') || strcmp(name, '..')
        continue;
    end
    fullPath = fullfile(rootDir, name);
    if entries(i).isdir
        files = [files; recursive_mat_files(fullPath)]; %#ok<AGROW>
    else
        [~, ~, ext] = fileparts(name);
        if strcmpi(ext, '.mat')
            files{end + 1, 1} = fullPath; %#ok<AGROW>
        end
    end
end
end

function [sourcePath, loaded] = load_first_valid_candidate(candidateFiles)
sourcePath = '';
loaded = struct();
for i = 1:numel(candidateFiles)
    try
        loadedCandidate = load(candidateFiles{i});
        if isfield(loadedCandidate, 'results') || isfield(loadedCandidate, 'resultSummary') ...
                || isfield(loadedCandidate, 'bestResult') || isfield(loadedCandidate, 'bestMean')
            sourcePath = candidateFiles{i};
            loaded = loadedCandidate;
            return;
        end
    catch
    end
end
end

function [resultSummary, allResults] = convert_loaded_a0_result(loaded, datasetInfo, config, paths, sourcePath)
source = [];
allResults = [];
if isfield(loaded, 'results')
    source = loaded.results;
    if isfield(source, 'records')
        allResults = source.records;
    end
elseif isfield(loaded, 'resultSummary')
    source = loaded.resultSummary;
    if isfield(loaded, 'allResults')
        allResults = loaded.allResults;
    end
else
    source = loaded;
end

bestRecord = extract_best_record(source);
resultSummary = make_empty_a0_summary(datasetInfo, config, paths, sourcePath);
resultSummary.source = 'existing_A0_result_from_3AMVC_main';
resultSummary.originalA0ResultPath = sourcePath;
resultSummary.foundExistingA0 = true;

if ~isempty(bestRecord)
    resultSummary.beta = get_field(bestRecord, 'beta', NaN);
    resultSummary.lambda = get_field(bestRecord, 'lambda', NaN);
    resultSummary.lambdaBIC = get_field(bestRecord, 'lambdaBIC', NaN);
    resultSummary.minNodeSize = get_field(bestRecord, 'minNodeSize', NaN);
    resultSummary.tauSplit = get_field(bestRecord, 'tauSplit', config.tauSplit);
    resultSummary.targetView = get_field(bestRecord, 'targetView', NaN);
    resultSummary.anchorCounts = get_field(bestRecord, 'anchorCounts', []);
    resultSummary.anchorEvidenceGain = get_field(bestRecord, 'anchorEvidenceGain', []);
    resultSummary.totalSSEPerView = get_field(bestRecord, 'anchorSSE', []);
    resultSummary.randomSeed = get_field(bestRecord, 'randomSeed', NaN);
    resultSummary.anchorTime = get_field(bestRecord, 'anchorTime', NaN);
    resultSummary.totalTime = get_field(bestRecord, 'totalTime', NaN);
    resultSummary.numRuns = get_field(bestRecord, 'numRuns', NaN);
    resultSummary.kmeansReplicates = get_field(bestRecord, 'kmeansReplicates', NaN);
    resultSummary.cacheKeys = get_field(bestRecord, 'cacheKeys', {});
    resultSummary.cacheFiles = get_field(bestRecord, 'cacheFiles', {});
    resultSummary.cacheHit = get_field(bestRecord, 'cacheHit', []);
    resultSummary.metricsMean = ablation_metrics_to_struct(get_field(bestRecord, 'evalMeanMetrics', get_field(bestRecord, 'metricsMean', [])));
    resultSummary.metricsStd = ablation_metrics_to_struct(get_field(bestRecord, 'evalStdMetrics', get_field(bestRecord, 'metricsStd', [])));
    resultSummary.selectedConfig = build_selected_config(resultSummary);
end

if isfield(source, 'records') && ~isempty(source.records)
    resultSummary.numGridConfigs = numel(source.records);
elseif ~isempty(allResults)
    resultSummary.numGridConfigs = numel(allResults);
else
    resultSummary.numGridConfigs = NaN;
end
resultSummary.searchBudget = resultSummary.numGridConfigs * max(numel(config.seeds), 1) * max(resultSummary.numRuns, 1);
resultSummary = ablation_fill_missing_result_fields(resultSummary);
end

function bestRecord = extract_best_record(source)
bestRecord = [];
candidateNames = {'bestMean', 'bestSummary', 'best', 'bestResult', 'selectedResult'};
for i = 1:numel(candidateNames)
    name = candidateNames{i};
    if isstruct(source) && isfield(source, name) && ~isempty(source.(name))
        bestRecord = source.(name);
        return;
    end
end
if isstruct(source) && isfield(source, 'records') && ~isempty(source.records)
    bestRecord = source.records(1);
end
end

function resultSummary = make_empty_a0_summary(datasetInfo, config, paths, sourcePath)
resultSummary = struct();
resultSummary.methodName = 'A0_Full_Reference';
resultSummary.datasetName = datasetInfo.resultDirName;
resultSummary.targetSelectionMethod = 'BICUnitEvidence';
resultSummary.useMultiViewFusion = true;
resultSummary.singleViewOnly = false;
resultSummary.selectionMetric = config.selectionMetric;
resultSummary.selectionRule = config.selectionRule;
resultSummary.sourceMainCodeRoot = paths.mainCodeRoot;
resultSummary.source = 'existing_A0_result_from_3AMVC_main';
resultSummary.originalA0ResultPath = sourcePath;
resultSummary.foundExistingA0 = false;
resultSummary.metricsMean = ablation_metrics_to_struct([]);
resultSummary.metricsStd = ablation_metrics_to_struct([]);
resultSummary.selectedConfig = struct();
resultSummary = ablation_fill_missing_result_fields(resultSummary);
end

function value = get_field(s, name, defaultValue)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
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
