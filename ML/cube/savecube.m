function savecube(C, path)
    % Save Cube data as json/binary or .tif stack
    %   * The format is selected based on the file extension of 'path'
    %   * Use this function as an alternative to Cube.save or tifCube.save when saving 
    %      to a format different from the format handled by the implementation of 'C'
    %           -> i.e.: save a json/binary Cube to .tif or a tifCube to json/binary 
    
    if ~isa(C, 'Cube')
        error('First argument must be an instance of Cube or a Cube subclass');
    end 
    
    if nargin == 1
       path = C.path;
    end
    
    % Normalize 'path'
    if ~java.io.File(path).isAbsolute()
        path = fullfile(pwd, path);
    end
    
    % Cast path to char
    path = char(path);

    % Select Cube implementation based on file extension
    switch getExtension(path)
        case {'.bin', ''}
            CubeClass = @Cube;
        case '.tif'
            CubeClass = @tifCube;
        otherwise 
            error('Only .bin and .tif formats are supported')  
    end
    
    % Initialize new Cube instance, copy data from old Cube to new Cube and save.
    tempCube = CubeClass('', false);    

    tempCube.name = C.name;
    tempCube.desc = C.desc;
    tempCube.cube = C.cube;    
    tempCube.data = C.data;
    tempCube.meta = C.meta;
    
    tempCube.save(path);
end