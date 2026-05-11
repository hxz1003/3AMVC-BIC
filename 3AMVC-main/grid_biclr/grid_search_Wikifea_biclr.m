clear;
warning off;
clc;

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(rootDir));

config = struct();
config.betaList = [1 10 100];
config.lambdaList = [1e2 1e3 1e4];
config.lambdaBICList = [0.5 1 2 4];
config.minNodeSizeList = [10 20 40];
config.anchorOptions = struct('tauSplit', 0, 'epsVar', 1e-8, 'maxAnchors', 400, 'verbose', false, 'randomSeed', 1);
config.evalOptions = struct('numRuns', 6, 'kmeansReplicates', 3, 'useParallel', false, 'baseSeed', 1);
config.preprocessTag = 'raw';
config.useCache = true;
config.verbose = true;
config.verboseAnchors = false;

results = run_biclr_grid_search('Wikifea', config); %#ok<NASGU>
