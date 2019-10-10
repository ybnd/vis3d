classdef InteractiveMethodSelector
    % GUI element to handle 'selecting' CubeInteractiveMethod instances
    % i.e.: a 'ring control' to select slice or postprocess method -> selected instance adds parameters to GUI etc.
    
    properties
        Property1
    end
    
    methods
        function obj = CubeInteractiveMethodSelector(inputArg1,inputArg2)
            %CUBEINTERACTIVEMETHODSELECTOR Construct an instance of this class
            %   Detailed explanation goes here
            obj.Property1 = inputArg1 + inputArg2;
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

