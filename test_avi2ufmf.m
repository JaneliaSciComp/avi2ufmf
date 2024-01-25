avi_file_name = 'movie-enhanced.avi' ;
ufmf_file_name = 'movie-enhanced-test.ufmf' ;
output_frame_count = inf ;
bgthresh = 8 ;
tic_id = tic() ;
avi2ufmf(avi_file_name, ...
         'ufmfname', ufmf_file_name, ...
         'startframe', 1, ...
         'endframe', output_frame_count, ...
         'verbose', 1, ...
         'diffmode', 'other', ...
         'blocknframes',200,...
         'bgnframes',50,...
         'bgthresh', bgthresh) ;
elapsed_time = toc(tic_id) ;
fprintf(2, 'Wall time to encode was %g seconds\n', elapsed_time) ;

% Read it, make sure each frame does not deviate from the original by more
% than bgthresh
vr = VideoReader(avi_file_name) ;
input_fps = vr.FrameRate ;
input_dt = 1/input_fps ;
input_frame_count = vr.NumFrames ;
input_timestamp_from_frame_index = input_dt*(0:(input_frame_count-1)) ;
header = ufmf_read_header(ufmf_file_name) ;
output_frame_count = header.nframes ; 
read_frame = ufmf_get_readframe_fcn(header) ;
for i = 1 : output_frame_count ,
  input_frame = vr.readFrame() ;
  [output_frame,frame_timestamp] = read_frame(i) ;
  diff = output_frame - input_frame ;
  abs_diff = abs(diff) ;
  max_abs_diff = max(abs_diff, [], 'all') ;
  if max_abs_diff > bgthresh ,
    error('Maximum absolve difference in frame %d (%d) is larger than the specified bgthresh (%d)', i, max_abs_diff, bgthresh) ;
  end
  % Check the timestamp
  input_timestamp = input_timestamp_from_frame_index(i) ;
  if abs(frame_timestamp-input_timestamp)>1e-12 ,
    error('The encoded video frame timestamp (%g) for frame %d differs meaningfully from the original frame timestamp (%g)', ...
          frame_timestamp, i, input_timestamp) ;
  end    
end
fprintf(2, 'Test passed.\n') ;
