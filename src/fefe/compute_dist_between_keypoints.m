function tempTrack = compute_dist_between_keypoints(mouseData, shockFrames, keypts, tempTrack)
% tempTrack = compute_dist_between_keypoints(mouseData, shockFrames, keypts)
%
% This function will compute the distance IN PIXELS between unique pairs of
% keypts during the video frames given by shockFrames for a single session
% of data stored in mouseData. Because the distance is provided in pixels,
% measurements are highly dependent on camera angle. To normalize out
% camera angle differences, it is advised to have a ruler measurement to
% convert from pixel to cm.  Currently this conversion is stored in
% mouseData.Spout, so when this field is non-empty, pixels are converted to
% cm and given the feature name  "keypt1_keypt2_dist_cm". If not converted,
% they have the feature name "keypt1_keypt2_dist".
%
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
%   tempTrack (optional) if this structure is passed in, this function will
%      add fields; if not given, a new structure is created.
%
% Outputs
%   tempTrack
%
%
% Written by LR Keyes, Feb 10, 2023
% See also:

%% error checks
% error check 1: we assume the input will have the form of a cell array. If a
% structure is passed in (i.e., mouseData{1} was the input) we make it a
% temporary cell array to work in this function
if iscell(mouseData)
    error('input mouseData should be a structure, not a cell array')
    %mouseData = mouseData{1};
end

% error check: make sure mouseData has tracks in the structure
if ~isfield(mouseData,'tracks')
    error('%s:Input structure "mouseData" does not contain the expected field "tracks"',mfilename);
end

% error check 2: was tempTrack passed in as argument? if not, make it
if nargin<4
    tempTrack = struct;
end

% check if we convert pixels to cm
feature_name_ext = '';% don't tack anything onto your feature name
CONVERT_PX_TO_CM = 0; % flag to convert to CM
conversionFactorPixToCm = 1; % this will keep the measurements in pixels

if isfield(mouseData,'Spout') && ~isempty(mouseData.Spout)
    CONVERT_PX_TO_CM = 1;
    conversionFactorPixToCm = mouseData.Spout.conversionFactor;
    feature_name_ext = '_cm';% tack on '_cm' to your feature name
end


fprintf('Computing distances between all keypoint pairs...')
tStart = tic;
% get some parameters
nVidFrames = size(mouseData.tracks,1);
nFrames = size(shockFrames,2);
nPoints = numel(keypts);
keypts = clean_up_node_names(keypts);

%% create the field names from pairs of keypoints and initialize distance vectors
% fieldname will be of the form:
%      "keypt1_keypt2_dist"
for ii = 1:nPoints
    for jj = 1:nPoints
        if ii==jj || ii>jj,continue,end % skip nonsensical computations 

        feature_name = [keypts{ii},'_',keypts{jj},'_dist',feature_name_ext];
        tempTrack.(feature_name) = zeros(nFrames,1);
    end
end


%% create the different features values using generic keypoint info
for ff = 1:nFrames
    
    % this frame
    frame = shockFrames(ff);
    if frame>nVidFrames
        warning('Event frame selected is past end of video')
        continue
    end
    %% compute distance between pairs of key points
    for ii = 1:nPoints
        for jj = 1:nPoints
            if ii==jj || ii>jj,continue,end
            % compute distances between points
            feature_name = [keypts{ii},'_',keypts{jj},'_dist',feature_name_ext];
            
            % bp1 =  squeeze(mouseData.tracks(frame,ii,:)*conversionFactorPixToCm)';
            % bp2 =  squeeze(mouseData.tracks(frame,jj,:)*conversionFactorPixToCm)';
            % tempTrack.(feature_name)(ff,1) = pdist([bp1; bp2], 'euclidean');

            bp1 =  squeeze(mouseData.tracks(frame,ii,:))'; % bodypoint in pixels
            bp2 =  squeeze(mouseData.tracks(frame,jj,:))'; % bodypoint in pixels
            tempTrack.(feature_name)(ff,1) = pdist([bp1; bp2], 'euclidean')*conversionFactorPixToCm; % now convert dist to cm if specified
        end
    end
    
end % end loop over frames

tEnd = toc(tStart);
fprintf('Done in %5.3f s\n',tEnd)

