classdef slicefig < cubefig
    properties   
        current_slice = 1;
        slice_axis = 'z'
    end
    
    properties (Access = private)
        pad = [30 0 0 0]
    end
    
    methods
        function obj = slicefig(C, fig, M, slice_axis)
            switch nargin
                case 1
                    fig = figure;
                    M = 100;
                    slice_axis = 'z';
                case 2
                    M = 100;
                    slice_axis = 'z';
                case 3
                    slice_axis = 'z';
            end
            
            obj.C = C;
            obj.M = M;
            obj.slice_axis = slice_axis;
            
            obj.f = fig;
            
            obj = obj.build;
        end
        
        function obj = build(obj)            
            build@cubefig(obj);
            
            % Image display
            if isempty(fields(obj.image))
                [I,~] = obj.C.slice(obj.current_slice, obj.slice_axis);
                obj.image = imshow_tight(I, obj.M, obj.pad);

%                 aXY = copyobj(obj.image.XY.Parent, obj.f); cla(aXY);
%                 set(obj.f, 'CurrentAxes', aXY); 
%                 aXY.DataAspectRatio = obj.image.XY.Parent.DataAspectRatio;

                switch obj.slice_axis
                    case 'x'
                        [N,~,~] = size(obj.C.cube);
                    case 'y'
                        [~,N,~] = size(obj.C.cube);
                    case 'z'
                        [~,~,N] = size(obj.C.cube);
                end
                
                ap = get(gca, 'Position');            

                % Slice 'scanning' controls
                obj.control.ui_text = uicontrol('style', 'text', ...
                'Position', [5,3,45,20], ...
                'String', sprintf('%s(%d)', obj.slice_axis, obj.current_slice));

                obj.control.ui_slider = uicontrol('style', 'slider', ...
                'Position', [55,5,ap(3)-58,20] ,...
                'Value', obj.current_slice, 'min', 1, 'max', N, ...
                'SliderStep', [1/N, 1/N] ...
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
            obj.control.ui_text.String = sprintf('%s(%d)', obj.slice_axis, obj.current_slice);
            
            [I,~] = obj.C.slice(obj.current_slice, obj.slice_axis);
            obj.image.set('CData', I);
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
        
        function rh = draw_rectangle(obj)
            axis(obj.image.Parent);
            rh = drawrectangle();
        end
        
        function ax = get_XY_axis(obj)
            ax = obj.image.Parent;
        end
        end
end