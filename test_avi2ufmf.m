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
header = ufmf_read_header(ufmf_file_name) ;
output_frame_count = header.nframes ; 
read_frame = ufmf_get_readframe_fcn(header) ;
for i = 1 : output_frame_count ,
  input_frame = vr.readFrame() ;
  output_frame = read_frame(i) ;
  diff = output_frame - input_frame ;
  abs_diff = abs(diff) ;
  max_abs_diff = max(abs_diff, [], 'all') ;
  if max_abs_diff > bgthresh ,
    error('Maximum absolve difference in frame %d (%d) is larger than the specified bgthresh (%d)', i, max_abs_diff, bgthresh) ;
  end
end
fprintf(2, 'Test passed.\n') ;

