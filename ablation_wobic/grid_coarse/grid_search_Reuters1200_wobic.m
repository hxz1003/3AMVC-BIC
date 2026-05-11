clear;
warning off;
clc;

folderDir = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(folderDir));

config = struct();
results = run_ablation_wobic_grid_search('Reuters-1200', config); %#ok<NASGU>
