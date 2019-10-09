classdef CubeSlice < CubeInteractiveMethod

    methods(Access = public)
        function self = CubeSlice(methodh, default, expects, options)
            self@CubeInteractiveMethod(methodh, default, options, expects);
        end
    end
end