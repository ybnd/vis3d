function [path_out] = remove_extension(path_in)
    parts = strsplit(path_in, '.');

    try
        path_out = parts{1:end-1};
    catch
        path_out = path_in;
    end
end

