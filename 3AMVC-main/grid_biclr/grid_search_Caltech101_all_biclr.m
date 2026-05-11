clear;
warning off;
clc;

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(rootDir));

config = struct();
config.betaList = [10 100];
config.lambdaList = [1e2 1e3 1e4];
config.lambdaBICList = [1 2 4];
config.minNodeSizeList = [40 80 160];
config.anchorOptions = struct('tauSplit', 0, 'epsVar', 1e-8, 'maxAnchors', 500, 'verbose', false, 'randomSeed', 1);
config.evalOptions = struct('numRuns', 4, 'kmeansReplicates', 2, 'useParallel', false, 'baseSeed', 1);
config.preprocessTag = 'raw';
config.useCache = true;
config.verbose = true;
config.verboseAnchors = false;
config.removeClutter = false;

results = run_biclr_grid_search('Caltech101-all', config); %#ok<NASGU>
