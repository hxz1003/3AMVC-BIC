function run_all_strict_fixed_ablation(methodFilter, datasetFilter)
%RUN_ALL_STRICT_FIXED_ABLATION 运行 fixed-parameter strict ablation 总控脚本。
%   RUN_ALL_STRICT_FIXED_ABLATION() 运行全部数据集和全部严格消融组。
%   RUN_ALL_STRICT_FIXED_ABLATION(METHODFILTER) 只运行指定消融组。
%   RUN_ALL_STRICT_FIXED_ABLATION(METHODFILTER, DATASETFILTER) 同时限制方法和数据集。
%
%   说明：
%   本脚本是 fixed-parameter strict ablation；参数来自 A0 best；不执行
%   grid search；每个任务只改变一个模块，其余参数保持 A0 best 配置不变。
%   若某个任务报错，会记录错误并继续下一个任务。

strictRoot = fileparts(mfilename('fullpath'));
helperRoot = fullfile(strictRoot, 'helpers');
addpath(helperRoot);

allMethods = {'A1_fixed_woBIC', 'A3_fixed_SSETarget', 'A4_fixed_woMultiViewFusion'};
allDatasets = {'Mfeat', 'Reuters-1200', 'WIKI', 'ForestTypes', 'Caltech256'};

if nargin < 1 || isempty(methodFilter)
    methods = allMethods;
else
    methods = normalize_filter(methodFilter, allMethods, 'method');
end
if nargin < 2 || isempty(datasetFilter)
    datasets = allDatasets;
else
    datasets = normalize_filter(datasetFilter, allDatasets, 'dataset');
end

fprintf('[严格消融总控] methods=%s\n', strjoin(methods, ', '));
fprintf('[严格消融总控] datasets=%s\n', strjoin(datasets, ', '));

errorDir = fullfile(fileparts(strictRoot), 'res_strict_fixed', '_errors');
if ~exist(errorDir, 'dir')
    mkdir(errorDir);
end

for im = 1:numel(methods)
    for id = 1:numel(datasets)
        methodName = methods{im};
        datasetName = datasets{id};
        fprintf('\n============================================================\n');
        fprintf('[严格消融总控] 开始：dataset=%s, method=%s\n', datasetName, methodName);
        try
            result = run_strict_fixed_ablation_case(methodName, datasetName); %#ok<NASGU>
            fprintf('[严格消融总控] 完成：dataset=%s, method=%s\n', datasetName, methodName);
        catch ME
            timestamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
            safeDataset = regexprep(datasetName, '[^a-zA-Z0-9]+', '');
            matPath = fullfile(errorDir, sprintf('error_%s_%s_%s.mat', methodName, safeDataset, timestamp));
            txtPath = fullfile(errorDir, sprintf('error_%s_%s_%s.txt', methodName, safeDataset, timestamp));
            errorInfo = struct();
            errorInfo.method = methodName;
            errorInfo.dataset = datasetName;
            errorInfo.message = ME.message;
            errorInfo.identifier = ME.identifier;
            errorInfo.stack = ME.stack;
            save(matPath, 'errorInfo');
            write_error_text(txtPath, errorInfo);
            fprintf('[严格消融总控] 报错但继续：%s / %s -> %s\n', datasetName, methodName, ME.message);
        end
    end
end
fprintf('\n[严格消融总控] 全部请求任务处理结束。\n');
end

function selected = normalize_filter(filterValue, allowed, filterName)
if ischar(filterValue) || isstring(filterValue)
    selected = cellstr(string(filterValue));
elseif iscell(filterValue)
    selected = filterValue;
else
    error('run_all_strict_fixed_ablation:InvalidFilter', ...
        '%s filter 类型不支持。', filterName);
end
for i = 1:numel(selected)
    hit = strcmpi(selected{i}, allowed);
    if ~any(hit)
        error('run_all_strict_fixed_ablation:UnknownFilterValue', ...
            '未知 %s：%s。可选值：%s', filterName, selected{i}, strjoin(allowed, ', '));
    end
    selected{i} = allowed{find(hit, 1, 'first')};
end
end

function write_error_text(txtPath, errorInfo)
fid = fopen(txtPath, 'w');
if fid < 0
    return;
end
cleanupObj = onCleanup(@() fclose(fid));
fprintf(fid, '严格消融任务报错\n');
fprintf(fid, 'method=%s\n', errorInfo.method);
fprintf(fid, 'dataset=%s\n', errorInfo.dataset);
fprintf(fid, 'identifier=%s\n', errorInfo.identifier);
fprintf(fid, 'message=%s\n', errorInfo.message);
for i = 1:numel(errorInfo.stack)
    fprintf(fid, 'stack[%d]=%s:%d %s\n', i, errorInfo.stack(i).file, ...
        errorInfo.stack(i).line, errorInfo.stack(i).name);
end
end
