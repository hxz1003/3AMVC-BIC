function bestInfo = save_best_biclr_acc_result(results, outputDir)
%SAVE_BEST_BICLR_ACC_RESULT 将按 ACC 选出的最优结果单独保存。
%   BESTINFO = SAVE_BEST_BICLR_ACC_RESULT(RESULTS, OUTPUTDIR) 从
%   RUN_BICLR_GRID_SEARCH 返回的 RESULTS 结构体中提取最优结果，并保存为
%   单独的 .mat 与 .txt 文件，便于后续直接复现实验。文本摘要会同时
%   展示按“重复评价均值+标准差”最高和按重复评价均值最高得到的两组参数。
%
%   输入参数：
%   results   : RUN_BICLR_GRID_SEARCH 返回的结果结构体。
%   outputDir : 输出目录；若省略，则默认使用 results.savePath 所在目录。
%
%   输出参数：
%   bestInfo  : 结构体，兼容保留按 ACC 上界最高的顶层字段，并额外包含
%               bestUpper、bestMean 与 bestSummary 三组记录，便于比较
%               重复评价均值±标准差、逐指标范围、锚点数和随机种子。

if nargin < 2 || isempty(outputDir)
    if ~isfield(results, 'savePath') || isempty(results.savePath)
        error('save_best_biclr_acc_result:MissingSavePath', 'results 中缺少 savePath，无法推断输出目录。');
    end
    outputDir = fileparts(results.savePath);
end

validateattributes(results, {'struct'}, {'scalar', 'nonempty'}, mfilename, 'results', 1);
if ~isfield(results, 'best') || isempty(results.best)
    error('save_best_biclr_acc_result:MissingBest', 'results 中缺少 best 字段。');
end
if isstring(outputDir)
    outputDir = char(outputDir);
end
validateattributes(outputDir, {'char'}, {'row', 'nonempty'}, mfilename, 'outputDir', 2);

if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

bestSummary = get_best_record(results, 'bestSummary');
bestUpper = get_best_record(results, 'bestUpper');
bestMean = get_best_record(results, 'bestMean');
best = bestUpper;
bestInfo = struct();
bestInfo.datasetName = results.datasetName;
bestInfo.selectionMetricName = results.selectionMetricName;
bestInfo.selectionMode = '按重复评价均值+标准差上界';
bestInfo.sourceResultFile = results.savePath;
bestInfo.beta = best.beta;
bestInfo.lambda = best.lambda;
bestInfo.lambdaBIC = best.lambdaBIC;
bestInfo.minNodeSize = best.minNodeSize;
bestInfo.tauSplit = best.tauSplit;
bestInfo.epsVar = best.epsVar;
bestInfo.randomSeed = best.randomSeed;
bestInfo.numRuns = best.numRuns;
bestInfo.kmeansReplicates = best.kmeansReplicates;
if isfield(best, 'evalSummaryMode')
    bestInfo.evalSummaryMode = best.evalSummaryMode;
end
if isfield(best, 'bestEvalRun')
    bestInfo.bestEvalRun = best.bestEvalRun;
end
if isfield(best, 'bestEvalSeed')
    bestInfo.bestEvalSeed = best.bestEvalSeed;
end
bestInfo.anchorCounts = best.anchorCounts;
bestInfo.targetView = best.targetView;
if isfield(best, 'anchorQualityMethod')
    bestInfo.anchorQualityMethod = best.anchorQualityMethod;
end
if isfield(best, 'anchorEvidenceGain')
    bestInfo.anchorEvidenceGain = best.anchorEvidenceGain;
end
bestInfo.metricsMean = best.metricsMean;
bestInfo.metricsStd = best.metricsStd;
bestInfo.metricNames = best.metricNames;
if isfield(best, 'evalMeanMetrics') && ~isempty(best.evalMeanMetrics)
    bestInfo.evalMeanMetrics = best.evalMeanMetrics;
else
    bestInfo.evalMeanMetrics = best.metricsMean;
end
if isfield(best, 'evalStdMetrics') && ~isempty(best.evalStdMetrics)
    bestInfo.evalStdMetrics = best.evalStdMetrics;
else
    bestInfo.evalStdMetrics = best.metricsStd;
end
if isfield(best, 'evalMinMetrics') && ~isempty(best.evalMinMetrics)
    bestInfo.evalMinMetrics = best.evalMinMetrics;
end
if isfield(best, 'evalMaxMetrics') && ~isempty(best.evalMaxMetrics)
    bestInfo.evalMaxMetrics = best.evalMaxMetrics;
end
if isfield(best, 'bestEvalMetrics') && ~isempty(best.bestEvalMetrics)
    bestInfo.bestEvalMetrics = best.bestEvalMetrics;
end
bestInfo.totalTime = results.totalTime;
bestInfo.cacheKeys = best.cacheKeys;
bestInfo.bestUpper = build_best_block(results, bestUpper, '按重复评价均值+标准差上界');
bestInfo.bestSummary = build_best_block(results, bestSummary, '按选优汇总');
bestInfo.bestMean = build_best_block(results, bestMean, '按重复评价平均');

baseName = sprintf('%s_BICLR_refined_best_ACC', sanitize_key(results.datasetName));
matPath = fullfile(outputDir, [baseName '.mat']);
txtPath = fullfile(outputDir, [baseName '.txt']);
save(matPath, 'bestInfo');

fid = fopen(txtPath, 'w');
if fid < 0
    error('save_best_biclr_acc_result:WriteFailed', '无法写入最优结果摘要：%s', txtPath);
end
cleanupObj = onCleanup(@() fclose(fid));
fprintf(fid, 'BIC-LR 精细搜索最优 ACC 结果\n');
fprintf(fid, '\n【一、按重复评价均值+标准差上界 %s 最高】\n', bestInfo.selectionMetricName);
fprintf(fid, '数据集：%s\n', bestInfo.datasetName);
fprintf(fid, '来源结果文件：%s\n', bestInfo.sourceResultFile);
fprintf(fid, '选择准则：%s\n', bestInfo.selectionMetricName);
fprintf(fid, '选择口径：%s\n', bestInfo.selectionMode);
fprintf(fid, 'beta=%g\n', bestInfo.beta);
fprintf(fid, 'lambda=%g\n', bestInfo.lambda);
fprintf(fid, 'lambdaBIC=%g\n', bestInfo.lambdaBIC);
fprintf(fid, 'minNodeSize=%d\n', bestInfo.minNodeSize);
fprintf(fid, 'tauSplit=%g\n', bestInfo.tauSplit);
fprintf(fid, 'epsVar=%g\n', bestInfo.epsVar);
fprintf(fid, 'randomSeed=%d\n', bestInfo.randomSeed);
fprintf(fid, 'numRuns=%d\n', bestInfo.numRuns);
fprintf(fid, 'kmeansReplicates=%d\n', bestInfo.kmeansReplicates);
if isfield(bestInfo, 'evalSummaryMode')
    fprintf(fid, 'evalSummaryMode=%s\n', bestInfo.evalSummaryMode);
end
if isfield(bestInfo, 'bestEvalRun')
    fprintf(fid, 'bestEvalRun=%d\n', bestInfo.bestEvalRun);
end
if isfield(bestInfo, 'bestEvalSeed')
    fprintf(fid, 'bestEvalSeed=%d\n', bestInfo.bestEvalSeed);
end
fprintf(fid, 'anchorCounts=%s\n', mat2str(bestInfo.anchorCounts(:)'));
fprintf(fid, 'targetView=%d\n', bestInfo.targetView);
if isfield(bestInfo, 'anchorQualityMethod')
    fprintf(fid, 'anchorQualityMethod=%s\n', bestInfo.anchorQualityMethod);
end
if isfield(bestInfo, 'anchorEvidenceGain')
    fprintf(fid, 'anchorEvidenceGain=%s\n', mat2str(bestInfo.anchorEvidenceGain(:)', 6));
end
fprintf(fid, '重复评价均值±标准差：\n');
fprintf(fid, 'ACC=%.6f ± %.6f\n', bestInfo.evalMeanMetrics(1), bestInfo.evalStdMetrics(1));
fprintf(fid, 'NMI=%.6f ± %.6f\n', bestInfo.evalMeanMetrics(2), bestInfo.evalStdMetrics(2));
fprintf(fid, 'Purity=%.6f ± %.6f\n', bestInfo.evalMeanMetrics(3), bestInfo.evalStdMetrics(3));
fprintf(fid, 'Fscore=%.6f ± %.6f\n', bestInfo.evalMeanMetrics(4), bestInfo.evalStdMetrics(4));
if isfield(bestInfo, 'evalMinMetrics') && isfield(bestInfo, 'evalMaxMetrics')
    fprintf(fid, '重复评价逐指标范围：\n');
    fprintf(fid, 'ACC=[%.6f, %.6f]\n', bestInfo.evalMinMetrics(1), bestInfo.evalMaxMetrics(1));
    fprintf(fid, 'NMI=[%.6f, %.6f]\n', bestInfo.evalMinMetrics(2), bestInfo.evalMaxMetrics(2));
    fprintf(fid, 'Purity=[%.6f, %.6f]\n', bestInfo.evalMinMetrics(3), bestInfo.evalMaxMetrics(3));
    fprintf(fid, 'Fscore=[%.6f, %.6f]\n', bestInfo.evalMinMetrics(4), bestInfo.evalMaxMetrics(4));
end
fprintf(fid, '选优汇总指标：\n');
fprintf(fid, 'summaryACC=%.6f\n', bestInfo.metricsMean(1));
fprintf(fid, 'summaryNMI=%.6f\n', bestInfo.metricsMean(2));
fprintf(fid, 'summaryPurity=%.6f\n', bestInfo.metricsMean(3));
fprintf(fid, 'summaryFscore=%.6f\n', bestInfo.metricsMean(4));
if isfield(bestInfo, 'bestEvalMetrics')
    fprintf(fid, 'bestRun指标：ACC=%.6f，NMI=%.6f，Purity=%.6f，Fscore=%.6f\n', ...
        bestInfo.bestEvalMetrics(1), bestInfo.bestEvalMetrics(2), ...
        bestInfo.bestEvalMetrics(3), bestInfo.bestEvalMetrics(4));
end
fprintf(fid, '总耗时=%.2fs\n', bestInfo.totalTime);
fprintf(fid, '缓存键=%s\n', strjoin(bestInfo.cacheKeys, ', '));
fprintf(fid, '\n【二、按重复评价平均 %s 最高】\n', bestInfo.selectionMetricName);
write_best_block(fid, bestInfo.bestMean);
end

function best = get_best_record(results, fieldName)
if isfield(results, fieldName) && ~isempty(results.(fieldName))
    best = results.(fieldName);
else
    best = results.best;
end
end

function info = build_best_block(results, best, selectionMode)
info = struct();
info.selectionMode = selectionMode;
info.datasetName = results.datasetName;
info.selectionMetricName = results.selectionMetricName;
info.sourceResultFile = results.savePath;
info.beta = best.beta;
info.lambda = best.lambda;
info.lambdaBIC = best.lambdaBIC;
info.minNodeSize = best.minNodeSize;
info.tauSplit = best.tauSplit;
info.epsVar = best.epsVar;
info.randomSeed = best.randomSeed;
info.numRuns = best.numRuns;
info.kmeansReplicates = best.kmeansReplicates;
if isfield(best, 'evalSummaryMode')
    info.evalSummaryMode = best.evalSummaryMode;
end
if isfield(best, 'bestEvalRun')
    info.bestEvalRun = best.bestEvalRun;
end
if isfield(best, 'bestEvalSeed')
    info.bestEvalSeed = best.bestEvalSeed;
end
info.anchorCounts = best.anchorCounts;
info.targetView = best.targetView;
if isfield(best, 'anchorQualityMethod')
    info.anchorQualityMethod = best.anchorQualityMethod;
end
if isfield(best, 'anchorEvidenceGain')
    info.anchorEvidenceGain = best.anchorEvidenceGain;
end
info.metricsMean = best.metricsMean;
info.metricsStd = best.metricsStd;
info.metricNames = best.metricNames;
if isfield(best, 'evalMeanMetrics') && ~isempty(best.evalMeanMetrics)
    info.evalMeanMetrics = best.evalMeanMetrics;
else
    info.evalMeanMetrics = best.metricsMean;
end
if isfield(best, 'evalStdMetrics') && ~isempty(best.evalStdMetrics)
    info.evalStdMetrics = best.evalStdMetrics;
else
    info.evalStdMetrics = best.metricsStd;
end
if isfield(best, 'evalMinMetrics') && ~isempty(best.evalMinMetrics)
    info.evalMinMetrics = best.evalMinMetrics;
end
if isfield(best, 'evalMaxMetrics') && ~isempty(best.evalMaxMetrics)
    info.evalMaxMetrics = best.evalMaxMetrics;
end
if isfield(best, 'bestEvalMetrics') && ~isempty(best.bestEvalMetrics)
    info.bestEvalMetrics = best.bestEvalMetrics;
end
info.totalTime = results.totalTime;
if isfield(best, 'cacheKeys')
    info.cacheKeys = best.cacheKeys;
else
    info.cacheKeys = {};
end
end

function write_best_block(fid, info)
fprintf(fid, '数据集：%s\n', info.datasetName);
fprintf(fid, '来源结果文件：%s\n', info.sourceResultFile);
fprintf(fid, '选择准则：%s\n', info.selectionMetricName);
fprintf(fid, '选择口径：%s\n', info.selectionMode);
fprintf(fid, 'beta=%g\n', info.beta);
fprintf(fid, 'lambda=%g\n', info.lambda);
fprintf(fid, 'lambdaBIC=%g\n', info.lambdaBIC);
fprintf(fid, 'minNodeSize=%d\n', info.minNodeSize);
fprintf(fid, 'tauSplit=%g\n', info.tauSplit);
fprintf(fid, 'epsVar=%g\n', info.epsVar);
fprintf(fid, 'randomSeed=%d\n', info.randomSeed);
fprintf(fid, 'numRuns=%d\n', info.numRuns);
fprintf(fid, 'kmeansReplicates=%d\n', info.kmeansReplicates);
if isfield(info, 'evalSummaryMode')
    fprintf(fid, 'evalSummaryMode=%s\n', info.evalSummaryMode);
end
if isfield(info, 'bestEvalRun')
    fprintf(fid, 'bestEvalRun=%d\n', info.bestEvalRun);
end
if isfield(info, 'bestEvalSeed')
    fprintf(fid, 'bestEvalSeed=%d\n', info.bestEvalSeed);
end
fprintf(fid, 'anchorCounts=%s\n', mat2str(info.anchorCounts(:)'));
fprintf(fid, 'targetView=%d\n', info.targetView);
if isfield(info, 'anchorQualityMethod')
    fprintf(fid, 'anchorQualityMethod=%s\n', info.anchorQualityMethod);
end
if isfield(info, 'anchorEvidenceGain')
    fprintf(fid, 'anchorEvidenceGain=%s\n', mat2str(info.anchorEvidenceGain(:)', 6));
end
fprintf(fid, '重复评价均值±标准差：\n');
fprintf(fid, 'ACC=%.6f ± %.6f\n', info.evalMeanMetrics(1), info.evalStdMetrics(1));
fprintf(fid, 'NMI=%.6f ± %.6f\n', info.evalMeanMetrics(2), info.evalStdMetrics(2));
fprintf(fid, 'Purity=%.6f ± %.6f\n', info.evalMeanMetrics(3), info.evalStdMetrics(3));
fprintf(fid, 'Fscore=%.6f ± %.6f\n', info.evalMeanMetrics(4), info.evalStdMetrics(4));
if isfield(info, 'evalMinMetrics') && isfield(info, 'evalMaxMetrics')
    fprintf(fid, '重复评价逐指标范围：\n');
    fprintf(fid, 'ACC=[%.6f, %.6f]\n', info.evalMinMetrics(1), info.evalMaxMetrics(1));
    fprintf(fid, 'NMI=[%.6f, %.6f]\n', info.evalMinMetrics(2), info.evalMaxMetrics(2));
    fprintf(fid, 'Purity=[%.6f, %.6f]\n', info.evalMinMetrics(3), info.evalMaxMetrics(3));
    fprintf(fid, 'Fscore=[%.6f, %.6f]\n', info.evalMinMetrics(4), info.evalMaxMetrics(4));
end
fprintf(fid, '选优汇总指标：\n');
fprintf(fid, 'summaryACC=%.6f\n', info.metricsMean(1));
fprintf(fid, 'summaryNMI=%.6f\n', info.metricsMean(2));
fprintf(fid, 'summaryPurity=%.6f\n', info.metricsMean(3));
fprintf(fid, 'summaryFscore=%.6f\n', info.metricsMean(4));
if isfield(info, 'bestEvalMetrics')
    fprintf(fid, 'bestRun指标：ACC=%.6f，NMI=%.6f，Purity=%.6f，Fscore=%.6f\n', ...
        info.bestEvalMetrics(1), info.bestEvalMetrics(2), ...
        info.bestEvalMetrics(3), info.bestEvalMetrics(4));
end
fprintf(fid, '总耗时=%.2fs\n', info.totalTime);
fprintf(fid, '缓存键=%s\n', strjoin(info.cacheKeys, ', '));
end

function key = sanitize_key(textValue)
key = regexprep(char(textValue), '[^a-zA-Z0-9]+', '_');
key = regexprep(key, '_+', '_');
key = regexprep(key, '^_|_$', '');
end
