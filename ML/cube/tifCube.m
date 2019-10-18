classdef tifCube < Cube 
% Reader for .tif 3d images
% Files with metadata saved as .tif will lose their metadata!

    properties(Hidden = true)
        files
        options
    end
    
    %% File I/O methods
    methods(Access = public)
        function load(obj)
            % Load data from .tif stack file
            
            % Requires 'Multipage TIFF stack' to be in the MATLAB path
            % https://nl.mathworks.com/matlabcentral/fileexchange/35684-multipage-tiff-stack?focused=7519470&tab=function
            
            if ~obj.is_loaded
                obj.meta = imfinfo(obj.path);
                obj.cube = loadtiff(obj.path);     
                
                [~,~,Nz] = size(obj.cube);
                obj.data.zpos = 0:Nz;
                
                obj.is_loaded = true;
            end
        end  
        
        function set_options(obj, options)
            switch nargin
                case 1
                    options = struct('overwrite', true);
            end
            
            obj.options = options;
        end
        
        function save(obj, path)
            switch nargin
                case 1
                    path = '';
            end
            
            if isempty(path)
               path = [remove_extension(obj.path) '.tif']; 
            end
            
            [do_save, path] = obj.resolve_save(path);
            
            if do_save
                if exist(path, 'file')  % Already confirmed overwrite, delete to avoid saveastiff() error.
                    delete(path)
                end
                saveastiff(obj.cube, path, obj.options); 
            end
        end
    end
end