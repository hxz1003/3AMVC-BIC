clear;  % 清空当前 MATLAB 工作区变量，避免旧变量影响本次 Wikifea 精细搜索。
warning off;  % 关闭警告输出，减少长时间网格搜索时的命令行噪声。
clc;  % 清空命令行窗口，方便只查看本次实验日志。

rootDir = fileparts(fileparts(mfilename('fullpath')));  % 获取 3AMVC-main 根目录：当前脚本在 grid_biclr_refined 下，需要向上两级。
addpath(genpath(rootDir));  % 将根目录及所有子目录加入 MATLAB 路径，确保算法、数据加载和评价函数可被调用。

seed = 1;  % 固定随机种子；用于锚点缓存键和 KMeans 重复评价，保证同配置可复现。
rng(seed, 'twister');  % 初始化 MATLAB 随机数流，避免不同会话中的 KMeans 初始化差异。

config = struct();  % 创建配置结构体，后续字段会传入 run_biclr_grid_search。
config.betaList = [80 100 120 160 200];  % 200905 结果中高值全部落在 beta=100 的粗搜上界，向 160/200 继续复核。
config.lambdaList = [1e2 3e2 1e3 3e3 1e4];  % 高值覆盖 1e2/1e3/1e4，加入 3e2/3e3 检查对齐强度过渡区。
config.lambdaBICList = [2 3 4 5 6];  % bestSummary 在 2，bestMean/bestUpper 在 4，同时向更强惩罚 5/6 外扩。
config.minNodeSizeList = [10 20 30 40 50];  % bestMean 在 10，bestSummary/bestUpper 在 40，保留两端并加入中间节点规模。
config.anchorOptions = struct( ...  % BIC-LR 锚点生成的固定工程参数，和 lambdaBIC/minNodeSize 网格共同决定锚点。
    'tauSplit', 0, ...  % 接受分裂的得分阈值；BIC-LR 得分必须大于该值才继续二分，0 表示只接受正收益分裂。
    'epsVar', 1e-8, ...  % 方差数值保护项；避免节点 SSE 极小时对数似然出现 log(0) 或数值不稳定。
    'maxAnchors', 400, ...  % 单视图最大锚点数安全上限；防止递归过度分裂导致锚点过多和计算过慢。
    'verbose', false, ...  % 是否输出每个节点的 BIC-LR 分裂日志；精细搜索中关闭以减少日志量。
    'randomSeed', seed);  % 记录锚点缓存使用的种子编号；该字段会进入缓存键，避免跨种子误复用。
config.evalOptions = struct( ...  % 聚类评价阶段参数，控制 myNMIACCwithmean 中 KMeans 重复评价方式。
    'numRuns', 8, ...  % 外层评价重复次数；精细搜索比粗搜索更重视结果稳定性。
    'kmeansReplicates', 4, ...  % 每次 litekmeans 内部随机初始化重复次数；提高最终 ACC/NMI 统计稳定性。
    'useParallel', false, ...  % 是否并行执行外层评价重复；false 表示串行，便于复现和避免并行池开销。
    'baseSeed', seed, ...  % 外层评价随机种子基值；第 i 次评价通常使用 baseSeed+i-1。
    'summaryMode', 'bestACC');  % 评价汇总模式；bestACC 表示返回 numRuns 中 ACC 最高那一次，mean 表示返回均值。
config.preprocessTag = 'raw';  % 数据预处理标签；raw 表示使用原始数据，也会写入缓存文件名区分不同预处理。
config.useCache = true;  % 是否启用锚点缓存；精细搜索只改变 beta/lambda 时可以安全复用同锚点配置。
config.verbose = true;  % 是否输出网格搜索总体进度日志；true 便于观察每组参数的 ACC、NMI 和耗时。
config.verboseAnchors = false;  % 是否输出锚点生成内部日志；false 表示只看网格层日志，不打印每个节点分裂细节。
config.removeClutter = false;  % Wikifea 不涉及 clutter 类，保留该字段以保持脚本字段风格统一。
config.selectionMetricName = 'ACC';  % 精细搜索仍按 ACC 选择最优组合，其余指标在该组合下同步报告。
config.storeDetailedModel = false;  % 不保存 U/A/Z 等大矩阵，避免精细搜索结果文件过大。
config.saveDir = fullfile(rootDir, 'res_biclr_refined');  % 精细搜索结果保存目录。
config.cacheDir = fullfile(rootDir, 'cache');  % 锚点缓存目录；缓存键包含数据集、视图、lambdaBIC、minNodeSize 和 seed。

results = run_biclr_grid_search('Wikifea', config);  % 运行 Wikifea 的 BIC-LR+3AMVC 精细搜索并保存结果。
save_best_biclr_acc_result(results, config.saveDir);  % 额外保存按 ACC 选出的最佳配置摘要，便于论文表格整理。
bestUpperMeanMetrics = results.bestUpper.evalMeanMetrics;  % 读取“均值+标准差上界”选优结果的重复评价均值。
bestUpperStdMetrics = results.bestUpper.evalStdMetrics;  % 读取“均值+标准差上界”选优结果的重复评价标准差。
bestMeanMeanMetrics = results.bestMean.evalMeanMetrics;  % 读取“平均 ACC”选优结果的重复评价均值。
bestMeanStdMetrics = results.bestMean.evalStdMetrics;  % 读取“平均 ACC”选优结果的重复评价标准差。

fprintf('Wikifea 精细搜索完成。固定随机种子=%d。\n', seed);
fprintf(['按 ACC 均值+标准差最高：beta=%g，lambda=%g，lambdaBIC=%g，minNodeSize=%d，' ...
    'ACC=%.4f±%.4f，summaryACC=%.4f\n'], ...
    results.bestUpper.beta, results.bestUpper.lambda, results.bestUpper.lambdaBIC, ...
    results.bestUpper.minNodeSize, bestUpperMeanMetrics(1), bestUpperStdMetrics(1), ...
    results.bestUpper.metricsMean(1));
fprintf(['按重复评价平均 ACC 最高：beta=%g，lambda=%g，lambdaBIC=%g，minNodeSize=%d，' ...
    'ACC=%.4f±%.4f，summaryACC=%.4f\n'], ...
    results.bestMean.beta, results.bestMean.lambda, results.bestMean.lambdaBIC, ...
    results.bestMean.minNodeSize, bestMeanMeanMetrics(1), bestMeanStdMetrics(1), ...
    results.bestMean.metricsMean(1));
