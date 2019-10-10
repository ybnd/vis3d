classdef PostprocessMethod < InteractiveMethod
    %{ 
    Postprocessing method wrapper class    
    
    Description:
    ============
        - Provides a simple interface to define postprocessing routines
        - Post-processing methods constructed in this way can be easily accessed through CLI and GUI interfaces
            * e.g. orthofig: provide user with a list of postprocessing methods in UI; each method can be accompanied by
                             its own set of controls to adjust any relevant parameters
    
        - To define interactive methods with mutable parameters, construct a CubePostprocess instance with 
          (at most one!) anonymous function 
    %}
    
    properties(Hidden = true)
        workson = ''           % If set to either 'slice' or 'cube' will only be suggested in the respective categories
    end
    
    methods(Access = public)
        function self = PostprocessMethod(methodh, default, expects, workson, options)
            switch nargin
                case 2
                    expects = @single;
                    workson = '';
                    options = struct();
                case 3
                    workson = '';
                    options = struct();
                case 4
                    options = struct();
            end
            
            self@InteractiveMethod(@(~)[], default, options, expects);   
            self.methodh = methodh; % Should perform some checks at interpret time!
                % If {} contains anonymous functions with parameters, class should provide a CLI and GUI interface to
                % interactively adjust these parameters
               
            self.workson = workson;
        end
        
        function out = do(self, in)
            if ~isempty(self.process)
                temp = normalize_input(in);
               
                for i = 1:length(self.methodh)
                    temp = self.methodh{i}(temp);       % Pass 
                end
            else
                out = in; %Should raise a warning
                return
            end
        end
    end
    
    methods(Access = private)
        function in = normalize_input(self, in)
            if ~isa(in, func2str(self.expects))
                in = self.expects(in);
            end
        end
    end
end