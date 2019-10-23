function [ols] = normalize_json(str)
    ols = regexprep(str, '[\r\n\t\f\v ]+', '');
end

