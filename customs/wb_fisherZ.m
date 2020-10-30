function zscore = wb_fisherZ(r)
% Fisher's z-transformation
% fisher z-score = 0.5 * log((1+r)/(1-r))
% Input:
%    r: vaules of coefficient belongs to [-1 1]. It can be vector or matrix.
% Output:
%   zscore: Fisher's z-score.
% -------------------------------------------------------------------------
% Written by Li Dong (UESTC, Li_dong729@163.com)
% $ 2018.1.23
% -------------------------------------------------------------------------

zscore = 0.5 * log((1+r)./(1-r));

