function tau = compute_rank_kendall_tau_safe(x, y)
%COMPUTE_RANK_KENDALL_TAU_SAFE 安全计算 Kendall tau 等级相关系数。
%   TAU = COMPUTE_RANK_KENDALL_TAU_SAFE(X, Y) 忽略 NaN/Inf 与并列对；
%   若有效样本不足或全为并列，返回 NaN 并给出 warning。
%
%   输入参数：
%   x, y : 等长向量，通常用于比较 BIC 证据排序和 SSE 排序。
%
%   输出参数：
%   tau : Kendall tau-a 相关系数，无法计算时为 NaN。

tau = NaN;
if nargin < 2 || isempty(x) || isempty(y)
    warning('compute_rank_kendall_tau_safe:EmptyInput', 'Kendall tau 输入为空，返回 NaN。');
    return;
end

x = double(x(:));
y = double(y(:));
if numel(x) ~= numel(y)
    warning('compute_rank_kendall_tau_safe:SizeMismatch', 'Kendall tau 输入长度不一致，返回 NaN。');
    return;
end

mask = isfinite(x) & isfinite(y);
x = x(mask);
y = y(mask);
n = numel(x);
if n < 2
    warning('compute_rank_kendall_tau_safe:NotEnoughData', '有效样本少于 2，Kendall tau 返回 NaN。');
    return;
end

concordant = 0;
discordant = 0;
validPairs = 0;
for i = 1:n-1
    for j = i+1:n
        dx = x(i) - x(j);
        dy = y(i) - y(j);
        if dx == 0 || dy == 0
            continue;
        end
        validPairs = validPairs + 1;
        if dx * dy > 0
            concordant = concordant + 1;
        else
            discordant = discordant + 1;
        end
    end
end

if validPairs == 0
    warning('compute_rank_kendall_tau_safe:AllTies', '所有有效对均存在并列，Kendall tau 返回 NaN。');
    return;
end

tau = (concordant - discordant) / validPairs;
end
