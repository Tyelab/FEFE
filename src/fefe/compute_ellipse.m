
function [tempTrack] = compute_ellipse(mouseData, frames, keypoints, feature_name, tempTrack, dbg)
% [major_axis, minor_axis, axis_ratio] = compute_ellipse(tracks, frames, keypoints)
%
% Given the list of keypoints, fit an ellipse for each frame in using the
% location data in tracks.  Resulting measurements are given in pixels.
%
% Input
%  mouseData is a structure containing the field, 'tracks' where
%      tracks = nPoints x nFrames x 2 array 
%  frames = 1xN array (N<=nFrames) can be a subset of nFrames or all 
%  keypoints = 1xK cell array, K<=nPoints, can be a subset or all tracked
%              keypoints
%  feature_name = an identifying string to add to the returned fields, such as
%            'ear'
%
%
% Output
%
%
% Usage
%   to fit the mouse's ear with an ellipse, select the keypoints that label
%   the ear, sleect the frames you are interested in, and use
%   mouseData{sesh}.tracks

if iscell(mouseData)
    error('input mouseData should be a structure, NOT a cell array')
    %mouseData = mouseData{1};
end

% error check: was tempTrack passed in as argument? if not, make it
if nargin<5
    tempTrack = struct;
end

if nargin<6
    dbg = 0;
end 

if dbg
    fh = figure; %#ok<NASGU>
end


% check if we convert distance to cm
feature_name_ext = '';% don't tack anything onto your feature name
CONVERT_PX_TO_CM = 0; % flag to convert to CM

if isfield(mouseData,'Spout') && ~isempty(mouseData.Spout)
    CONVERT_PX_TO_CM = 1;
    conversionFactorPixToCm = mouseData.Spout.conversionFactor;
    feature_name_ext = '_cm';% tack on '_cm' to your feature name
end


%% initialize feature arrays
nFrames = size(frames,2);
tempTrack.([feature_name,'_ellipse_major_axis_len',feature_name_ext]) = nan(nFrames,1);
tempTrack.([feature_name,'_ellipse_minor_axis_len',feature_name_ext]) = nan(nFrames,1);
tempTrack.([feature_name,'_ellipse_axis_ratio'])                      = nan(nFrames,1);
tempTrack.([feature_name,'_ellipse_tilt'])                            = nan(nFrames,1);
tempTrack.([feature_name,'_ellipse_area',feature_name_ext])           = nan(nFrames,1);
tempTrack.([feature_name,'_ellipse_eccentricity'])                    = nan(nFrames,1);

%% fill in feature arrays
for ii = 1:numel(frames)
    x =  mouseData.tracks(frames(ii),keypoints,1);
    y =  mouseData.tracks(frames(ii),keypoints,2);
    % check that all keypoints are non-nan, otherwise leave ellipse values
    % as nans
    if sum(~isnan(x)) <  numel(keypoints) || sum(~isnan(y)) < numel(keypoints), continue, end

    % remove any nan values as we can't use them in fit_ellipse
    x = x(~isnan(x));
    y = y(~isnan(y));

    if CONVERT_PX_TO_CM
        x =  x * conversionFactorPixToCm;
        y =  y* conversionFactorPixToCm;
    end

    try
        if dbg && CONVERT_PX_TO_CM==0
            % note you can only run the debug plots on the NOT CONVERTED TO
            % CM version, otherwise the ellipse is in centimeters and not
            % in pixels and will not align correctly with video (which is
            % in pixels)
            %
            % to run a test, set the mouseData.spout = []; and the
            % convertion step will not be run in compute_ellipse.  Then the
            % still frame from the video will show where the 
            clf
            
            if ispc
                mouseData.vidpath = strrep(mouseData.vidpath,'/','\');
                mouseData.vidpath = strrep(mouseData.vidpath,'\ktdata\snlkt','\\ktdata');
            end
            v = VideoReader(mouseData.vidpath); %#ok<TNMLP> % open the video
            v.CurrentTime =  frames(ii)/v.FrameRate; % set the time to the current frame
            img = readFrame(v); % read the current frame
            imagesc(img);hold on; % plot it
            plot(x,y,'oy','MarkerFaceColor','y') % plot the keypoints
            hold on;
            % debugging will draw the elipse for this frame
            title(sprintf('%d',frames(ii)))

            E = fit_ellipse(x,y,gca); 
            % plot the ellipse
            

        else
            E = fit_ellipse(x,y);
        end

        % % if the value of E is larger than 3.5 cm, toss out detection; this
        % % is unrealistic size of ear for C57black/j6 strain
        % if E.long_axis > 3.5
        %     warning('%s: Ignoring unrealistic size of C57black/j6 ear diameter ',mfilename)
        %     E = [];
        %     E.status= 'Hyperbola found';
        % end


        % checking if we found ellipse or not
        if strcmp(E.status, 'Hyperbola found') == 1
            continue
        else            
            tempTrack.([feature_name,'_ellipse_major_axis_len',feature_name_ext])(ii,1) = E.long_axis;
            tempTrack.([feature_name,'_ellipse_minor_axis_len',feature_name_ext])(ii,1) = E.short_axis;
            tempTrack.([feature_name,'_ellipse_axis_ratio'])(ii,1) = E.long_axis/E.short_axis; 
            tempTrack.([feature_name,'_ellipse_tilt'])(ii,1)       = E.phi;
            tempTrack.([feature_name,'_ellipse_area',feature_name_ext])(ii,1)       = E.long_axis * E.short_axis * pi;
            tempTrack.([feature_name,'_ellipse_eccentricity'])(ii,1) = sqrt( 1 - (E.short_axis)^2/ (E.long_axis)^2);
        end
    catch
        % this should never happen because if an ellipse is not found, an
        % empty strucutre is returned.
        error('could not fit ellipse')
    end
end


