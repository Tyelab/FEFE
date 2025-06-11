
function d = compute_point_dist(x, y)
% d = compute_point_dist(x, y)
% Compute the Euclidean distance metric between two 2D points.
% x = [x1,x2] is a point
% y = [y1,y2] is a point
%
% then d = sqrt(    (x(1)-y(1)).^2 +    (x(2)-y(2)).^2);
% another option here is pdist()
% calculate the distance between  xy1 and xy2

% errorcheck
if size(x,1)>size(x,2), x=x'; end
if size(y,1)>size(y,2), y=y'; end

if size(x,1)>1 || size(y,1)>1, error('inputs must be arrays of size 1xN');end
d = pdist([x;y],'euclidean');
end