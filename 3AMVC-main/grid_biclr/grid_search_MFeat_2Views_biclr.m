clear;
warning off;
clc;

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(rootDir));

config = struct();
config.betaList = [1 10 100];
config.lambdaList = [1e3 1e4 1e5];
config.lambdaBICList = [0.5 1 2];
config.minNodeSizeList = [10 20 40];
config.anchorOptions = struct('tauSplit', 0, 'epsVar', 1e-8, 'maxAnchors', 400, 'verbose', false, 'randomSeed', 1);
config.evalOptions = struct('numRuns', 8, 'kmeansReplicates', 3, 'useParallel', false, 'baseSeed', 1);
config.preprocessTag = 'raw';
config.useCache = true;
config.verbose = true;
config.verboseAnchors = false;

results = run_biclr_grid_search('MFeat_2Views', config); %#ok<NASGU>
