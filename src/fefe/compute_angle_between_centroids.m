function tempTrack = compute_angle_between_centroids(mouseData, shockFrames, keypts,keypt_index1,keypt_index2,keypt_index3, feature_name1, feature_name2, feature_name3,tempTrack)
% tempTrack = compute_centroid_features(mouseData, shockFrames, keypts)
%
% This function will compute the distance between unique pairs of keypts
% during the video frames given by shockFrames for a single session of data
% stored in mouseData. 
% Resulting feature names are automated using the values in keypts; these
% correspond to the body or face labels provided to SLEAP (e.g. skeleton)
%
% Inputs
%   mouseData: stucture containing SLEAP tracked data from a specific
%      session; in this function it must contain the field
%      mouseData.tracks, where tracks is an array of size [numberFrames by
%      nKeyPoints by 2]   
%   shockFrames: array of integers (numberFrames by 1) corresponding to the
%      frames of a the video session in mouseData.sleap_file; The frames
%      usually correspond to when a specific stimulus occured; but can be
%      any set of frames but this is expected to follow a trial structure,
%      so frame indices may not be contiguous 
%   keypts: cell array of strings corresponds to the keypoint labels
%      labels must be alphanumeric and may include an underscore; other
%      characters are removed when fieldnames are created
%   keypts_index1, keypts_index2, keypts_index3: set of integer indices in
%      keypnts that corresponds to label used to make up the angle  
%      Ex. angle between ear, nose and mouth
%   feature_name1, feature_name2, feature_name3: string for what to call
%      the collection of keypoints, e.g. "head"
%   tempTrack (optional) if this structure is passed in, this function will
%      add fields; if not given, a new structure is created.
%
% Outputs
%   tempTrack
%
%
% Written by LR Keyes, Feb 10, 2023
% See also:

% error check: we assume the input structure mouseData is NOT a cell array. 
if iscell(mouseData) && size(mouseData,2)==1
    %error('input mouseData should be a structure, not a cell array')
    mouseData = mouseData{1};
end

if iscell(mouseData) && size(mouseData,2)>1
    error('input mouseData should be a structure, not a cell array')
    % mouseData = mouseData{1};
end

% error check: make sure mouseData has tracks in the structure
if ~isfield(mouseData,'tracks')
    error('%s:Input structure "mouseData" does not contain the expected field "tracks"',mfilename);
end

% error check: was tempTrack passed in as argument? if not, make it
if nargin<4
    tempTrack = struct;
end

nFrames = size(shockFrames,2);
keypts = clean_up_node_names(keypts);

tStart = tic;
%% Create feature name

if numel(keypt_index1)==1
    % get the track info corresponding to each keypoint
    keypt_1 = squeeze(mouseData.tracks(shockFrames,keypt_index1,:));
    fn1=keypts{keypt_index1};
else
    % compute the centroid
    tmp.(feature_name1) =  mouseData.tracks(shockFrames,keypt_index1,:);
    keypt_1 = squeeze(mean(tmp.(feature_name1),2));
    fn1 = feature_name1;
end

if numel(keypt_index2)==1
    keypt_2 = squeeze(mouseData.tracks(shockFrames,keypt_index2,:));
    fn2=keypts{keypt_index2};
else
    % compute the centroid
    tmp.(feature_name2) =  mouseData.tracks(shockFrames,keypt_index2,:);
    keypt_2 = squeeze(mean(tmp.(feature_name2),2));
    fn2 = feature_name2;
end

if numel(keypt_index3)==1
    keypt_3 = squeeze(mouseData.tracks(shockFrames,keypt_index3,:));
    fn3 = keypts{keypt_index3};
else
    % compute the centroid
    tmp.(feature_name3) =  mouseData.tracks(shockFrames,keypt_index3,:);
    keypt_3 = squeeze(mean(tmp.(feature_name3),2));
    fn3 = feature_name3;
end


fprintf('Computing angle between %s-%s-%s ...', fn1,fn2,fn3)
feat_name = [fn1,'_',fn2,'_',fn3,'_angle'];
% if the feat_name exists in tempTrack, give a warning that you are
% skipping so as not to overwrite an existing feature
existing_feature_names = fieldnames(tempTrack);
if any(strcmp(existing_feature_names, feat_name))
    warning('%s: field already exists in structure... skipping')
else

    %% calculate the angle
    tempTrack.(feat_name) = zeros(nFrames,1);

    for ii = 1:nFrames
        % Vector from mouse's body to head
        res_n2 = (keypt_2(ii,:) - keypt_3(ii,:)) ./ norm(keypt_2(ii,:) - keypt_3(ii,:));
        res_n1 = (keypt_2(ii,:) - keypt_1(ii,:)) ./ norm(keypt_2(ii,:) - keypt_1(ii,:));
        if isnan(res_n2)
            continue
        else
            tempTrack.(feat_name)(ii) = (atan2(norm(det([res_n2; res_n1])), dot(res_n1, res_n2)));
        end

    end

    tEnd = toc(tStart);
    fprintf('Done in %5.3f s\n',tEnd)

end