function limits_from_box_index = find_boxes_from_image(is_fg)
  % limits_from_box_index is 3d, 2 x 2 x box_count
  % 1st dimension is x vs y: 1 = x, 2 = y
  % 2nd dimension is lower-limit/upper-limit: 1=lower, 2=upper
  % 3rd dimension is box index
  [ny, nx] = size(is_fg) ;
  [ix_image, iy_image] = meshgrid(1:nx, 1:ny) ;
  is_fg_and_uncovered = is_fg ;
  box_count = 0 ;
  limits_from_box_index = zeros(2,2,1000) ;  % pre-allocate enough for more use-cases
  i_seed_from_possible_seed_index = find(is_fg_and_uncovered) ;
  hot_pixel_count = length(i_seed_from_possible_seed_index) ;
  for k = 1 : hot_pixel_count ,  
    i_seed = i_seed_from_possible_seed_index(k) ;
    if is_fg_and_uncovered(i_seed) ,
      ix_seed = ix_image(i_seed) ;
      iy_seed = iy_image(i_seed) ;
      box = find_box_from_seed(is_fg, ix_seed, iy_seed) ;
      box_count = box_count + 1 ;
      limits_from_box_index(:,:,box_count) = box ;
      is_fg_and_uncovered(box(2,1):box(2,2), box(1,1):box(1,2)) = false ;  % clear the pixels covered by the box
    end
  end
  if any(is_fg_and_uncovered, 'all') ,
    error('Internal error: Find_boxes_from_image left some pixels uncovered') ;
  end
  limits_from_box_index = limits_from_box_index(:,:,1:box_count) ;  % trim to proper size  
end
