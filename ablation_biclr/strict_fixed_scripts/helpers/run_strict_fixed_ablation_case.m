function result = run_strict_fixed_ablation_case(ablationType, datasetName)
%RUN_STRICT_FIXED_ABLATION_CASE 执行 fixed-parameter strict ablation。
%   RESULT = RUN_STRICT_FIXED_ABLATION_CASE(ABLATIONTYPE, DATASETNAME)
%   从 3AMVC-main/res_biclr_refined 读取对应数据集的 A0 best 配置，不执行
%   grid search，只改变一个消融模块并保存结果到 ablation_biclr/res_strict_fixed。
%
%   输入参数：
%   ablationType : 'A1_fixed_woBIC'、'A3_fixed_SSETarget' 或
%                  'A4_fixed_woMultiViewFusion'。
%   datasetName  : 'Mfeat'、'Reuters-1200'、'WIKI'、'ForestTypes' 或
%                  'Caltech256'。
%
%   输出参数：
%   result : 严格消融结果结构体，包含固定配置、唯一变化项、均值/标准差、
%            best run 指标、锚点机制指标和保存路径。
%
%   注意事项：
%   本函数只在 strict_fixed_scripts 与 res_strict_fixed 下新增文件，不覆盖
%   ablation_biclr/res 中已有网格消融结果。

if nargin < 2
    error('run_strict_fixed_ablation_case:MissingInput', ...
        '必须提供 ablationType 和 datasetName。');
end

paths = strict_project_paths();
addpath(genpath(paths.mainRoot));
addpath(genpath(fullfile(paths.ablationRoot, 'configs')));
addpath(genpath(fullfile(paths.ablationRoot, 'utils')));
addpath(paths.helperRoot);

datasetInfo = strict_dataset_info(datasetName, paths);
fixedConfig = load_a0_best_fixed_config(datasetInfo, paths);
[runConfig, changedOnly, methodSettings] = build_strict_run_config(ablationType, fixedConfig);

fprintf('\n[严格消融] dataset=%s, method=%s\n', datasetInfo.standardName, ablationType);
fprintf('[严格消融] 参数来自：%s\n', fixedConfig.sourceFile);
fprintf('[严格消融] fixedConfig: beta=%g, lambda=%g, lambdaBIC=%g, minNodeSize=%d, numRuns=%d, seed=%d, A0_targetView=%d\n', ...
    fixedConfig.beta, fixedConfig.lambda, fixedConfig.lambdaBIC, fixedConfig.minNodeSize, ...
    fixedConfig.numRuns, fixedConfig.randomSeed, fixedConfig.targetView);
fprintf('[严格消融] changedOnly: %s\n', changedOnly);

totalTimer = tic;
rng(runConfig.randomSeed, 'twister');

[X, Y, meta] = load_biclr_dataset(datasetInfo.canonicalName, struct( ...
    'rootDir', paths.mainRoot, ...
    'preprocessTag', runConfig.preprocessTag, ...
    'verbose', true, ...
    'removeClutter', runConfig.removeClutter, ...
    'maxPerClass', runConfig.maxPerClass));

anchorOptions = runConfig.anchorOptions;
anchorOptions.lambdaBIC = runConfig.lambdaBIC;
anchorOptions.minNodeSize = runConfig.minNodeSize;
anchorOptions.tauSplit = runConfig.tauSplit;
anchorOptions.epsVar = runConfig.epsVar;
anchorOptions.randomSeed = runConfig.randomSeed;
anchorOptions.verbose = false;

anchorPack = strict_prepare_anchor_pack(X, Y, meta, datasetInfo, paths, anchorOptions);
targetInfo = strict_select_target_view(anchorPack, methodSettings.targetSelectionMethod);

modelTimer = tic;
if methodSettings.useMultiViewFusion
    [U, ~, ~, iter, obj, traceInfo] = algo_qp(X, Y, anchorPack.thetaall, ...
        runConfig.beta, runConfig.lambda, targetInfo.targetView);
    modelTime = toc(modelTimer);
    alignmentTime = modelTime;
    lambdaForRecord = runConfig.lambda;
else
    targetTheta = anchorPack.thetaall{targetInfo.targetView};
    model = run_single_view_anchor_clustering(X{targetInfo.targetView}, Y, targetTheta, ...
        runConfig.beta, struct());
    U = model.U;
    iter = model.iter;
    obj = model.obj;
    traceInfo = model.traceInfo;
    modelTime = toc(modelTimer);
    alignmentTime = 0;
    lambdaForRecord = runConfig.lambda;
end

evalOptions = struct();
evalOptions.numRuns = runConfig.numRuns;
evalOptions.kmeansReplicates = runConfig.kmeansReplicates;
evalOptions.useParallel = false;
evalOptions.baseSeed = runConfig.randomSeed;
evalOptions.summaryMode = 'mean';

evalTimer = tic;
[~, metricStd, evalInfo] = myNMIACCwithmean(U, Y, meta.numClusters, evalOptions);
evalTime = toc(evalTimer);
totalTime = toc(totalTimer);

result = build_result_struct(ablationType, datasetInfo, fixedConfig, runConfig, ...
    changedOnly, methodSettings, targetInfo, anchorPack, evalInfo, metricStd, ...
    iter, obj, traceInfo, modelTime, alignmentTime, evalTime, totalTime, lambdaForRecord);

[matPath, txtPath] = save_strict_result(result, paths, datasetInfo, ablationType);
result.resultMatPath = matPath;
result.resultTextPath = txtPath;
save(matPath, 'result', '-v7.3');
write_strict_text_summary(txtPath, result);

fprintf('[严格消融] 已保存 MAT：%s\n', matPath);
fprintf('[严格消融] 已保存摘要：%s\n', txtPath);
end

function paths = strict_project_paths()
helperRoot = fileparts(mfilename('fullpath'));
strictRoot = fileparts(helperRoot);
ablationRoot = fileparts(strictRoot);
repoRoot = fileparts(ablationRoot);
paths = struct();
paths.helperRoot = helperRoot;
paths.strictRoot = strictRoot;
paths.ablationRoot = ablationRoot;
paths.repoRoot = repoRoot;
paths.mainRoot = fullfile(repoRoot, '3AMVC-main');
paths.dataRoot = fullfile(paths.mainRoot, 'dataset');
paths.strictResRoot = fullfile(ablationRoot, 'res_strict_fixed');
if ~exist(paths.mainRoot, 'dir')
    error('run_strict_fixed_ablation_case:MissingMainRoot', ...
        '未找到 3AMVC-main 目录：%s', paths.mainRoot);
end
end

function datasetInfo = strict_dataset_info(datasetName, paths)
key = lower(regexprep(char(datasetName), '[^a-zA-Z0-9]+', ''));
datasetInfo = struct();
datasetInfo.inputName = char(datasetName);
switch key
    case {'mfeat', 'mfeat2views'}
        datasetInfo.standardName = 'Mfeat';
        datasetInfo.fileToken = 'Mfeat';
        datasetInfo.canonicalName = 'MFeat_2Views';
        datasetInfo.resultDirName = 'Mfeat';
        datasetInfo.a0MatName = 'MFeat_2Views_BICLR_refined_best_ACC.mat';
        datasetInfo.a0TextName = 'MFeat_2Views_BICLR_refined_best_ACC.txt';
    case {'reuters1200', 'reuters', 'ruter1200'}
        datasetInfo.standardName = 'Reuters-1200';
        datasetInfo.fileToken = 'Reuters1200';
        datasetInfo.canonicalName = 'Reuters-1200';
        datasetInfo.resultDirName = 'Ruter1200';
        datasetInfo.a0MatName = 'Reuters_1200_BICLR_refined_best_ACC.mat';
        datasetInfo.a0TextName = 'Reuters_1200_BICLR_refined_best_ACC.txt';
    case {'wiki', 'wikifea'}
        datasetInfo.standardName = 'WIKI';
        datasetInfo.fileToken = 'WIKI';
        datasetInfo.canonicalName = 'Wikifea';
        datasetInfo.resultDirName = 'WIKI';
        datasetInfo.a0MatName = 'Wikifea_BICLR_refined_best_ACC.mat';
        datasetInfo.a0TextName = 'Wikifea_BICLR_refined_best_ACC.txt';
    case {'foresttypes', 'foresttype', 'forest'}
        datasetInfo.standardName = 'ForestTypes';
        datasetInfo.fileToken = 'ForestTypes';
        datasetInfo.canonicalName = 'ForestTypes';
        datasetInfo.resultDirName = 'ForestTypes';
        datasetInfo.a0MatName = 'ForestTypes_BICLR_refined_best_ACC.mat';
        datasetInfo.a0TextName = 'ForestTypes_BICLR_refined_best_ACC.txt';
    case {'caltech256', 'caltech2564views257clswithclutter', 'caltech256withclutter'}
        datasetInfo.standardName = 'Caltech256';
        datasetInfo.fileToken = 'Caltech256';
        datasetInfo.canonicalName = 'Caltech256_4Views_257cls_withClutter';
        datasetInfo.resultDirName = 'Caltech256_4Views_257cls_withClutter';
        datasetInfo.a0MatName = '';
        datasetInfo.a0TextName = 'Caltech256_4Views_257cls_withClutter_BICLR_refined_best_ACC.txt';
    otherwise
        error('run_strict_fixed_ablation_case:UnsupportedDataset', ...
            '不支持的数据集：%s', datasetName);
end
datasetInfo.dataFile = fullfile(paths.dataRoot, [datasetInfo.canonicalName '.mat']);
if ~exist(datasetInfo.dataFile, 'file')
    error('run_strict_fixed_ablation_case:MissingDataset', ...
        '未找到数据集文件：%s', datasetInfo.dataFile);
end
end

function fixedConfig = load_a0_best_fixed_config(datasetInfo, paths)
fixedConfig = struct();
fixedConfig.dataset = datasetInfo.standardName;
fixedConfig.canonicalName = datasetInfo.canonicalName;
fixedConfig.dataFile = datasetInfo.dataFile;
fixedConfig.fixedFrom = 'A0_best_res_biclr_refined';
fixedConfig.targetSelectionMethod = 'BICUnitEvidence';
fixedConfig.removeClutter = false;
fixedConfig.maxPerClass = [];
fixedConfig.preprocessTag = 'raw';
fixedConfig.anchorOptions = struct('tauSplit', 0, 'epsVar', 1e-8, ...
    'maxAnchors', 400, 'verbose', false, 'randomSeed', 1);
fixedConfig.kmeansReplicates = 3;

try
    gridConfig = build_biclr_refined_config(datasetInfo.canonicalName, 1);
    fixedConfig.anchorOptions = gridConfig.anchorOptions;
    fixedConfig.removeClutter = gridConfig.removeClutter;
    fixedConfig.maxPerClass = gridConfig.maxPerClass;
    fixedConfig.preprocessTag = gridConfig.preprocessTag;
    fixedConfig.kmeansReplicates = gridConfig.evalOptions.kmeansReplicates;
catch
end

textPath = fullfile(paths.mainRoot, 'res_biclr_refined', datasetInfo.a0TextName);
matPath = fullfile(paths.mainRoot, 'res_biclr_refined', datasetInfo.a0MatName);
if exist(textPath, 'file')
    parsed = parse_a0_text_config(textPath);
    fixedConfig.sourceFile = textPath;
elseif ~isempty(datasetInfo.a0MatName) && exist(matPath, 'file')
    parsed = parse_a0_mat_config(matPath);
    fixedConfig.sourceFile = matPath;
else
    write_config_missing_report(paths.strictRoot, datasetInfo, {'A0 best mat/txt 文件缺失'});
    error('run_strict_fixed_ablation_case:MissingA0Config', ...
        '未找到 %s 的 A0 best 配置文件。', datasetInfo.standardName);
end

fields = fieldnames(parsed);
for i = 1:numel(fields)
    fixedConfig.(fields{i}) = parsed.(fields{i});
end
if ~isfield(fixedConfig, 'epsVar') || isempty(fixedConfig.epsVar) || isnan(fixedConfig.epsVar)
    fixedConfig.epsVar = fixedConfig.anchorOptions.epsVar;
end
if ~isfield(fixedConfig, 'tauSplit') || isempty(fixedConfig.tauSplit) || isnan(fixedConfig.tauSplit)
    fixedConfig.tauSplit = fixedConfig.anchorOptions.tauSplit;
end
if ~isfield(fixedConfig, 'randomSeed') || isempty(fixedConfig.randomSeed) || isnan(fixedConfig.randomSeed)
    fixedConfig.randomSeed = fixedConfig.anchorOptions.randomSeed;
end
if ~isfield(fixedConfig, 'numRuns') || isempty(fixedConfig.numRuns) || isnan(fixedConfig.numRuns)
    write_config_missing_report(paths.strictRoot, datasetInfo, {'numRuns 缺失'});
    error('run_strict_fixed_ablation_case:MissingA0ConfigField', ...
        '%s 的 A0 best 配置缺少 numRuns。', datasetInfo.standardName);
end
if ~isfield(fixedConfig, 'kmeansReplicates') || isempty(fixedConfig.kmeansReplicates) || isnan(fixedConfig.kmeansReplicates)
    fixedConfig.kmeansReplicates = 3;
end

requiredFields = {'beta', 'lambda', 'lambdaBIC', 'minNodeSize', 'targetView', 'randomSeed'};
missing = {};
for i = 1:numel(requiredFields)
    name = requiredFields{i};
    if ~isfield(fixedConfig, name) || isempty(fixedConfig.(name)) || isnan(fixedConfig.(name))
        missing{end + 1} = name; %#ok<AGROW>
    end
end
if ~isempty(missing)
    write_config_missing_report(paths.strictRoot, datasetInfo, missing);
    error('run_strict_fixed_ablation_case:MissingA0ConfigField', ...
        '%s 的 A0 best 配置缺少字段：%s。', datasetInfo.standardName, strjoin(missing, ', '));
end

fixedConfig.anchorOptions.lambdaBIC = fixedConfig.lambdaBIC;
fixedConfig.anchorOptions.minNodeSize = fixedConfig.minNodeSize;
fixedConfig.anchorOptions.tauSplit = fixedConfig.tauSplit;
fixedConfig.anchorOptions.epsVar = fixedConfig.epsVar;
fixedConfig.anchorOptions.randomSeed = fixedConfig.randomSeed;
end

function parsed = parse_a0_text_config(textPath)
text = fileread(textPath);
block = regexp(text, '【一、按重复评价均值\+标准差上界 ACC 最高】(?<body>[\s\S]*?)(?=【二、|$)', 'names', 'once');
if isempty(block)
    block.body = text;
end
body = block.body;
parsed = struct();
parsed.beta = parse_number(body, 'beta');
parsed.lambda = parse_number(body, 'lambda');
parsed.lambdaBIC = parse_number(body, 'lambdaBIC');
parsed.minNodeSize = parse_number(body, 'minNodeSize');
parsed.tauSplit = parse_number(body, 'tauSplit');
parsed.epsVar = parse_number(body, 'epsVar');
parsed.randomSeed = parse_number(body, 'randomSeed');
parsed.numRuns = parse_number(body, 'numRuns');
parsed.kmeansReplicates = parse_number(body, 'kmeansReplicates');
parsed.targetView = parse_number(body, 'targetView');
parsed.anchorCounts = parse_vector_after_label(body, 'anchorCounts');
parsed.evalSummaryMode = parse_text_after_label(body, 'evalSummaryMode');
end

function parsed = parse_a0_mat_config(matPath)
loaded = load(matPath);
if isfield(loaded, 'bestInfo')
    b = loaded.bestInfo;
    if isfield(b, 'bestUpper') && ~isempty(b.bestUpper)
        b = b.bestUpper;
    end
else
    b = loaded;
end
parsed = struct();
parsed.beta = get_field_number(b, 'beta');
parsed.lambda = get_field_number(b, 'lambda');
parsed.lambdaBIC = get_field_number(b, 'lambdaBIC');
parsed.minNodeSize = get_field_number(b, 'minNodeSize');
parsed.tauSplit = get_field_number(b, 'tauSplit');
parsed.epsVar = get_field_number(b, 'epsVar');
parsed.randomSeed = get_field_number(b, 'randomSeed');
parsed.numRuns = get_field_number(b, 'numRuns');
parsed.kmeansReplicates = get_field_number(b, 'kmeansReplicates');
parsed.targetView = get_field_number(b, 'targetView');
parsed.anchorCounts = get_field_any(b, 'anchorCounts', []);
parsed.evalSummaryMode = get_field_any(b, 'evalSummaryMode', '');
end

function [runConfig, changedOnly, methodSettings] = build_strict_run_config(ablationType, fixedConfig)
if isstring(ablationType)
    ablationType = char(ablationType);
end
runConfig = fixedConfig;
methodSettings = struct();
methodSettings.ablationType = ablationType;
methodSettings.targetSelectionMethod = fixedConfig.targetSelectionMethod;
methodSettings.useMultiViewFusion = true;
methodSettings.lambdaNotUsed = false;

switch ablationType
    case 'A1_fixed_woBIC'
        runConfig.lambdaBIC = 0;
        methodSettings.targetSelectionMethod = fixedConfig.targetSelectionMethod;
        methodSettings.useMultiViewFusion = true;
        changedOnly = sprintf('仅关闭 BIC 复杂度惩罚：lambdaBIC 从 %g 改为 0；不重新搜索参数。', fixedConfig.lambdaBIC);
    case 'A3_fixed_SSETarget'
        methodSettings.targetSelectionMethod = 'SSEMin';
        methodSettings.useMultiViewFusion = true;
        changedOnly = '仅将目标视图选择准则从 BICUnitEvidence 改为 SSEMin；不重新搜索参数。';
    case 'A4_fixed_woMultiViewFusion'
        methodSettings.targetSelectionMethod = fixedConfig.targetSelectionMethod;
        methodSettings.useMultiViewFusion = false;
        methodSettings.lambdaNotUsed = true;
        changedOnly = '仅关闭多视图对齐融合，使用目标视图单视图锚图聚类；lambda 记录但不参与计算。';
    otherwise
        error('run_strict_fixed_ablation_case:UnsupportedAblation', ...
            '未知严格消融类型：%s', ablationType);
end
end

function anchorPack = strict_prepare_anchor_pack(X, Y, meta, datasetInfo, paths, anchorOptions)
numViews = numel(X);
thetaall = cell(numViews, 1);
objectAll = cell(numViews, 1);
labelAll = cell(numViews, 1);
infoAll = cell(numViews, 1);
cacheFiles = cell(numViews, 1);
cacheHit = false(numViews, 1);
cacheSource = cell(numViews, 1);
anchorTimePerView = zeros(numViews, 1);

for iv = 1:numViews
    cacheFile = find_readonly_anchor_cache(paths, datasetInfo, meta, iv, anchorOptions);
    if ~isempty(cacheFile)
        loaded = load(cacheFile);
        [thetaall{iv}, objectAll{iv}, labelAll{iv}, infoAll{iv}] = read_anchor_cache(loaded);
        cacheFiles{iv} = cacheFile;
        cacheHit(iv) = true;
        cacheSource{iv} = 'readonly_existing_cache';
    else
        timerAnchor = tic;
        [~, ~, label_neighbor, object, theta, ~, info] = Neighbor_BICLR(X{iv}, Y, anchorOptions);
        anchorTimePerView(iv) = toc(timerAnchor);
        thetaall{iv} = theta;
        objectAll{iv} = object;
        labelAll{iv} = label_neighbor;
        infoAll{iv} = info;
        cacheFiles{iv} = '';
        cacheSource{iv} = 'generated_without_cache_write';
    end
    infoAll{iv} = ensure_view_evidence_for_options(X{iv}, objectAll{iv}, labelAll{iv}, infoAll{iv}, anchorOptions);
end

[bicTargetView, ~, bicUnitGains] = biclr_select_target_view(infoAll);
totalSSEPerView = zeros(numViews, 1);
anchorCounts = zeros(numViews, 1);
acceptedSplits = zeros(numViews, 1);
rejectedSplits = zeros(numViews, 1);
meanLeafSize = zeros(numViews, 1);
maxDepth = zeros(numViews, 1);
for iv = 1:numViews
    info = infoAll{iv};
    totalSSEPerView(iv) = get_info_scalar(info, 'totalSSE', sum(objectAll{iv}));
    anchorCounts(iv) = get_info_scalar(info, 'numAnchors', size(thetaall{iv}, 1));
    acceptedSplits(iv) = get_info_scalar(info, 'acceptedSplits', NaN);
    rejectedSplits(iv) = get_info_scalar(info, 'rejectedSplits', NaN);
    maxDepth(iv) = get_info_scalar(info, 'maxDepth', NaN);
    if isfield(info, 'anchorSizes') && ~isempty(info.anchorSizes)
        meanLeafSize(iv) = mean(double(info.anchorSizes(:)));
    else
        meanLeafSize(iv) = NaN;
    end
end

anchorPack = struct();
anchorPack.thetaall = thetaall;
anchorPack.objectAll = objectAll;
anchorPack.labelAll = labelAll;
anchorPack.infoAll = infoAll;
anchorPack.bicTargetView = bicTargetView;
anchorPack.bicUnitGains = bicUnitGains(:)';
anchorPack.totalSSEPerView = totalSSEPerView(:)';
anchorPack.anchorCounts = anchorCounts(:)';
anchorPack.avgAnchors = mean(anchorCounts);
anchorPack.acceptedSplits = acceptedSplits(:)';
anchorPack.rejectedSplits = rejectedSplits(:)';
anchorPack.meanLeafSize = meanLeafSize(:)';
anchorPack.maxDepth = maxDepth(:)';
anchorPack.anchorTime = sum(anchorTimePerView);
anchorPack.anchorTimePerView = anchorTimePerView(:)';
anchorPack.cacheFiles = cacheFiles(:)';
anchorPack.cacheHit = cacheHit(:)';
anchorPack.cacheSource = cacheSource(:)';
end

function targetInfo = strict_select_target_view(anchorPack, targetSelectionMethod)
targetInfo = struct();
targetInfo.BIC_targetView = anchorPack.bicTargetView;
[~, targetInfo.SSE_targetView] = min(anchorPack.totalSSEPerView);
switch targetSelectionMethod
    case 'BICUnitEvidence'
        targetInfo.targetView = targetInfo.BIC_targetView;
    case 'SSEMin'
        targetInfo.targetView = targetInfo.SSE_targetView;
    otherwise
        error('run_strict_fixed_ablation_case:UnknownTargetSelection', ...
            '未知目标视图选择准则：%s', targetSelectionMethod);
end
targetInfo.targetSelectionMethod = targetSelectionMethod;
end

function cacheFile = find_readonly_anchor_cache(paths, datasetInfo, meta, viewIndex, anchorOptions)
cacheFile = '';
searchDirs = { ...
    fullfile(paths.mainRoot, 'cache'), ...
    fullfile(paths.ablationRoot, 'cache', 'A1_woBIC_Joint'), ...
    fullfile(paths.ablationRoot, 'cache', 'A3_SSETarget'), ...
    fullfile(paths.ablationRoot, 'cache', 'A4_woMultiViewFusion')};
requiredTokens = { ...
    sprintf('view%d', viewIndex), ...
    ['lambic' sanitize_numeric(anchorOptions.lambdaBIC)], ...
    sprintf('minnode%d', anchorOptions.minNodeSize), ...
    sprintf('seed%d', anchorOptions.randomSeed)};
datasetTokens = unique(lower({ ...
    sanitize_key(datasetInfo.standardName), ...
    sanitize_key(datasetInfo.resultDirName), ...
    sanitize_key(datasetInfo.canonicalName), ...
    sanitize_key(meta.datasetName)}));

bestPath = '';
bestScore = -inf;
for idir = 1:numel(searchDirs)
    if ~exist(searchDirs{idir}, 'dir')
        continue;
    end
    files = dir(fullfile(searchDirs{idir}, '*.mat'));
    for i = 1:numel(files)
        nameLower = lower(files(i).name);
        if ~contains_any(nameLower, datasetTokens)
            continue;
        end
        ok = true;
        score = 0;
        for t = 1:numel(requiredTokens)
            if contains(nameLower, requiredTokens{t})
                score = score + 1;
            else
                ok = false;
                break;
            end
        end
        if ok && score > bestScore
            bestScore = score;
            bestPath = fullfile(files(i).folder, files(i).name);
        end
    end
end
if ~isempty(bestPath)
    cacheFile = bestPath;
end
end

function tf = contains_any(textValue, tokens)
tf = false;
for i = 1:numel(tokens)
    if contains(textValue, tokens{i})
        tf = true;
        return;
    end
end
end

function [theta, object, label_neighbor, info] = read_anchor_cache(loaded)
required = {'theta', 'object', 'label_neighbor', 'info'};
for i = 1:numel(required)
    if ~isfield(loaded, required{i})
        error('run_strict_fixed_ablation_case:InvalidCache', ...
            '锚点缓存缺少字段：%s。', required{i});
    end
end
theta = loaded.theta;
object = loaded.object;
label_neighbor = loaded.label_neighbor;
info = loaded.info;
end

function info = ensure_view_evidence_for_options(Xv, object, label_neighbor, info, anchorOptions)
if nargin < 4 || isempty(info)
    info = struct();
end
if ~isfield(info, 'anchorSizes') || isempty(info.anchorSizes)
    info.anchorSizes = accumarray(double(label_neighbor(:)), 1);
end
if ~isfield(info, 'totalSSE') || isempty(info.totalSSE)
    info.totalSSE = sum(object);
end
info.options = anchorOptions;
info.viewEvidence = biclr_view_evidence(Xv, object, info.anchorSizes, anchorOptions);
info.qualityMethod = 'BICUnitEvidenceGain';
info.qualityScore = info.viewEvidence.qualityScore;
info.unitBICEvidence = info.viewEvidence.unitGain;
info.relativeBICEvidence = info.viewEvidence.unitGain;
info.bicEvidenceGain = info.viewEvidence.deltaBIC;
end

function result = build_result_struct(ablationType, datasetInfo, fixedConfig, runConfig, ...
    changedOnly, methodSettings, targetInfo, anchorPack, evalInfo, metricStd, ...
    iter, obj, traceInfo, modelTime, alignmentTime, evalTime, totalTime, lambdaForRecord)
metricMean = evalInfo.meanMetrics;
bestMetrics = evalInfo.bestRunMetrics;

result = struct();
result.method = ablationType;
result.dataset = datasetInfo.standardName;
result.ablationType = ablationType;
result.isStrictFixedAblation = true;
result.fixedFrom = 'A0_best_res_biclr_refined';
result.fixedConfig = fixedConfig;
result.changedOnly = changedOnly;
result.ACC_mean = metricMean(1);
result.NMI_mean = metricMean(2);
result.AR_mean = metricMean(7);
result.ACC_std = metricStd(1);
result.NMI_std = metricStd(2);
result.AR_std = metricStd(7);
result.ACC_best = bestMetrics(1);
result.NMI_best = bestMetrics(2);
result.AR_best = bestMetrics(7);
result.numRuns = runConfig.numRuns;
result.seed = runConfig.randomSeed;
result.anchorCounts = anchorPack.anchorCounts;
result.avgAnchors = anchorPack.avgAnchors;
result.targetView = targetInfo.targetView;
result.A0_targetView = fixedConfig.targetView;
result.SSE_targetView = targetInfo.SSE_targetView;
result.BIC_targetView = targetInfo.BIC_targetView;
result.acceptedSplits = anchorPack.acceptedSplits;
result.rejectedSplits = anchorPack.rejectedSplits;
result.meanLeafSize = anchorPack.meanLeafSize;
result.maxDepth = anchorPack.maxDepth;
result.anchorTime = anchorPack.anchorTime;
result.anchorTimePerView = anchorPack.anchorTimePerView;
result.alignmentTime = alignmentTime;
result.modelTime = modelTime;
result.evalTime = evalTime;
result.totalTime = totalTime;
result.lambdaNotUsed = methodSettings.lambdaNotUsed;
result.beta = runConfig.beta;
result.lambda = lambdaForRecord;
result.lambdaBIC = runConfig.lambdaBIC;
result.minNodeSize = runConfig.minNodeSize;
result.tauSplit = runConfig.tauSplit;
result.epsVar = runConfig.epsVar;
result.targetSelectionMethod = methodSettings.targetSelectionMethod;
result.useMultiViewFusion = methodSettings.useMultiViewFusion;
result.numGridConfigs = 1;
result.numSeeds = 1;
result.searchBudget = runConfig.numRuns;
result.selectionRule = 'fixed_A0_best_no_grid_search';
result.evalBestRunIndex = evalInfo.bestRunIndex;
result.evalBestRunSeed = evalInfo.bestRunSeed;
result.evalAllMetrics = evalInfo.allMetrics;
result.iter = iter;
result.objFinal = obj(end);
result.objTrace = obj(:)';
if isfield(traceInfo, 'objectiveTraceForPlot')
    result.objectiveTraceForPlot = traceInfo.objectiveTraceForPlot(:)';
else
    result.objectiveTraceForPlot = [];
end
result.cacheHit = anchorPack.cacheHit;
result.cacheFiles = anchorPack.cacheFiles;
result.cacheSource = anchorPack.cacheSource;
result.notes = build_result_notes(ablationType, methodSettings);
end

function notes = build_result_notes(ablationType, methodSettings)
switch ablationType
    case 'A1_fixed_woBIC'
        notes = ['fixed-parameter strict ablation；参数来自 A0 best；不执行 grid search；' ...
            '仅通过 lambdaBIC=0 关闭 BIC 复杂度惩罚，目标视图选择规则保持 A0 的 BICUnitEvidence 口径。'];
    case 'A3_fixed_SSETarget'
        notes = ['fixed-parameter strict ablation；参数来自 A0 best；不执行 grid search；' ...
            '仅将目标视图选择准则改为 SSEMin，同时保存 A0/BIC targetView 与 SSE targetView。'];
    case 'A4_fixed_woMultiViewFusion'
        notes = ['fixed-parameter strict ablation；参数来自 A0 best；不执行 grid search；' ...
            '仅关闭多视图对齐融合，lambda 保存但不参与计算，alignmentTime 记为 0。'];
    otherwise
        notes = sprintf('fixed-parameter strict ablation；targetSelection=%s。', methodSettings.targetSelectionMethod);
end
end

function [matPath, txtPath] = save_strict_result(~, paths, datasetInfo, ablationType)
saveDir = fullfile(paths.strictResRoot, ablationType, datasetInfo.fileToken);
if ~exist(saveDir, 'dir')
    mkdir(saveDir);
end
timestamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
baseName = sprintf('%s_%s_%s', ablationType, datasetInfo.fileToken, timestamp);
matPath = fullfile(saveDir, [baseName '.mat']);
txtPath = fullfile(saveDir, [baseName '.txt']);
end

function write_strict_text_summary(txtPath, result)
fid = fopen(txtPath, 'w');
if fid < 0
    error('run_strict_fixed_ablation_case:WriteFailed', ...
        '无法写入结果摘要：%s', txtPath);
end
cleanupObj = onCleanup(@() fclose(fid));
fprintf(fid, 'fixed-parameter strict ablation 结果摘要\n');
fprintf(fid, 'method=%s\n', result.method);
fprintf(fid, 'dataset=%s\n', result.dataset);
fprintf(fid, 'fixedFrom=%s\n', result.fixedFrom);
fprintf(fid, 'changedOnly=%s\n', result.changedOnly);
fprintf(fid, 'beta=%g\n', result.beta);
fprintf(fid, 'lambda=%g\n', result.lambda);
fprintf(fid, 'lambdaBIC=%g\n', result.lambdaBIC);
fprintf(fid, 'minNodeSize=%d\n', result.minNodeSize);
fprintf(fid, 'numRuns=%d\n', result.numRuns);
fprintf(fid, 'seed=%d\n', result.seed);
fprintf(fid, 'targetView=%d\n', result.targetView);
fprintf(fid, 'A0_targetView=%d\n', result.A0_targetView);
fprintf(fid, 'BIC_targetView=%d\n', result.BIC_targetView);
fprintf(fid, 'SSE_targetView=%d\n', result.SSE_targetView);
fprintf(fid, 'anchorCounts=%s\n', mat2str(result.anchorCounts));
fprintf(fid, 'avgAnchors=%.6f\n', result.avgAnchors);
fprintf(fid, 'acceptedSplits=%s\n', mat2str(result.acceptedSplits));
fprintf(fid, 'rejectedSplits=%s\n', mat2str(result.rejectedSplits));
fprintf(fid, 'meanLeafSize=%s\n', mat2str(result.meanLeafSize, 6));
fprintf(fid, 'maxDepth=%s\n', mat2str(result.maxDepth));
fprintf(fid, 'ACC_mean=%.6f, ACC_std=%.6f, ACC_best=%.6f\n', result.ACC_mean, result.ACC_std, result.ACC_best);
fprintf(fid, 'NMI_mean=%.6f, NMI_std=%.6f, NMI_best=%.6f\n', result.NMI_mean, result.NMI_std, result.NMI_best);
fprintf(fid, 'AR_mean=%.6f, AR_std=%.6f, AR_best=%.6f\n', result.AR_mean, result.AR_std, result.AR_best);
fprintf(fid, 'anchorTime=%.6f\n', result.anchorTime);
fprintf(fid, 'alignmentTime=%.6f\n', result.alignmentTime);
fprintf(fid, 'modelTime=%.6f\n', result.modelTime);
fprintf(fid, 'evalTime=%.6f\n', result.evalTime);
fprintf(fid, 'totalTime=%.6f\n', result.totalTime);
fprintf(fid, 'lambdaNotUsed=%d\n', result.lambdaNotUsed);
fprintf(fid, 'useMultiViewFusion=%d\n', result.useMultiViewFusion);
fprintf(fid, 'cacheHit=%s\n', mat2str(result.cacheHit));
fprintf(fid, 'notes=%s\n', result.notes);
end

function write_config_missing_report(strictRoot, datasetInfo, missing)
reportPath = fullfile(strictRoot, 'config_missing_report.md');
fid = fopen(reportPath, 'a');
if fid < 0
    return;
end
cleanupObj = onCleanup(@() fclose(fid));
fprintf(fid, '# A0 best 配置缺失报告\n\n');
fprintf(fid, '- 数据集：%s\n', datasetInfo.standardName);
fprintf(fid, '- 缺失字段或文件：%s\n', strjoin(missing, ', '));
fprintf(fid, '- 建议：检查 `3AMVC-main/res_biclr_refined` 中对应 `.mat` 或 `.txt` 摘要；若字段无法解析，请人工补全 beta/lambda/lambdaBIC/minNodeSize/targetView/numRuns/randomSeed。\n\n');
end

function value = parse_number(text, name)
expr = [regexptranslate('escape', name) '\s*=\s*([-+]?\d*\.?\d+(?:[eE][-+]?\d+)?)'];
token = regexp(text, expr, 'tokens', 'once');
if isempty(token)
    value = NaN;
else
    value = str2double(token{1});
end
end

function value = parse_text_after_label(text, name)
expr = [regexptranslate('escape', name) '\s*=\s*([^\r\n]+)'];
token = regexp(text, expr, 'tokens', 'once');
if isempty(token)
    value = '';
else
    value = strtrim(token{1});
end
end

function vec = parse_vector_after_label(text, name)
expr = [regexptranslate('escape', name) '\s*=\s*(\[[^\]]*\])'];
token = regexp(text, expr, 'tokens', 'once');
if isempty(token)
    vec = [];
    return;
end
try
    vec = str2num(token{1}); %#ok<ST2NM>
catch
    vec = [];
end
end

function value = get_field_number(s, name)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = double(s.(name));
else
    value = NaN;
end
end

function value = get_field_any(s, name, defaultValue)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end

function value = get_info_scalar(info, fieldName, defaultValue)
if isstruct(info) && isfield(info, fieldName) && ~isempty(info.(fieldName))
    value = double(info.(fieldName));
else
    value = defaultValue;
end
end

function key = sanitize_key(textValue)
key = lower(regexprep(char(textValue), '[^a-zA-Z0-9]+', '_'));
key = regexprep(key, '_+', '_');
key = regexprep(key, '^_|_$', '');
end

function textValue = sanitize_numeric(value)
textValue = lower(regexprep(sprintf('%.6g', value), '[^0-9a-zA-Z]+', 'p'));
end
