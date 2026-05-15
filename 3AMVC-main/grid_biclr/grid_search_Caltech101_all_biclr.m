clear;  % 清空当前 MATLAB 工作区变量，避免旧变量影响本次 Caltech101-all 粗网格搜索。
warning off;  % 关闭警告输出，减少长时间网格搜索时的命令行噪声。
clc;  % 清空命令行窗口，方便只查看本次实验日志。

rootDir = fileparts(fileparts(mfilename('fullpath')));  % 获取 3AMVC-main 根目录：当前脚本在 grid_biclr 下，需要向上两级。
addpath(genpath(rootDir));  % 将根目录及所有子目录加入 MATLAB 路径，确保算法、数据加载和评价函数可被调用。

config = struct();  % 创建配置结构体，后续字段会传入 run_biclr_grid_search。
config.betaList = [10 100];  % 3AMVC 主优化中的 beta 候选；Caltech101-all 规模较大，这里使用较少候选控制总耗时。
config.lambdaList = [1e2 1e3 1e4];  % 3AMVC 对齐阶段的 lambda 候选；控制跨视图锚图对齐的正则/权衡强度。
config.lambdaBICList = [1 2 4];  % BIC-LR 中 BIC 惩罚系数候选；Caltech101-all 使用偏保守范围以避免锚点过多。
config.minNodeSizeList = [40 80 160];  % BIC-LR 子节点最小样本数候选；大数据集使用较大下限以控制锚点数和运行时间。
config.anchorOptions = struct( ...  % BIC-LR 锚点生成的固定工程参数，和 lambdaBIC/minNodeSize 网格共同决定锚点。
    'tauSplit', 0, ...  % 接受分裂的得分阈值；BIC-LR 得分必须大于该值才继续二分，0 表示只接受正收益分裂。
    'epsVar', 1e-8, ...  % 方差数值保护项；避免节点 SSE 极小时对数似然出现 log(0) 或数值不稳定。
    'maxAnchors', 500, ...  % 单视图最大锚点数安全上限；Caltech101-all 视图较大，因此允许最多 500 个锚点。
    'verbose', false, ...  % 是否输出每个节点的 BIC-LR 分裂日志；粗网格搜索中关闭以减少日志量。
    'randomSeed', 1);  % 记录锚点缓存使用的种子编号；BIC-LR 本身确定性较强，但该字段会进入缓存键。
config.evalOptions = struct( ...  % 聚类评价阶段参数，控制 myNMIACCwithmean 中 KMeans 重复评价方式。
    'numRuns', 4, ...  % 外层评价重复次数；Caltech101-all 计算更重，因此粗搜索只重复 4 次并按 summaryMode 汇总。
    'kmeansReplicates', 2, ...  % 每次 litekmeans 内部随机初始化重复次数；此处取 2 以降低大数据集评价成本。
    'useParallel', false, ...  % 是否并行执行外层评价重复；false 表示串行，便于复现和避免并行池开销。
    'baseSeed', 1, ...  % 外层评价随机种子基值；第 i 次评价通常使用 baseSeed+i-1。
    'summaryMode', 'bestACC');  % 评价汇总模式；bestACC 表示返回 numRuns 中 ACC 最高那一次，mean 表示返回均值。
config.preprocessTag = 'raw';  % 数据预处理标签；raw 表示使用原始数据，也会写入缓存文件名区分不同预处理。
config.useCache = true;  % 是否启用锚点缓存；true 会复用/保存 cacheDir 中同参数的单视图 BIC-LR 锚点结果。
config.verbose = true;  % 是否输出网格搜索总体进度日志；true 便于观察每组参数的 ACC、NMI 和耗时。
config.verboseAnchors = false;  % 是否输出锚点生成内部日志；false 表示只看网格层日志，不打印每个节点分裂细节。
config.removeClutter = false;  % 是否删除 Caltech 数据集中的 clutter 类；false 表示保留原始标签和全部样本。

results = run_biclr_grid_search('Caltech101-all', config);  % 运行 Caltech101-all 的 BIC-LR+3AMVC 网格搜索并保存结果。
