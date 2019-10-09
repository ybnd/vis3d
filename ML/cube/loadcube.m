function C = loadcube(varargin)
    % Cast path to char
    path = char(varargin{1});

    CubeClass = @Cube;

    switch getExtension(path)
        case ''
            if isfolder(path)
                % todo: check if there actually are .tiff files in that folder
                CubeClass = @tifCube;
            end
        case '.tif'
            CubeClass = @tifCube;
        case '.oct'
            CubeClass = @thorCube;
        case {'.ocmbin', '.ocm'}
            CubeClass = @ocmCube;
        case {'.bin'}
            if isempty(getSubExtension(path))
                CubeClass = @ocmCube;
            end
    end

    C = CubeClass(varargin{:});
    C.path = path;
end