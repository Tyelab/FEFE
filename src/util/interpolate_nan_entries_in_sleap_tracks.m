function interpolated_md = interpolate_nan_entries_in_sleap_tracks(md,max_consecutive_nan_thresh)
% This function will take in single mouseData structure, search for nan
% entries and apply interpolation to fill in nan values when the number of
% maximum successive nan entries is below the given threshold.
%
% 1. Count up max num of consecutive nan entries for this node
% 2. If below thresh, interpolate the nan entries using a gridded
%    interpolant and applying a linear method 
%
% INPUT
% md  -  mouseData structure (NOT a cell array of structures)
% max_consecutive_nan_thresh - integer for the greatest number of
%         consecutive nan in a row.  This function will interpolate only
%         when the max num of consecutive nan are below this setting
%
% OUPUT
% interpolated_md = same mouseData structure as input, except the tracks
%         field.  Here the tracks that had nan entries have been
%         interpolated. 
%
% example usage:
% > md = mouseData{1};
% > interpolated_md = interpolate_nan_entries(md,15);
%
% written for Tyelab by Laurel Keyes, 7/30/2024
%
% see also load_sleap_and_events_data_mainWrapperCMS_new_cohort,
% load_sleap_and_events_data_v6 

if iscell(md), error('Expected a single mouseData structure, not cell array'),end

PLT = 0;
DBG = 0;
%% search over all nodes and find total nan count per node and max consecutive nan count per node
% initialize matrices to hold counts of nan entries
total_nan_count =  zeros(numel(md.node_names),1);
max_successive_nan_count = zeros(numel(md.node_names),1);
if ~isempty(md)
    total_nan_count(:) =  sum(isnan(md.tracks(:,:,1)),1)' ;
end

% get max number of consecutive nans
small_nan_nodes = find( total_nan_count > 0);
for jj = 1:numel(small_nan_nodes)
    small_nan_node=small_nan_nodes(jj);
    a = find(isnan(md.tracks(:,small_nan_node,1)));
    if numel(a)==1
        max_count = 1;
        max_successive_nan_count(small_nan_node) = max_count;
        continue;
    else
        da = diff(a);
        count = 0;
        max_count = 0;
        for kk = 1:numel(da)
            if da(kk)==1 && kk<numel(da)
                count = count+1;
            elseif da(kk)==1 && kk==numel(da)
                count = count+1;
                max_count = max(max_count, count);
            else
                max_count = max(max_count, count);
                count = 0;
            end
            max_successive_nan_count(small_nan_node,1) = max_count;
        end
    end
end %loop over small_nan_nodes

nodes_to_be_interpolated = find(max_successive_nan_count>0 & max_successive_nan_count<=max_consecutive_nan_thresh);

%% for every node with nan entries, where the max consecutive is below threshold, interpolate nan entries
interpolated_md = md;    
if ~isempty(nodes_to_be_interpolated)
    if DBG
        vid = VideoReader(md.vidpath)   ; % used in debug mode to plot interpolated points
    end

    for nn = 1:numel(nodes_to_be_interpolated)
        node = nodes_to_be_interpolated(nn);
        % take the x component of the sleap track data; if this is nan, y component
        % will also be nan
        track_x = md.tracks(:,node,1);
        track_y = md.tracks(:,node,2);

        % basic linear interpolation for x-component
        inn_x = ~isnan(track_x);  % your data
        i1x = (1:numel(track_x)).'; % points for your data
        Npts = size(track_x,1); % increase num pts to evaluate for interpolated data
        XX = linspace(i1x(1),i1x(end),Npts);
        % this was my orignal method, but not recommended by matlab
        % pp_y = interp1(i1x(inn_x),track_x(inn_x),'linear','pp'); % interpolated values
        % interpolated_track_x = fnval(pp_y,XX);
        Fx = griddedInterpolant(i1x(inn_x),track_x(inn_x),'linear'); % interpolated values
        interpolated_track_x = Fx(XX);

        % basic linear interpolation for y-component
        inn_y = ~isnan(track_y);  % your data
        i1_y = (1:numel(track_y)).'; % points for your data
        Npts = size(track_y,1); % increase num pts to evaluate for interpolated data
        YY = linspace(i1_y(1),i1_y(end),Npts);
        % this was my orignal method, but not recommended by matlab
        % pp_y = interp1(i1_y(inn_y),track_y(inn_y),'linear','pp'); % interpolated values
        % interpolated_track_y = fnval(pp_y,YY);
        Fy = griddedInterpolant(i1_y(inn_y),track_y(inn_y),'linear'); % interpolated values
        interpolated_track_y = Fy(XX);
        
        if PLT
            fh = figure;
            subplot(2,1,1)
            plot(i1x,track_x,'ko'); hold on;
            plot(XX,interpolated_track_x,'r.-')
            title('track X-component')        
            subplot(2,1,2)
            plot(i1_y,track_y,'ko'); hold on;
            plot(YY,interpolated_track_y,'r.-')
            title('track Y-component')
        end

        interpolated_md.tracks(:,node,1) = interpolated_track_x;
        interpolated_md.tracks(:,node,2) = interpolated_track_y;
    end



    if DBG
        % show location on video of first 20 interpolated values
        figure;
        frames = find(isnan(track_x),20,"first");
        for ii = 1:numel(frames)
            frame = frames(ii);
            vid.CurrentTime = frame/md.fps;
            vidFrame = readFrame(vid);
            image(vidFrame);
            hold on;
            % plot(interpolated_track_x(frame), interpolated_track_y(frame),'y*')
            plot(interpolated_md.tracks(frame,:,1), interpolated_md.tracks(frame,:,2),'y*')
            plot(md.tracks(frame,:,1), md.tracks(frame,:,2),'ro')
            title(sprintf('%s_%s, frame %d',md.id, md.session, frame),'Interpreter','none')
            pause(.1)
        end
    end

end