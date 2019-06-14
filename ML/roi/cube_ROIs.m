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
        
        slice_method = @blend_slice;
        slice_args = struct('blendN', 7, 'window', @gausswin, 'windowpar', 2);
        
        filepath
        
        last_position
        
        z
    end
    
    methods        
        function self = cube_ROIs(I)
            self.I = I;
            self.M = 100;
            
            if isa(self.I, 'thorCube')
               self.slice_method = @normalize_slice;  % Don't blend Thorlabs OCT slices
            end
            
            self.z = self.I.position;
            self.overlay.axis = false;
        end
        
%         function init_fig(self)
%             self.fig_cube = figure('CloseRequestFcn', @close_fig);   
%             
%             function close_fig(~, ~)
%                 delete(gcf)
%             end
%         end
        
        function enough = select_roi(self, M)   
            if ~ishandle(self.axis_image)
                self.sf = slicefig(self.I.cube, self.fig, self.slice_method, self.slice_args, M); 
                    % todo: should be in it's own preparation method
                self.axis_image = self.sf.get_XY_axis;
            else
                self.axis_image = self.sf.get_XY_axis;
            end

            if ~ishandle(self.overlay.axis)
                self.overlay.axis = copyobj(self.axis_image, self.fig);
                set(self.overlay.axis, 'Tag', 'Overlay')
                cla(self.overlay.axis);
            end
            
            r = length(self.ROIs);
            
            % Overlay previous ROIs... this may not be efficient
            self.show_selections

            r = r+1;
            
            try 
                rh = self.sf.imrect;
                self.ROIs{r} = ROI(self.I, rh, r, self.sf.current_slice, self.overlay.axis, self.slice_method, self.slice_args);
%                 self.ROIs{r}.show
                clear rh
                enough = false;
            catch ME % todo: should be done in a more 'elegant' way...
%                 disp(ME)
                enough = true;
            end
        end
        
        function show_selections(self)
            hold on
            for i = 1:length(self.ROIs)
                self.ROIs{i}.show(self.overlay.axis)
            end   
        end
        
        function sobj = saveobj(self)
            sobj = self;  
            sobj.unload()
            
            sobj.overlay = struct('axis', false);
            sobj.fig = false;            
        end
        
        function unload(self)
            try
                close(self.fig)
                close(self.sf)
            end
            self.sf = false;
            self.I.unload_data()
        end
        
        function select(self, M)  % todo: should add an argument to specify slice method
            switch nargin
                case 1
                    M = 100;
            end
            
            self.I.load_data
            enough = false;
            
            if ~ishandle(self.fig)
                self.fig = figure('Name', self.I.name);
            end
            
            while ishandle(self.fig) && ~enough
                enough = self.select_roi(M);
            end
        end
        
%         function explore(self)
%             self.I.load_data
%             
%             if ~ishandle(self.fig)
%                 self.fig = figure('Name', self.I.MD.Main.File.Name);        
%             end
%             
%             if ~ishandle(self.axis_image)
%                 self.fig = slicestack(self.fig, self.I.cube, self.slice_method, self.slice_args); 
%                     % todo: should be in it's own preparation method
%                 self.axis_image = self.sf.get_XY_axis;
%             else
%                 axes(self.axis_image)
% %                 self.fig = slicestack(self.fig, self.I.cube, self.slice_method, self.slice_args);
%             end
% 
%             if ~ishandle(self.overlay.axis)
%                 self.overlay.axis = copyobj(gca, self.fig);
%                 cla(self.overlay.axis);
%             end
%             
%             r = length(self.ROIs);
%             
%             % Overlay previous ROIs... this may not be efficient
%             self.show_selections
%             
%             axis(self.axis_image)
%         end
    end
end

