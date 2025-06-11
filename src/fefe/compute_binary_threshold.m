
function new_x = compute_binary_threshold(x,dbg)
% new_x = compute_binary_threshold(x,dbg)
%
% Compute a binary threshold using the mean value of array x.
%  - set values less than mean value to 0
%  - set values greater than mean value to 1
% Input
%   x - 1xN array of double
%   dbg - debugging flag; if true, will plot the array and threshold
%

if nargin <2, dbg =0; end
thresh = mean(x,'omitnan');
new_x = x;
new_x(x<thresh) = 0;
new_x(x>thresh) = 1;


if dbg
    figure
    plot(x,'o')
    yline(thresh,'r')
end
end