classdef InteractiveMethodSelector < dynamicprops
    % GUI element to handle 'selecting' CubeInteractiveMethod instances
    % i.e.: a 'ring control' to select slice or postprocess method -> selected instance adds parameters to GUI etc.
    
    properties
        name
        items
    end
    
    methods(Access=public)
        function obj = InteractiveMethodSelector(name, items)
            obj.name = name;
            obj.items = items;
        end
        
        function im = get(obj, item)
            % Sanity check: item in obj.item.field?
            if isfield(obj.items, item)
                im = obj.items.(item);
            else
                warning('Requested field %s does not exist.', item)
            end
        end
        
        function gui_handle = build_gui(figure, anchor, callback)
            global gui
            if isempty(gui)
                interactive_methods;
            end
            
            gui_handle = uicontrol( ...
                'Parent', figure, 'Style', 'popupmenu', 'TooltipString', obj.name, 'String', fields(obj.items), ...
                'Position', [anchor(1), anchor(2), gui.selector_width, gui.height] ...
            );
            addlistener(gui_handle, 'Value', 'PostSet', callback);
        end
    end
end