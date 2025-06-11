function tempTrack = compute_triangle_area(mouseData, shockFrames, keypts,keypt_index1,keypt_index2,keypt_index3, feature_name1, feature_name2, feature_name3,tempTrack)
% TEMPTRACK = COMPUTE_TRIANGLE_AREA(MOUSEDATA, SHOCKFRAMES, KEYPTS, TEMPTRACK)
% This function will compute the trianglular area defined by 3 points on
% the face during the video frames given by shockFrames for a single
% session of data stored in mouseData.
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
% Written by LR Keyes, Jan 16, 2025


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

% check if we convert pixels to cm
feature_name_ext = '';% don't tack anything onto your feature name
CONVERT_PX_TO_CM = 0; % flag to convert to CM
conversionFactorPixToCm = 1; % this will keep the measurements in pixels

if isfield(mouseData,'Spout') && ~isempty(mouseData.Spout)
    CONVERT_PX_TO_CM = 1;
    conversionFactorPixToCm = mouseData.Spout.conversionFactor;
    feature_name_ext = '_cm';% tack on '_cm' to your feature name
end

tStart = tic;
% get some parameters
nFrames = size(shockFrames,2);
keypts = clean_up_node_names(keypts);
nVidFrames = size(mouseData.tracks,1);


%% define the 3 side of the triangle using the points given
ii = keypt_index1;
jj = keypt_index2;
kk = keypt_index3;

% create the field names for triangle area
% fieldname will be of the form:
%      "keypt1_keypt2_keypt3_area"
feature_name = [keypts{ii},'_',keypts{jj},'_',keypts{kk},'_area',feature_name_ext];
tempTrack.(feature_name) = zeros(nFrames,1);

fprintf('Computing triangular area between %s,  %s,  %s ...', keypts{ii}, keypts{jj}, keypts{kk});

for ff = 1:nFrames

    % this frame
    frame = shockFrames(ff);
    if frame>nVidFrames
        warning('Event frame selected is past end of video')
        continue
    end
    bp1 =  squeeze(mouseData.tracks(ff,ii,:))'; % bodypoint in pixels
    bp2 =  squeeze(mouseData.tracks(ff,jj,:))'; % bodypoint in pixels
    a = pdist([bp1; bp2], 'euclidean')*conversionFactorPixToCm; % now convert dist to cm if specified

    bp1 =  squeeze(mouseData.tracks(ff,ii,:))'; % bodypoint in pixels
    bp2 =  squeeze(mouseData.tracks(ff,kk,:))'; % bodypoint in pixels
    b = pdist([bp1; bp2], 'euclidean')*conversionFactorPixToCm; % now convert dist to cm if specified

    bp1 =  squeeze(mouseData.tracks(ff,jj,:))'; % bodypoint in pixels
    bp2 =  squeeze(mouseData.tracks(ff,kk,:))'; % bodypoint in pixels
    c = pdist([bp1; bp2], 'euclidean')*conversionFactorPixToCm; % now convert dist to cm if specified

    % Heron's formula for area of triangle, given length of 3 sides 
    tempTrack.(feature_name)(ff,1) = 1/4 * sqrt(4*a*a*b*b - (a*a+b*b-c*c)^2);
end% end loop over frames

tEnd = toc(tStart);
fprintf('Done in %5.3f s\n',tEnd)


