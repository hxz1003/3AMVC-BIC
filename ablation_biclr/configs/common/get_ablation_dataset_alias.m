function datasetInfo = get_ablation_dataset_alias(datasetName)
%GET_ABLATION_DATASET_ALIAS 解析消融实验数据集别名。
%   DATASETINFO = GET_ABLATION_DATASET_ALIAS(DATASETNAME) 将用户输入的数据集
%   名称映射到 3AMVC-main 中的真实 .mat 文件名和消融结果目录名。
%
%   输入参数：
%   datasetName : 数据集名称或别名，例如 'Mfeat'、'Ruter-1200'、'WIKI'。
%
%   输出参数：
%   datasetInfo.inputName         : 原始输入名称。
%   datasetInfo.canonicalName     : 3AMVC-main/dataset 下不带 .mat 的文件名。
%   datasetInfo.resultDirName     : ablation_biclr/res 中使用的目录名。
%   datasetInfo.possibleFileNames : 可能的数据文件名列表。
%   datasetInfo.possibleDataDirs  : 可能的数据目录列表。

if nargin < 1 || isempty(datasetName)
    error('get_ablation_dataset_alias:MissingName', '必须提供数据集名称。');
end
if isstring(datasetName)
    datasetName = char(datasetName);
end
validateattributes(datasetName, {'char'}, {'row', 'nonempty'}, mfilename, 'datasetName', 1);

paths = get_project_paths();
key = lower(regexprep(datasetName, '[^a-zA-Z0-9]+', ''));

datasetInfo = struct();
datasetInfo.inputName = datasetName;
datasetInfo.aliasKey = key;
datasetInfo.possibleDataDirs = {paths.dataRoot, paths.mainCodeRoot};

switch key
    case {'mfeat', 'mfeat2views'}
        datasetInfo.canonicalName = 'MFeat_2Views';
        datasetInfo.resultDirName = 'Mfeat';
        datasetInfo.displayName = 'Mfeat';
        datasetInfo.possibleFileNames = {'MFeat_2Views.mat', 'MFeat.mat', 'Mfeat.mat', 'mfeat.mat'};
    case {'ruter1200', 'reuters1200', 'reuters'}
        datasetInfo.canonicalName = 'Reuters-1200';
        datasetInfo.resultDirName = 'Ruter1200';
        datasetInfo.displayName = 'Ruter1200';
        datasetInfo.possibleFileNames = {'Reuters-1200.mat', 'Reuters1200.mat', ...
            'Ruter-1200.mat', 'Ruter1200.mat', 'Reuters.mat'};
    case {'wiki', 'wikifea'}
        datasetInfo.canonicalName = 'Wikifea';
        datasetInfo.resultDirName = 'WIKI';
        datasetInfo.displayName = 'WIKI';
        datasetInfo.possibleFileNames = {'Wikifea.mat', 'WIKI.mat', 'Wiki.mat', 'wiki.mat'};
    case {'catlch101all', 'caltech101all', 'caltech101'}
        datasetInfo.canonicalName = 'Caltech101-all';
        datasetInfo.resultDirName = 'Catlch101All';
        datasetInfo.displayName = 'Catlch101All';
        datasetInfo.possibleFileNames = {'Caltech101-all.mat', 'Caltech101_all.mat', ...
            'Catlch101All.mat', 'Caltech101.mat'};
    case {'foresttypes', 'foresttype', 'forest'}
        datasetInfo.canonicalName = 'ForestTypes';
        datasetInfo.resultDirName = 'ForestTypes';
        datasetInfo.displayName = 'ForestTypes';
        datasetInfo.possibleFileNames = {'ForestTypes.mat', 'ForestType.mat', 'foresttypes.mat'};
    case {'caltech2564views257clswithclutter', 'caltech256withclutter', 'caltech256'}
        datasetInfo.canonicalName = 'Caltech256_4Views_257cls_withClutter';
        datasetInfo.resultDirName = 'Caltech256_4Views_257cls_withClutter';
        datasetInfo.displayName = 'Caltech256_4Views_257cls_withClutter';
        datasetInfo.possibleFileNames = {'Caltech256_4Views_257cls_withClutter.mat', ...
            'Caltech256.mat', 'Caltech256_withClutter.mat'};
    otherwise
        error('get_ablation_dataset_alias:UnsupportedDataset', ...
            ['不支持的数据集别名：%s。\n支持：Mfeat/MFeat/mfeat，Ruter-1200/Ruter1200/' ...
             'Reuters-1200/Reuters1200/Reuters，WIKI/Wiki/wiki，catlch101 all/' ...
             'Catlch101All/Caltech101-all/Caltech101_all/Caltech101，ForestTypes/Forest，' ...
             'Caltech256_4Views_257cls_withClutter/Caltech256。'], datasetName);
end

datasetInfo.dataFile = locate_dataset_file(datasetInfo);
end

function dataFile = locate_dataset_file(datasetInfo)
dataFile = '';
for idir = 1:numel(datasetInfo.possibleDataDirs)
    dataDir = datasetInfo.possibleDataDirs{idir};
    for ifile = 1:numel(datasetInfo.possibleFileNames)
        candidate = fullfile(dataDir, datasetInfo.possibleFileNames{ifile});
        if exist(candidate, 'file')
            dataFile = candidate;
            return;
        end
    end
end
end
