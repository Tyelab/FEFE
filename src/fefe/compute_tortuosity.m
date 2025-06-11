

function tau = compute_tortuosity(x)
% this computes tortuosity defined as:
%  tau = C/L, the ratio of C (the length of a curve) to L (the distance
%  between its endpoints)
%
% x  nBack by 2 matrix of points
%
% This function is expecting to operate on a single body point (usually a
% mean over arms/legs/haunch/tail base/ skull base.

n = size(x,1);
d = sqrt(    (diff(x(:,1))).^2 +    (diff(x(:,2))).^2);
C = sum(d);
L = sqrt(    ( x(1,1)-x(n,1) ).^2 +    (  x(1,2)-x(n,2)  ).^2);
tau = C/L;
end

