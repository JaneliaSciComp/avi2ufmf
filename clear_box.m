function result = clear_box(im, box) 
  % zero-out the pixels within the box
  result = im ;
  result(box(2,1):box(2,2), box(1,1):box(1,2)) = 0 ; 
end
