function median_image = compute_bg_med_simple(readframe, nframes, varargin)

[bgstartframe,bgendframe,bgnframes,verbose] = ...
    myparse(varargin, ...
            'bgstartframe',1, ...
            'bgendframe',nframes,...
            'bgnframes',200, ...
            'verbose',1);  %#ok<ASGLU> 

% Frame indices to read in, evenly spaced over given range
video_frame_index_from_sample_index = round(linspace(bgstartframe,bgendframe,bgnframes));

% Read in the sample frames, into a big 3d array
for sample_index = 1:bgnframes,
  video_frame_index = video_frame_index_from_sample_index(sample_index);
  raw_frame = readframe(video_frame_index) ;
  im1 = forcegray(raw_frame);
  if sample_index==1 ,
    [nc,nr] = size(im1) ;
    imbuf = zeros(nc, nr, bgnframes, 'uint8') ;
  end
  imbuf(:,:,sample_index) = im1 ;
end
median_image = median(imbuf,3) ;  % uint8
