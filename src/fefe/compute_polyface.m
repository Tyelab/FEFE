function tempTrack = compute_polyface(mouseData, shockFrames, keypts, tempTrack)
% TEMPTRACK = COMPUTE_POLYFACE(MOUSEDATA, SHOCKFRAMES, KEYPTS, TEMPTRACK)
% This function will compute the angle between unique triplets of keypts
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
%   tempTrack (optional) if this structure is passed in, this function will
%      add fields; if not given, a new structure is created.
%
% Outputs
%   tempTrack
%
%
% Written by LR Keyes, Feb 1, 2024
% See also: compute_angle_between_centroids

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


% make sure the nodes are ordered and named as expected
expected_node_names = {    ...
    'upper_eye';... % 1
    'lower_eye';... % 2
    'inner_eye';... % 3
    'outer_eye';... % 4
    'inner_ear_lower';...% 5
    'inner_ear_upper';...% 6
    'ear_fold_top';...   % 7
    'upper_ear';...      % 8
    'outer_ear_upper_edge';...% 9
    'outer_ear_lower_edge';...% 10
    'bottom_ear';...   % 11
    'nose_upper';...   % 12
    'nose_tip';...     % 13
    'nostril_left';... % 14
    'nostril_right';...% 15
    'mouth_upper';...  % 16
    'mouth_lower';...  % 17
    'chin';...         % 18
    'headplate';...    % 19
    'top_whisker_stem';...% 20
    'bottom_whisker_stem';...% 21
    };
if ~all(strcmp(expected_node_names, keypts))
    error('Actual node names appear inconsistent with expected node names, this function may not work as expected');
end


%% these are the node angles we consider:

USE_EAR_POINTS = 0;

if USE_EAR_POINTS==1
    % selected triangles:
    combos = [...
        8 9 10;...  % ear
        8 10 7;...  % ear
        7 6 5;...   % inner ear
        5 11 10;... % lower ear
        6 5 11;...  % inner ear
        6 4 1;...   % ear/high temple
        6 4 11;...  % temple
        11 4 18;... % cheek
        1 3 4;...   % eye
        2 3 4;...   % eye
        3 4 18;...  % under eye
        3 18 21;... % cheek
        6 18 3;...  % big cheek including eye
        2 11 18;... % lower cheek
        3 20 21;... % eye to whiskers
        3 12 20;... % upper bride of nose, above whiskers
        12 13 20;... % side of nose
        12 13 15;... % nose
        12 13 14;... % nose
        12 21 15;... % nose/whisker
        20 21 13;... % nose/whisker
        20 16 15;... % nose/mouth
        12 16 13;... % nose/mouth
        17 14 21;... % nose/whisker/lower mouth
        21 20 13;... % whiskers/nose
        21 15 13;...% whiskers/nose
        13 14 15;... % nose tip
        14 15 16;... % nose/upper lip
        16 17 18;... % mouth
        18 16 21;... % chin/uppermouth/lower whisker
        21 15 16;... % whisker/nostril/uppermouth
        11 20 21;... % lower cheek
        11 21 18;... % lower cheek
        11 16 17;... % lower cheek
        ];

else
    % selected triangles:
    combos = [...
        1 3 4;...   % eye
        2 3 4;...   % eye
        3 4 18;...  % under eye
        3 18 21;... % cheek
        3 20 21;... % eye to whiskers
        3 12 20;... % upper bride of nose, above whiskers
        12 13 20;... % side of nose
        12 13 15;... % nose
        12 13 14;... % nose
        12 21 15;... % nose/whisker
        20 21 13;... % nose/whisker
        20 16 15;... % nose/mouth
        12 16 13;... % nose/mouth
        17 14 21;... % nose/whisker/lower mouth
        21 20 13;... % whiskers/nose
        21 15 13;...% whiskers/nose
        13 14 15;... % nose tip
        14 15 16;... % nose/upper lip
        16 17 18;... % mouth
        18 16 21;... % chin/uppermouth/lower whisker
        21 15 16;... % whisker/nostril/uppermouth
        ];

    % this is all combinations of keypoints (without ear) taken 3 at a
    % time:
    % m = nchoosek(unique(combos), 3);
end

%% loop through the list of combinations of keypoints and define the angle

% angles
for ii = 1:size(combos,1)
    pts = combos(ii,:); % get the index of keypoints
    tempTrack = compute_angle_between_centroids(mouseData, shockFrames, keypts,...
        pts(1),pts(2),pts(3),...
        keypts{1},keypts{2},keypts{3},tempTrack);
end

% triangular areas
for ii = 1:size(combos,1)
    pts = combos(ii,:); % get the index of keypoints
    tempTrack = compute_triangle_area(mouseData, shockFrames, keypts,...
        pts(1),pts(2),pts(3),...
        keypts{1},keypts{2},keypts{3},tempTrack);
end

% debugging: this will plot the triangles overlaid on mouse face
% make sure you are using the right points
if 0
    % define the colormap for triangles
    clrmap = hsv(size(combos,1)); %#ok<UNRCH>
    % plot first frame of video
    vid = VideoReader(mouseData.vidpath);
    vid.CurrentTime = 1/vid.FrameRate;
    frame = readFrame(vid);
    figure;
    image(frame); hold on
    title(vid.Name, 'Interpreter','none')
    hold on
    % plot each triangle
    for ii = 1:size(combos,1)
        % set axis
        x1 = min(mouseData.tracks(1,:,1)) - 10;
        x2 = max(mouseData.tracks(1,:,1)) + 10;
        y1 = min(mouseData.tracks(1,:,2)) - 30;
        y2 = max(mouseData.tracks(1,:,2)) + 30;
        axis([ x1 x2 y1 y2])

        p1 = combos(ii,1);
        p2 = combos(ii,2);
        p3 = combos(ii,3);
        % draw triangle and shade in

        % plot keypoints
        plot(mouseData.tracks(1,:,1),mouseData.tracks(1,:,2),'ok','MarkerFaceColor','y')

        % plot triangle
        plot(mouseData.tracks(1,[p1 p2],1),mouseData.tracks(1,[p1 p2],2),'Color',clrmap(ii,:))
        plot(mouseData.tracks(1,[p1 p3],1),mouseData.tracks(1,[p1 p3],2),'Color',clrmap(ii,:))
        plot(mouseData.tracks(1,[p3 p2],1),mouseData.tracks(1,[p3 p2],2),'Color',clrmap(ii,:))
pause
    end

end