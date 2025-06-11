function tempTrack = compute_ave_dist_from_previous_frame(mouseData, shockFrames, keypts, tempTrack)
% tempTrack = compute_dist_features(mouseData, shockFrames, keypts)
%
% This function will compute the distance for each keypoint from the
% previous frame during the video frames given by shockFrames for a single
% session of data stored in mouseData.  
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

% error check: we assume input is structure, NOT cell array. 
if iscell(mouseData)
    error('input mouseData should be a structure, NOT a cell array')
    %mouseData = mouseData{1};
end

end

% error check: make sure mouseData has tracks in the structure
if ~isfield(mouseData,'tracks') %#ok<SYNER>
    error('%s:Input structure "mouseData" does not contain the expected field "tracks"',mfilename);
end

% error check: was tempTrack passed in as argument? if not, make it
if nargin<4
    tempTrack = struct;
end

% get some parameters
nVidFrames = size(mouseData.tracks,1);
nFrames = size(shockFrames,2);
nPoints = numel(keypts);

fprintf('Computing average movement over all keypoints from previous frame ...')
tStart = tic;
%% initialize distance vectors
tempTrack.pointDistAllAve = zeros(nFrames,1);
pointDistAll = zeros(nFrames,nPoints);


%% create the different features values using generic keypoint info
trial_start_frames = find(diff(shockFrames)>20);
for ff = 1:nFrames
    
    % this frame
    frame = shockFrames(ff);
    if frame>nVidFrames
        warning('Event frame selected is past end of video')
        continue
    end

    %% compute average distance between all keypoints from previous frame,
    % (except if start of a new trial)
    if any(frame == trial_start_frames)
        % do nothing, this is first frame of new trial
    else
        % loop through keypoint and get the distance from previous frame,
        % then take average over all keypts
        for pp = 1:numel(keypts)
            bp1 =  squeeze(mouseData.tracks(frame,pp,:));
            bp0 =  squeeze(mouseData.tracks(frame-1,pp,:));
            pointDistAll(ff,pp) = pdist( [bp1';bp0'],'euclidean');
        end
        tempTrack.pointDistAllAve(ff,1) = mean(pointDistAll(ff,:),'omitnan');
    end
    
end

outlier_dbg = 0; % flag for debugging remove outliers
tempTrack.pointDistAllAve = remove_outliers(tempTrack.pointDistAllAve,outlier_dbg);
%tempTrack.pointDistAll = pointDistAll;

tEnd = toc(tStart);
fprintf('Done in %5.3f s\n',tEnd)
