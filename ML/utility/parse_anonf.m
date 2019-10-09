function [func, pars] = parse_anonf(handle)
% Get command and parameters from anonymous function handle

    fs = functions(handle);
    if strcmp(fs.type,'anonymous')
        [tokens] = regexp(fs.function, '@\(([a-zA-Z0-9,~_]+)\)(.*)', 'tokens');
        
        % To get 'pars': extract contents of brackets "@(...)" into a cell array of strings <- second token
        pars = split(tokens{1}{1}, ',');
        
        % To get 'func': remove "@(...) " from fs.func <- first token
        func = tokens{1}{2};        
    else
        func = fs.function;
        pars = {};
    end  
end

