function box = find_box_from_seed(is_fg, ix_seed, iy_seed)
  [ny, nx] = size(is_fg) ;
  ix_limits = [ix_seed ix_seed] ;
  iy_limits = [iy_seed iy_seed] ;
  span = max(nx,ny) ;
  for k = 1 : span ,  % use a for loop to avoid any chance of an infinite loop
    % Get the subimage determined by the current limits
    subimage = get_subimage(is_fg, ix_limits(1), ix_limits(2), iy_limits(1), iy_limits(2)) ;
      % get_subimage() pads with false's for out-of-bounds limits

%     f = findall(groot(), 'Type', 'figure', 'Tag', 'subimage_figure') ;
%     if isempty(f) ,
%       f = figure('Tag', 'subimage_figure', 'Color', 'white') ;
%     end
%     ax = findall(f, 'Type', 'axes', 'Tag', 'subimage_axes') ;
%     if isempty(ax) ,
%       ax = axes('Parent', f, 'Tag', 'subimage_axes_axes') ;
%     end
%     delete(ax.Children) ;
%     imshow(subimage', 'Parent', ax) ;  % Want to show normal, not transposed
%     drawnow('nocallbacks') ;

    % Save the old limits
    ix_limits_last = ix_limits ;
    iy_limits_last = iy_limits ;

    % See if there are foreground pixels in any part of the 'rind' of the expanded
    % image.  If there are, expand the x/y lower/upper limit to include them.
    x_projection = any(subimage,1) ;  % row vector
    y_projection = any(subimage,2) ;  % col vector
    if x_projection(1) ,
      ix_limits(1) = ix_limits(1) - 1 ;
    end
    if x_projection(end) ,
      ix_limits(2) = ix_limits(2) + 1 ;
    end
    if y_projection(1) ,
      iy_limits(1) = iy_limits(1) - 1 ;
    end
    if y_projection(end) ,
      iy_limits(2) = iy_limits(2) + 1 ;      
    end

    % Exit if limits did not change
    if isequal(ix_limits, ix_limits_last) && isequal(iy_limits, iy_limits_last) ,
      break
    end
  end
  % At this point the limits will have a 1-pixel-wide rind of falsehood around
  % them. 
  box = [ ix_limits(1)+1 ix_limits(2)-1 ; ...
          iy_limits(1)+1 iy_limits(2)-1 ] ;
end


function result = get_subimage(im, xl, xh, yl, yh)
  % Extract a subimage, putting in falses for any out-of-bounds limits
  [ny, nx] = size(im) ;
  xl_bounded = max(1, xl) ;
  xh_bounded = min(xh, nx) ;
  yl_bounded = max(1, yl) ;
  yh_bounded = min(yh, ny) ;
  if (xl==xl_bounded) && (xh==xh_bounded) && (yl==yl_bounded) && (yh==yh_bounded) ,
    % This should be the common case---no limits hard against the image boundaries
    result = im(yl:yh, xl:xh) ;
  else
    xl_pad_depth = xl_bounded-xl ;
    %xh_pad_depth = xh-xh_bounded ;
    yl_pad_depth = yl_bounded-yl ;
    %yh_pad_depth = yh-yh_bounded ;
    core_result = im(yl_bounded:yh_bounded, xl_bounded:xh_bounded) ;
    [core_height, core_width] = size(core_result) ;
    result_width = xh-xl+1 ;
    result_height = yh-yl+1 ;
    result = false(result_height, result_width) ;
    result(yl_pad_depth+1:yl_pad_depth+core_height, xl_pad_depth+1:xl_pad_depth+core_width) = core_result ;
  end
end