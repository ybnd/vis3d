classdef cube_ROIs < handle      
    properties
        I = false;
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
        function obj = cube_ROIs(I)
            obj.I = I;
            obj.M = 100;
            
            if isa(obj.I, 'thorCube')
               obj.slice_method = @slice;  % Don't blend Thorlabs OCT slices
            end
            
            obj.z = obj.I.position;
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
            if ~ishandle(obj.axis_image)
%                 obj.sf = slicefig(obj.I.cube, obj.fig, obj.slice_method, obj.slice_args, M); 
                    % todo: should be in it's own preparation method
                obj.sf = obj.I.slice('XY', M, obj.slice_method, obj.slice_args, obj.fig);
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
                rh = obj.sf.imrect;
                obj.ROIs{r} = ROI(obj.I, rh, r, obj.sf.current_slice, obj.overlay.axis, obj.slice_method, obj.slice_args);
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
            obj.I.unload_data()
        end
        
        function select(obj, M)  % todo: should add an argument to specify slice method
            switch nargin
                case 1
                    M = 100;
            end
            
            if isempty(obj.I.cube)
                obj.I.load_data
            end
            
            enough = false;
            
            if ~ishandle(obj.fig)
                obj.fig = figure('Name', obj.I.name);
            end
            
            while ishandle(obj.fig) && ~enough
                enough = obj.select_roi(M);
            end
        end
        
%         function explore(obj)
%             obj.I.load_data
%             
%             if ~ishandle(obj.fig)
%                 obj.fig = figure('Name', obj.I.MD.Main.File.Name);        
%             end
%             
%             if ~ishandle(obj.axis_image)
%                 obj.fig = slicestack(obj.fig, obj.I.cube, obj.slice_method, obj.slice_args); 
%                     % todo: should be in it's own preparation method
%                 obj.axis_image = obj.sf.get_XY_axis;
%             else
%                 axes(obj.axis_image)
% %                 obj.fig = slicestack(obj.fig, obj.I.cube, obj.slice_method, obj.slice_args);
%             end
% 
%             if ~ishandle(obj.overlay.axis)
%                 obj.overlay.axis = copyobj(gca, obj.fig);
%                 cla(obj.overlay.axis);
%             end
%             
%             r = length(obj.ROIs);
%             
%             % Overlay previous ROIs... this may not be efficient
%             obj.show_selections
%             
%             axis(obj.axis_image)
%         end
    end
end

