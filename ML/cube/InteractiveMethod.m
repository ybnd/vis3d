classdef InteractiveMethod < matlab.mixin.Copyable    
%{ 
Cube plugin method with built-in user interface

    * Method handle
    * Cell array of parameters, used to call the method
        * Parameters can be addressed through a GUI or programmatically
        * Define default, minimum and maximum values
%}
    
    properties
       methodh = false;         % Method handle
       parname = {};           % Used to identify parameters.
       current = {};            % Current parameter values   % Reflect changes to parameters (e.g. ~ orthofig) in CubePostprocess instances!
       default = {};            % Default parameter values
       minimum = {};            % Minimum parameter values
       maximum = {};            % Maximum parameter values
    end
    
    properties(Hidden = true)
        method = '';            % Method name
        
        callback = false;       % Function to execute when modified
        expects = @single;      % Expected input data type
        
        gui_handles = {};       % 
    end
    
    methods(Access = public)
        function obj = InteractiveMethod(methodh, parname, default, minimum, maximum, expects)
            switch nargin
                case 1
                    parname = {};
                    default = {};
                    minimum = {};
                    maximum = {};
                    expects = @single;
                case 3
                    minimum = {};
                    maximum = {};
                    expects = @single;
                case 4
                    maximum = {};
                    expects = @single;
                case 5
                    expects = @single;
            end
            
            obj.methodh = methodh;         % Should perform checks!
            obj.parname = parname;
            obj.default = default;
            obj.current = obj.default;
            obj.minimum = minimum;
            obj.maximum = maximum;
            obj.expects = expects;
            
            obj.setup;
        end
        
        function set_callback(obj, callback)
           obj.callback = callback; % todo: basic sanity checks 
        end
        
        function out = do(obj, in, varargin) % TODO: should handle nargin after 'in' by modifying obj.current -> i.e. call slice.do(cube, 123) -> 123 to first parameter in obj.current
            % Call method with current parameter values     
            for i = 1:numel(varargin)
               obj.current{i} = varargin{i}; 
            end
            
            out = obj.methodh(obj.expects(in), obj.current{:});
        end
        
        function set(obj, parameter, value)
            if any(strcmp(parameter, obj.parname))
                i = find(not(cellfun('isempty', strfind(obj.parname, parameter)))); % https://nl.mathworks.com/matlabcentral/answers/2015-find-index-of-cells-containing-my-string
%                 if class(value) == class(obj.default{i})     % todo: with check: too stringent
                obj.current{i} = value;    % todo: without check: too loose
%                 end
            end
        end
        
        function value = get(obj, parameter)
            if any(strcmp(parameter, obj.parname))
                i = find(not(cellfun('isempty', strfind(obj.parname, parameter)))); % https://nl.mathworks.com/matlabcentral/answers/2015-find-index-of-cells-containing-my-string
%                 if class(value) == class(obj.default{i})     % todo: with check: too stringent
                value = obj.current{i};    % todo: without check: too loose
%                 end
            else
                value = '';
            end
        end
        
        function reset(obj, parameter)
            if any(strcmp(parameter, obj.parname))
                i = find(not(cellfun('isempty', strfind(obj.parname, parameter)))); % https://nl.mathworks.com/matlabcentral/answers/2015-find-index-of-cells-containing-my-string
%                 if class(value) == class(obj.default{i})     % todo: with check: too stringent
                obj.current{i} = obj.default{i};    % todo: without check: too loose
%                 end
            end
        end
        
        
        function update_numeric_parameter(obj, source, ~)
            i = obj.get_parameter_index(source); % Parameter index (see InteractiveMethod.build_gui)         
            new_value = str2num(source.String);
            obj.current{i} = min(max(new_value, obj.minimum{i}), obj.maximum{i}); % todo: do this same sanity check when setting default value in constructor!
            source.String = obj.current{i};
            
            if isa(obj.callback, 'function_handle')
                obj.callback();
            end
        end
        
        function update_string_parameter(obj, source, ~)
            i = obj.get_parameter_index(source); % Parameter index (see InteractiveMethod.build_gui)
            obj.current{i} = source.String;
            if isa(obj.callback, 'function_handle')
                obj.callback();
            end
        end
        
        function gui_handles = build_gui(obj, figure, anchor, callback, disabled_parameters)
            % Build own GUI at anchor in figure
            % ALSO: implement callbacks ~ this gui
            
            % TODO: handle string and numeric values, uicontrol('edit') vs uieditfield
            
            switch nargin
                case 4
                    disabled_parameters = {};               
            end
            
            obj.set_callback(callback);
            

            % Remove disabled parameters from obj.parname
            % https://nl.mathworks.com/matlabcentral/answers/298884-remove-cell-that-contains-strings-of-another-cell-array
            
            x = false(size(obj.parname));
            for k=1:numel(disabled_parameters)
                x = x | strcmp(obj.parname,disabled_parameters{k});
            end
            enabled_parameters = obj.parname;
            enabled_parameters(x) = [];
            
            gui = interactive_methods_gui;
            
            gui_handles = cell(size(enabled_parameters));      
            parN = length(enabled_parameters);
            gui_width = floor(gui.controls_max_width / parN);
            
            k = 1;
            for i = 1:length(obj.parname)  
                if any(strcmp(obj.parname{i}, enabled_parameters))
                    if isnumeric(obj.default{i})
                        parameter_callback = @obj.update_numeric_parameter;
                    else
                        parameter_callback = @obj.update_string_parameter;
                    end

                    gui_handles{i} = uicontrol( ...
                        'Parent', figure, 'Style', 'edit', 'TooltipString', obj.parname{i}, ...
                        'FontSize', gui.fontsize, 'String', num2str(obj.current{i}), ...
                        'Callback', parameter_callback, ...
                        'Position', [anchor(1)+(k-1)*(gui_width+gui.gap), anchor(2), gui_width, gui.height] ...
                    );
                    k = k+1;

                    obj.set_parameter_index(gui_handles{i}, i);
%                     obj.callback(); % todo: temporary, this is not a good idea if values for (source, event) are used!
                end
            end
            obj.gui_handles = gui_handles;
        end
    end
    
    methods(Static)
        function set_parameter_index(handle, i)
            % Set parameter index in associated uicontrol
            set(handle, 'UserData', i);
        end
        
        function i = get_parameter_index(handle)
            % Get parameter index from associated uicontrol
            i = get(handle, 'UserData');
        end
    end
    
    methods(Access = protected)
        function setup(obj)
            if ~isempty(obj.methodh)
               fs = functions(obj.methodh);
               
               switch fs.type
                   case 'anonymous'
                       [tokens] = regexp(fs.function, '@\(([a-zA-Z0-9,~_]+)\)(.*)', 'tokens');        
                       
                        if isempty(obj.parname)
                            % To get 'pars': extract contents of brackets "@(...)" into a cell array of strings <- second token
                            obj.parname = split(tokens{1}{1}, ',');
                            obj.parname = obj.parname(2:end); % First parameter doesn't need an interface (it's the slice or cube)
                            % To get 'func': remove "@(...) " from fs.func <- first token
                        end
                        obj.method = tokens{1}{2};    
                        
                        % TODO: string parameter min/max should just be ''
                        
                        
                   case {'scopedfunction', 'nested'}
                        parts = strsplit(fs.function, '/');
                        obj.method = parts{2};
                   case 'simple'
                       obj.method = fs.function;
                   otherwise
                       error('What even is a %s function: %s', fs.type, fs.function)
                end
               
                if isempty(obj.minimum)
                   obj.minimum = num2cell(-Inf * ones(size(obj.default)));
                end

                if isempty(obj.maximum)
                   obj.maximum = num2cell(Inf * ones(size(obj.default)));
                end
            else
                error('Function handle is empty also make this error more informative pls')
            end
        end
        

    end
end