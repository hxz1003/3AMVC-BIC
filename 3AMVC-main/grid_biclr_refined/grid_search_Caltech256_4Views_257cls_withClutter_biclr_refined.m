clear;  % 清空当前 MATLAB 工作区变量，避免旧变量影响本次 Caltech256 四视图精细搜索。
warning off;  % 关闭警告输出，减少长时间网格搜索时的命令行噪声。
clc;  % 清空命令行窗口，方便只查看本次实验日志。

rootDir = fileparts(fileparts(mfilename('fullpath')));  % 获取 3AMVC-main 根目录：当前脚本在 grid_biclr_refined 下，需要向上两级。
addpath(genpath(rootDir));  % 将根目录及所有子目录加入 MATLAB 路径，确保算法、数据加载和评价函数可被调用。

seed = 1;  % 固定随机种子；用于锚点缓存键和 KMeans 重复评价，保证同配置可复现。
rng(seed, 'twister');  % 初始化 MATLAB 随机数流，避免不同会话中的 KMeans 初始化差异。

config = struct();  % 创建配置结构体，后续字段会传入 run_biclr_grid_search。
config.betaList = [80 100 150 200];  % 粗搜最优 beta=100 且位于粗搜上界，向 150/200 扩展并保留 80 作回退复核。
config.lambdaList = [5e2 1e3 3e3 1e4];  % 粗搜最优 lambda=1e3，保留 1e4 并加入 5e2/3e3 观察局部结构权重敏感性。
config.lambdaBICList = [3 4 5 6];  % 粗搜最优 lambdaBIC=4 且强于 lambdaBIC=2，向更保守的 5/6 扩展。
config.minNodeSizeList = [40 60 80 120];  % 粗搜最优 minNodeSize=80 位于下界，向 40/60 检查更细锚点，并保留 120 作稳健复核。
config.anchorOptions = struct( ...  % BIC-LR 锚点生成的固定工程参数，和 lambdaBIC/minNodeSize 网格共同决定锚点。
    'tauSplit', 0, ...  % 接受分裂的得分阈值；BIC-LR 得分必须大于该值才继续二分，0 表示只接受正收益分裂。
    'epsVar', 1e-8, ...  % 方差数值保护项；避免节点 SSE 极小时对数似然出现 log(0) 或数值不稳定。
    'maxAnchors', 600, ...  % 单视图最大锚点数安全上限；Caltech256 类别多，保留和粗搜一致的上限。
    'verbose', false, ...  % 是否输出每个节点的 BIC-LR 分裂日志；精细搜索中关闭以减少日志量。
    'randomSeed', seed);  % 记录锚点缓存使用的种子编号；该字段会进入缓存键，避免跨种子误复用。
config.evalOptions = struct( ...  % 聚类评价阶段参数，控制 myNMIACCwithmean 中 KMeans 重复评价方式。
    'numRuns', 3, ...  % 外层评价重复次数；沿用粗搜口径，避免 Caltech256 精细搜索成本失控。
    'kmeansReplicates', 1, ...  % 每次 litekmeans 内部随机初始化重复次数；沿用粗搜口径，后续确认最优点时再单独增加重复。
    'useParallel', false, ...  % 是否并行执行外层评价重复；false 表示串行，便于复现和避免并行池开销。
    'baseSeed', seed, ...  % 外层评价随机种子基值；第 i 次评价通常使用 baseSeed+i-1。
    'summaryMode', 'mean');  % 评价汇总模式；mean 表示按 numRuns 均值选优，不把单次最好结果当作平均性能。
config.preprocessTag = 'raw_withClutter_257cls_ordered';  % 数据预处理标签；沿用粗搜结果文件中的 withClutter 257 类有序协议。
config.useCache = true;  % 是否启用锚点缓存；精细搜索中 beta/lambda 改变时可复用同一组锚点缓存。
config.verbose = true;  % 是否输出网格搜索总体进度日志；true 便于观察每组参数的 ACC、NMI、锚点数和耗时。
config.verboseAnchors = false;  % 是否输出锚点生成内部日志；false 表示只看网格层日志，不打印每个节点分裂细节。
config.removeClutter = false;  % 本脚本使用 257 类 withClutter 协议，不删除第 257 类 clutter。
config.maxPerClass = [];  % 不做按类限样；保持 Caltech256_4Views_257cls_withClutter.mat 的完整 30607 样本协议。
config.selectionMetricName = 'ACC';  % 精细搜索仍按 ACC 选择最优组合，其余指标在该组合下同步报告。
config.storeDetailedModel = false;  % 不保存 U/A/Z 等大矩阵，避免精细搜索结果文件过大。
config.saveDir = fullfile(rootDir, 'res_biclr_refined');  % 精细搜索结果保存目录。
config.cacheDir = fullfile(rootDir, 'cache');  % 锚点缓存目录；缓存键包含数据集、视图、lambdaBIC、minNodeSize 和 seed。

results = run_biclr_grid_search('Caltech256_4Views_257cls_withClutter', config);  % 运行 Caltech256 四视图 257 类 BIC-LR+3AMVC 精细搜索并保存结果。
save_best_biclr_acc_result(results, config.saveDir);  % 额外保存按 ACC 选出的最佳配置摘要，便于论文表格整理。
bestUpperMeanMetrics = results.bestUpper.evalMeanMetrics;  % 读取“均值+标准差上界”选优结果的重复评价均值。
bestUpperStdMetrics = results.bestUpper.evalStdMetrics;  % 读取“均值+标准差上界”选优结果的重复评价标准差。
bestMeanMeanMetrics = results.bestMean.evalMeanMetrics;  % 读取“平均 ACC”选优结果的重复评价均值。
bestMeanStdMetrics = results.bestMean.evalStdMetrics;  % 读取“平均 ACC”选优结果的重复评价标准差。

fprintf('Caltech256_4Views_257cls_withClutter 精细搜索完成。固定随机种子=%d。\n', seed);
fprintf(['粗搜参考：bestMean beta=100，lambda=1000，lambdaBIC=4，minNodeSize=80，' ...
    'anchors=[159 62 69 95]，targetView=3，ACC=0.2215±0.0003，NMI=0.4724，Purity=0.2922，Fscore=0.1602，AR=0.1560。\n']);
fprintf(['按 ACC 均值+标准差最高：beta=%g，lambda=%g，lambdaBIC=%g，minNodeSize=%d，' ...
    'ACC=%.4f±%.4f，NMI=%.4f±%.4f，Purity=%.4f±%.4f，Fscore=%.4f±%.4f，AR=%.4f±%.4f，summaryACC=%.4f\n'], ...
    results.bestUpper.beta, results.bestUpper.lambda, results.bestUpper.lambdaBIC, ...
    results.bestUpper.minNodeSize, bestUpperMeanMetrics(1), bestUpperStdMetrics(1), ...
    bestUpperMeanMetrics(2), bestUpperStdMetrics(2), bestUpperMeanMetrics(3), ...
    bestUpperStdMetrics(3), bestUpperMeanMetrics(4), bestUpperStdMetrics(4), ...
    bestUpperMeanMetrics(7), bestUpperStdMetrics(7), results.bestUpper.metricsMean(1));
fprintf(['按重复评价平均 ACC 最高：beta=%g，lambda=%g，lambdaBIC=%g，minNodeSize=%d，' ...
    'ACC=%.4f±%.4f，NMI=%.4f±%.4f，Purity=%.4f±%.4f，Fscore=%.4f±%.4f，AR=%.4f±%.4f，summaryACC=%.4f\n'], ...
    results.bestMean.beta, results.bestMean.lambda, results.bestMean.lambdaBIC, ...
    results.bestMean.minNodeSize, bestMeanMeanMetrics(1), bestMeanStdMetrics(1), ...
    bestMeanMeanMetrics(2), bestMeanStdMetrics(2), bestMeanMeanMetrics(3), ...
    bestMeanStdMetrics(3), bestMeanMeanMetrics(4), bestMeanStdMetrics(4), ...
    bestMeanMeanMetrics(7), bestMeanStdMetrics(7), results.bestMean.metricsMean(1));
