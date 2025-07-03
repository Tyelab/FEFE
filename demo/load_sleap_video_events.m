function mouseData = load_sleap_video_events(vidpath_in, eventFile_in, h5file_in,spoutfile_in)
% mouseData = load_sleap_video_events(vidpath_in, eventFile_in, h5file_in,spoutfile_in)
%
% Load the sleap predictions and the associated events file
%
% This script creates the structure mouseData, which includes
%    
% 1. the sleap track data from tracked mouse faces, using a pre-defined
%    SLEAP model (i.e., this is not run in this script) 
% 2. an events file showing the trial structure of stimuli presentation
% 3. (optional) a spout file, that contains the conversion of pixels to cm
% 4. (optional) a video file of the mouse
% 
% The script then creates a features table using the sleap tracked data.
%
% INPUTS
%  vidpath_in   - full path to raw video file (mp4)
%  eventFile_in - full path to event file (csv)
%  h5file_in    - full path to sleap predicted file, converted to .h5 (h5)
%  spoutfile_in - fullpath to matlab file showing how long visible spout is
%  (NOTE: the spoutfile provides a way to convert pixels to cm uniformly
%  across all subjects. If this file is absent, this conversion is not
%  performed and distances remain in pixels.)
% 
% Output
%  mouseData is a structure showing the mouse ID, session number,
%  originating file folders,  events table showing the start/end times for
%  different reward/adversive stimuli , video frame numbers for
%  airpuff/sucrose/ITI or baseline  (one entry in mouse data corresponds to
%  one session) and information about the facial video.
%
% See also import_corrected_USevents_file, compute_select_features_v02
%
% Written by Laurel Keyes on 9/11/2023, updated on 1/11/2024

% addpath to source codes
gitdir = pwd; tmp = split(gitdir,'demo'); 
maindir = tmp{1};
addpath(genpath(fullfile(maindir,'src')));

if nargin<4
    vidpath_in   = fullfile(maindir,'demo','data','20230225_CSE022_plane1_-367.5.mp4');
    eventFile_in = fullfile(maindir,'demo','data','CSE022_20230225_corrected.csv');
    h5file_in    = fullfile(maindir,'demo','data','20230225_CSE022_plane1_-367.5.predictions.analysis.h5');
    spoutfile_in = fullfile(maindir,'demo','data','20230225_CSE022_plane1_-367.5_SL_spout.mat');
end

% check that file has been downloaded and placed in data folder
fprintf("Checking for video file...")
if exist(vidpath_in,'file')==2
    fprintf('... found it.\n')
    LOAD_VIDEO = 1;
else
    
    %google_link = 'https://drive.google.com/file/d/1OVx5j9EGm0spBwF-NX4SjhbkNVs_JWUM/view?usp=drive_link';
    fileID = '1OVx5j9EGm0spBwF-NX4SjhbkNVs_JWUM';
    url = sprintf('https://drive.google.com/uc?export=download&id=%s', fileID);
    outFile = 'data\20230225_CSE022_plane1_-367.5.mp4';  
    drive_msg = sprintf('\nYou must download the video file and move to data directory.\n Use this google drive link: \n\thttps://drive.google.com/file/d/%s/view?usp=drive_link\n',fileID);

    fprintf('... file not found! \nAttempting to download from Tyelab google drive... \n\n')
    try
        fprintf('Starting video download...\n');
        websave(outFile, url);
        fprintf('Download completed successfully. Saved as %s\n', outFile);

        vidpath_in = fullfile(maindir,'demo', outFile)
        LOAD_VIDEO = 1;
    catch ME
        fprintf(2, 'Error downloading file: %s\n', ME.message);
        fprintf(drive_msg)
        % Optionally rethrow or handle specific cases
        % rethrow(ME);
        LOAD_VIDEO = 0;
    end


    % test that file downloaded correctly
    fprintf('Verifying video download...')
    try
        v = VideoReader(vidpath_in);
    catch ME
        fprintf(2, 'Video file appears to be corrupted!\n %s\n', ME.message);        
        fprintf(drive_msg)
        fprintf('Program will remove corrupted file and continue without video.\n\n')
        delete(vidpath_in)
        LOAD_VIDEO = 0;
    end

end

if exist("spoutfile_in","var")   
    fprintf('detected spout file ... loading conversion pixels to cm ...')
    load(spoutfile_in,'Spout'); % load the matlab file
    fprintf('done.\n')
else
     % no spout file is provided
    Spout = [];
    error('could not find spoutfile')
end


% get the name tag to use from file name
% [~, eventfile,~] = fileparts(eventFile_in);
[~,h5file,~] = fileparts(h5file_in);
tmp1 = split( h5file,'.predictions');
nametag = tmp1{1};

% set FLAGS
ZSCORE_FLAG = 0; % when 0, do NOT normalize to baseline; when 1 normalize
VERBOSE = 1; % print comments to screen

%% create mouseData structure with basic info about session
% tmp = split( nametag,'_');

%mouseData.folder = mp4path;
% mouseData.id = tmp{2};
% mouseData.session = tmp{1};
mouseData.Spout= Spout;
if VERBOSE, fprintf("\nCreating %s\n", nametag);end


%% load video info
if LOAD_VIDEO
    % get video frame rate information
    if VERBOSE, fprintf('\tAdding video details\n');end

    if exist(vidpath_in,'file')
        v = VideoReader(vidpath_in);
        c.facialVid_fps = v.FrameRate; % this is the frame rate of the facial video, however here we want to use the bruker frame rate, which is ~29.87
        % c.Bruker_fps = 29.87; % this is the frame rate of the Bruker 2p microscope
        % c.note = 'frame rate of the facial video differs from Bruker frame rate, which is ~29.87; FaceVidEvents_msec = BrukerEvents_msec*Bruker_fps/FaceVid_fps';
        c.NumFrames = round(v.Duration*v.FrameRate);
        if VERBOSE, fprintf('\tvideo=%s \n',vidpath_in);end
        if VERBOSE, fprintf('\tThis video frame rate is %3.5f\n',c.facialVid_fps);end

    else
        error('Video not found! (%s)',vidpath_in)
    end
    mouseData.vidpath = vidpath_in;
    % mouseData.Bruker_fps = c.Bruker_fps;
    mouseData.fps = c.facialVid_fps;  % all videos in this cohort used 30 fps
    % mouseData.fps_note = c.note;
    mouseData.numFrames = c.NumFrames;  % all videos in this cohort used 30 fps
else
    % manually enter the frame rate of the video
    x = input('Enter the frame rate of the video used in H5 predictions file:  ');    
    if ~isnumeric(x)
        error('error! enter the frame rate as numbers only.  For example if the frame rate is 30 fps, enter 30')
    else
        c.facialVid_fps = x;
    end      
end


%% 
mouseData.event_file_in = eventFile_in;
mouseData.sleap_h5_file_in = h5file_in;
mouseData.spout_file_in = spoutfile_in;


%% load events data
% In demo event file:
%    -5 sec to 0 sec = baseline (BL)
%    0-5 seconds when tone sounds (CS)
%    US is delivered at 2 s after tone onset
%
% The times in the events file are given in miliseconds from start of
% recording.  First convert to seconds (/1000), then get frame by
% (*v.frameRate)

if VERBOSE, fprintf("\n\tLoading Events data \n");end

% load the corrected events file for US delivery (manually corrected)
us_delivery = import_corrected_USevents_file(eventFile_in);

% make a new table from the US timings
events_corrected = us_delivery(:,{'Subject','Session','Stimulus_type','PrePost'});
events_corrected.us_delivery_frame = us_delivery.TRUE;

% compute the estimated cs_onset and offset frame values
events_corrected.cs_onset_frame = floor(us_delivery.TRUE - 2*c.facialVid_fps); % tone onset 2 seconds before us del
events_corrected.cs_offset_frame = floor(us_delivery.TRUE + 3*c.facialVid_fps); % tone offset 3 seconds after us del
events_corrected.Properties.VariableDescriptions = {...
    'SubjectID', 'session date in YYYYMMDD', 'stimulus is either Airpuff or Sucrose', ...
    'pre = before dopamine stimulation, during = during opto stimulation of dopamine terminals, post = after stim',...
    'video frame number of mouse facial video where the US (unconditioned stimulus) delivery occurs',...
    'video frame number of mouse facial video where the CS (conditioned stimulus) tone starts',...
    'video frame number of mouse facial video where the CS (conditioned stimulus) tone turns off'...
    };
mouseData.eventsTable = events_corrected;


%% load sleap tracked data
if VERBOSE, fprintf("\n\tLoading Track data \n");end
% h5files = dir(fullfile(mouseData.folder,'*.h5'));
if exist(h5file_in,'file')~=2
    %warning('could not find H5 for %s', mouseData.folder)
    %continue;
    %pause
    error('H5 not found (%s)', h5file_in)
end

% load tracks info
mouseData.instance_scores = h5read(h5file_in, '/instance_scores');
mouseData.node_names = h5read(h5file_in, '/node_names');
mouseData.point_scores = h5read(h5file_in, '/point_scores');
mouseData.track_names = h5read(h5file_in, '/track_names');
mouseData.track_occupancy = h5read(h5file_in, '/track_occupancy');
mouseData.point_scores = h5read(h5file_in, '/point_scores');
mouseData.tracking_scores = h5read(h5file_in, '/tracking_scores');
mouseData.tracks = h5read(h5file_in, '/tracks');
mouseData.sleap_file = h5file_in;


REMOVE_WHISKER_END = 1;  
if REMOVE_WHISKER_END
    % remove "top_whisker_end" and "bottom_whisker_end" points
    % the ends of the whiskers did not track well at this frame rate, so remove
    iWhiskerEnd = contains(mouseData.node_names,'whisker_end');
    mouseData.node_names = mouseData.node_names(~iWhiskerEnd);
    mouseData.point_scores = mouseData.point_scores(:,~iWhiskerEnd);
    mouseData.tracks    = mouseData.tracks(:,~iWhiskerEnd,:);
end

% remove "left_nostril" points
iLeftNostril = contains(mouseData.node_names,'left_nostril');
mouseData.node_names = mouseData.node_names(~iLeftNostril);
mouseData.point_scores = mouseData.point_scores(:,~iLeftNostril);
mouseData.tracks    = mouseData.tracks(:,~iLeftNostril,:);

%% SMOOTH the track points using savitzky-golay filter, 2 points before,
% 2 points after current point; by default this ignores nan entries
mouseData.tracks = smoothdata(mouseData.tracks, 1, 'sgolay', 5); % mouseData now contains smoothed track data

%% Replace individual missing sleap track points with k-nearest neighbor
% entry for ear (keypoints = 6:11)
% md_tracks_fix = fill_nan_sleap_track(mouseData.tracks,6:11, mouseData.vidpath,0);
% mouseData.tracks = md_tracks_fix;

%% fill in nan entries in tracks when fewer than 15 consecutive entries,
% e.g. 1/2 second
% below we set the maximum number of frames that are allowed to be NAN
% in our 30 fps paradigm, 15 frames is about 1/2 second
max_consecutive_nan_thresh = 15;
tmp = interpolate_nan_entries_in_sleap_tracks(mouseData,max_consecutive_nan_thresh);
mouseData = tmp; clear tmp


if VERBOSE, fprintf('\tDone adding tracks\n');end


%% Extract featurenames
keypts = mouseData.node_names; % get the node names from sleap
keypts = clean_up_node_names(keypts); % clean up so well formatted


%% extract the features for all frames in this session
tempTrack =  compute_select_features_v02(mouseData, 1:size(mouseData.tracks,1), keypts,ZSCORE_FLAG);
mouseData.features = tempTrack;

end


