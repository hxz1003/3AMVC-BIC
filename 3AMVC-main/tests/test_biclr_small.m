function tests = test_biclr_small
%TEST_BICLR_SMALL BIC-LR 锚点选择与评价接口的最小单元测试。
tests = functiontests(localfunctions);
end

function testNeighborBICLRBasic(testCase)
rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(rootDir));

rng(1, 'twister');
X = [randn(30, 2) * 0.15 + [-2, -2]; ...
    randn(30, 2) * 0.15 + [2, 2]; ...
    randn(30, 2) * 0.15 + [-2, 2]];
Y = [ones(30, 1); 2 * ones(30, 1); 3 * ones(30, 1)];

options = struct('lambdaBIC', 1, 'minNodeSize', 8, 'tauSplit', 0, ...
    'epsVar', 1e-8, 'maxAnchors', 12, 'verbose', false, 'randomSeed', 1);
[res, ~, label_neighbor, object, theta, class, info] = Neighbor_BICLR(X, Y, options);

verifyGreaterThanOrEqual(testCase, class, 3, 'BIC-LR 至少应产生 3 个锚点。');
verifyEqual(testCase, numel(unique(label_neighbor)), class, '标签类别数与锚点数不一致。');
verifyEqual(testCase, size(theta, 1), class, '锚点中心数量与 class 不一致。');
verifyEqual(testCase, numel(object), class, 'object 长度与锚点数不一致。');
verifyGreaterThanOrEqual(testCase, res(1), 0.5, '该合成数据上的 ACC 不应过低。');
verifyEqual(testCase, sum(object), info.totalSSE, 'AbsTol', 1e-8, '总 SSE 记录不一致。');
end

function testMyNMIACCwithmeanOptionalOptions(testCase)
rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(rootDir));

U = eye(6);
Y = [1; 1; 2; 2; 3; 3];
evalOptions = struct('numRuns', 2, 'kmeansReplicates', 1, 'useParallel', false, 'baseSeed', 5);
[meanMetric, stdMetric, evalInfo] = myNMIACCwithmean(U, Y, 3, evalOptions);

verifySize(testCase, meanMetric, [1, 8]);
verifySize(testCase, stdMetric, [1, 8]);
verifyGreaterThanOrEqual(testCase, meanMetric(1), 0);
verifyLessThanOrEqual(testCase, meanMetric(1), 1);
verifyEqual(testCase, evalInfo.summaryMode, 'mean');
verifySize(testCase, evalInfo.allMetrics, [2, 8]);
verifySize(testCase, evalInfo.minMetrics, [1, 8]);
verifySize(testCase, evalInfo.maxMetrics, [1, 8]);
verifyLessThanOrEqual(testCase, evalInfo.minMetrics(1), meanMetric(1));
verifyGreaterThanOrEqual(testCase, evalInfo.maxMetrics(1), meanMetric(1));
end

function testMyNMIACCwithmeanBestACCMode(testCase)
rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(rootDir));

U = eye(6);
Y = [1; 1; 2; 2; 3; 3];
evalOptions = struct('numRuns', 3, 'kmeansReplicates', 1, ...
    'useParallel', false, 'baseSeed', 5, 'summaryMode', 'bestACC');
[bestMetric, stdMetric, evalInfo] = myNMIACCwithmean(U, Y, 3, evalOptions);

verifySize(testCase, bestMetric, [1, 8]);
verifySize(testCase, stdMetric, [1, 8]);
verifyEqual(testCase, evalInfo.summaryMode, 'bestacc');
verifyEqual(testCase, bestMetric, evalInfo.bestRunMetrics, 'AbsTol', 1e-12);
verifyEqual(testCase, bestMetric(1), max(evalInfo.allMetrics(:, 1)), 'AbsTol', 1e-12);
end
