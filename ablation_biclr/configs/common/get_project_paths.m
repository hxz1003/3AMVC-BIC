function paths = get_project_paths()
%GET_PROJECT_PATHS 返回 BIC-LR 消融框架的项目路径。
%   PATHS = GET_PROJECT_PATHS() 自动定位项目总根目录、3AMVC-main 主代码
%   目录以及 ablation_biclr 下的结果、缓存和报告目录。
%
%   输出参数：
%   paths.repoRoot     : 项目总根目录。
%   paths.mainCodeRoot : 原 3AMVC 主代码目录。
%   paths.ablationRoot : 当前消融实验框架目录。
%   paths.dataRoot     : 原 3AMVC 数据集目录。
%   paths.resRoot      : 消融结果保存目录。
%   paths.cacheRoot    : 消融缓存保存目录。
%   paths.reportRoot   : 消融报告输出目录。

thisFile = mfilename('fullpath');
commonDir = fileparts(thisFile);
configsDir = fileparts(commonDir);
paths.ablationRoot = fileparts(configsDir);
paths.repoRoot = fileparts(paths.ablationRoot);
paths.mainCodeRoot = fullfile(paths.repoRoot, '3AMVC-main');
paths.dataRoot = fullfile(paths.mainCodeRoot, 'dataset');
paths.resRoot = fullfile(paths.ablationRoot, 'res');
paths.cacheRoot = fullfile(paths.ablationRoot, 'cache');
paths.reportRoot = fullfile(paths.ablationRoot, 'reports');

if ~exist(paths.mainCodeRoot, 'dir')
    error('get_project_paths:MissingMainCode', ...
        '未找到 3AMVC-main 主代码目录：%s', paths.mainCodeRoot);
end
if ~exist(paths.ablationRoot, 'dir')
    error('get_project_paths:MissingAblationRoot', ...
        '未找到 ablation_biclr 目录：%s', paths.ablationRoot);
end
end
