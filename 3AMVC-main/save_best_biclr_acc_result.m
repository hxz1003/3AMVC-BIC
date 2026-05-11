function bestInfo = save_best_biclr_acc_result(results, outputDir)
%SAVE_BEST_BICLR_ACC_RESULT 将按 ACC 选出的最优结果单独保存。
%   BESTINFO = SAVE_BEST_BICLR_ACC_RESULT(RESULTS, OUTPUTDIR) 从
%   RUN_BICLR_GRID_SEARCH 返回的 RESULTS 结构体中提取最优结果，并保存为
%   单独的 .mat 与 .txt 文件，便于后续直接复现实验。
%
%   输入参数：
%   results   : RUN_BICLR_GRID_SEARCH 返回的结果结构体。
%   outputDir : 输出目录；若省略，则默认使用 results.savePath 所在目录。
%
%   输出参数：
%   bestInfo  : 结构体，包含最优参数、指标、锚点数、随机种子和来源文件。

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

best = results.best;
bestInfo = struct();
bestInfo.datasetName = results.datasetName;
bestInfo.selectionMetricName = results.selectionMetricName;
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
bestInfo.anchorCounts = best.anchorCounts;
bestInfo.targetView = best.targetView;
bestInfo.metricsMean = best.metricsMean;
bestInfo.metricsStd = best.metricsStd;
bestInfo.metricNames = best.metricNames;
bestInfo.totalTime = results.totalTime;
bestInfo.cacheKeys = best.cacheKeys;

baseName = sprintf('%s_BICLR_refined_best_ACC', sanitize_key(results.datasetName));
matPath = fullfile(outputDir, [baseName '.mat']);
txtPath = fullfile(outputDir, [baseName '.txt']);
save(matPath, 'bestInfo');

fid = fopen(txtPath, 'w');
if fid < 0
    error('save_best_biclr_acc_result:WriteFailed', '无法写入最优结果摘要：%s', txtPath);
end
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, 'BIC-LR 精细搜索最优 ACC 结果\n');
fprintf(fid, '数据集：%s\n', bestInfo.datasetName);
fprintf(fid, '来源结果文件：%s\n', bestInfo.sourceResultFile);
fprintf(fid, '选择准则：%s\n', bestInfo.selectionMetricName);
fprintf(fid, 'beta=%g\n', bestInfo.beta);
fprintf(fid, 'lambda=%g\n', bestInfo.lambda);
fprintf(fid, 'lambdaBIC=%g\n', bestInfo.lambdaBIC);
fprintf(fid, 'minNodeSize=%d\n', bestInfo.minNodeSize);
fprintf(fid, 'tauSplit=%g\n', bestInfo.tauSplit);
fprintf(fid, 'epsVar=%g\n', bestInfo.epsVar);
fprintf(fid, 'randomSeed=%d\n', bestInfo.randomSeed);
fprintf(fid, 'numRuns=%d\n', bestInfo.numRuns);
fprintf(fid, 'kmeansReplicates=%d\n', bestInfo.kmeansReplicates);
fprintf(fid, 'anchorCounts=%s\n', mat2str(bestInfo.anchorCounts(:)'));
fprintf(fid, 'targetView=%d\n', bestInfo.targetView);
fprintf(fid, 'ACC=%.6f ± %.6f\n', bestInfo.metricsMean(1), bestInfo.metricsStd(1));
fprintf(fid, 'NMI=%.6f ± %.6f\n', bestInfo.metricsMean(2), bestInfo.metricsStd(2));
fprintf(fid, 'Purity=%.6f ± %.6f\n', bestInfo.metricsMean(3), bestInfo.metricsStd(3));
fprintf(fid, 'Fscore=%.6f ± %.6f\n', bestInfo.metricsMean(4), bestInfo.metricsStd(4));
fprintf(fid, '总耗时=%.2fs\n', bestInfo.totalTime);
fprintf(fid, '缓存键=%s\n', strjoin(bestInfo.cacheKeys, ', '));
end

function key = sanitize_key(textValue)
key = regexprep(char(textValue), '[^a-zA-Z0-9]+', '_');
key = regexprep(key, '_+', '_');
key = regexprep(key, '^_|_$', '');
end
