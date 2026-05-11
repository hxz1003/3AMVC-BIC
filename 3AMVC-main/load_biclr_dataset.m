function [X, Y, meta] = load_biclr_dataset(datasetName, options)
%LOAD_BICLR_DATASET 统一加载 3AMVC 仓库中的多视图数据集。
%   [X, Y, META] = LOAD_BICLR_DATASET(DATASETNAME, OPTIONS) 从 dataset 目录
%   加载目标数据集，自动识别标签字段并检查各视图样本方向。
%
%   输入参数：
%   datasetName : 字符串或字符向量，例如 'MFeat_2Views'。
%   options     : 可选结构体，支持字段：
%                 - rootDir          : 仓库根目录，默认当前文件所在目录。
%                 - preprocessTag    : 预处理标签，默认 'raw'。
%                 - verbose          : 是否输出日志，默认 false。
%                 - removeClutter    : 是否删除 Caltech 的 clutter 类，默认 false。
%                 - maxPerClass      : 每类最多保留样本数，默认 [] 表示不限。
%
%   输出参数：
%   X    : 视图 cell 数组，每个单元为 n*d_v 的 double 矩阵。
%   Y    : n*1 的连续正整数标签。
%   meta : 数据集元信息结构体。
%
%   注意事项：
%   1. 本函数不会修改原始 .mat 文件。
%   2. 若检测到视图方向为 d*n，会自动转置并记录在 meta 中。

if nargin < 2
    options = struct();
end

if isstring(datasetName)
    datasetName = char(datasetName);
end
validateattributes(datasetName, {'char'}, {'row', 'nonempty'}, mfilename, 'datasetName', 1);

rootDir = fileparts(mfilename('fullpath'));
defaultOptions = struct();
defaultOptions.rootDir = rootDir;
defaultOptions.preprocessTag = 'raw';
defaultOptions.verbose = false;
defaultOptions.removeClutter = false;
defaultOptions.maxPerClass = [];

optionNames = fieldnames(defaultOptions);
for i = 1:numel(optionNames)
    name = optionNames{i};
    if ~isfield(options, name) || isempty(options.(name))
        options.(name) = defaultOptions.(name);
    end
end

dataFile = fullfile(options.rootDir, 'dataset', [datasetName '.mat']);
if ~exist(dataFile, 'file')
    error('load_biclr_dataset:FileNotFound', '未找到数据集文件：%s', dataFile);
end

S = load(dataFile);
if ~isfield(S, 'X')
    error('load_biclr_dataset:MissingX', '数据集 %s 不包含变量 X。', datasetName);
end

if isfield(S, 'Y')
    Y = S.Y;
    labelField = 'Y';
elseif isfield(S, 'y')
    Y = S.y;
    labelField = 'y';
elseif isfield(S, 'gnd')
    Y = S.gnd;
    labelField = 'gnd';
else
    error('load_biclr_dataset:MissingLabel', '数据集 %s 中未找到 Y/y/gnd 标签字段。', datasetName);
end

X = S.X;
if ~iscell(X) || isempty(X)
    error('load_biclr_dataset:InvalidX', '数据集 %s 的 X 必须是非空 cell 数组。', datasetName);
end

Y = Y(:);
if any(~isfinite(Y))
    error('load_biclr_dataset:InvalidLabel', '标签向量中含有 NaN 或 Inf。');
end

if options.removeClutter
    [X, Y, clutterInfo] = maybe_remove_clutter(datasetName, X, Y, S);
else
    clutterInfo = struct('applied', false, 'removedLabel', []);
end

if ~isempty(options.maxPerClass)
    [X, Y, maxPerClassInfo] = apply_class_cap(X, Y, options.maxPerClass);
else
    maxPerClassInfo = struct('applied', false, 'maxPerClass', []);
end

[Y, labelMap] = relabel_to_consecutive(Y);
n = numel(Y);

numViews = numel(X);
viewDims = zeros(numViews, 1);
transposedViews = false(numViews, 1);
for iv = 1:numViews
    Xi = double(X{iv});
    if ~ismatrix(Xi) || isempty(Xi)
        error('load_biclr_dataset:InvalidView', '第 %d 个视图不是合法的二维数值矩阵。', iv);
    end
    if any(~isfinite(Xi(:)))
        error('load_biclr_dataset:InvalidView', '第 %d 个视图含有 NaN 或 Inf。', iv);
    end
    if size(Xi, 1) ~= n && size(Xi, 2) == n
        Xi = Xi';
        transposedViews(iv) = true;
    end
    if size(Xi, 1) ~= n
        error('load_biclr_dataset:SizeMismatch', ...
            '第 %d 个视图与标签样本数不一致，视图大小为 %s，标签长度为 %d。', ...
            iv, mat2str(size(Xi)), n);
    end
    X{iv} = Xi;
    viewDims(iv) = size(Xi, 2);
end

meta = struct();
meta.datasetName = datasetName;
meta.dataFile = dataFile;
meta.labelField = labelField;
meta.numSamples = n;
meta.numViews = numViews;
meta.numClusters = numel(unique(Y));
meta.viewDims = viewDims;
meta.preprocessTag = options.preprocessTag;
meta.transposedViews = transposedViews;
meta.labelMap = labelMap;
meta.removeClutterInfo = clutterInfo;
meta.maxPerClassInfo = maxPerClassInfo;

if options.verbose
    fprintf('[数据加载] 数据集=%s，样本数=%d，视图数=%d，类别数=%d\n', ...
        meta.datasetName, meta.numSamples, meta.numViews, meta.numClusters);
    for iv = 1:numViews
        fprintf('[数据加载] 视图 %d：%d x %d%s\n', iv, size(X{iv}, 1), size(X{iv}, 2), ...
            ternary(transposedViews(iv), '（已自动转置）', ''));
    end
end
end

function [Ynew, labelMap] = relabel_to_consecutive(Y)
uniqueLabels = unique(Y(:));
Ynew = zeros(size(Y));
labelMap = zeros(numel(uniqueLabels), 2);
for i = 1:numel(uniqueLabels)
    Ynew(Y == uniqueLabels(i)) = i;
    labelMap(i, :) = [uniqueLabels(i), i];
end
end

function [X, Y, info] = maybe_remove_clutter(datasetName, X, Y, S)
info = struct('applied', false, 'removedLabel', []);
if ~strcmpi(datasetName, 'Caltech101-all')
    return;
end
if ~isfield(S, 'categories') || isempty(S.categories)
    return;
end

categories = S.categories;
clutterLoc = find(strcmpi(categories, 'clutter') | strcmpi(categories, 'BACKGROUND_Google'), 1, 'first');
if isempty(clutterLoc)
    return;
end

keepMask = Y ~= clutterLoc;
for iv = 1:numel(X)
    Xi = X{iv};
    if size(Xi, 1) == numel(Y)
        X{iv} = Xi(keepMask, :);
    elseif size(Xi, 2) == numel(Y)
        X{iv} = Xi(:, keepMask);
    else
        error('load_biclr_dataset:ClutterMismatch', '删除 clutter 时第 %d 个视图样本方向无法识别。', iv);
    end
end
Y = Y(keepMask);
info.applied = true;
info.removedLabel = clutterLoc;
end

function [X, Y, info] = apply_class_cap(X, Y, maxPerClass)
validateattributes(maxPerClass, {'double', 'single'}, {'scalar', 'integer', 'positive', 'finite'}, mfilename, 'options.maxPerClass');
classes = unique(Y(:));
keepMask = false(size(Y));
for i = 1:numel(classes)
    classIdx = find(Y == classes(i));
    keepMask(classIdx(1:min(numel(classIdx), maxPerClass))) = true;
end

for iv = 1:numel(X)
    Xi = X{iv};
    if size(Xi, 1) == numel(Y)
        X{iv} = Xi(keepMask, :);
    else
        X{iv} = Xi(:, keepMask);
    end
end
Y = Y(keepMask);
info = struct('applied', true, 'maxPerClass', maxPerClass);
end

function out = ternary(condition, trueText, falseText)
if condition
    out = trueText;
else
    out = falseText;
end
end
