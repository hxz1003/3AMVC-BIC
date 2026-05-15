clear;
warning off;
clc;

rootDir = fileparts(mfilename('fullpath'));
addpath(genpath(rootDir));

dataName = 'MFeat_2Views';
beta = 100;
lambda = 1e4;

anchorOptions = struct();
anchorOptions.lambdaBIC = 1;
anchorOptions.minNodeSize = 20;
anchorOptions.tauSplit = 0;
anchorOptions.epsVar = 1e-8;
anchorOptions.maxAnchors = 400;
anchorOptions.verbose = true;
anchorOptions.randomSeed = 1;

evalOptions = struct();
evalOptions.numRuns = 10;
evalOptions.kmeansReplicates = 3;
evalOptions.useParallel = false;
evalOptions.baseSeed = 1;
evalOptions.summaryMode = 'bestACC';

fprintf('===== demo_biclr 开始 =====\n');
fprintf('数据集=%s，beta=%g，lambda=%g，lambdaBIC=%g，minNodeSize=%d，seed=%d\n', ...
    dataName, beta, lambda, anchorOptions.lambdaBIC, anchorOptions.minNodeSize, anchorOptions.randomSeed);

[X, Y, meta] = load_biclr_dataset(dataName, struct('verbose', true));
k = meta.numClusters;
v = meta.numViews;

thetaall = cell(v, 1);
object_sum = zeros(v, 1);
infoAll = cell(v, 1);

totalTimer = tic;
for iv = 1:v
    fprintf('--- 视图 %d / %d 锚点生成 ---\n', iv, v);
    [~, time_neighbor, ~, object, theta, class, info] = Neighbor_BICLR(X{iv}, Y, anchorOptions);
    thetaall{iv} = theta;
    object_sum(iv) = sum(object);
    infoAll{iv} = info;
    fprintf(['视图 %d：锚点数=%d，SSE=%.6f，单位BIC证据增益=%.6g，' ...
        'BIC质量分=%.6g，耗时=%.2fs\n'], ...
        iv, class, object_sum(iv), info.viewEvidence.unitGain, ...
        info.qualityScore, time_neighbor);
end

[target_view, qualityScores, unitGains] = biclr_select_target_view(infoAll);
fprintf('基准视图编号=%d（按单位 BIC 证据增益最大选择）\n', target_view);
fprintf('各视图单位 BIC 证据增益=%s\n', mat2str(unitGains', 6));

algoTimer = tic;
[U, A, Z, iter, obj] = algo_qp(X, Y, thetaall, beta, lambda, target_view);
algoTime = toc(algoTimer);
[resultSummary, ~, evalInfo] = myNMIACCwithmean(U, Y, k, evalOptions);
resultMean = evalInfo.meanMetrics;
resultStd = evalInfo.stdMetrics;
totalTime = toc(totalTimer);

fprintf('algo_qp 迭代次数=%d，最终目标值=%.6f\n', iter, obj(end));
fprintf('每个视图锚点数=%s\n', mat2str(cellfun(@(s) s.numAnchors, infoAll)'));
fprintf('重复评价均值±标准差：ACC=%.4f±%.4f，NMI=%.4f±%.4f，Purity=%.4f±%.4f，Fscore=%.4f±%.4f\n', ...
    resultMean(1), resultStd(1), resultMean(2), resultStd(2), ...
    resultMean(3), resultStd(3), resultMean(4), resultStd(4));
if strcmpi(evalInfo.summaryMode, 'bestacc')
    fprintf('bestACC 汇总指标：ACC=%.4f，NMI=%.4f，Purity=%.4f，Fscore=%.4f，bestRun=%d，seed=%d\n', ...
        resultSummary(1), resultSummary(2), resultSummary(3), resultSummary(4), ...
        evalInfo.bestRunIndex, evalInfo.bestRunSeed);
end
fprintf('algo_qp 耗时=%.2fs，总耗时=%.2fs\n', algoTime, totalTime);

demoResult = struct();
demoResult.dataName = dataName;
demoResult.beta = beta;
demoResult.lambda = lambda;
demoResult.anchorOptions = anchorOptions;
demoResult.evalOptions = evalOptions;
demoResult.targetView = target_view;
demoResult.viewQualityScores = qualityScores;
demoResult.unitBICEvidence = unitGains;
demoResult.infoAll = infoAll;
demoResult.resultSummary = resultSummary;
demoResult.resultMean = resultMean;
demoResult.resultStd = resultStd;
demoResult.evalInfo = evalInfo;
demoResult.iter = iter;
demoResult.obj = obj;
demoResult.U = U;
demoResult.A = A;
demoResult.Z = Z;

fprintf('===== demo_biclr 结束 =====\n');
