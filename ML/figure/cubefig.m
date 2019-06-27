classdef cubefig < handle
	properties
        C
       
        figure = false;
        contrast_method = @pass_data;
        slice_method = @normalize_slice;
        contrast_args = struct();
        slice_args = struct();

        do_db = true;
        noise_floor = -30;
    end
    
    properties (Access = public)
        image = struct();
        control = struct();
        imagecontrol = struct()
        
        M = 100;
    end
    
    methods (Abstract = true)
        build(self);
    end
    
    methods
        function close(self)
            close(self.figure);
            self.figure = false;
        end
    end
end