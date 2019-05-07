function [out_string, out, unit] = b2relevant(in, precision)
    switch nargin
        case 0
            error('No inout')
        case 1 
            precision = 1;
    end

    series = {'B', 'KB', 'MB', 'GB', 'TB', 'PB'};

    i = 1;
    while in > 1024
        in = in / 1024;
        i = i+1;
    end
    out = in;
    
    try
        unit = series{i};
    catch
        warning('Out of range')
    end
       
    out_string = [num2str(out,['%3.' num2str(precision) 'f']), ' ', unit];
end

