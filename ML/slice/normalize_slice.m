function I = normalize_slice(C,s,~)
    I = rescale(double(C(:,:,s)));
end