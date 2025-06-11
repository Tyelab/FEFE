function  [norm_table, mu, sigma] = zscore_feature_table_by_session_baseline(features_table, baseline_table)
% features_table = zscore_feature_table_by_session_baseline(features_table, session_array)
% This function takes in a table of features of facial expression data and
% zscores each column using the session_array to identify each unique session's
% entries.
%
% input
%    features_table - table (nrows x nFeatures) comes from average over
%                     trials
%    baseline_table  - table (nrows x nFeatures) comes from the average
%                     over ITI
%
% output
%    norm_table - table (nrows x nFeatures), where data is normalized
%     using baseline_table session 
%
% 

error('you have to update codes so what you have saved to MouseData is a table not a matrix!')


% error check 
if ~istable(features_table) || ~istable(baseline_table)
    error('Input must be two tables')
end

% set debugging flag
DBG = 0;

% get mu and sigma for baseline table
[~, mu, sigma] = zscore(baseline_table);

% loop over features
norm_table = features_table;
features = features_table.Properties.VariableNames;
numFeat = numel(features);
for ii = 1:numFeat
    norm_table{:,ii} = (features_table{:,ii}-mu(ii))/sigma(ii);

    if DBG
        fh=figure;
       
        scatter(features_table{:,ii}, baseline{:,ii});
        title([feat,' ORIGINAL'],'Interpreter','none')
        xlabel('table');ylabel('baseline')
  
    end
end

clear tmp vv ff DBG ii fh sesh numFeat numSesh c ans feat

%save('\\ktdata\snlkt\home\lkeyes\Projects\Austin\facial_expression\matlab\SpecialKCS_Full_UMAP_ShkRew_zscored.mat')

