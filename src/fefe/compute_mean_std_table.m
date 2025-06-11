function [mu,sig] = compute_mean_std_table(T)
% [mu,sig] = compute_mean_std_table(T)

% This function computes the mean and standard deviation over all features
% for the table T.
% It loops through columns and takes mean of each column, and the std of
% each column.  If the table has an array for the column, then MU will also
% have the mean of each element in the array as output. (Same for SIGMA)
%
%
% INPUT
%   T is a table of features (ex for all the baseline frames)
%
% OUTPUT
%  mu = table with one row, with same number of columns as T, each
%     containing the mean of each feature in the table
%  sig = table with one row, with same number of columns as T, each
%     containing the mean of each feature in the table
%
% Usage
% The expected way to use this function for facial expression is to have a
% set of frames that correspond to a baseline period, for which you have
% computed features.  Use this function to compute the mean across all
% subjects and sessions in the set in order to average out any changes in
% camera angle across sessions.  You may then use this computed mean and
% std to zscore your features during specific stimulus periods.
%
% Written by Laurel Keyes Feb 16, 2023


tStart = tic;
fprintf('Computing mean (and std) over feature set ...')

mean_varnames = cellfun(@(x) strcat('mean_',x), T.Properties.VariableNames, 'UniformOutput', false);
std_varnames = cellfun(@(x) strcat('std_',x), T.Properties.VariableNames, 'UniformOutput', false);

mu  = T(1,:); 
mu.Properties.VariableNames = mean_varnames;

sig = T(1,:);
sig.Properties.VariableNames = std_varnames;

for ii = 1:size(T,2)
    mu{1,ii} = mean(T{:,ii},1,'omitnan');
    sig{1,ii} = std(T{:,ii},0,1,'omitnan');
end

tEnd = toc(tStart);
fprintf('Done in %5.3f s\n',tEnd)
