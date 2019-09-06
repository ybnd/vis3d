classdef cubefig < handle
	properties
        C
        size = [0,0,0];
       
        f = false;
        slice_method = @slice;
        slice_args = struct();

        do_db = true;
        noise_floor = 0;
        signal_ceil = 90;
    end
    
    properties (Access = public)
        image = struct();
        control = struct();
        imagecontrol = struct()
        
        M = 0.3;
    end
    
    properties (Access = private)
        
    end
    
    methods (Abstract = true)
        
    end
    
    methods (Access = public)
        function open(self)
            if ishandle(self.f)
                figure(self.f.Number)
            else
                self.f = figure;
                self.build
            end            
        end
        
        function build(self)
            if ~ishandle(self.f)
               self.f = figure; 
            end
            
            set(self.f, 'visible', 'off');
            set(self.f, 'UserData', self);
            set(self.f, 'MenuBar', 'none');
            set(self.f, 'Resize', 'off');
        end
        
        function update(self)
            
        end
        
        function close(self)
            close(self.f);
            self.f = false;
        end
    end
end