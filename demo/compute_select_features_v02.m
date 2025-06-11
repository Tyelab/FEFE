
function tempTrack = compute_select_features_v02(mouseData, shockFrames, keypts, ZSCORE_FLAG)
% tempTrack = compute_select_features_v02(mouseData, shockFrames, keypts, ZSCORE_FLAG)
%
% This function computes the following features for the frames provided:
%
% 1) (Blink or squinting) - distance between top and bottom eye
% 2) distance between top and bottom ear
% 3) distance between middle ear point and ear centroid
% 4) distance between middle ear and middle mouth
% 5) distance between mouth top and bottom
% 6) distance between middle mouth point and centroid
% 7) Distance between nostril and eye
% 8) Distance between ear to nose
% 9) ear to mouth
% 10) eye to ear
% 11) ear to whisker Distance
% 12) whisker angle down
% 13) whisker angle up
% 14) ear angle down
% 15) ear angle up
% 16) Nostril angle up
% 17) nostril angle down
% 18) includes the triangles for polyface feature set 
%
% Assumption is that the mouse face skeleton structured for 23 points:
%   1 -         "upper_eye              "
%   2 -         "lower_eye              "
%   3 -         "inner_eye              "
%   4 -         "outer_eye              "
%   5 -         "inner_ear_lower        "
%   6 -         "inner_ear_upper        "
%   7 -         "ear_fold_top           "
%   8 -         "upper_ear              "
%   9 -         "outer_ear_upper_edge   "
%   10 -         "outer_ear_lower_edge   "
%   11 -         "bottom_ear             "
%   12 -         "nose_upper             "
%   13 -         "nose_tip               "
%   14 -         "nostril_left           "
%   15 -         "nostril_right          "
%   16 -         "mouth_upper            "
%   17 -         "mouth_lower            "
%   18 -         "chin                   "
%   19 -         "headplate              "
%   20 -         "top_whisker_stem       "
%   21 -         "top_whisker_end        " (not used, too unreliable!)
%   22 -         "bottom_whisker_stem    "
%   23 -         "bottom_whisker_end     " (not used, too unreliable!)
%
% inputs
%   mouseData (struct) must contain mouseData.tracks, the sleap keypoint
%      locations for each frame
%   shockFrames (array of integers) corresponds to the video frame numbers
%       for which you want to extract features
%   keypts (cell array of strings) names of the sleap nodes (see above)
%   ZSCORE_FLAG (logical) if true, zscore the session
%
%
% see also compute_dist_between_keypoints,compute_angle_between_centroids,
% compute_ellipse, compute_centroid_features, compute_area, zscore_table
% 


if nargin < 4
    ZSCORE_FLAG = 0;
end

% % mouseData should only have one entry in the cell
% sesh = 1;
tempTrack = struct;
%% start with the generic distance features

% 1) (Blink or squinting) - distance between top and bottom eye
% 2) distance between top and bottom ear
% 3) distance between middle ear point and ear centroid
% 4) distance between outer ear and outer mouth
% 5) distance between mouth top and bottom
% 6) distance between middle mouth point and centroid
% 7) Distance between nostril and eye
% 8) Distance between ear to nose
% 9) Distance between ear to mouth
% 10) Distance between eye to ear
% 11) Distance between ear to whisker
tempTrack = compute_dist_between_keypoints(mouseData, shockFrames, keypts, tempTrack);

%% compute each set of features
% if have removed "whisker_end" features and have 21 node points

% cheek angles
tempTrack = compute_angle_between_centroids(mouseData, shockFrames, keypts,20,15,21,'top_whisker_stem','nostril_right','bottom_whisker_stem',tempTrack);
tempTrack = compute_angle_between_centroids(mouseData, shockFrames, keypts,20,21,15,'top_whisker_stem','bottom_whisker_stem','nostril_right',tempTrack);

% 14) ear angle down
tempTrack = compute_angle_between_centroids(mouseData, shockFrames, keypts,9,10,8,'outer_ear_upper_edge','outer_ear_lower_edge','upper_ear',tempTrack);
% 15) ear angle up
tempTrack = compute_angle_between_centroids(mouseData, shockFrames, keypts,10,9,8,'outer_ear_lower_edge','outer_ear_upper_edge','upper_ear',tempTrack);

% 16) Nostril angle up
tempTrack = compute_angle_between_centroids(mouseData, shockFrames, keypts,14,15,16,'nostril_left','nostril_right','mouth_upper',tempTrack);

% 17) nostril angle down
tempTrack = compute_angle_between_centroids(mouseData, shockFrames, keypts,14,16,15,'nostril_left','mouth_upper','nostril_right',tempTrack);

% 18) ear ellipse
[tempTrack] = compute_ellipse(mouseData, shockFrames, [6,7,8,9,10,11], 'ear', tempTrack);

% 19) compute ear, eye, nose centroids
tempTrack = compute_centroid_features(mouseData, shockFrames, keypts, [1,2,3,4], 'whole_eye', tempTrack);
tempTrack = compute_centroid_features(mouseData, shockFrames, keypts, [5,6,7,8,9,10,11], 'whole_ear', tempTrack);
tempTrack = compute_centroid_features(mouseData, shockFrames, keypts, [12,13,14,15], 'whole_nose', tempTrack);

tempTrack = compute_angle_between_centroids(mouseData, shockFrames, keypts, [1,2,3,4], [5,6,7,8,9,10,11],[12,13,14,15], 'whole_eye', 'whole_ear', 'whole_nose',tempTrack);

% compute area of eye, ear, nose
tempTrack = compute_area(mouseData, shockFrames, [1,2,3,4], 'whole_eye', tempTrack);
tempTrack = compute_area(mouseData, shockFrames, [7,8,9,10,11], 'whole_ear', tempTrack); % only use outer points to compute area, e.g. not inner-ear
tempTrack = compute_area(mouseData, shockFrames, [12,13,14,15], 'whole_nose', tempTrack);

% compute polyface/triangles feature set; 
tempTrack = compute_polyface(mouseData, shockFrames, keypts, tempTrack);

feature_names = fieldnames(tempTrack);
features = table();
for ii = 1:length(feature_names)
    %disp( feature_names{ii})
    features = addvars(features, getfield(tempTrack, feature_names{ii}), 'NewVariableNames', feature_names{ii}); %#ok<GFLD>
end
tempTrack.features = features;


if ZSCORE_FLAG
    % if this flag is set to TRUE, the feature table will be zscored using
    % the feature values for this session.  This may make it harder to
    % identify changes ACROSS sessions and could show more subtle effects
    % within a single session because you are looking mostly at the change
    % that occurs. It will also minimize overall changes between punishment
    % and reward trials, which are zscored separately in this code.
    %
    % If set to FALSE, you will be looking at the raw measurement values,
    % which we hypothesize will change across sessions in subjects showing
    % more depressive-like symptoms
    disp('Normalizing distances to individual session data')
    % zscore to each session's data, as given by shockFrames
    % tempTrack  = zscore_feature_table_by_session(tempTrack.features, shockFrames);
    
    tempTrack.features = zscore_table(tempTrack.features);
end



%% clean up features by removing features computed from keypoints with
% unreliable tracking (e.g., ear keypoints)
REMOVE_ALL_EAR = 1;
if REMOVE_ALL_EAR
    % "inner_ear_lower        "
    % "inner_ear_upper        "
    % "ear_fold_top           "
    % "upper_ear              "
    % "outer_ear_upper_edge   "
    % "outer_ear_lower_edge   "
    % "bottom_ear             "
    % remove features with "ear" in the name; these keypoints are not
    % tracking with sufficient accuracy to be useful at this stage
    warning('Removing features with "ear" in the name')
    fn = fieldnames(tempTrack.features);
    iEar = find(contains(fn,'ear'));
    for ii = numel(iEar):-1:1
        if isfield(tempTrack, fn{iEar(ii)})
            tempTrack = rmfield(tempTrack,fn{iEar(ii)});
        end
        tempTrack.features = removevars(tempTrack.features,fn{iEar(ii)});
    end
end

% headstage keypoint is used for sleap tracking but not intended to be used
% as a facial feature
REMOVE_HEADSTAGE= 1;
if REMOVE_HEADSTAGE
    % remove "headstage" points; this was used only for sleap model and not
    % for tracking face
    warning('Removing features with "headstage" in the name')
    fn = tempTrack.features.Properties.VariableNames;
    iHeadstage = find(contains(fn,'headstage'));
    for ii = numel(iHeadstage):-1:1
        if isfield(tempTrack,fn{iHeadstage(ii)})
            tempTrack = rmfield(tempTrack,fn{iHeadstage(ii)});
        end
        tempTrack.features = removevars(tempTrack.features,fn{iHeadstage(ii)});
    end
end

% the 'center' features are used to compute other facial angles but should
% not be used as a facial feature, as this set of features labels a
% specific x,y location in each video and does not generalize across
% animals.   
REMOVE_CENT_FEATURES= 1;
if REMOVE_CENT_FEATURES
    % remove "headstage" points; this was used only for sleap model and not
    % for tracking face
    warning('Removing center features (with "cent" in the name)')
    fn = tempTrack.features.Properties.VariableNames;
    iCent_feature = find(contains(fn,'cent_'));
    for ii = numel(iCent_feature):-1:1
        if isfield(tempTrack,fn{iCent_feature(ii)})
            tempTrack = rmfield(tempTrack,fn{iCent_feature(ii)});
        end
        tempTrack.features = removevars(tempTrack.features,fn{iCent_feature(ii)});
    end
end

%
% if REMOVE_LEFT_NOSTRIL
%     % remove "left_nostril" points; this is the nostril facing away from
%     % camera angle and is occasional blocked by extended snout
%     warning('Removing features with "left_nostril" in the name')
%     fn = tempTrack.features.Properties.VariableNames;
%     iLeftNostril = find(contains(fn,'nostril_left'));
%     for ii = numel(iLeftNostril):-1:1
%         if isfield(tempTrack,fn{iLeftNostril(ii)})
%             tempTrack = rmfield(tempTrack,fn{iLeftNostril(ii)});
%         end
%         tempTrack.features = removevars(tempTrack.features,fn{iLeftNostril(ii)});
%     end
% end
%

end



