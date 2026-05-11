clear;
warning off;
clc;

folderDir = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(folderDir));

config = struct();
results = run_ablation_wolr_grid_search('MFeat_2Views', config); %#ok<NASGU>
