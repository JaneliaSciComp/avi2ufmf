function frameloc = ufmf_write_frame_fixed_size(fp,stamp,x0,y0,val)

  % Write a ufmf frame, assuming IsFixedSize is true in the header, and that
  % we're writing a uint8 grayscale video.
  % 
  % val: Serialized pixel values for all pixels stored in this frame. The values are
  % indexed by box number, followed by x index,
  % followed by y index.

  frameloc = ftell(fp);
  % write the chunk id (points=1)
  fwrite(fp,1,'uchar');
  % write timestamp
  fwrite(fp,stamp,'double');
  % write number of points
  npts = numel(x0);
  fwrite(fp,npts,'uint32');

  % write x, y, width, height
  fwrite(fp,x0,'ushort');
  fwrite(fp,y0,'ushort');

  % write region intensities
  fwrite(fp,val,'uint8');
end
