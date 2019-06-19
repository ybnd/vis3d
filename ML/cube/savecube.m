function [outputArg1,outputArg2] = savecube(C, path, options, process_method)
    % Save cube as binary or .tif stack
    
    switch nargin
        case 2
            options = struct();
            process_method = @pass_data;
        case 3
            process_method = @pass_data;
    end
    
    if ~isa(C, 'Cube')
        error('First argument must be an instance of Cube or a Cube subclass');
    end

    switch getExtension(path)
        case '.bin'
            CubeClass = @Cube;
        case '.tif'
            CubeClass = @tifCube;
    end
    
    tempCube = CubeClass('', false);
    tempCube.cube = process_method(C.cube);
    tempCube.save_data(path, options);
end

