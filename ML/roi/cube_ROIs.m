classdef cube_ROIs < handle      
    properties
        C = false;
        fig = false;
        sf = false;
        axis_image = false;
        axis_overlay = false;  
        M = 100;
        
        overlay = struct('axis', false);
        
        ROIs = {};
        MinPeakProminence = 0.1;
        
        slice_method = @normalize_slice;
        slice_args = struct('blendN', 7, 'window', @gausswin, 'windowpar', 2);
        
        filepath
        
        last_position
        
        z
    end
    
    methods        
        function obj = cube_ROIs(C)
            obj.C = C;
            obj.M = 100;
            
            if isa(obj.C, 'thorCube')
               C.im_select('postprocess', 'global_normalize');
            else
                C.im_select('slice', 'blur_slice');
            end
            
            obj.z = obj.C.position;
            obj.overlay.axis = false;
        end
        
%         function init_fig(obj)
%             obj.fig_cube = figure('CloseRequestFcn', @close_fig);   
%             
%             function close_fig(~, ~)
%                 delete(gcf)
%             end
%         end
        
        function enough = select_roi(obj, M)  
            switch nargin                
                case 1
                    M = obj.M;
            end
            
            if ~ishandle(obj.axis_image)
                obj.sf = obj.C.sf('XY', M, obj.fig);
                obj.axis_image = obj.sf.get_XY_axis;
            else
                obj.axis_image = obj.sf.get_XY_axis;
            end

            if ~ishandle(obj.overlay.axis)
                obj.overlay.axis = copyobj(obj.axis_image, obj.fig);
                set(obj.overlay.axis, 'Tag', 'Overlay')
                cla(obj.overlay.axis);
            end
            
            r = length(obj.ROIs);
            
            % Overlay previous ROIs... this may not be efficient
            obj.show_selections

            r = r+1;
            
            try 
                rh = obj.sf.draw_rectangle;
                obj.ROIs{r} = ROI(obj.C, rh, r, obj.sf.current_slice, obj.overlay.axis);
%                 obj.ROIs{r}.show
                clear rh
                enough = false;
            catch ME % todo: should be done in a more 'elegant' way...
%                 disp(ME)
                enough = true;
            end
        end
        
        function show_selections(obj)
            hold on
            for i = 1:length(obj.ROIs)
                obj.ROIs{i}.show(obj.overlay.axis)
            end   
        end
        
        function sobj = saveobj(obj)
            sobj = obj;  
            sobj.unload()
            
            sobj.overlay = struct('axis', false);
            sobj.fig = false;            
        end
        
        function unload(obj)
            try
                close(obj.fig)
                close(obj.sf)
            catch err
                
            end
            obj.sf = false;
            obj.C.unload()
        end
        
        function select(obj, M)  % todo: should add an argument to specify slice method
            switch nargin
                case 1
                    M = 100;
            end
            
            if isempty(obj.C.cube)
                obj.C.load();
            end
            
            enough = false;
            
            if ~ishandle(obj.fig)
                obj.fig = figure('Name', obj.C.name);
            end
            
            while ishandle(obj.fig) && ~enough
                enough = obj.select_roi(M);
            end
        end
        
        function explore(obj)
            obj.C.load();
            
            if ~ishandle(obj.fig)
                obj.fig = figure('Name', obj.C.name);        
            end
            
            if ~ishandle(obj.axis_image)
                obj.sf = obj.C.sf('XY', obj.M, obj.fig);
                obj.axis_image = obj.sf.get_XY_axis;
            else
                obj.axis_image = obj.sf.get_XY_axis;
            end

            if ~ishandle(obj.overlay.axis)
                obj.overlay.axis = copyobj(obj.axis_image, obj.fig);
                set(obj.overlay.axis, 'Tag', 'Overlay')
                cla(obj.overlay.axis);
            end

            % Overlay previous ROIs... this may not be efficient
            obj.show_selections
            
            axis(obj.axis_image)
        end
    end
end

