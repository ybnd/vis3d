function [I] = binFFOCM(path, shape, dtype) 
    if nargin == 1 % Shape not given
        % Deduce shape from filename
        [~,fname,~] = fileparts(path);
        nums = regexp(fname, '\d*', 'Match');
        
        file_shape = zeros(1, length(nums));
        for i = 1:length(nums)
            file_shape(i) = str2num(nums{i});
        end
        
        rep = '*uint32';
    elseif nargin == 2
        rep = '*uint32';
    else
        file_shape = shape;    
        rep = dtype;
    end
    
    file_length = prod(file_shape);
    
    fid = fopen(path, 'r');
    A = fread(fid, file_length, rep);
    I = reshape(A, file_shape);
    I = permute(I, [2,1,3]);
end

