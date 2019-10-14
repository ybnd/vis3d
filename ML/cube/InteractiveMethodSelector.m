classdef InteractiveMethodSelector < dynamicprops
    % GUI element to handle 'selecting' CubeInteractiveMethod instances
    % i.e.: a 'ring control' to select slice or postprocess method -> selected instance adds parameters to GUI etc.
    
    properties
        name
        items
        selected
        disabled_parameters = {};
    end
    
    properties(Hidden=true)        
        figure;
        callback = false;
        gui_handle = false;
        controls = false;
        controls_anchor = false;
    end
    
    methods(Access=public)
        function obj = InteractiveMethodSelector(name, items)
            obj.name = name;
            obj.items = items;
        end
        
        function selected = select(obj, item)
            % Sanity check: item in obj.item.field?
            if isfield(obj.items, item)
                selected = obj.items.(item);
                obj.selected = selected;
                if ishandle(obj.figure)
                    obj.replace_controls(selected)
                end
                set(obj.gui_handle, 'Value', find(strcmp(fields(obj.items),item))) % Update UI (e.g. handle explicit calls 'from outside')
                obj.callback() % todo: this is not a good idea if values for (source, event) are used!
            else
                warning('Requested field %s does not exist.', item)
            end
        end
        
        function gui_handle = build_gui(obj, figure, anchor, callback, disabled_parameters)
            switch nargin
                case 4
                    disabled_parameters = {};               
            end
            
            global gui
            if isempty(gui)
                interactive_methods;
            end
            
            obj.disabled_parameters = disabled_parameters;
            
            gui_handle = uicontrol( ...
                'Parent', figure, 'Style', 'popupmenu', 'TooltipString', obj.name, ...
                'String', fields(obj.items), 'FontSize', gui.selector_fontsize, ...
                'Position', [anchor(1), anchor(2), gui.selector_width, gui.height] ...
            );
            addlistener(gui_handle, 'Value', 'PostSet', @obj.gui_select_callback);
            obj.gui_handle = gui_handle;
            
            obj.figure = figure;
            obj.callback = callback;
            obj.controls_anchor = anchor + [gui.selector_width + gui.gap, 0];
            
            % Show controls for first InteractiveMethod by default
            temp_items = fields(obj.items);
            obj.select(temp_items{1});
        end
        
        function out = do(obj, in, varargin)
            % Pass to selected InteractiveMethod
            try
                out = obj.selected.do(in, varargin{:});
            catch err
               warning(err.message); 
               out = in;
            end
        end
    end
    
    methods(Access=protected)
        function replace_controls(obj, selected)
            try
                for i = 1:numel(obj.controls)
                   delete(obj.controls{i}); 
                end
            catch err
                warning(err.message);
            end
            obj.controls = selected.build_gui(obj.figure, obj.controls_anchor, obj.callback, obj.disabled_parameters);
            set(obj.gui_handle, 'UserData', selected);
        end
        
        function gui_select_callback(obj, ~, event)
            obj.select(event.AffectedObject.String{event.AffectedObject.Value});   
        end
    end
end