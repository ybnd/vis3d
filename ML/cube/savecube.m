function savecube(C, path, process_method)
    % Save cube as binary or .tif stack
    
    switch nargin
        case 2
            process_method = @pass_data;
    end
    
    if ~isa(C, 'Cube')
        error('First argument must be an instance of Cube or a Cube subclass');
    end
    
    if ~java.io.File(path).isAbsolute()
        if ~isempty(C.path)
            [folder, ~, ~] = fileparts(C.path);
        else
            folder = pwd;
        end
        path = fullfile(folder, path);
    end
    
    % Cast path to char
    path = char(path);

    switch getExtension(path)
        case {'.bin', ''}
            CubeClass = @Cube;
        case '.tif'
            CubeClass = @tifCube;
        otherwise 
            error('Only .bin and .tif formats are supported')  
    end
    
    tempCube = CubeClass('', false);    

    tempCube.name = C.name;
    tempCube.desc = C.desc;
    tempCube.cube = process_method(C.cube);    
    tempCube.data = C.data;
    tempCube.meta = C.meta;
    
    tempCube.save_data(path);
end

