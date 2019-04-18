function I = lift_slice(C,s,~)
    I = double(C(:,:,s));
    I = I - min(min(I));
end