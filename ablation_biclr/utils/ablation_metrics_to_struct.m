function metrics = ablation_metrics_to_struct(metricVector)
%ABLATION_METRICS_TO_STRUCT 将 8 维聚类指标向量转换为结构体。
%   METRICS = ABLATION_METRICS_TO_STRUCT(METRICVECTOR) 返回 ACC、NMI、
%   Purity、Fscore、Precision、Recall、AR、Entropy 字段。

metricNames = {'ACC', 'NMI', 'Purity', 'Fscore', 'Precision', 'Recall', 'AR', 'Entropy'};
metrics = struct();
if isempty(metricVector)
    metricVector = nan(1, numel(metricNames));
end
metricVector = double(metricVector(:))';
if numel(metricVector) < numel(metricNames)
    metricVector(end + 1:numel(metricNames)) = NaN;
end
for i = 1:numel(metricNames)
    metrics.(metricNames{i}) = metricVector(i);
end
end
