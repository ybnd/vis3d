function C = loadcube(varargin)
    path = varargin{1};

    CubeClass = @Cube;

    switch getExtension(path)
        case ''
            if isfolder(path)
                % Maybe: check if .tiff / .tif files in that folder
                CubeClass = @tifCube;
            end
        case '.oct'
            CubeClass = @thorCube;
        case {'.ocmbin', '.ocm'}
            CubeClass = @ocmCube;
        case '.bin'
            if isempty(getSubExtension(path))
                CubeClass = @ocmCube;
            end
    end

    C = CubeClass(varargin{:});
end