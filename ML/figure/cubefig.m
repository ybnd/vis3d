classdef cubefig < handle
	properties
        C

       
        f = false;
    end
    
    properties (Access = protected)
        ofsize = [0,0,0];
        image = struct();
        control = struct();
        imagecontrol = struct()
        
        im_gui = interactive_methods_gui();
        slice
        postprocess
        
        M = 0.3;
        
        border = 5;     % border distance (v,h)
        
        min_width = 320;
        min_height = 240;
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
            [obj.slice, obj.postprocess] = obj.C.copy_selectors();
            
            if ~ishandle(obj.f)
               obj.f = figure; 
            end
            
            set(obj.f, 'visible', 'off');
            set(obj.f, 'UserData', obj);
            set(obj.f, 'MenuBar', 'none');
            set(obj.f, 'Resize', 'off');
        end
        
        function ensure_min_size(obj)
            p = get(obj.f, 'Position');
            set(obj.f, 'Position', [p(1) p(2) max(p(3), obj.min_width), max(p(4), obj.min_height)]);
                % ! will mess up unreasonably small images though. Shouldn't come up too often, I hope.
        end
        
        function close(obj)
            close(obj.f);
            obj.f = false;
        end
    end
end