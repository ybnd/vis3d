classdef tifCube < Cube 
    properties(Hidden = true)
        files
    end
    
    methods(Access = public)
        function load_data(self)
            % Requires 'Multipage TIFF stack' to be in the MATLAB path
            % https://nl.mathworks.com/matlabcentral/fileexchange/35684-multipage-tiff-stack?focused=7519470&tab=function
            
            if ~self.is_loaded
                self.meta = imfinfo(self.path);
                self.cube = loadtiff(self.path);     
                
                [~,~,Nz] = size(self.cube);
                self.data.zpos = 0:Nz;
                
                self.is_loaded = true;
            end
        end  
        
        function save_data(self, path, options)
            switch nargin
                case 1
                    path = self.path;
                    options = struct();
                case 2
                    options = struct();
            end
            [do_save, path, options] = self.resolve_save(path, options);
            
            if do_save
                saveastiff(self.cube, path, options);
            end
        end
    end
end