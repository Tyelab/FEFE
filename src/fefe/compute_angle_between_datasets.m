function ang = compute_angle_between_datasets(D1, D2, dbg)
% ang = compute_angle_between_datasets(D1, D2, dbg)
% D1 is an Nx2 matrix, where first column is x coords and second is y
% D2 is an Nx2 matrix, where first column is x coords and second is y
% dbg (optional) debug flag, if true will show a plot of data
%
%
% The idea is that the points in each dataset can EACH be fitted with a line
% then we find the angle between the lines
%
% returns angle in radians

% if you need to debug and show the plot, set dbg to 1
if nargin<3
    dbg = 0;
end

% get the x and y components of dataset and fit the line to them
x = D1(:,1);
y = D1(:,2);
p = polyfit(x,y,1);
f  = polyval(p,x); % this is used for plot only

% take the endpoints of your data and find the corresponding points on your
% fitted line
x_ends = [x(1) x(end)];
f2 = polyval(p,x_ends);

%put your y=mx+b line into vector form
q1 = ([x(1) f2(1)]); % vector from origin to one point on line
q2 = ([x(end) f2(2)]); % vector from origin to another point on line
v1 = (q2-q1)'; % difference between them defines the vector

if dbg
    figure
    % plot the data points and the line through them
    plot(x,y,'o',x,f,'-or');
    hold on
    %     plot(x,y,'o',x_ends,f2,':r');hold on
    hold on;
    % plot the vector from the origin
    plotv(v1,'r')
end


% doing same as above for other data set
x = D2(:,1);
y = D2(:,2);
p = polyfit(x,y,1);
f  = polyval(p,x);

x_ends = [x(1) x(end)];
f2 = polyval(p,x_ends);

q1 = ([x(1) f2(1)]);
q2 = ([x(end) f2(2)]);
v2 = (q2-q1)';
if dbg
    plot(x,y,'o',x,f,'-og');hold on
    %     plot(x,y,'o',x_ends,f2,':');hold on
    hold on; plotv(v2,'g')
end


% Angle between v1 and v2
if any(isnan(v1)) || any(isnan(v2))
    ang = 0;  % means no angle was computed
else
    ang = atan2(norm(det([v1'; v2'])), dot(v2, v1));
end

if dbg
    title(sprintf('angle is %f radians (%f deg)',ang, ang*(180/pi)))
end

end

