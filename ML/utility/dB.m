function [out] = dB(in, floor, do_renormalize)   
    switch nargin
        case 1
            floor = 0;
            do_renormalize = false;
        case 2
            do_renormalize = false;
    end
    
    if ~isfloat(in)
       in = double(in);
    end

    if ~floor   % todo: twice if, dumb
        in_nonzero = in;
        in_nonzero(in == 0) = [];
        min_nonzero = min(in_nonzero);
        in(in == 0) = min_nonzero;
    end 
    
    out = 10 * log10(in);
    
    if floor
        out(out < floor) = floor;
    end
    
    if do_renormalize            % better to do a 'real' rescale 
       if length(size(out)) == 3
           out = normalize3(out);
       elseif length(size(out)) == 2
           out = normalize2(out);
       elseif length(size(out)) == 1
           out = normalize(out, 'range');
       end
    end
end

