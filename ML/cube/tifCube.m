classdef tifCube < Cube 
% Reader for .tif 3d images
% Files with metadata saved as .tif will lose their metadata!

    properties(Hidden = true)
        files
        options
    end
    
    %% .tif stack I/O methods
    methods(Access = protected)
        function load_data(obj)
            % Load data from .tif stack file
            
            % Requires 'Multipage TIFF stack' to be in the MATLAB path
            % https://nl.mathworks.com/matlabcentral/fileexchange/35684-multipage-tiff-stack?focused=7519470&tab=function
            
            obj.meta = imfinfo(obj.path);
            obj.cube = loadtiff(obj.path);     

            [~,~,Nz] = size(obj.cube);
            obj.data.zpos = 0:Nz;
        end  
        
        function save_data(obj, path)
            if exist(path, 'file')  % Already confirmed overwrite, delete to avoid saveastiff() error.
                delete(path)
            end
            saveastiff(obj.cube, path, obj.options); 
        end
    end
    
    methods(Access = public)
        function set_options(obj, options)
            switch nargin
                case 1
                    options = struct('overwrite', true);
            end
            
            obj.options = options;
        end
    end
end