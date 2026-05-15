function [label,theta,num_class,class] = Pro_Out(X0,label_pre)
%PRO_OUT 合并原始 HBNC 预划分中的离群小簇。
%   [LABEL, THETA, NUM_CLASS, CLASS] = PRO_OUT(X0, LABEL_PRE) 将预划分中
%   样本数过少且靠近其他中心的节点并入最近节点，保持标签连续。
%
%   输入参数：
%   X0        : n*d 的单视图特征矩阵。
%   label_pre : n*1 的正整数预划分标签。
%
%   输出参数：
%   label     : n*1 的离群点处理后标签。
%   theta     : class*d 的节点中心。
%   num_class : class*1 的每个节点样本数。
%   class     : 节点数量。

validateattributes(X0, {'double', 'single'}, {'2d', 'nonempty', 'real'}, mfilename, 'X0', 1);
validateattributes(label_pre, {'double', 'single'}, {'vector', 'nonempty', 'real', 'integer', 'positive'}, mfilename, 'label_pre', 2);
if any(~isfinite(X0(:))) || any(~isfinite(label_pre(:)))
    error('Pro_Out:InvalidInput', 'X0 或 label_pre 含有 NaN 或 Inf。');
end
flag = 1;
n = size(X0,1);
label = label_pre(:);
if numel(label) ~= n
    error('Pro_Out:SizeMismatch', 'label_pre 的长度必须等于 X0 的样本数。');
end
class = max(unique(label));


% Process Outliers
while flag
    class = max(unique(label));
    clear num_class;
    for i=1:class
        num_class(i,:) = sum(label==i);
    end
    clear theta;
    for i=1:class
        theta(i,:) = mean(X0(label==i,:),1);
    end
    [number_min,class_min_number] = min(num_class);
    clear theta_distance;
    for i = 1 : class
        theta_distance(i,1) =  norm(theta(class_min_number,:)-theta(i,:));
    end
    if class > 1
        nonzeroThetaDistance = theta_distance(theta_distance~=0);
        if isempty(nonzeroThetaDistance)
            flag = 0;
        elseif number_min >= 2 && min(nonzeroThetaDistance)/mean(nonzeroThetaDistance)>=0.8
            flag = 0;
        else
            class_ori = find(theta_distance==min(nonzeroThetaDistance), 1, 'first');
            if class_ori < class_min_number
                label(label==class_min_number) = class_ori;
                for i = class_min_number+1 : class
                    label(label==i) = i-1;
                end
            else
                label(label==class_ori) = class_min_number;
                for i = class_ori+1 : class
                    label(label==i) = i-1;
                end
            end
            clear theta;
            class = max(unique(label));
            for i=1:class
                theta(i,:) = mean(X0(label==i,:),1);
            end
            
        end
    else
        flag = 0;
    end
    
end
