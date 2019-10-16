classdef cubefig < handle
	properties
        C
        size = [0,0,0];
       
        f = false;
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
        function open(obj)
            if ishandle(obj.f)
                figure(obj.f.Number)
            else
                obj.f = figure;
                obj.build
            end            
        end
        
        function build(obj)
            if ~ishandle(obj.f)
               obj.f = figure; 
            end
            
            set(obj.f, 'visible', 'off');
            set(obj.f, 'UserData', obj);
            set(obj.f, 'MenuBar', 'none');
            set(obj.f, 'Resize', 'off');
        end
        
        function update(obj)
            
        end
        
        function close(obj)
            close(obj.f);
            obj.f = false;
        end
    end
end