function [fieldsafe_string] = fieldsafe(original_string)
    fieldsafe_string = matlab.lang.makeValidName(original_string);
end
