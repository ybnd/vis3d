classdef tifCube < Cube 
    properties(Hidden = true)
        files
    end
    
    methods(Access = public)
        function load_data(obj)
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
        
        function save_data(obj, path, options)
            switch nargin
                case 1
                    path = '';
                    options = struct();
                case 2
                    options = struct();
            end
            
            if isempty(path)
               path = [remove_extension(obj.path) '.tif']; 
            end
            
            [do_save, path, options] = obj.resolve_save(path, options);
            
            if do_save
                saveastiff(obj.cube, path, options);
            end
        end
    end
end