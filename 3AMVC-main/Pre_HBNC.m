function [label, object, theta, num_class, class] = Pre_HBNC(X0, options)
%PRE_HBNC 原始 HBNC 路径的预划分阶段。
%   [LABEL, OBJECT, THETA, NUM_CLASS, CLASS] = PRE_HBNC(X0) 使用固定默认
%   随机种子选择初始目标样本，以保证原始 HBNC 路径可复现。
%
%   [...] = PRE_HBNC(X0, OPTIONS) 支持 OPTIONS.randomSeed。若将
%   randomSeed 设为空，则沿用当前 MATLAB 随机状态。

if nargin < 2
    options = struct();
end
validateattributes(X0, {'double', 'single'}, {'2d', 'nonempty', 'real'}, mfilename, 'X0', 1);
if any(~isfinite(X0(:)))
    error('Pre_HBNC:InvalidData', 'X0 含有 NaN 或 Inf，请先检查数据。');
end
if ~isfield(options, 'randomSeed')
    options.randomSeed = 1;
end

flag = 1;
n = size(X0,1);
label = zeros(n,1);
if ~isempty(options.randomSeed)
    rngState = rng;
    cleanupObj = onCleanup(@() rng(rngState));
    rng(options.randomSeed, 'twister');
end
target = randi([1 n]);
target_range_label = ones(n,1);
target_range_label = target_range_label > 0;
class = 1;

while flag
    target_range = X0(target_range_label,:);
    n_target = size(target_range,1);
    clear target_distance;
    for i=1:n_target
        target_distance(i,:) = norm(X0(target,:)-target_range(i,:))^2;
    end
    target_class_label = criterion(target_distance);
    
        % Distinguish samples within the target range
    target_label = target_range_label;
    target_label_loc = find(target_range_label==1);
    target_label(target_label_loc(target_class_label==0)) = 0;
    target_label_other = target_range_label & ~target_label;
    
        % Update class label
    % 原始 HBNC 仅当剩余样本超过 5 个时继续保留待分裂区域，避免极小尾部簇反复生成。
    if sum(target_label_other)>5
        label(target_label) = class;
        theta(class,:) = mean(X0(target_label,:),1);
        nc = sum(target_label);
        num_class(class,:) = nc;
        clear Xclass;
        Xclass = X0(target_label,:);
        clear object_distance;
        for i=1:nc
            object_distance(i,:) = norm(theta(class,:)-Xclass(i,:))^2;
        end
        object(class,:) = sum(object_distance);
        
        % find next target
        target_range_loc = find(target_range_label==1);
        [~,next_target_loc]=max(target_distance);
        target = target_range_loc(next_target_loc);
        target_range_label = label == 0;
        class = class + 1;
    elseif sum(target_label_other)>0
        label(label==0) = class;
        theta(class,:) = mean(X0(label==class,:),1);
        nc = sum(label==class);
        num_class(class,:) = nc;
        clear Xclass;
        Xclass = X0(label==class,:);
        clear object_distance;
        for i=1:nc
            object_distance(i,:) = norm(theta(class,:)-Xclass(i,:))^2;
        end
        object(class,:) = sum(object_distance);
        flag = 0;
    else
        flag = 0;
    end
end
