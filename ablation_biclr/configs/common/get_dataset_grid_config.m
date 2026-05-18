function config = get_dataset_grid_config(datasetName, config)
%GET_DATASET_GRID_CONFIG 设置指定数据集的默认网格。
%   CONFIG = GET_DATASET_GRID_CONFIG(DATASETNAME, CONFIG) 优先沿用
%   3AMVC-main/build_biclr_refined_config.m 中已有 A0 精细搜索网格；若
%   无法调用，则使用本文件中的兼容默认值。
%
%   输入参数：
%   datasetName : 数据集别名。
%   config      : 通用配置结构体。
%
%   输出参数：
%   config : 补齐 beta/lambda/lambdaBIC/minNodeSize 等字段后的配置。

if nargin < 2 || isempty(config)
    config = get_default_grid_config();
end

paths = get_project_paths();
datasetInfo = get_ablation_dataset_alias(datasetName);
addpath(genpath(paths.mainCodeRoot));

[grid, source] = load_grid_from_a0(datasetInfo.canonicalName);
if isempty(grid)
    [grid, source] = fallback_grid(datasetInfo.canonicalName);
end

config.datasetInfo = datasetInfo;
config.gridSource = source;
config.betaList = grid.betaList;
config.lambdaList = grid.lambdaList;
config.lambdaBICList = grid.lambdaBICList;
config.minNodeSizeList = grid.minNodeSizeList;
config.numRuns = grid.numRuns;
config.kmeansReplicates = grid.kmeansReplicates;
config.removeClutter = grid.removeClutter;
config.maxPerClass = grid.maxPerClass;
config.preprocessTag = grid.preprocessTag;
config.anchorOptions.maxAnchors = grid.maxAnchors;
config.anchorOptions.tauSplit = config.tauSplit;
config.anchorOptions.epsVar = config.epsVar;
config.anchorOptions.randomSeed = config.seeds(1);
config.evalOptions.numRuns = config.numRuns;
config.evalOptions.kmeansReplicates = config.kmeansReplicates;
config.evalOptions.baseSeed = config.seeds(1);
config.evalOptions.useParallel = config.useParallel;
config.evalOptions.summaryMode = config.summaryMode;

largeDatasetNames = {'Catlch101All'};
if any(strcmp(datasetInfo.resultDirName, largeDatasetNames)) && ~config.enableLargeDataset
    config.fullGridWhenLargeDatasetEnabled = grid;
    config.betaList = first_value(grid.betaList);
    config.lambdaList = first_value(grid.lambdaList);
    config.lambdaBICList = first_value(grid.lambdaBICList);
    config.minNodeSizeList = first_value(grid.minNodeSizeList);
    config.numRuns = min(grid.numRuns, 2);
    config.kmeansReplicates = min(grid.kmeansReplicates, 2);
    config.evalOptions.numRuns = config.numRuns;
    config.evalOptions.kmeansReplicates = config.kmeansReplicates;
    config.gridSource = [source '；Catlch101All 默认收缩为 smoke 网格，enableLargeDataset=true 才启用完整网格。'];
end

if config.smokeTest
    config.betaList = first_value(config.betaList);
    config.lambdaList = first_value(config.lambdaList);
    config.lambdaBICList = first_value(config.lambdaBICList);
    config.minNodeSizeList = first_value(config.minNodeSizeList);
    config.seeds = first_value(config.seeds);
    config.numRuns = min(config.numRuns, 2);
    config.kmeansReplicates = min(config.kmeansReplicates, 1);
    config.evalOptions.numRuns = config.numRuns;
    config.evalOptions.kmeansReplicates = config.kmeansReplicates;
    config.evalOptions.baseSeed = config.seeds(1);
end
end

function [grid, source] = load_grid_from_a0(canonicalName)
grid = [];
source = '';
if exist('build_biclr_refined_config', 'file') ~= 2
    return;
end
try
    a0 = build_biclr_refined_config(canonicalName, 1);
    grid = struct();
    grid.betaList = a0.betaList;
    grid.lambdaList = a0.lambdaList;
    grid.lambdaBICList = a0.lambdaBICList;
    grid.minNodeSizeList = a0.minNodeSizeList;
    grid.maxAnchors = a0.anchorOptions.maxAnchors;
    grid.numRuns = a0.evalOptions.numRuns;
    grid.kmeansReplicates = a0.evalOptions.kmeansReplicates;
    grid.removeClutter = a0.removeClutter;
    grid.maxPerClass = a0.maxPerClass;
    grid.preprocessTag = a0.preprocessTag;
    source = '沿用 3AMVC-main/build_biclr_refined_config.m 的 A0 精细网格。';
catch
    grid = [];
    source = '';
end
end

function [grid, source] = fallback_grid(canonicalName)
source = '未能调用 A0 精细网格，使用 ablation_biclr 内置兼容默认网格，请人工确认。';
grid = struct();
grid.removeClutter = false;
grid.maxPerClass = [];
grid.preprocessTag = 'raw';
switch lower(canonicalName)
    case 'mfeat_2views'
        grid.betaList = [80 100 120 160];
        grid.lambdaList = [1e3 3e3 1e4];
        grid.lambdaBICList = [0.5 0.75 1 1.5 2];
        grid.minNodeSizeList = [24 32 40 48];
        grid.maxAnchors = 400;
        grid.numRuns = 10;
        grid.kmeansReplicates = 4;
    case 'reuters-1200'
        grid.betaList = [50 75 100 125];
        grid.lambdaList = [1e2 3e2 1e3];
        grid.lambdaBICList = [0.5 0.75 1 1.25];
        grid.minNodeSizeList = [8 10 12 16];
        grid.maxAnchors = 300;
        grid.numRuns = 8;
        grid.kmeansReplicates = 4;
    case 'wikifea'
        grid.betaList = [80 100 120 160];
        grid.lambdaList = [1e2 3e2 1e3];
        grid.lambdaBICList = [2 2.5 3 3.5 4];
        grid.minNodeSizeList = [20 30 40 50];
        grid.maxAnchors = 400;
        grid.numRuns = 8;
        grid.kmeansReplicates = 4;
    case 'caltech101-all'
        grid.betaList = [5 10 15 20];
        grid.lambdaList = [3e2 1e3 3e3];
        grid.lambdaBICList = [1 1.5 2];
        grid.minNodeSizeList = [40 60 80 120 160];
        grid.maxAnchors = 500;
        grid.numRuns = 6;
        grid.kmeansReplicates = 3;
    case 'foresttypes'
        grid.betaList = [80 100 120 160 200];
        grid.lambdaList = [10 30 100 300 1000];
        grid.lambdaBICList = [0.2 0.35 0.5 0.75 1];
        grid.minNodeSizeList = [16 20 24 28 32];
        grid.maxAnchors = 200;
        grid.numRuns = 10;
        grid.kmeansReplicates = 4;
    case 'caltech256_4views_257cls_withclutter'
        grid.betaList = [80 100 150 200];
        grid.lambdaList = [5e2 1e3 3e3 1e4];
        grid.lambdaBICList = [3 4 5 6];
        grid.minNodeSizeList = [40 60 80 120];
        grid.maxAnchors = 600;
        grid.numRuns = 3;
        grid.kmeansReplicates = 3;
        grid.preprocessTag = 'raw_withClutter_257cls_ordered';
    otherwise
        error('get_dataset_grid_config:UnsupportedDataset', ...
            '未为数据集 %s 设置默认网格。', canonicalName);
end
end

function value = first_value(values)
value = values(1);
end
