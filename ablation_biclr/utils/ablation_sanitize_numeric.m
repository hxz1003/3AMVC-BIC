function textValue = ablation_sanitize_numeric(value)
%ABLATION_SANITIZE_NUMERIC 将数值转换为稳定缓存键片段。
%   TEXTVALUE = ABLATION_SANITIZE_NUMERIC(VALUE) 与 A0 缓存键中的数值
%   格式保持一致，例如 0.5 转为 0p5。

if isempty(value) || any(isnan(value(:)))
    textValue = 'NaN';
else
    textValue = regexprep(sprintf('%.6g', double(value(1))), '[^0-9a-zA-Z]+', 'p');
end
end
