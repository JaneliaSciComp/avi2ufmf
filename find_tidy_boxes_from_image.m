function box_from_box_index = find_tidy_boxes_from_image(is_fg)
  % box_from_box_index is 3d, 2 x 2 x box_count
  % 1st dimension is x vs y: 1 = x, 2 = y
  % 2nd dimension is lower-limit/upper-limit: 1=lower, 2=upper
  % 3rd dimension is box index

  % Find the boxes, which may include some that are completely contained within
  % others
  box_from_raw_box_index = find_boxes_from_image(is_fg) ;

  % Run a pass to see if 'later' boxes completely contain 'earlier' boxes  
  % 'Later' here means 'having a higher index'.
  raw_box_count = size(box_from_raw_box_index,3) ;
  is_doomed_from_raw_box_index = false(raw_box_count,1) ;
  for late_raw_box_index = 1 : raw_box_count ,
    late_box = box_from_raw_box_index(:,:,late_raw_box_index) ;
    for early_raw_box_index = 1 : late_raw_box_index-1 ,    
      if ~is_doomed_from_raw_box_index(early_raw_box_index) ,  % don't recheck already-doomed boxes
        early_box = box_from_raw_box_index(:,:,early_raw_box_index) ;
        is_doomed_from_raw_box_index(early_raw_box_index) = is_box_b_within_box_a(late_box, early_box) ;
      end
    end
  end
  box_from_box_index = box_from_raw_box_index(:,:,~is_doomed_from_raw_box_index) ;
end
