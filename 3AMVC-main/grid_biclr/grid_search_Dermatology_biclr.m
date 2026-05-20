clear;  % 清空当前 MATLAB 工作区变量，避免旧变量影响本次 Dermatology 粗网格搜索。
warning off;  % 关闭警告输出，减少长时间网格搜索时的命令行噪声。
clc;  % 清空命令行窗口，方便只查看本次实验日志。

rootDir = fileparts(fileparts(mfilename('fullpath')));  % 获取 3AMVC-main 根目录：当前脚本在 grid_biclr 下，需要向上两级。
addpath(genpath(rootDir));  % 将根目录及所有子目录加入 MATLAB 路径，确保算法、数据加载和评价函数可被调用。

config = struct();  % 创建配置结构体，后续字段会传入 run_biclr_grid_search。
config.betaList = [1 10 100];  % Dermatology 是小样本低维数据，先沿用轻量级 beta 粗搜索范围。
config.lambdaList = [1e1 1e2 1e3];  % 低维医学特征尺度较小，对齐正则从 10 到 1000 做数量级扫描。
config.lambdaBICList = [0.5 1 2];  % BIC-LR 惩罚系数采用常规粗搜索范围，覆盖偏细到偏保守分裂。
config.minNodeSizeList = [5 10 20];  % 样本数为 358，允许较小节点以避免少数类被过早停止分裂。
config.anchorOptions = struct( ...  % BIC-LR 锚点生成的固定工程参数，和 lambdaBIC/minNodeSize 网格共同决定锚点。
    'tauSplit', 0, ...  % 接受分裂的得分阈值；BIC-LR 得分必须大于该值才继续二分，0 表示只接受正收益分裂。
    'epsVar', 1e-8, ...  % 方差数值保护项；避免节点 SSE 极小时对数似然出现 log(0) 或数值不稳定。
    'maxAnchors', 200, ...  % Dermatology 样本量较小，设置安全上限防止异常过分裂。
    'verbose', false, ...  % 是否输出每个节点的 BIC-LR 分裂日志；粗网格搜索中关闭以减少日志量。
    'randomSeed', 1);  % 记录锚点缓存使用的种子编号；该字段会进入缓存键，避免跨种子误复用。
config.evalOptions = struct( ...  % 聚类评价阶段参数，控制 myNMIACCwithmean 中 KMeans 重复评价方式。
    'numRuns', 6, ...  % 外层评价重复次数；对同一嵌入 U 重复运行 KMeans 后按 summaryMode 汇总指标。
    'kmeansReplicates', 3, ...  % 每次 litekmeans 内部随机初始化重复次数；越大通常评价更稳定但更耗时。
    'useParallel', false, ...  % 是否并行执行外层评价重复；false 表示串行，便于复现和避免并行池开销。
    'baseSeed', 1, ...  % 外层评价随机种子基值；第 i 次评价通常使用 baseSeed+i-1。
    'summaryMode', 'bestACC');  % 评价汇总模式；bestACC 表示返回 numRuns 中 ACC 最高那一次，mean 表示返回均值。
config.preprocessTag = 'raw';  % 数据预处理标签；raw 表示使用原始数据，也会写入缓存文件名区分不同预处理。
config.useCache = true;  % 是否启用锚点缓存；true 会复用/保存 cacheDir 中同参数的单视图 BIC-LR 锚点结果。
config.verbose = true;  % 是否输出网格搜索总体进度日志；true 便于观察每组参数的 ACC、NMI 和耗时。
config.verboseAnchors = false;  % 是否输出锚点生成内部日志；false 表示只看网格层日志，不打印每个节点分裂细节。

results = run_biclr_grid_search('Dermatology', config);  % 运行 Dermatology 的 BIC-LR+3AMVC 网格搜索并保存结果。
