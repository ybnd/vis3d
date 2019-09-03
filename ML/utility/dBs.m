function [out] = dBs(in, floor, ceil)
% Shifted decibel transformation
%   input should NOT be normalized to [0,1] !
%
%   out = 10log10(in+1) clipped to [floor,ceil]

    switch nargin
        case 1
            ceil = 0;
            floor = 0;
        case 2
            ceil = 0;
    end
    
    if ~isfloat(in)
       in = double(in);
    end
   
    out = 10 * log10(in+1);
    
    if floor
        out(out < floor) = floor;
    end
    
    if ceil
        out(out > ceil) = ceil;
    end
    
    out = rescale(out);
end
