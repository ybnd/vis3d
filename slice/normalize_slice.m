function I = normalize_slice(C,slice,~)
    I = rescale(double(C(:,:,slice)));
end