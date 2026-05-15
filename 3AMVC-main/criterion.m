function label = criterion(distance)
%CRITERION 原始 HBNC 路径中的距离阈值判据。
%   LABEL = CRITERION(DISTANCE) 根据非零距离序列寻找阈值，并返回与
%   DISTANCE 等长的逻辑标签。该函数仅服务原始 HBNC 路径。
%
%   输入参数：
%   distance : 样本到目标样本的平方距离向量。
%
%   输出参数：
%   label : 逻辑列向量，true 表示距离不超过自动阈值。
%
%   注意事项：
%   当所有距离为 0 或有效非零距离不足 2 个时，不存在稳定二分阈值，
%   此时返回全 true，表示不在该节点内强行切分。

validateattributes(distance, {'double', 'single'}, {'vector', 'nonempty', 'real'}, mfilename, 'distance', 1);
if any(~isfinite(distance(:)))
    error('criterion:InvalidInput', 'distance 中含有 NaN 或 Inf。');
end

distance = distance(:);
nonzeroDistance = distance(distance ~= 0);
n = numel(nonzeroDistance);
if n < 2
    label = true(size(distance));
    return;
end

S = sort(nonzeroDistance);
Cri = inf(n - 1, 1);
for k = 1:n - 1
    leftMean = mean(S(1:k));
    rightMean = mean(S(k + 1:n));
    denominator = k * (n - k) / (n * n) * (leftMean - rightMean)^2;
    Cri(k) = leftMean / max(denominator, eps(class(distance)));
%     Cri(k)=(1/k*sum(S(1:k))).^2/(1/(n-k)*sum(S((k+1):n)));
end

[~, location] = min(Cri);
threshold = S(location);
label = distance <= threshold;
end
