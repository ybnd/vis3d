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
%                 obj.control.ui_text = uicontrol('style', 'text', ...
%                 'Position', [5,3,45,20], ...
%                 'String', sprintf('%s(%d)', obj.slice_axis, obj.current_slice));


                
                gui = obj.im_gui;
                
                obj.slice.build_gui(obj.f, [obj.border, obj.border], @obj.ui_update_image, {'position', 'axis'});
                obj.postprocess.build_gui(obj.f, ...
                    [obj.border + gui.gap*3 + gui.selector_width + gui.controls_max_width, obj.border], ...
                    @obj.ui_update_image, {'global range'} ...
                );
            
                obj.control.ui_slider = uicontrol( ...
                    'Parent', obj.f, 'style', 'slider', ...
                    'Position', [obj.border + 2*(gui.gap*3 + gui.selector_width + gui.controls_max_width), ...
                        obj.border, ap(3)-9-2*(gui.gap*3 + gui.selector_width + gui.controls_max_width),19], ...
                    'Value', obj.current_slice, 'min', 1, 'max', N, ...
                    'SliderStep', [1/N, 1/N], ...
                    'TooltipString', sprintf('%s(%d)', obj.slice_axis, obj.current_slice) ...
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
%             obj.control.ui_text.String = sprintf('%s(%d)', obj.slice_axis, obj.current_slice);
            set(obj.control.ui_slider, 'TooltipString', sprintf('%s(%d)', obj.slice_axis, obj.current_slice))
            
            obj.ui_update_image();
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
        
        function ui_update_image(obj)
            [I,~] = obj.C.slice(obj.current_slice, obj.slice_axis);
            obj.image.set('CData', I);
        end
        
        function rh = draw_rectangle(obj)
            % what if: This doesn't need to be a rectangle!
            %   https://nl.mathworks.com/help/images/ref/drawrectangle.html
            %   https://nl.mathworks.com/help/images/ref/imroi-class.html
            axis(obj.image.Parent);
            rh = drawrectangle();
        end
        
        function ax = get_XY_axis(obj)
            ax = obj.image.Parent;
        end
        end
end