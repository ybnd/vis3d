function C = loadcube(path, do_load)
% Create a Cube instance pointing to 'path'
%   * The specific implementation is selected automatically based on the file extension of 'path'
%   * Call with do_load=false to NOT load the data in 'path'

    switch nargin
        case 1
            do_load = true;
    end

    % Cast path to char
    path = char(path);

    % Open as a regular Cube (json/binary format) by default
    CubeClass = @Cube;

    % Select Cube implementation based on file extension
    switch getExtension(path)
        case '.tif'
            CubeClass = @tifCube;
        case '.oct'
            CubeClass = @thorCube;
        case {'.ocmbin', '.ocm', '.bin'}
            CubeClass = @ocmCube;
    end

    % Initialize a new Cube instance pointing to 'path'
    C = CubeClass(path, do_load);
end