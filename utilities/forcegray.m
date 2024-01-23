function result = forcegray(im)
    if ismatrix(im) ,
        result = im ;
    else
        result = rgb2gray(im) ;
    end
end    
