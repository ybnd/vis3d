function [gui] = interactive_methods_gui()
    % GUI geometry
    gui = struct( ...
        'selector_fontsize', 7, 'fontsize', 9, 'height', 19, 'gap', 2, 'selector_width', 80, 'controls_max_width', 120 ...     
    );  % popupmenu uicontrol height is determined by font size. 
end

