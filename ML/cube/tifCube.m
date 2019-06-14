classdef tifCube < Cube 
    properties(Hidden = true)
        files
    end
    
    methods
        function load_data(self)
            if ~self.is_loaded
                
                self.is_loaded = true;
            end
        end        
        
        function load_folder(self)
            self = self;
        end
        
        function load_stack(self)
            self = self;
        end
    end
end