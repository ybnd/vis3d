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
        im_gui = interactive_methods_gui();
        parname = {};
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
            
            parname = [];
            item_fields = fields(items);
            for i = 1:length(item_fields)
                parname = [parname items.(item_fields{i}).parname];
            end
            obj.parname = unique(parname);
            
            item_fields = fields(items);
            obj.select(item_fields{1});            
        end
        
        function selected = select(obj, item)
            % Sanity check: item in obj.item.field?
            if isfield(obj.items, item)
                selected = obj.items.(item);
                try
                    obj.selected = selected;
                    if ishandle(obj.figure)
                        obj.replace_controls(selected)
                    end
                    set(obj.gui_handle, 'Value', find(strcmp(fields(obj.items),item))) % Update UI (e.g. handle explicit calls 'from outside')
                    obj.callback() % todo: this may not be a good idea if values for (source, event) are actually used!
                catch err
                    %todo: should not show warnings if GUI has not been built yet!
                end
            else
                warning('Requested field %s does not exist.', item)
            end
        end
        
        function set(obj, parameter, value)
            % Set parameter to value for all InteractiveMethods in obj.items
            options = fields(obj.items);
            for i = 1:length(options)
                item = obj.items.(options{i});
                item.set(parameter, value);
            end
        end
        
        function values = get(obj, parameter)
            % Set parameter to value for all InteractiveMethods in obj.items
            values = struct();
            
            options = fields(obj.items);
            for i = 1:length(options)
                item = obj.items.(options{i});
                value = item.get(parameter);
                if ~isempty(value)
                    values.(options{i}) = value;
                end
            end
        end
        
        function reset(obj, parameter)
            options = fields(obj.items);
            for i = 1:length(options)
                item = obj.items.(options{i});
                item.reset(parameter);
            end
        end
        
        function gui_handle = build_gui(obj, figure, anchor, callback, disabled_parameters)
            switch nargin
                case 4
                    disabled_parameters = {};               
            end
            
            obj.disabled_parameters = disabled_parameters;
            gui = obj.im_gui;
            
            gui_handle = uicontrol( ...
                'Parent', figure, 'Style', 'popupmenu', 'TooltipString', obj.name, ...
                'String', fields(obj.items), 'FontSize', gui.selector_fontsize, ...
                'Position', [anchor(1), anchor(2), gui.selector_width+gui.gap+gui.controls_max_width, gui.height] ...
            );
            addlistener(gui_handle, 'Value', 'PostSet', @obj.gui_select_callback);
            obj.gui_handle = gui_handle;
            
            obj.figure = figure;
            obj.callback = callback;
            obj.controls_anchor = anchor + [gui.selector_width + gui.gap, 0];
            
            obj.replace_controls(obj.selected);
        end
        
        function out = do(obj, in, varargin)
            % Pass to selected InteractiveMethod
            try
                out = obj.selected.do(in, varargin{:});
            catch err
               % todo: Try not to even 'try' this when GUI not built completely yet?
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
                % todo: Try not to even 'try' this when GUI not buily completely yet?
                % warning(err.message);
            end
            obj.controls = selected.build_gui(obj.figure, obj.controls_anchor, obj.callback, obj.disabled_parameters);
            set(obj.gui_handle, 'UserData', selected);
            
            gui = interactive_methods_gui;
            
            if isempty(obj.controls)
                p = get(obj.gui_handle, 'Position');
                set(obj.gui_handle, 'Position', [p(1), p(2), gui.selector_width+gui.gap*2+gui.controls_max_width, p(4)]);
            else
                p = get(obj.gui_handle, 'Position');
                set(obj.gui_handle, 'Position', [p(1), p(2), gui.selector_width, p(4)]);
            end
        end
        
        function gui_select_callback(obj, ~, event)
            obj.select(event.AffectedObject.String{event.AffectedObject.Value});   
        end
    end
end