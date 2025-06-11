function x = remove_outliers(x, dbg)
% x = remove_outliers(x, dbg)
% remove the values that fall above 6 standard dev from the mean
%
% INPUT
%    x = an Nx1 or Nx2 array.
%    dbg = flag; if true shows a figure with outlier points 
%
% OUTPUT
%    x = Nx1 or Nx2 array with outliers removed (e.g. points are replaced
%        with a value of 0
%
% See also: compute_centroid_features, compute_ave_dist_from_previous_frame

% set default debugging flag
if nargin<2, dbg = 0; end

[n,m] =size(x);
x_orig = x; % make a copy to plot later
if n<m && n==1
    x = x';
elseif m~=1
    error('expected an Nx1 array ')
end
x_upper = mean(x,1,'omitnan') + 6*std(x,1,'omitnan');
x(x > x_upper)= 0;


if dbg
    figure; 
    plot(x_orig,'ro')
    hold on;
    plot(find(x_orig > x_upper), x_orig(x_orig > x_upper),'g.')
    legend('orig data', 'outliers')
end

end
