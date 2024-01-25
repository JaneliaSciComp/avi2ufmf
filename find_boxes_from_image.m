function box_from_box_index = find_boxes_from_image(is_fg)
  % box_from_box_index is 3d, 2 x 2 x box_count
  % 1st dimension is x vs y: 1 = x, 2 = y
  % 2nd dimension is lower-limit/upper-limit: 1=lower, 2=upper
  % 3rd dimension is box index
  %
  % Note that the boxes returned by this function may contain boxes 
  % that overlap with, or are completely included in, other boxes.
  % However box_from_box_index(:,:,i) can only be a strict subset of 
  % box_from_box_index(:,:,j) if i<j.
  [ny, nx] = size(is_fg) ;
  [ix_image, iy_image] = meshgrid(1:nx, 1:ny) ;
  is_covered = false(size(is_fg)) ;
  box_count = 0 ;
  box_from_box_index = zeros(2,2,10000) ;  % pre-allocate enough for most use-cases
  i_seed_from_possible_seed_index = find(is_fg) ;
  hot_pixel_count = length(i_seed_from_possible_seed_index) ;
  for k = 1 : hot_pixel_count ,  
    i_seed = i_seed_from_possible_seed_index(k) ;
    if ~is_covered(i_seed) ,
      % Find a box containing this seed and neighboring hot pixels
      ix_seed = ix_image(i_seed) ;
      iy_seed = iy_image(i_seed) ;
      box = find_box_from_seed(is_fg, ix_seed, iy_seed) ;
      box_count = box_count + 1 ;
      box_index = box_count ;  % box index of the new box
      box_from_box_index(:,:,box_index) = box ;  % add the box to the list
      is_covered(box(2,1):box(2,2), box(1,1):box(1,2)) = true ;  % mark the pixels covered by the new box
    end
  end
  if any(is_fg & ~is_covered, 'all') ,
    error('Internal error: find_boxes_from_image left some pixels uncovered') ;
  end
  box_from_box_index = box_from_box_index(:,:,1:box_count) ;  % trim to proper size  
end