function logL1 = biclr_loglik_double(n1, n2, d, W1, W2, epsVar)
%BICLR_LOGLIK_DOUBLE 计算双簇共享方差球形高斯模型的极大对数似然。
%   LOGL1 = BICLR_LOGLIK_DOUBLE(N1, N2, D, W1, W2, EPSVAR) 根据两个
%   子节点的样本数和簇内平方误差，计算共享球形方差模型下的极大对数似然。
%
%   输入参数：
%   n1     : 左子节点样本数，正标量或正向量。
%   n2     : 右子节点样本数，正标量或正向量。
%   d      : 特征维度，正整数标量。
%   W1     : 左子节点簇内平方误差，非负。
%   W2     : 右子节点簇内平方误差，非负。
%   epsVar : 方差数值保护项，非负标量。
%
%   输出参数：
%   logL1  : 双簇模型极大对数似然，与 n1/n2 同大小。
%
%   注意事项：
%   本函数假设每个候选划分满足 n1>0 且 n2>0。

validateattributes(n1, {'double', 'single'}, {'real', 'positive'}, mfilename, 'n1', 1);
validateattributes(n2, {'double', 'single'}, {'real', 'positive'}, mfilename, 'n2', 2);
validateattributes(d, {'double', 'single'}, {'real', 'scalar', 'integer', 'positive'}, mfilename, 'd', 3);
validateattributes(W1, {'double', 'single'}, {'real', 'nonnegative'}, mfilename, 'W1', 4);
validateattributes(W2, {'double', 'single'}, {'real', 'nonnegative'}, mfilename, 'W2', 5);
validateattributes(epsVar, {'double', 'single'}, {'real', 'scalar', 'nonnegative'}, mfilename, 'epsVar', 6);

if ~isequal(size(n1), size(n2)) && ~(isscalar(n1) || isscalar(n2))
    error('biclr_loglik_double:SizeMismatch', 'n1 与 n2 的尺寸不匹配。');
end
if ~isequal(size(W1), size(W2)) && ~(isscalar(W1) || isscalar(W2))
    error('biclr_loglik_double:SizeMismatch', 'W1 与 W2 的尺寸不匹配。');
end

nC = n1 + n2;
pi1 = n1 ./ nC;
pi2 = n2 ./ nC;
sigma12Sq = (W1 + W2) ./ (nC .* d) + epsVar;
logL1 = n1 .* log(pi1) + n2 .* log(pi2) ...
    - (nC .* d ./ 2) .* (log(2 * pi .* sigma12Sq) + 1);
logL1 = real(logL1);
end
