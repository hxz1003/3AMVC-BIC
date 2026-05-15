function key = ablation_sanitize_key(textValue)
%ABLATION_SANITIZE_KEY 将文本转换为适合文件名和缓存键的安全字符串。
%   KEY = ABLATION_SANITIZE_KEY(TEXTVALUE) 删除非字母数字字符并压缩下划线。

if isstring(textValue)
    textValue = char(textValue);
end
key = regexprep(char(textValue), '[^a-zA-Z0-9]+', '_');
key = regexprep(key, '_+', '_');
key = regexprep(key, '^_|_$', '');
end
