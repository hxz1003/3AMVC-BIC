function anchorPack = prepare_biclr_ablation_anchors(X, Y, meta, datasetInfo, methodName, config, methodConfig, anchorOptions)
%PREPARE_BICLR_ABLATION_ANCHORS 为消融实验生成或读取 BIC-LR 锚点。
%   ANCHORPACK = PREPARE_BICLR_ABLATION_ANCHORS(X, Y, META, DATASETINFO,
%   METHODNAME, CONFIG, METHODCONFIG, ANCHOROPTIONS) 按视图读取 ablation
%   缓存、A0 主缓存或重新调用 Neighbor_BICLR。
%
%   注意事项：
%   1. A1 的 lambdaBIC 固定为 0，不能复用 A0 非零 lambdaBIC 缓存。
%   2. A3/A4 可优先读取 A0 锚点缓存；若找不到，则生成并保存到各自缓存。
%   3. 缓存键显式包含 dataset/method/view/lambdaBIC/minNodeSize/tau/seed/
%      targetSelectionMethod/useMultiViewFusion/preprocessTag。

paths = get_project_paths();
numViews = numel(X);
thetaall = cell(numViews, 1);
objectAll = cell(numViews, 1);
labelAll = cell(numViews, 1);
infoAll = cell(numViews, 1);
cacheKeys = cell(numViews, 1);
cacheFiles = cell(numViews, 1);
cacheSource = cell(numViews, 1);
cacheHit = false(numViews, 1);
anchorTimePerView = zeros(numViews, 1);

methodCacheDir = fullfile(paths.cacheRoot, methodName);
if config.useCache && ~exist(methodCacheDir, 'dir')
    mkdir(methodCacheDir);
end

for iv = 1:numViews
    cacheKey = make_ablation_anchor_cache_key(datasetInfo, methodName, iv, anchorOptions, methodConfig, config);
    cacheFile = fullfile(methodCacheDir, [cacheKey '.mat']);
    cacheKeys{iv} = cacheKey;
    cacheFiles{iv} = cacheFile;

    if config.useCache && exist(cacheFile, 'file')
        loaded = load(cacheFile);
        [thetaall{iv}, objectAll{iv}, labelAll{iv}, infoAll{iv}] = read_cached_anchor(loaded);
        cacheHit(iv) = true;
        cacheSource{iv} = 'ablation_cache';
    else
        a0CacheFile = '';
        if isfield(methodConfig, 'preferA0AnchorCache') && methodConfig.preferA0AnchorCache ...
                && anchorOptions.lambdaBIC > 0
            a0CacheFile = find_a0_anchor_cache(paths.mainCodeRoot, meta, iv, anchorOptions, config);
        end

        if config.useCache && ~isempty(a0CacheFile)
            loaded = load(a0CacheFile);
            [thetaall{iv}, objectAll{iv}, labelAll{iv}, infoAll{iv}] = read_cached_anchor(loaded);
            cacheHit(iv) = true;
            cacheSource{iv} = 'A0_main_cache';
            cacheFiles{iv} = a0CacheFile;
        else
            timerAnchor = tic;
            [~, ~, label_neighbor, object, theta, ~, info] = Neighbor_BICLR(X{iv}, Y, anchorOptions);
            anchorTimePerView(iv) = toc(timerAnchor);
            thetaall{iv} = theta;
            objectAll{iv} = object;
            labelAll{iv} = label_neighbor;
            infoAll{iv} = info;
            cacheSource{iv} = 'generated';

            if config.useCache
                labelField = meta.labelField;
                methodCacheKey = cacheKey; %#ok<NASGU>
                save(cacheFile, 'theta', 'object', 'label_neighbor', 'info', ...
                    'anchorOptions', 'methodCacheKey', 'methodName', 'labelField');
            end
        end
    end

    infoAll{iv} = ensure_ablation_view_evidence(X{iv}, objectAll{iv}, labelAll{iv}, infoAll{iv}, anchorOptions, methodConfig);
end

[bicTargetView, qualityScores, unitGains] = biclr_select_target_view(infoAll);
totalSSEPerView = zeros(numViews, 1);
anchorCounts = zeros(numViews, 1);
acceptedSplits = zeros(numViews, 1);
rejectedSplits = zeros(numViews, 1);
meanLeafSize = zeros(numViews, 1);
maxDepth = zeros(numViews, 1);
leafDepths = cell(numViews, 1);
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
    if isfield(info, 'leafDepths')
        leafDepths{iv} = info.leafDepths(:)';
    else
        leafDepths{iv} = [];
    end
end

anchorPack = struct();
anchorPack.thetaall = thetaall;
anchorPack.objectAll = objectAll;
anchorPack.labelAll = labelAll;
anchorPack.infoAll = infoAll;
anchorPack.qualityScores = qualityScores;
anchorPack.bicTargetView = bicTargetView;
anchorPack.bicUnitGains = unitGains;
anchorPack.totalSSEPerView = totalSSEPerView;
anchorPack.anchorCounts = anchorCounts;
anchorPack.acceptedSplits = acceptedSplits;
anchorPack.rejectedSplits = rejectedSplits;
anchorPack.meanLeafSize = meanLeafSize;
anchorPack.maxDepth = maxDepth;
anchorPack.leafDepths = leafDepths;
anchorPack.cacheKeys = cacheKeys;
anchorPack.cacheFiles = cacheFiles;
anchorPack.cacheSource = cacheSource;
anchorPack.cacheHit = cacheHit;
anchorPack.anchorTime = sum(anchorTimePerView);
anchorPack.anchorTimePerView = anchorTimePerView;
end

function cacheKey = make_ablation_anchor_cache_key(datasetInfo, methodName, viewIndex, anchorOptions, methodConfig, config)
cacheKey = sprintf('%s_%s_%s_view%d_lamBIC%s_minNode%d_tau%s_seed%d_sel%s_fusion%d_pre%s', ...
    ablation_sanitize_key(datasetInfo.resultDirName), ...
    ablation_sanitize_key(datasetInfo.canonicalName), ...
    ablation_sanitize_key(methodName), ...
    viewIndex, ...
    ablation_sanitize_numeric(anchorOptions.lambdaBIC), ...
    anchorOptions.minNodeSize, ...
    ablation_sanitize_numeric(anchorOptions.tauSplit), ...
    anchorOptions.randomSeed, ...
    ablation_sanitize_key(methodConfig.targetSelectionMethod), ...
    logical(methodConfig.useMultiViewFusion), ...
    ablation_sanitize_key(config.preprocessTag));
end

function [theta, object, label_neighbor, info] = read_cached_anchor(loaded)
required = {'theta', 'object', 'label_neighbor', 'info'};
for i = 1:numel(required)
    if ~isfield(loaded, required{i})
        error('prepare_biclr_ablation_anchors:InvalidCache', ...
            '锚点缓存缺少字段：%s。', required{i});
    end
end
theta = loaded.theta;
object = loaded.object;
label_neighbor = loaded.label_neighbor;
info = loaded.info;
end

function a0CacheFile = find_a0_anchor_cache(mainCodeRoot, meta, viewIndex, anchorOptions, config)
a0CacheFile = '';
cacheRoot = fullfile(mainCodeRoot, 'cache');
if ~exist(cacheRoot, 'dir')
    return;
end
files = dir(fullfile(cacheRoot, '*.mat'));
if isempty(files)
    return;
end

tokens = { ...
    lower(ablation_sanitize_key(meta.datasetName)), ...
    lower(ablation_sanitize_key(meta.preprocessTag)), ...
    lower(sprintf('view%d', viewIndex)), ...
    lower(['lamBIC' ablation_sanitize_numeric(anchorOptions.lambdaBIC)]), ...
    lower(sprintf('minNode%d', anchorOptions.minNodeSize)), ...
    lower(sprintf('seed%d', anchorOptions.randomSeed))};
if isfield(config, 'removeClutter')
    tokens{end + 1} = lower(sprintf('rmClutter%d', logical(config.removeClutter)));
end

bestIndex = 0;
bestScore = -inf;
for i = 1:numel(files)
    nameLower = lower(files(i).name);
    score = 0;
    missing = false;
    for t = 1:numel(tokens)
        if ~isempty(strfind(nameLower, tokens{t})) %#ok<STREMP>
            score = score + 1;
        else
            missing = true;
        end
    end
    if ~missing && score > bestScore
        bestIndex = i;
        bestScore = score;
    end
end

if bestIndex > 0
    a0CacheFile = fullfile(cacheRoot, files(bestIndex).name);
end
end

function info = ensure_ablation_view_evidence(Xv, object, label_neighbor, info, anchorOptions, methodConfig)
if nargin < 4 || isempty(info)
    info = struct();
end
if ~isfield(info, 'anchorSizes') || isempty(info.anchorSizes)
    labels = double(label_neighbor(:));
    info.anchorSizes = accumarray(labels, 1);
end
if ~isfield(info, 'totalSSE') || isempty(info.totalSSE)
    info.totalSSE = sum(object);
end
info.options = anchorOptions;
info.viewEvidence = biclr_view_evidence(Xv, object, info.anchorSizes, anchorOptions);
info.legacySSEQuality = info.totalSSE;
if strcmp(methodConfig.targetSelectionMethod, 'LRUnitEvidence')
    info.qualityMethod = 'LRUnitEvidence';
    info.viewEvidence.methodName = 'LRUnitEvidence';
    info.LRUnitEvidence = info.viewEvidence.unitGain;
else
    info.qualityMethod = 'BICUnitEvidenceGain';
end
info.qualityScore = info.viewEvidence.qualityScore;
info.unitBICEvidence = info.viewEvidence.unitGain;
info.relativeBICEvidence = info.viewEvidence.unitGain;
info.bicEvidenceGain = info.viewEvidence.deltaBIC;
end

function value = get_info_scalar(info, fieldName, defaultValue)
if isstruct(info) && isfield(info, fieldName) && ~isempty(info.(fieldName))
    value = double(info.(fieldName));
else
    value = defaultValue;
end
end
