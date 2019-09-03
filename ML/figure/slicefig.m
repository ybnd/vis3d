classdef slicefig < cubefig
    properties   
        current_slice = 1;
    end
    
    properties (Access = private)
        pad = [30 0 0 0]
    end
    
    methods
        function self = slicefig(C, fig, slice_method, slice_args, M)
            switch nargin
                case 1
                    fig = figure;
                    slice_method = @normalize_slice;
                    slice_args = struct();
                    M = 100;
                case 2
                    slice_method = @normalize_slice;
                    slice_args = struct();
                    M = 100;
                case 3
                    slice_args = struct();
                    M = 100;
                case 4
                    M = 100;
            end
            
            self.C = C;
            self.M = M;
            
            self.figure = fig;
            set(self.figure, 'visible', 'off');
            set(self.figure, 'UserData', self);
            set(self.figure, 'MenuBar', 'none');
            set(self.figure, 'Resize', 'off');
            
            self.slice_method = slice_method;
            self.slice_args = slice_args;
            
            self = self.build;
        end
        
        function self = build(self)
            % Image display
            if isempty(fields(self.image))
                self.image.XY = imshow_tight(                                       ...
                    self.slice_method(self.C,self.current_slice,'z',self.slice_args),   ...
                    self.M, self.pad                                                ...
                );

%                 aXY = copyobj(self.image.XY.Parent, self.figure); cla(aXY);
%                 set(self.figure, 'CurrentAxes', aXY); 
%                 aXY.DataAspectRatio = self.image.XY.Parent.DataAspectRatio;

                [~,~,Nz] = size(self.C);
                ap = get(gca, 'Position');            

                % Slice 'scanning' controls
                self.control.ui_text = uicontrol('style', 'text', ...
                'Position', [5,3,45,20], ...
                'String', sprintf('z(%d)', self.current_slice));

                self.control.ui_slider = uicontrol('style', 'slider', ...
                'Position', [55,5,ap(3)-58,20] ,...
                'Value', self.current_slice, 'min', 1, 'max', Nz, ...
                'SliderStep', [1/Nz, 1/Nz] ...
                );
                addlistener(self.control.ui_slider, 'Value', 'PostSet', @self.slider_callback);

                set(self.figure, 'WindowScrollWheelFcn', @self.scroll_callback);
                
                set(self.figure, 'visible', 'on')
            end
        
            % Image postprocessing controls
            % todo: ...
            

        end
        
        function slider_callback(self, ~, eventdata)
            self.current_slice = floor(get(eventdata.AffectedObject, 'Value'));
            eventdata.AffectedObject.Parent.UserData = self.current_slice;
            self.control.ui_text.String = sprintf('z(%d)',self.current_slice);
            self.image.XY.set('CData', self.slice_method(self.C, self.current_slice, 'z', self.slice_args));
        end
        
        function scroll_callback(self, ~, eventdata)
            try
                new_value = get(self.control.ui_slider, 'Value') - 1 * eventdata.VerticalScrollCount;
                if new_value <= get(self.control.ui_slider, 'max') && new_value >= get(self.control.ui_slider, 'min')
                    set(self.control.ui_slider, 'Value', new_value);
                end
            catch
                return
            end
        end
        
        function rh = imrect(self)
            axis(self.image.XY.Parent);
            rh = imrect();
        end
        
        function ax = get_XY_axis(self)
            ax = self.image.XY.Parent;
        end
        end
end