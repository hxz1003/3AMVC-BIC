function [resmax, resstd, evalInfo] = myNMIACCwithmean(U, Y, numclass, evalOptions)
%MYNMIACCWITHMEAN 多次 KMeans 评价聚类结果并按指定模式汇总。
%   [RESMEAN, RESSTD] = MYNMIACCWITHMEAN(U, Y, NUMCLASS) 保持原始默认行为：
%   运行 50 次 KMeans，每次使用 3 次内部重复，返回 8 个聚类指标的均值与标准差。
%
%   [RESSUMMARY, RESSTD, EVALINFO] = MYNMIACCWITHMEAN(U, Y, NUMCLASS, EVALOPTIONS)
%   允许通过 EVALOPTIONS 控制评价次数，支持字段：
%   - numRuns          : 外层重复次数，默认 50。
%   - kmeansReplicates : 每次 litekmeans 的内部重复次数，默认 3。
%   - useParallel      : 是否对重复实验使用 parfor，默认 false。
%   - baseSeed         : 复现随机种子的基值，默认 1。
%   - summaryMode      : 结果汇总模式，默认 'mean'；设为 'bestACC' 时返回
%                        外层 numRuns 中 ACC 最高的那一次指标。
%   EVALINFO.meanMetrics / stdMetrics 用于“均值±标准差”展示；
%   EVALINFO.minMetrics / maxMetrics 记录重复评价中的逐指标最差值和最好值。
%
%   输出指标顺序：
%   [ACC nmi Purity Fscore Precision Recall AR Entropy]

if nargin < 4
    evalOptions = struct();
end

validateattributes(U, {'double', 'single'}, {'2d', 'nonempty', 'real'}, mfilename, 'U', 1);
validateattributes(Y, {'double', 'single'}, {'vector', 'nonempty', 'real'}, mfilename, 'Y', 2);
validateattributes(numclass, {'double', 'single'}, {'scalar', 'integer', 'positive', 'finite'}, mfilename, 'numclass', 3);
if any(~isfinite(U(:))) || any(~isfinite(Y(:)))
    error('myNMIACCwithmean:InvalidInput', '输入 U 或 Y 含有 NaN 或 Inf。');
end

defaultOptions = struct('numRuns', 50, 'kmeansReplicates', 3, ...
    'useParallel', false, 'baseSeed', 1, 'summaryMode', 'mean');
optionNames = fieldnames(defaultOptions);
for i = 1:numel(optionNames)
    name = optionNames{i};
    if ~isfield(evalOptions, name) || isempty(evalOptions.(name))
        evalOptions.(name) = defaultOptions.(name);
    end
end

validateattributes(evalOptions.numRuns, {'double', 'single'}, {'scalar', 'integer', 'positive', 'finite'}, mfilename, 'evalOptions.numRuns');
validateattributes(evalOptions.kmeansReplicates, {'double', 'single'}, {'scalar', 'integer', 'positive', 'finite'}, mfilename, 'evalOptions.kmeansReplicates');
validateattributes(evalOptions.useParallel, {'logical', 'numeric'}, {'scalar'}, mfilename, 'evalOptions.useParallel');
validateattributes(evalOptions.baseSeed, {'double', 'single'}, {'scalar', 'integer', 'finite', 'nonnegative'}, mfilename, 'evalOptions.baseSeed');
evalOptions.summaryMode = normalize_summary_mode(evalOptions.summaryMode);

Y = Y(:);
if size(U, 1) ~= numel(Y)
    error('myNMIACCwithmean:SizeMismatch', 'U 的行数必须与标签长度一致。');
end

denom = sqrt(sum(U.^2, 2));
denom = max(denom, eps(class(U)));
U_normalized = U ./ repmat(denom, 1, size(U, 2));
numRuns = evalOptions.numRuns;
kmeansReplicates = evalOptions.kmeansReplicates;
result = zeros(numRuns, 8);
seedList = evalOptions.baseSeed + (0:numRuns - 1);

useParallel = logical(evalOptions.useParallel) ...
    && license('test', 'Distrib_Computing_Toolbox') ...
    && ~isempty(gcp('nocreate'));

if useParallel
    parfor iter = 1:numRuns
        rng(seedList(iter), 'twister');
        indx = litekmeans(U_normalized, numclass, 'MaxIter', 100, 'Replicates', kmeansReplicates);
        result(iter, :) = Clustering8Measure(Y, indx(:));
    end
else
    for iter = 1:numRuns
        rng(seedList(iter), 'twister');
        indx = litekmeans(U_normalized, numclass, 'MaxIter', 100, 'Replicates', kmeansReplicates);
        result(iter, :) = Clustering8Measure(Y, indx(:));
    end
end

metricNames = {'ACC', 'NMI', 'Purity', 'Fscore', 'Precision', 'Recall', 'AR', 'Entropy'};
meanMetric = mean(result, 1);
resstd = std(result, 1, 1);
minMetric = min(result, [], 1);
maxMetric = max(result, [], 1);
bestRunIndex = select_best_acc_run(result);

switch evalOptions.summaryMode
    case 'mean'
        resmax = meanMetric;
    case 'bestacc'
        resmax = result(bestRunIndex, :);
    otherwise
        error('myNMIACCwithmean:InvalidSummaryMode', ...
            '未知 summaryMode：%s。支持 mean 或 bestACC。', evalOptions.summaryMode);
end

evalInfo = struct();
evalInfo.summaryMode = evalOptions.summaryMode;
evalInfo.metricNames = metricNames;
evalInfo.allMetrics = result;
evalInfo.meanMetrics = meanMetric;
evalInfo.stdMetrics = resstd;
evalInfo.minMetrics = minMetric;
evalInfo.maxMetrics = maxMetric;
evalInfo.bestRunIndex = bestRunIndex;
evalInfo.bestRunSeed = seedList(bestRunIndex);
evalInfo.bestRunMetrics = result(bestRunIndex, :);
evalInfo.bestACC = result(bestRunIndex, 1);
end

function summaryMode = normalize_summary_mode(summaryMode)
if isstring(summaryMode)
    summaryMode = char(summaryMode);
end
validateattributes(summaryMode, {'char'}, {'row', 'nonempty'}, mfilename, 'evalOptions.summaryMode');
summaryMode = lower(strtrim(summaryMode));
if strcmp(summaryMode, 'best')
    summaryMode = 'bestacc';
end
if ~ismember(summaryMode, {'mean', 'bestacc'})
    error('myNMIACCwithmean:InvalidSummaryMode', ...
        'evalOptions.summaryMode 必须为 mean 或 bestACC。');
end
end

function bestRunIndex = select_best_acc_run(result)
stableIndex = (1:size(result, 1))';
sortKey = [-result(:, 1), -result(:, 2), -result(:, 4), -result(:, 3), stableIndex];
[~, order] = sortrows(sortKey);
bestRunIndex = order(1);
end
