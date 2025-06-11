function t2 = zscore_table(t, mu, sigma)
% t2 = zscore_table(t, mu, sigma)
% this function will zscore a table using the means in mu and the std in
% sigma.  
% expected size of MU, SIGMA should equal number of columns in table

% % error check
% if any(sigma==0)
%     warning('Some entries in input parameter SIGMA are 0')
% end

if nargin<3
    % compute mu and sigma from the table provided

    mu = mean(t,'omitnan');
    sigma = std(t,0,'omitnan');
end

[~,COLS] = size(t);
t2 = t;
for col = 1:COLS    
%    t2(:,col) = (t{:,col}-mu(col))./sigma(col);
    t2{:,col} = (t{:,col}-mu{:,col})./sigma{:,col};
end

% debugging
if 0
    figure; %#ok<UNRCH> 
    subplot(2,1,1);imagesc(t{:,:},[0 1]);title('Original ');colorbar
    subplot(2,1,2); imagesc(t2{:,:},[0 1]);title('Zscore ');colorbar
end












