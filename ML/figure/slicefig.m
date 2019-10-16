classdef slicefig < cubefig
    properties   
        current_slice = 1;
    end
    
    properties (Access = private)
        pad = [30 0 0 0]
    end
    
    methods
        function obj = slicefig(C, fig, slice_method, slice_args, M)
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
            
            obj.C = C;
            obj.M = M;
            
            obj.f = fig;
            
            obj.slice_method = slice_method;
            obj.slice_args = slice_args;
            
            obj = obj.build;
        end
        
        function obj = build(obj)            
            build@cubefig(obj);
            
            % Image display
            if isempty(fields(obj.image))
                obj.image.XY = imshow_tight(                                       ...
                    obj.slice_method(obj.C,obj.current_slice,'z',obj.slice_args),   ...
                    obj.M, obj.pad                                                ...
                );

%                 aXY = copyobj(obj.image.XY.Parent, obj.f); cla(aXY);
%                 set(obj.f, 'CurrentAxes', aXY); 
%                 aXY.DataAspectRatio = obj.image.XY.Parent.DataAspectRatio;

                [~,~,Nz] = size(obj.C);
                ap = get(gca, 'Position');            

                % Slice 'scanning' controls
                obj.control.ui_text = uicontrol('style', 'text', ...
                'Position', [5,3,45,20], ...
                'String', sprintf('z(%d)', obj.current_slice));

                obj.control.ui_slider = uicontrol('style', 'slider', ...
                'Position', [55,5,ap(3)-58,20] ,...
                'Value', obj.current_slice, 'min', 1, 'max', Nz, ...
                'SliderStep', [1/Nz, 1/Nz] ...
                );
                addlistener(obj.control.ui_slider, 'Value', 'PostSet', @obj.slider_callback);

                set(obj.f, 'WindowScrollWheelFcn', @obj.scroll_callback);
                
                set(obj.f, 'visible', 'on')
            end
        
            % Image postprocessing controls
            % todo: ...
            

        end
        
        function slider_callback(obj, ~, eventdata)
            obj.current_slice = floor(get(eventdata.AffectedObject, 'Value'));
            eventdata.AffectedObject.Parent.UserData = obj.current_slice;
            obj.control.ui_text.String = sprintf('z(%d)',obj.current_slice);
            obj.image.XY.set('CData', obj.slice_method(obj.C, obj.current_slice, 'z', obj.slice_args));
        end
        
        function scroll_callback(obj, ~, eventdata)
            try
                new_value = get(obj.control.ui_slider, 'Value') - 1 * eventdata.VerticalScrollCount;
                if new_value <= get(obj.control.ui_slider, 'max') && new_value >= get(obj.control.ui_slider, 'min')
                    set(obj.control.ui_slider, 'Value', new_value);
                end
            catch
                return
            end
        end
        
        function rh = imrect(obj)
            axis(obj.image.XY.Parent);
            rh = imrect();
        end
        
        function ax = get_XY_axis(obj)
            ax = obj.image.XY.Parent;
        end
        end
end