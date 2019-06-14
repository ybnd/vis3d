function [ext] = getExtension(fname)
    parts = strsplit(fname, '.');
    
    if length(parts) <= 1
        ext = '';
    else
        ext = strcat('.', parts{end});
    end
end