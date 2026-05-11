clear;
warning off;
clc;

folderDir = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(folderDir));

config = struct();
results = run_ablation_woalignment_grid_search('Caltech101-all', config); %#ok<NASGU>
