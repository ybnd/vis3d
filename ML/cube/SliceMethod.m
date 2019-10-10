classdef SliceMethod < InteractiveMethod

    methods(Access = public)
        function self = SliceMethod(methodh, default, expects, options)
            self@InteractiveMethod(methodh, default, options, expects);
        end
    end
end