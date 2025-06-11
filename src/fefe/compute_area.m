function tempTrack = compute_area(mouseData, shockFrames, keypts_index, feature_name, tempTrack)
% tempTrack = compute_area(mouseData, shockFrames, keypts_index, feature_name, tempTrack)
%
% This function will compute the area genreated by the points in
% mouseData.tracks(keypts{keypts_index}).  It uses the matlab built-in
% function polyarea.
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
%   keypts_index: array of integers corresponds to the index is keypoint
%      labels that define the larger body part
%      e.g., "eye" is made up of "upper eye", "lower eye" and "inner eye"
%      and "outer eye"; keypts_index would be the indices of those keypts
%   feature_name: string for what to call the collection of keypoints, e.g.
%      "eye"; this function will automatically append the string '_area'
%      onto the feature_name provided by user
%   tempTrack (optional) if this structure is passed in, this function will
%      add fields; if not given, a new structure is created.
%
% Outputs
%   tempTrack
%
%
% Written by LR Keyes, Feb 10, 2023
% See also:

% error check: we assume the input will have the form of a cell array. If a
% structure is passed in (i.e., mouseData{1} was the input) we make it a
% temporary cell array to work in this function
if iscell(mouseData)
    error('input mouseData should be a structure, NOT a cell array')
    %mouseData = mouseData{1};
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
CONVERT_PX_TO_CM = 0; % flag to convert to CM
feature_name_ext = ''; % don't tack on anything to the feature name

if isfield(mouseData,'Spout') && ~isempty(mouseData.Spout)
    CONVERT_PX_TO_CM = 1;
    conversionFactorPixToCm = mouseData.Spout.conversionFactor;
    feature_name_ext = '_cm';% tack on '_cm' to your feature name
end

% get some parameters
nFrames = size(shockFrames,2);

fprintf('Computing %s area ...', feature_name)
tStart = tic;

%% create the field names from pairs of keypoints and initialize distance vectors
feature_name = [feature_name,'_area',feature_name_ext];
tempTrack.(feature_name) = zeros(nFrames,1);

for ii = 1:length(shockFrames)
     x = mouseData.tracks(ii,keypts_index,1);
     y = mouseData.tracks(ii,keypts_index,2);
    if CONVERT_PX_TO_CM
        x = x * conversionFactorPixToCm;
        y = y * conversionFactorPixToCm;
    end
    % 
    % % remove nan values or the area is nan
    % x = x(~isnan(x)); 
    % y = y(~isnan(y)); 
    % 
    tempTrack.(feature_name)(ii,1) = polyarea(x,y);

end

tEnd = toc(tStart);
fprintf('Done in %5.3f s\n',tEnd)

end