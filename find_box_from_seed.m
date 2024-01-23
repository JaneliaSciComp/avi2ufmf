function box = find_box_from_seed(is_fg, ix_seed, iy_seed)
  [ny, nx] = size(is_fg) ;
  ix_offset = [0 0] ;
  iy_offset = [0 0] ;
  span = max(nx,ny) ;
  for k = 1 : span ,  % use a for loop to avoid any chance of an infinite loop
    ix_limits = ix_seed + ix_offset ;
    iy_limits = iy_seed + iy_offset ;
    subimage = is_fg(iy_limits(1):iy_limits(2), ix_limits(1):ix_limits(2)) ;
    x_projection = any(subimage,1) ;  % row vector
    y_projection = any(subimage,2) ;  % col vector
    % See if there are foreground pixels in any part of the 'rind' of the expanded
    % image.  If there are, expand the x/y lower/upper limit to include them.
    if x_projection(1) ,
      ix_limits(1) = ix_limits(1) - 1 ;
    end
    if x_projection(end) ,
      ix_limits(end) = ix_limits(end) + 1 ;
    end
    if y_projection(1) ,
      iy_limits(1) = iy_limits(1) - 1 ;
    end
    if y_projection(end) ,
      iy_limits(end) = iy_limits(end) + 1 ;
    end
    % Limit the limits to the bounds of the image
    ix_limits(1) = max(1, ix_limits(1)) ;
    ix_limits(2) = min(ix_limits(2), nx) ;
    iy_limits(1) = max(1, iy_limits(1)) ;
    iy_limits(2) = min(iy_limits(2), ny) ;
    % Convert the limits back to offsets
    ix_offset_last = ix_offset ;
    iy_offset_last = iy_offset ;
    ix_offset = ix_limits - ix_seed ;
    iy_offset = iy_limits - iy_seed ;
    if isequal(ix_offset, ix_offset_last) && isequal(iy_offset, iy_offset_last) ,
      break
    end
  end
  box = [ ix_limits ; ...
          iy_limits ] ;
end
