function [] = showGabor(img)
% scale all values to range 0..1
    a = min(img(:));
    g = img - a;
    b = max(g(:));
    g = g./b;
% show
    figure(2);
    imshow(g);
end