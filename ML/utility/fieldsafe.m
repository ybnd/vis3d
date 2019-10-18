function [fieldsafe_string] = fieldsafe(string)
string = strrep(string, '-', '_');  % todo: this is really clunky and not even extensive. replace with more involved regex
string = strrep(string, ':', '_');
string = strrep(string, ',', '_');
string = strrep(string, '.', '_');
string = strrep(string, ';', '_');
string = strrep(string, '/', '_');
string = strrep(string, '\', '_');
fieldsafe_string = strrep(string, ' ', '_');
end

