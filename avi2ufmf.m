% ufmfname = avi2ufmf(aviname, ...)
%
% Inputs an AVI movie and converts to an ufmf movie.
%
% Usage:
% The parameters to avitoufmf can be specified as pairs 
% consisting of a string specifying the parameter name 
% followed by the parameter value. If a given parameter is 
% not specifed, then either the user is prompted for this
% value or default values are chosen.
%
% Parameters:
%
% 'aviname': Name of the AVI file to convert. If not 
%   specified, the user is prompted for a name. 
% 'ufmfname': Name of the ufmf file to output.
% 'startframe': first frame to write out to file. 1 by default.
% 'endframe': last frame to write out to file. nframes by default.
% 'diffmode': direction used in background subtraction. One of
%   'dark-on-light-background',
%   'light-on-dark-background',
%   'other'
%   This is 'Other' by default.
% 'bgthresh': Background subtraction threshold for choosing which
%   pixels to store per frame. 1 by default. This should be between 1 
%   and 255.
% 'bgnframes': Number of frames sampled to estimate the background 
%   model. 200 by default.
% 'maxmem': maximum amount of memory to use when computing the 
%   median backgroud model.
% 'verbose': how much diagnostic print statements should be executed.
%   0 means none, 1 means some, 2 means all. 1 by default.
%
% Outputs:
% ufmfname: Name of the ufmf files saved. 
%
% KB 01/13/2010
% ALT 01/19/2024
%
function ufmfname = avi2ufmf(aviname, varargin)

% parse inputs, set defaults as necessary
[ufmfname, ...
 startframe, ...
 endframe_requested,...
 blocknframes, ...
 diffmode, ...
 bgthresh, ...
 bgnframes_requested,...
 verbose] = ...
  myparse(varargin,...
          'ufmfname','',...
          'startframe',1, ...
          'endframe',inf,...
          'blocknframes',2000,...
          'diffmode','other', ...
          'bgthresh',1,...
          'bgnframes',200,...
          'verbose',1);
diffmode = lower(diffmode);

% check for input errors
if startframe < 1 || endframe_requested < startframe,
  error('1 <= startframe <= endframe must hold');
end

% Make up an output file name if none provided
if isempty(ufmfname) ,
  ufmfname = replace_extension(aviname, '.ufmf') ;
end

% open avi file for reading
vr = VideoReader(aviname);
input_video_frame_count = get(vr,'NumFrames');
if isempty(input_video_frame_count),
  % approximate nframes from duration
  input_video_frame_count = get(vr,'Duration')*get(vr,'FrameRate');
end

% set endframes to be at most last frame
endframe = min(endframe_requested,input_video_frame_count);

% create readframe function
readframe = @(frame_index)(vr.read(frame_index)) ;
headerinfo = get(vr);
headerinfo.type = 'avi';
fps = headerinfo.FrameRate ;
dt = 1/fps ;

% read in the first frame to get the size
frame = readframe(startframe);
assert(ismatrix(frame)) ;
ny = size(frame,1);
nx = size(frame,2);
ncolors = size(frame,3);

if verbose >= 1,
  fprintf('AVI File Info:\n');
  fprintf('Name = %s\n',aviname);
  fprintf('Frame size = %d rows x %d columns x %d colors\n',ny,nx,ncolors);
  fprintf('Number of frames = %d\n',input_video_frame_count);
  fprintf('Frame rate = %d\n',fps);
  fprintf('VideoFormat = %s\n',headerinfo.VideoFormat);
  fprintf('BitsPerPixel = %d\n',headerinfo.BitsPerPixel);
end

% make an image with x, y coords
%[x_image, y_image] = meshgrid(1:nc, 1:nr) ;
%[x_image_transposed, y_image_transposed] = meshgrid(1:nr, 1:nc) ;
  % image of x/y coord in *transposed* frame

% set one roi for whole image of no ROIs specified
%roi = [1,nc,1,nr];

if verbose >= 1,
  fprintf('\nSaving ufmf from frame %d to %d\n',startframe,endframe);
end

% open the ufmf
fid = fopen(ufmfname,'w');

% close the file once fp goes out of scope
cleaner = onCleanup(@()(fclose(fid))) ;

% how many frames we are actually writing
output_frame_count = endframe - startframe + 1;

% write header
% already taken the transpose
max_box_width = nx ;
max_box_height = ny ;
is_fixed_size = false ;
indexlocloc = ufmf_write_header(fid, max_box_width, max_box_height, 'mono8', is_fixed_size) ;
  % indexlocloc is where the index location will be stored in the file

% store the locations of the frames in the file
loc_from_output_frame_index = zeros(1, output_frame_count, 'int64') ;
timestamp0 = (startframe-1)*dt ;
timestamp_from_output_frame_index = timestamp0 + dt*(0:(output_frame_count-1)) ;

% Each block gets one keyframe image
block_count = ceil(output_frame_count/blocknframes) ;
bgnframes = min(bgnframes_requested, blocknframes) ;
keyframe_loc_from_block_index = zeros(1, block_count, 'int64') ;
first_output_frame_index_from_block_index = blocknframes*(0:(block_count-1)) + 1 ;
timestamp_from_block_index = timestamp_from_output_frame_index(first_output_frame_index_from_block_index) ;
  % We want *precise* equality between the timestamp of the block and the
  % timestamp of the first frame in the block
for block_index = 1 : block_count ,
  %
  block_input_offset = startframe - 1 + (block_index-1)*blocknframes ;
  block_input_first_frame_index = block_input_offset + 1  ;
  block_input_last_frame_index = min(block_input_offset + blocknframes, endframe) ;
  block_frame_count = block_input_last_frame_index - block_input_first_frame_index + 1 ;
  block_output_offset = (block_index-1)*blocknframes ; 
  %block_output_first_frame_index = block_output_offset + 1  ;
  %block_output_last_frame_index = block_output_offset + block_frame_count ; 

  % compute bg model for block
  if verbose >= 1,
    fprintf('Computing background model for block %d...\n', block_index);
    fprintf('%d frames sampled between frames %d and %d\n', bgnframes, block_input_first_frame_index, block_input_last_frame_index) ;
  end
  bg_image = ...
    compute_bg_med_simple(...
    readframe, ...
    input_video_frame_count,...
    'bgstartframe',block_input_first_frame_index,...
    'bgendframe',block_input_last_frame_index,...
    'bgnframes',bgnframes);
  if verbose >= 1,
    fprintf('Done computing background model for block %d.\n', block_index);
  end
  
  % Plot all the pixels that will get saved to the frame
  if verbose >= 3 ,
    f = findall(groot(), 'Type', 'figure', 'Tag', 'bg_image_figure') ;
    if isempty(f) ,
      f = figure('Tag', 'bg_image_figure', 'Color', 'white') ;
      set_figure_size_bang(f, [13 12]) ;
    end
    ax = findall(f, 'Type', 'axes', 'Tag', 'bg_image_axes') ;
    if isempty(ax) ,
      ax = axes('Parent', f, 'Tag', 'bg_image_axes', 'Title', 'bg_image', ...
                'YDir', 'reverse', 'DataAspectRatioMode', 'manual', 'CLim', [0 255], 'Colormap', gray(256)) ;
    end
    delete(ax.Children) ;
    image(ax, 'CData', bg_image, 'CDataMapping', 'direct') ;
    axis(ax, 'equal') ;
    axis(ax, 'tight') ;
    title(ax, 'bg_image', 'Interpreter', 'none') ;
    drawnow('nocallbacks') ;
  end


  % Write the keyframe to the file
  % ufmf_write_keyframe() expects images to be serialized Python-style, i.e. row-major
  % order.  So we transpose the image to make it happy.
  block_timestamp = timestamp_from_block_index(block_index) ;
  bg_image_transposed = bg_image' ;
  keyframe_loc = ufmf_write_keyframe(fid, block_timestamp, bg_image_transposed, 'mean') ;
  keyframe_loc_from_block_index(block_index) = keyframe_loc ;

  if verbose >= 1,
    fprintf('Encoding frames for block %d (frames %d-%d)...\n', block_index, block_input_first_frame_index, block_input_last_frame_index) ;
  end
  
  % Encode each frame in the block
  box_count_from_block_frame_index = zeros(block_frame_count,1) ;
  for block_frame_index = 1 : block_frame_count ,
    % read in the current frame
    input_frame_index = block_input_offset + block_frame_index ;
    frame = readframe(input_frame_index);

    % we'll need this for indexing into framesloc
    output_frame_index = block_output_offset + block_frame_index ;
    frame_timestamp = timestamp_from_output_frame_index(output_frame_index) ;
    if block_frame_index == 1 ,
      assert(frame_timestamp==block_timestamp) ;
    end

    %
    % write the current frame
    %

%     % convert to double grayscale, transpose
%     transposed_frame = frame' ;

    % subtract and threshold
    switch diffmode,
      case 'dark-on-light-background',
        diff_image = imsubtract(bg_image, frame) ;
      case 'light flies on a dark backgroud',
        diff_image = imsubtract(frame, bg_image) ;
      otherwise,
        diff_image = imabsdiff(frame, bg_image) ;
    end
    is_foreground = ( diff_image >= bgthresh ) ;

    % Plot all the pixels that are different enough to be considered foreground
    if verbose >= 3 ,
      f = findall(groot(), 'Type', 'figure', 'Tag', 'is_foreground_figure') ;
      if isempty(f) ,
        f = figure('Tag', 'is_foreground_figure', 'Color', 'white') ;
        set_figure_size_bang(f, [13 12]) ;
      end
      ax = findall(f, 'Type', 'axes', 'Tag', 'is_foreground_axes') ;
      if isempty(ax) ,
        ax = axes('Parent', f, 'Tag', 'is_foreground_axes', ...
                  'YDir', 'reverse', 'DataAspectRatioMode', 'manual', 'Colormap', [0 0 0 ; 1 1 1]) ;
      end
      delete(ax.Children) ;
      image(ax, 'CData', is_foreground, 'CDataMapping', 'direct') ;
      axis(ax, 'equal') ;
      axis(ax, 'tight') ;
      title(ax, sprintf('is_foreground (input_frame_index=%d)', input_frame_index), 'Interpreter', 'none') ;
    end

    % Compute a set of boxes that cover all the foreground pixels
    box_from_box_index = find_tidy_boxes_from_image(is_foreground) ;
      % limits_from_box_index is 3d.  Each page is a box, and each page looks like
      %   [ x_lo x_hi ;
      %     y_lo y_hi ]
      % x_lo and x_hi are the limits of the box in x, similar for y. The limits are
      % inclusive (both _lo and _hi are part of the box), and use Matlab-style
      % 1-based indexing.

    % Add the boxes to the foreground image
    if verbose >= 3 ,
      ax = findall(groot(), 'Type', 'axes', 'Tag', 'is_foreground_axes') ;
      box_count = size(box_from_box_index, 3) ;
      for box_index = 1 : box_count ,
        box = box_from_box_index(:,:,box_index) ;
        limits_for_drawing = box + [-0.5 +0.5 ; -0.5 +0.5] ;
        rectangle_x_from_vertex_index = ...
          [limits_for_drawing(1,1) limits_for_drawing(1,2) limits_for_drawing(1,2) limits_for_drawing(1,1) limits_for_drawing(1,1) ] ;
        rectangle_y_from_vertex_index = ...
          [limits_for_drawing(2,1) limits_for_drawing(2,1) limits_for_drawing(2,2) limits_for_drawing(2,2) limits_for_drawing(2,1) ] ;
        line(ax, 'XData', rectangle_x_from_vertex_index, 'YData', rectangle_y_from_vertex_index, 'Color', 'r') ;        
      end      
      drawnow('nocallbacks') ;
    end

    % Convert the boxes and pixel values to the format ufmf_write_frame()
    % requires.
    box_count = size(box_from_box_index, 3) ;
    x0 = zeros(box_count, 1) ;
    y0 = zeros(box_count, 1) ;
    w = zeros(box_count, 1) ;
    h = zeros(box_count, 1) ;
    val = cell(box_count, 1) ;
    for box_index = 1 : box_count ,
      box = box_from_box_index(:,:,box_index) ;
      x0(box_index) = box(1,1) - 1 ;  % -1 converts from 1-based indexing to 0-based
      y0(box_index) = box(2,1) - 1 ;
      w(box_index) = box(1,2) - box(1,1) + 1 ;  % +1 b/c limits are inclusive on both ends
      h(box_index) = box(2,2) - box(2,1) + 1 ;
      box_image = frame(box(2,1):box(2,2), box(1,1):box(1,2)) ;
      box_image_transposed = box_image' ;      
      val{box_index} = box_image_transposed(:) ;  % col vector
    end

    % Write out the frame
    loc_from_output_frame_index(output_frame_index) = ...
      ufmf_write_frame(fid, frame_timestamp, x0, y0, w, h, val) ;

%     % This is the old code from where each box was a single pixel    
%     % store different pixels
%     value_from_pixel_index = transposed_frame(idx) ;
%     x_from_pixel_index = x_image_transposed(idx)-1 ;  % integral x coord in transposed image for each pixel
%     y_from_pixel_index = y_image_transposed(idx)-1 ;  % integral y coord in transposed image for each pixel
%     loc_from_output_frame_index(output_frame_index) = ...
%       ufmf_write_frame_fixed_size(fid, timestamp, y_from_pixel_index, x_from_pixel_index, value_from_pixel_index) ;

    % Record the box count
    box_count_from_block_frame_index(block_frame_index) = box_count ;
  end

  if verbose >= 1,
    mean_box_count = mean(box_count_from_block_frame_index) ;
    fprintf('Done encoding frames for block %d.  Average box count per frame was %g\n', block_index, mean_box_count) ;
  end
end

% Write the index
indexloc = ufmf_write_index(fid, ...
                            keyframe_loc_from_block_index, ...
                            timestamp_from_block_index, ...
                            loc_from_output_frame_index, ...
                            timestamp_from_output_frame_index) ;

% Write the index location to the correct spot in header
fseek(fid, indexlocloc, 'bof') ;
fwrite(fid, indexloc, 'uint64') ; 

% fp will automatically be close on exit
end  % function
