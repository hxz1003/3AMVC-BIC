function logL0 = biclr_loglik_single(nC, d, W0, epsVar)
%BICLR_LOGLIK_SINGLE 计算单簇球形高斯模型的极大对数似然。
%   LOGL0 = BICLR_LOGLIK_SINGLE(NC, D, W0, EPSVAR) 根据样本数 NC、
%   特征维度 D 和簇内平方误差 W0 计算单簇模型的极大对数似然。
%
%   输入参数：
%   nC     : 标量或向量，节点样本数，要求为正。
%   d      : 标量，特征维度，要求为正整数。
%   W0     : 与 nC 同大小的非负簇内平方误差。
%   epsVar : 非负标量，方差数值保护项。
%
%   输出参数：
%   logL0  : 与 nC 同大小的极大对数似然值。
%
%   注意事项：
%   本函数只做统计量到对数似然的映射，不直接操作原始样本矩阵。

validateattributes(nC, {'double', 'single'}, {'real', 'positive'}, mfilename, 'nC', 1);
validateattributes(d, {'double', 'single'}, {'real', 'scalar', 'integer', 'positive'}, mfilename, 'd', 2);
validateattributes(W0, {'double', 'single'}, {'real', 'nonnegative'}, mfilename, 'W0', 3);
validateattributes(epsVar, {'double', 'single'}, {'real', 'scalar', 'nonnegative'}, mfilename, 'epsVar', 4);

if ~isequal(size(nC), size(W0)) && ~(isscalar(nC) || isscalar(W0))
    error('biclr_loglik_single:SizeMismatch', 'nC 与 W0 的尺寸不匹配。');
end

sigma0Sq = W0 ./ (nC .* d) + epsVar;
logL0 = -(nC .* d ./ 2) .* (log(2 * pi .* sigma0Sq) + 1);
logL0 = real(logL0);
end
