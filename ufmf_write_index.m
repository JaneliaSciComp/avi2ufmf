function indexloc = ufmf_write_index(fp, ...
                                     loc_from_keyframe_index, ...
                                     timestamp_from_keyframe_index, ...
                                     loc_from_frame_index, ...
                                     timestamp_from_frame_index)

  % Want to return the index location, so it can be written to the ufmf header
  indexloc = ftell(fp);

  % Construct the index struct we will serialize with ufmf_write_struct()
  index = build_index_struct(loc_from_keyframe_index, ...
                             timestamp_from_keyframe_index, ...
                             loc_from_frame_index, ...
                             timestamp_from_frame_index) ;

  % Write the serialized index struct to the file
  ufmf_write_struct(fp, index) ;

end  % function



function index = build_index_struct(loc_from_keyframe_index, ...
                                    timestamp_from_keyframe_index, ...
                                    loc_from_frame_index, ...
                                    timestamp_from_frame_index)  
  % Constuct the index as a struct.

  % These are the lowest-level arrays.  Make sure the data types are correct.
  index_keyframe_mean_loc = int64(loc_from_keyframe_index) ;
  index_keyframe_mean_timestamp = double(timestamp_from_keyframe_index) ;
  index_frame_loc = int64(loc_from_frame_index) ;
  index_frame_timestamp = double(timestamp_from_frame_index) ;

  % Package the frame/keyframe arrays into a frame/keyframe index
  index_keyframe_mean = struct('loc', {index_keyframe_mean_loc}, ...
                               'timestamp', {index_keyframe_mean_timestamp}) ;
  index_keyframe = struct('mean', {index_keyframe_mean}) ;  
  index_frame = struct('loc', {index_frame_loc}, ...
                       'timestamp', {index_frame_timestamp}) ;

 

  % Package the frame and keyframe indexes into the final index
  index = struct('frame', index_frame, ...
                 'keyframe', index_keyframe) ;
end