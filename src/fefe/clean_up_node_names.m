function keypts = clean_up_node_names(keypts)
% keypts = clean_up_node_names(keypts)
% This function removes leading and trailing whitespace from the node
% names.  It checks that remaining characters have only numbers, letters or
% underscores. If it finds another character, it is replaced with an
% underscore. 
%
% February 14, 2023
% Written by Laurel Keyes
%

% errorcheck: 
% error check: make sure mouseData has tracks in the structure
%


% get number of entries
nPoints = numel(keypts);

% make sure keypts has good naming convention using alphanumerics with
% underscore only (no whitespace or special characters or hyphens), as
% matlab cannot interpret these as fieldnames with a structure  
for ii = 1:nPoints
    
    % strip out whitespace at end of string    
    tmp = keypts{ii};
    tmp = deblank(tmp);
    tmp = strip(tmp,'both');
    % replace remaining whitespace with underscore
    tmp = strrep(tmp,' ','_');

    % check remaining characters 
    if any(isstrprop(tmp,'alphanum'))
        % if any character is something other than an underscore, replace
        % with an underscore
        ind = find(isstrprop(tmp,'alphanum')==0);
        % loop through each special character and replace with underscore
        for jj = 1:numel(ind)
            if ~strcmp(tmp(ind(jj)),'_')
                tmp(ind(jj)) = '_';
            end
        end
    end
    
    % overwrite keypts
    keypts{ii} = tmp;
    
end