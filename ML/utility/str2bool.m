function [b] = str2bool(s)
    switch lower(s)
        case {'t', 'true', 'y', 'yes', '1', 'o'}
            b = true;
        case {'f', 'false', 'n', 'no', '0', 'x'}
            b = false;
        otherwise
            error("'%s' is not a recognized boolean string", s)
    end
end

