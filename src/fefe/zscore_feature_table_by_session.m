function  [features_table2, mu, sigma] = zscore_feature_table_by_session(features_table, session_array, features)
% features_table = zscore_feature_table_by_session(features_table, session_array)
% This function takes in a table of features of facial expression data and
% zscores each column using the session_array to identify each unique session's
% entries.
%
% input
%    features_table - table (nrows x nFeatures)
%    session_array  - array of integers starting at 1 (nrows x 1)
%
% output
%    features_table - table (nrows x nFeatures), where data is normalized
%    to each session as given by session_array
%
%
% 


% set debugging flag
DBG = 0;

% get features and sessions 
if nargin<3
    features = features_table.Properties.VariableNames;
end
sessions = unique(session_array);
numSesh = numel(sessions); 
numFeat = numel(features);
features_table2 = features_table;

% for each feature and session, zscore the data 
for ff = 1:numFeat
    feat = features{ff};
    if DBG
        fh=figure;
        subplot(2,1,1)
        scatter(features_table.(feat),session_array);
        title([feat,' ORIGINAL'],'Interpreter','none')
        xlabel(feat);ylabel('SessionIdx')
    end
    
    for vv = 1:numSesh
        % get indices for this session
        sesh =  session_array == sessions(vv);
        % get associated feature
        tmp = features_table{sesh, feat};
        for ii =1:size(tmp,2)
            % if tmp contains nan, this returns nan
            [tmp(:,ii), tmpmu(ii), tmpsigma(ii)] = zscore(tmp(:,ii)); 
        end
        mu(vv, ii) = tmpmu;
        sigma(vv,ii) = tmpsigma;
        features_table2{sesh, feat} = tmp; 
        % figure;subplot(2,1,1);plot(tmp); subplot(2,1,2); plot(zscore(tmp)); title(data_labels.animal(vv),'Interpreter','none')
        clear ztmp
    end
    
    if DBG
        figure(fh);
        subplot(2,1,2)
        scatter(features_table2.(feat),session_array);
        title([feat,' ZSCORE'],'Interpreter','none')
        xlabel(feat);ylabel('SessionIdx')
    end
end

clear tmp vv ff DBG ii fh sesh numFeat numSesh c ans feat

%save('\\ktdata\snlkt\home\lkeyes\Projects\Austin\facial_expression\matlab\SpecialKCS_Full_UMAP_ShkRew_zscored.mat')

