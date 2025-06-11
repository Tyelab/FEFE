function  md_tracks_fix = fill_nan_sleap_track(md_tracks, keypoints, vidpath, DBG)
% MD_TRACKS_FIX = FILL_NAN_SLEAP_TRACK(MD_TRACKS, KEYPOINTS,VIDPATH, DBG)
%
% This function takes in sleap track data and a set of keypoints in the
% sleap track data. It attempts to fill in nan values by searching for the
% nearest neighbor match and replacing the nan value with the non-nan
% values of the nearest neighbor.
%
% To start, the track data is first split into data will NO nan entries and
% data with ONE nan entry per group of keypoints.  For example, this was
% designed to work on Austin Coley's depression dataset, where the outer
% edge of the mouse ear was often missing. As input, we take the ear
% keypoints, loop through each of the keypoints singly to identify where
% individual keypoints have a nan entry (e.g. one per group).
%
% INPUT
% md_tracks - output from sleap, organzied by nFrames by nKeypoints by 2
% keypoints - set of indices for part or all keypoints in the sleap track
% vidpath (optional if you want to make a video with the replaced keypoint)
%
% OUTPUT
% md_tracks_fix = copy of md_tracks with nan entries filled in with
%     nearest neighbor entries
%
% Example: Suppose you have the following sleap track informatioN:
%  ans(:,:,1) =
%    820.5732  NaN  983.5481
%  ans(:,:,2) =
%    411.9544  375.3897  386.9135
% and you want to fill in the nan with the nearest neighbor value.  
% Here is the nearest neighbor with all non-nan entries:
%  ans(:,:,1) =
%    819.532  919.8250  983.51
%  ans(:,:,2) =
%    410.94  375.3897  386.9135
% 
% Your corrected sleap track will fill in the match like so:
%  ans(:,:,1) =
%    820.5732  919.8250  983.5481
%  ans(:,:,2) =
%    411.9544  375.3897  386.9135
%
% NOTE: this function assumes head-fixed animal and works directly off
% pixel outputs of sleap track.  If your animal is freely moving, try
% changing this function to work off relative distances between points or
% another measure.
%
% Written by Laurel Keyes, Aug 5, 2024
%

if nargin<2
    % this is for testing out mouse ear in Austin Coley data
    keypoints = 6:11;
end
if nargin<4
    DBG = 0;  % debug flag; when true, creates video showing keypoint placement 
end

% errorchecks
if any(keypoints>size(md_tracks,2)), error('Bad keypoint! Keypoint index out of bounds for tracks.'), end
if isempty(vidpath) && DBG == 1, error('Missing videopath field! Cannot plot debug video without this'),end

% define your data to be the x component of your sleap track followed by the
% y-component of your sleap track
nK = numel(keypoints);
data_x = md_tracks(:,keypoints,1);
data_y = md_tracks(:,keypoints,2);
data = [data_x data_y];
data2 = data; % make a copy of your data to fill in
% TODO: in the future, you could provide other options besides just raw
% pixel values.  maybe relative distances between points.  then use that
% data to knnsearch and identify nearest value according to relative
% positioning

% set your 'good' data to be when no NaN present in any of the keypoints
non_nan_x_ind = find(sum(isnan(data),2)==0);
X = data(non_nan_x_ind,:);
fprintf('Filling in nan entries using k-nearest neighbor approx...\n')
fprintf(sprintf('\t%3.2f of track data is good (non-nan)!\n',numel(non_nan_x_ind)/size(md_tracks,1)*100))
fprintf(sprintf('\t there are %d frames with one keypoint missing and %d frames with more than one nan keypoint\n',sum(sum(isnan(data),2)==2), sum(sum(isnan(data),2)>2)))

if DBG,  vid = VideoReader(vidpath);  figure; end
% loop over each keypoint separately.
if DBG==1
    fprintf('\tDebug ON: will create a video\n')
else
    fprintf('\tDebug OFF: no video created\n')
end

kypts = 1:size(data,2);
for ii = 1:nK
    %disp(ii)    
    tic

    % look for nan entries in the data for this keypoint
    iY = find(sum(isnan(data(:,ii)),2)==1);
    Y = data(iY,:); % this is the data with nan entries in this keypoint
    fprintf(sprintf('\tWorking keypoint %d: there are %d Nan entries.\n',keypoints(ii),size(Y,1)))
    if size(Y,1)>=1
        % loop over each nan entry
        for jj = 1:size(Y,1)
            % find all the other keypoints
            iX = setdiff(kypts, [ii ii+nK]);
            % do a nearest neighbor search in the non-nan data closest to
            % this nan-data entry:
            Idx = knnsearch(X(:,iX),Y(jj,iX));
            % this is your old data
            oldY = data(iY(jj),:); %#ok<NASGU>
            newY = data(iY(jj),:);
            % now update the newY with the nearest non-nan data entry for
            % that keypoint
            newY([ii ii+nK]) = X(Idx,[ii ii+nK]);
            % disp([oldY;newY])
            data2(iY(jj),:)= newY; % copy the entry to data2, your filled in copy


            if DBG
                % make a video so you can check the output
                % load the frame and data with the nan entry:
                vid.CurrentTime = iY(jj)/vid.FrameRate; %#ok<UNRCH>
                vidFrame = readFrame(vid);
                subplot(2,1,1)
                image(vidFrame);
                hold on ; plot(oldY(1:nK), oldY(nK+1:2*nK),'or') % plot orig data
                hold on ; plot(newY(ii), newY(ii+nK),'yo','MarkerFaceColor','g') % plot new non-nan match
                title(sprintf('Filled-in nan: %d, vidFrame=%d',  jj,iY(jj)),'Interpreter','none')
                hold off

                % load the nearest neighbor entry
                subplot(2,1,2)
                vid.CurrentTime = non_nan_x_ind(Idx)/vid.FrameRate; % get the frame right!
                vidFrame = readFrame(vid);
                image(vidFrame);
                hold on ; plot(X(Idx,1:nK),X(Idx,nK+1:2*nK),'oy') % non-nan data
                title(sprintf('Closest matching neighbor frame (%d)',non_nan_x_ind( Idx)))
                % NOTE:  X(Idx,1:nK) is the same as data(non_nan_x_ind(Idx),1:nK)
                hold off
            end
        end
    else
        fprintf(sprintf('\t keypoint %d is clean (no-Nan)',keypoints(ii)))
    end
    toc

end

is_nan_x_ind = sum(sum(isnan(data),2)>0);
is_nan_x2_ind = sum(sum(isnan(data2),2)>0);
fprintf(sprintf('\tReplaced %d nan values with non-nan knn.  Done!\n',is_nan_x_ind - is_nan_x2_ind))

%now put your corrected data back in the right place
md_tracks_fix = md_tracks;
md_tracks_fix(:,keypoints,1) = data2(:, 1:nK);
md_tracks_fix(:,keypoints,2) = data2(:, 1+nK:2*nK);