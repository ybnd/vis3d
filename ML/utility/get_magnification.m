function [M] = get_magnification(shape, max_ratio)
    switch nargin
        case 1
            max_ratio = 2/3;
    end
    
    try
        % Make sure the shape is 'legal'
        assert(all(size(shape) == [1,2]));
    catch err
       shape = shape(1:2); 
    end
    
    M = min( monitor_resolution ./ shape * max_ratio );
end