function I = normalize_slice(C,slice,~)
    I = normalize(C(:,:,slice), 'range');
end