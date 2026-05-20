function [label,object,theta,num_class,class] = Impro_HBNC(X0,label_pre,~)
%IMPRO_HBNC 原始 HBNC 路径的迭代改进阶段。
%   [LABEL, OBJECT, THETA, NUM_CLASS, CLASS] = IMPRO_HBNC(X0, LABEL_PRE, OBJECT_PRE)
%   在 Pre_HBNC 的预划分结果上处理离群点并继续按原始 HBNC 判据细分高 SSE 节点。
%
%   输入参数：
%   X0        : n*d 的单视图特征矩阵。
%   label_pre : n*1 的预划分标签，要求为正整数。
%   object_pre: 预划分阶段的节点 SSE，仅为兼容原始接口保留。
%
%   输出参数：
%   label     : n*1 的最终锚点标签。
%   object    : class*1 的每个锚点 SSE。
%   theta     : class*d 的锚点中心。
%   num_class : class*1 的每个锚点样本数。
%   class     : 最终锚点数量。

validateattributes(X0, {'double', 'single'}, {'2d', 'nonempty', 'real'}, mfilename, 'X0', 1);
validateattributes(label_pre, {'double', 'single'}, {'vector', 'nonempty', 'real', 'integer', 'positive'}, mfilename, 'label_pre', 2);
if any(~isfinite(X0(:))) || any(~isfinite(label_pre(:)))
    error('Impro_HBNC:InvalidInput', 'X0 或 label_pre 含有 NaN 或 Inf。');
end
n = size(X0,1);
label_pre = label_pre(:);
if numel(label_pre) ~= n
    error('Impro_HBNC:SizeMismatch', 'label_pre 的长度必须等于 X0 的样本数。');
end
flag = 1;
iter = 1;
% Process Outliers
[label,theta,num_class,class] = Pro_Out(X0,label_pre);


while flag

    % Update variables
    for i=1:class
        clear Xclass;
        Xclass = X0(label==i,:);
        clear object_distance;
        for j = 1:num_class(i)
            object_distance(j,:) = norm(theta(i,:)-Xclass(j,:))^2;
        end
        object(i,:) = sum(object_distance);
    end
    
   % find target range 
   [~,class_max] = max(object);
    target_range_label = label == class_max;

    % Randomly select a target sample in the target range
    next_target_selection = find(target_range_label==1);
    target = next_target_selection(randi([1 size(next_target_selection,1)]));
    
    % Calculate the distance between other samples and the target sample in this range.
    target_range = X0(target_range_label,:);
    n_target = size(target_range,1);
    clear target_distance;
    for i=1:n_target
        target_distance(i,:) = norm(X0(target,:)-target_range(i,:))^2;
    end
    
    % Confirm the non-outliers of the target sample
    clear target_theta_distance;
    for i=1:size(theta,1)
        target_theta_distance(i,:) = norm(X0(target,:)-theta(i,:))^2;
    end
    if min(target_theta_distance)<min(target_distance(target_distance~=0))
        far_class = find(target_theta_distance==min(target_theta_distance));
        clear next_target_distance;
        for i=1:size(next_target_selection,1)
            next_target_distance(i,:) = norm(X0(next_target_selection(i),:)-theta(far_class,:))^2;
        end
        Loc = find(next_target_distance == max(next_target_distance));
        target = next_target_selection(Loc);
        for i=1:n_target
            target_distance(i,:) = norm(X0(target,:)-target_range(i,:))^2;
        end
    end
    % Find good neighbor of target
    target_class_label = criterion(target_distance);
    
     % Distinguish samples within the target range
    target_label = target_range_label;
    target_label_loc = find(target_range_label==1);
    target_label(target_label_loc(target_class_label==0)) = 0;
    if sum(target_class_label) < sum(target_range_label)
        % Update label
        class = class + 1;
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
        
        % Calculate the center and distance of the remaining samples of the original category
        class_ori = class_max;
        clear Xorigin;
        Xorigin = X0(label==class_ori,:);
        theta_origin = mean(Xorigin,1);
        no = sum(label==class_ori);
        num_class(class_ori,:) = no;
        clear origin_distance;
        for i=1:no
            origin_distance(i,1) = norm(theta_origin-Xorigin(i,:))^2;
        end
        origin = sum(origin_distance);
        object(class_ori,:) = origin;
        theta(class_ori,:) = theta_origin;
    else
        flag = 0;
    end
    
    
    % Convergence conditions
    [object_max,class_max] = max(object);
    otherObject = object;
    otherObject(class_max) = [];
    if isempty(otherObject)
        flag = 0;
        continue;
    end
    object_othersMean = mean(otherObject);
    relativeObjectGap = (object_max-object_othersMean) / max(object_othersMean, eps);
    Obj(iter,:) = relativeObjectGap;
    iter = iter + 1 ;
    % 原始 HBNC 规则：最大 SSE 簇小于总样本 2% 时停止，避免细分极小簇。
    if sum(label==class_max)<n/50
        flag = 0;
    end
    if sum(num_class==1)>=1
        flag = 0;
    end
    % 原始 HBNC 规则：最大 SSE 与其他簇平均 SSE 的相对差距不超过 0.5 时停止。
    if relativeObjectGap <= 0.5
        flag = 0;
    end 
    
end

