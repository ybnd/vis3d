function fig = slicestack(fig, C, slice_method, slice_args) 
    switch nargin
        case 2
            slice_method = @normalize_slice;
            slice_args = struct();
        case 3
            slice_args = struct();
    end

    if ~isempty(fig.UserData)
        slice = fig.UserData;
    else
        slice = 1;
        fig.UserData = 1;
    end
    
    if ishandle(fig)
        figure(fig);
        set(fig, 'visible', 'on')
    else
        fig = figure;
        set(fig, 'visible', 'on')        
    end

    if isempty(get(gca, 'Children'))
        % Image display
        image = imshow_tight(slice_method(C,slice,slice_args), 150, [30,0,0,0]);
            [~, ~, Nz] = size(C);
            
        % Slice 'scanning' controls
        ui_text = uicontrol('style', 'text', ...
            'Position', [5,3,45,20], ...
            'String', sprintf('z(%d)',slice));
        ap = get(gca, 'Position');
        ui_slider = uicontrol('style', 'slider', ...
            'Position', [55,5,ap(3)-58,20] ,...
            'Value', slice, 'min', 1, 'max', Nz, ...
            'SliderStep', [1/Nz, 1/Nz] ...
            );
        addlistener(ui_slider, 'Value', 'PostSet', @slider_callback);
        
        set(fig, 'WindowScrollWheelFcn', @scroll);
        
        % Image postprocessing controls
        
        
    end

    function slider_callback(~, eventdata)
        new_slice = floor(get(eventdata.AffectedObject, 'Value'));
        eventdata.AffectedObject.Parent.UserData = new_slice;
        ui_text.String = sprintf('z(%d)',new_slice);
        image.set('CData', slice_method(C,new_slice,slice_args));
    end

    function scroll(~, eventdata)
        try
            new_value = get(ui_slider, 'Value') - 1 * eventdata.VerticalScrollCount;
            if new_value <= get(ui_slider, 'max') && new_value >= get(ui_slider, 'min')
                set(ui_slider, 'Value', new_value);
            end
        catch
            return
        end
    end
end