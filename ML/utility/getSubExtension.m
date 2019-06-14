function [ext] = getSubExtension(fname)
    parts = strsplit(fname, '.');
    
    if length(parts) <= 2
        ext = '';
    else
        ext = strcat('.', parts{end-1});
    end
end

