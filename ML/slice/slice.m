function I = slice(C,s,axis,~)
assert(isa('axis','char'));

    switch lower(axis)
        case 'x'
            I = permute(C(s,:,:), [3,2,1]);
        case 'y'
            I = permute(C(:,s,:), [1,3,2]);
        otherwise
            I = C(:,:,s);
    end
end