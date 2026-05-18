function summaries = run_ablation_biclr_suite(options)
%RUN_ABLATION_BICLR_SUITE 批量运行 BIC-LR 消融实验。
%   SUMMARIES = RUN_ABLATION_BICLR_SUITE(OPTIONS) 支持按方法、数据集和
%   smokeTest 过滤运行 A1/A3/A4，并可选读取 A0 已有结果。
%
%   OPTIONS 可选字段：
%   methodName         : 仅运行某个方法。
%   datasetName        : 仅运行某个数据集。
%   smokeTest          : 是否使用极小网格。
%   includeA0          : 是否先读取 A0_Full_Reference。
%   enableLargeDataset : 是否允许 Catlch101All 使用完整网格。
%
%   注意事项：
%   默认不自动运行 Catlch101All 和 Caltech256 的完整大网格；若未指定
%   datasetName，默认批量运行 Mfeat、Ruter1200、WIKI、ForestTypes。

if nargin < 1 || isempty(options)
    options = struct();
end

paths = get_project_paths();
addpath(genpath(paths.mainCodeRoot));
addpath(genpath(paths.ablationRoot));

if ~isfield(options, 'smokeTest') || isempty(options.smokeTest)
    options.smokeTest = false;
end
if ~isfield(options, 'includeA0') || isempty(options.includeA0)
    options.includeA0 = false;
end
if ~isfield(options, 'enableLargeDataset') || isempty(options.enableLargeDataset)
    options.enableLargeDataset = false;
end

methods = {'A1_woBIC_Joint', 'A3_SSETarget', 'A4_woMultiViewFusion'};
if options.includeA0
    methods = [{'A0_Full_Reference'}, methods];
end
if isfield(options, 'methodName') && ~isempty(options.methodName)
    methods = {char(options.methodName)};
end

if isfield(options, 'datasetName') && ~isempty(options.datasetName)
    datasets = {char(options.datasetName)};
else
    datasets = {'Mfeat', 'Ruter1200', 'WIKI', 'ForestTypes'};
    if options.enableLargeDataset
        datasets{end + 1} = 'Catlch101All';
        datasets{end + 1} = 'Caltech256_4Views_257cls_withClutter';
    end
end

summaries = struct([]);
idx = 0;
for im = 1:numel(methods)
    for id = 1:numel(datasets)
        config = get_default_grid_config();
        config.smokeTest = options.smokeTest;
        config.enableLargeDataset = options.enableLargeDataset;
        config = get_dataset_grid_config(datasets{id}, config);
        config = get_method_config(methods{im}, config);

        idx = idx + 1;
        summaries(idx).methodName = methods{im}; %#ok<AGROW>
        summaries(idx).datasetName = datasets{id};
        summaries(idx).resultSummary = run_one_biclr_ablation(methods{im}, datasets{id}, config);
    end
end
end
