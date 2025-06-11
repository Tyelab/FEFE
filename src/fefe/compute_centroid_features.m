function tempTrack = compute_centroid_features(mouseData, shockFrames, keypts, keypts_index, feature_name, tempTrack,PRESERVE_NAN)
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
%   keypts_index: array of integers corresponds to the index is keypoint
%      labels that define the larger body part
%      e.g., "head" is made up of "L_ear", "nose" and "R_ear", so
%      the keypts_index would be the indices in keypts
%   feature_name: string for what to call the collection of keypoints, e.g.
%      "head"
%   tempTrack (optional) if this structure is passed in, this function will
%      add fields; if not given, a new structure is created.
%   PRESERVE_NAN (logical) flag to preserve nan values (when true) or omit
%   nan in mean computations (when false); default PRESERVE_NAN=1
%
% Outputs
%   tempTrack
%
%
% Written by LR Keyes, Feb 10, 2023
% See also:


if nargin<7,    PRESERVE_NAN=1; end
% error check: we assume the input will have the form of a cell array. If a
% structure is passed in (i.e., mouseData{1} was the input) we make it a
% temporary cell array to work in this function
if iscell(mouseData) && size(mouseData,2)==1
    mouseData = mouseData{1};
elseif iscell(mouseData) && size(mouseData,2)>1
    error('input mouseData should be a structure, NOT a cell array')
end


% error check: make sure mouseData has tracks in the structure
if ~isfield(mouseData,'tracks')
    error('%s:Input structure "mouseData" does not contain the expected field "tracks"',mfilename);
end

% error check: was tempTrack passed in as argument? if not, make it
if nargin<4
    tempTrack = struct;
end

% check if we convert distance to cm
feature_name_ext = '';% don't tack anything onto your feature name
CONVERT_PX_TO_CM = 0; % flag to convert to CM

if isfield(mouseData,'Spout') && ~isempty(mouseData.Spout)
    CONVERT_PX_TO_CM = 1;
    conversionFactorPixToCm = mouseData.Spout.conversionFactor;
    feature_name_ext = '_cm';% tack on '_cm' to your feature name
end

% get some parameters
nFrames = size(shockFrames,2);
% nPoints = numel(keypts);
% tmp = struct;
keypts = clean_up_node_names(keypts);

fprintf('Computing %s centroids, velocity, acceleration, and AOC ...', feature_name)
tStart = tic;

%% create the field names from pairs of keypoints and initialize distance vectors
tempTrack.([feature_name,'_cent']) = zeros(nFrames,1);
tempTrack.([feature_name,'_velocity_001',feature_name_ext]) = zeros(nFrames,1);

%% create the different features values using generic keypoint info
% Compute body part centroid
% note, this is store in tmp because it is an intermediary feature that
% should NOT be added to the larger feature set
if CONVERT_PX_TO_CM
    tmp.(feature_name) =  mouseData.tracks(shockFrames,keypts_index,:)*conversionFactorPixToCm;
else
    tmp.(feature_name) =  mouseData.tracks(shockFrames,keypts_index,:);
end
feature_centroid = squeeze(mean(tmp.(feature_name),2));
if PRESERVE_NAN
    % fill in nan entries using linear interpolation and overwrite the array
    [feature_centroid,TF] = fillmissing(feature_centroid,'linear','SamplePoints',shockFrames);
    if any(sum(TF)>0), warning('%s: filled in nan entries in feature-centroids',mfilename),end
end
% define x and y components individually
tempTrack.([feature_name,'_cent_x']) = feature_centroid(:,1);
tempTrack.([feature_name,'_cent_y']) = feature_centroid(:,2);
% mean change in position of body across 2 consecutive frames
tempTrack.([feature_name,'_velocity_001',feature_name_ext]) =[0; sqrt(  diff(tempTrack.([feature_name,'_cent_x'])(:,1)).^2  + diff(tempTrack.([feature_name,'_cent_y'])(:,1)).^2)]; %speed
% average velocity over 10 frames
if PRESERVE_NAN
    tempTrack.([feature_name,'_velocity_010',feature_name_ext]) = movmean(tempTrack.([feature_name,'_velocity_001',feature_name_ext]),[10 0]);
else
    tempTrack.([feature_name,'_velocity_010',feature_name_ext]) = movmean(tempTrack.([feature_name,'_velocity_001',feature_name_ext]),[10 0],"omitnan");
end
% average velocity over 30 frames
if PRESERVE_NAN
    tempTrack.([feature_name,'_velocity_030',feature_name_ext]) = movmean(tempTrack.([feature_name,'_velocity_001',feature_name_ext]),[30 0]);
else
    tempTrack.([feature_name,'_velocity_030',feature_name_ext]) = movmean(tempTrack.([feature_name,'_velocity_001',feature_name_ext]),[30 0],"omitnan");
end
% mean change in velocity of head across 2 consecutive frames
tempTrack.([feature_name,'_acceleration_001',feature_name_ext])=[0;0; sqrt(  diff(tempTrack.([feature_name,'_cent_x']),2).^2  + diff(tempTrack.([feature_name,'_cent_y']),2).^2)]; %acceleration of head




% remove outliers from velocities and accelerations
outlier_dbg = 0; % flag for debugging remove outliers
tempTrack.([feature_name,'_velocity_001',feature_name_ext]) = remove_outliers(tempTrack.([feature_name,'_velocity_001',feature_name_ext]),outlier_dbg);
tempTrack.([feature_name,'_velocity_010',feature_name_ext]) = remove_outliers(tempTrack.([feature_name,'_velocity_010',feature_name_ext]),outlier_dbg);
tempTrack.([feature_name,'_velocity_030',feature_name_ext]) = remove_outliers(tempTrack.([feature_name,'_velocity_030',feature_name_ext]),outlier_dbg);
tempTrack.([feature_name,'_acceleration_001',feature_name_ext]) = remove_outliers(tempTrack.([feature_name,'_acceleration_001',feature_name_ext]),outlier_dbg);

% compute integral of velocities using area under curve
win_size= 4; % compute over 5 frame window
for ii = 1:length(shockFrames)

    if ii<win_size+1
        tempTrack.([feature_name,'_aoc_velocity_001',feature_name_ext])(ii,1)      = 0;
        tempTrack.([feature_name,'_aoc_velocity_010',feature_name_ext])(ii,1)      = 0;
        tempTrack.([feature_name,'_aoc_velocity_030',feature_name_ext])(ii,1)      = 0;
        tempTrack.([feature_name,'_aoc_acceleration_001',feature_name_ext])(ii,1)  = 0;
    else
        tempTrack.([feature_name,'_aoc_velocity_001',feature_name_ext])(ii,1) = trapz(tempTrack.([feature_name,'_velocity_001',feature_name_ext])(ii-win_size:ii));
        tempTrack.([feature_name,'_aoc_velocity_010',feature_name_ext])(ii,1) = trapz(tempTrack.([feature_name,'_velocity_010',feature_name_ext])(ii-win_size:ii));
        tempTrack.([feature_name,'_aoc_velocity_030',feature_name_ext])(ii,1) = trapz(tempTrack.([feature_name,'_velocity_030',feature_name_ext])(ii-win_size:ii));
        tempTrack.([feature_name,'_aoc_acceleration_001',feature_name_ext])(ii,1) = trapz(tempTrack.([feature_name,'_acceleration_001',feature_name_ext])(ii-win_size:ii));
    end
end

tEnd = toc(tStart);
fprintf('Done in %5.3f s\n',tEnd)
end