classdef stackfig < handle
	properties
        C
       
        figure;
        contrast_method = @pass_data;
        slice_method = @normalize_slice;
        contrast_args = struct();
        slice_args = struct();

        do_db = true;
        noise_floor = -30;
    end
    
    properties (Access = protected)
        image = struct();
        control = struct();
        imagecontrol = struct()
        
        M = 0.9;
    end
    
    methods (Abstract = true)
        build(self);
    end
end