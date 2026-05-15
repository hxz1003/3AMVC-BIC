

clear;
warning off;
clc;

rootDir = fileparts(mfilename('fullpath'));
addpath(genpath(rootDir));

%% dataset
ds={'Reuters-1200'};
dsPath = fullfile(rootDir, 'dataset');
resultdir = fullfile(rootDir, 'res');
metric = {'ACC','nmi','Purity','Fscore','Precision','Recall','AR','Entropy'};
seed = 1;
neighborOptions = struct('randomSeed', seed);
fprintf('原始 3AMVC demo 固定随机种子 seed=%d。\n', seed);



for dsi =1:length(ds)
    dataName = ds{dsi}; disp(dataName);
    dataFile = fullfile(dsPath, [dataName '.mat']);
    if ~exist(dataFile, 'file')
        error('demo:FileNotFound', '未找到数据集文件：%s', dataFile);
    end
    load(dataFile);
k = length(unique(Y)) ;
n = size(Y,1);
v = length(X);
beta = 100;
lambda = 10^4;

    %%
    for id =  1:length(beta)
        for ic = 1:length(lambda)
            for it = 1 : 1
                for iv = 1:v
                    tic
                    [res_neighbor,time_neighbor,label_neighbor,object,theta,k_neighbor] = Neighbor(X{iv},Y,neighborOptions);
                    thetaall{iv,:} = theta;
                    object_sum(iv,:) = sum(object);
                end
                [~,target_view] = min(object_sum);
                [U,A,Z,iter,obj] = algo_qp(X,Y,thetaall,beta(id),lambda(ic),target_view); % X,Y,lambda,d,theta
                [result(it,:),resultStd(it,:)] = myNMIACCwithmean(U,Y,k); % [ACC nmi Purity Fscore Precision Recall AR Entropy]
                times(it)  = toc;
            end
            max_id = find(result(:,1)==max(result(:,1)), 1, 'first');
            resmax = result(max_id,:);
            resstd = resultStd(max_id,:);
            timem = mean(times);
            fprintf(['Beta:%d\t Lambda:%d\t Res(均值±标准差):' ...
                ' ACC=%12.6f±%.6f NMI=%12.6f±%.6f Purity=%12.6f±%.6f Fscore=%12.6f±%.6f \tTime:%12.6f \n'], ...
                [beta(id) lambda(ic) resmax(1) resstd(1) resmax(2) resstd(2) ...
                resmax(3) resstd(3) resmax(4) resstd(4) timem]);
        end
    end

end
