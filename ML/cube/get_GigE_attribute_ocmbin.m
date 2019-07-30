function [value] = get_GigE_attribute_ocmbin(C, attribute)
    if isa(C, 'Cube')
        try
            for j = 1:length(C.meta.Variant.GigEConfig.Attributes)
                if strcmp(C.meta.Variant.GigEConfig.Attributes{j}{1}, attribute)
                    value_string = C.meta.Variant.GigEConfig.Attributes{j}{2};
                    value = str2num(value_string);
                    if isempty(value)
                        try
                            value = str2bool(value_string);
                        catch err
                            value = value_string;
                        end
                    end                    
                end
            end
        catch err
            warning(err);
            value = NaN;
        end
    end
end

