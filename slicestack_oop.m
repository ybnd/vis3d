classdef slicestack_oop < stackfig
    properties   
        current_slice = 1;
    end
    
    properties (Access = private)
        pad = [30 0 0 0]
    end
    
    methods
        function self = slicestack_oop(C, fig)
            switch nargin
                case 1
                    fig = figure;
            end
            
            self.C = C;
            
            self.figure = fig;
            set(self.figure, 'visible', 'off');
            set(self.figure, 'UserData', self);
            set(self.figure, 'MenuBar', 'none');
            set(self.figure, 'Resize', 'off');
            
            self.build
        end
        
        function build(self)
            % Image display
            self.image.XY = imshow_tight(self.slice_method(self.C,self.current_slice,self.slice_args), self.M*100, self.pad);
            
            aXY = copyobj(self.image.XY.Parent, self.figure); cla(aXY);
            set(self.figure, 'CurrentAxes', aXY); 
            aXY.DataAspectRatio = self.image.XY.Parent.DataAspectRatio;
            
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
        
            % Image postprocessing controls
            % todo: ...
            
            set(self.figure, 'visible', 'on')
        end
        
        function slider_callback(self, ~, eventdata)
            self.current_slice = floor(get(eventdata.AffectedObject, 'Value'));
            eventdata.AffectedObject.Parent.UserData = self.current_slice;
            self.control.ui_text.String = sprintf('z(%d)',self.current_slice);
            self.image.XY.set('CData', self.slice_method(self.C,self.current_slice, self.slice_args));
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
    end
    
end