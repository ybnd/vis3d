function un7zip(file, destination)
% Unzip file with 7zip (faster than builtin unzip function)
% Please make sure the command below correctly points to the 7zip executable.

% Notice: order of ' and " matters! 
% cmd.exe can't interpret ' when launching executables, so command string must be defined with '' in MATLAB!

% Notice: when switching PCs, this seems to break, is 7zip just installed elsewhere? (32-bit version maybe?)
% if so, check which of the following checks out:
%           isfile("C:/Program Files/7-zip/7z.exe")
%           isfile("C:/Program Files (x86)/7-zip/7z.exe")
%       and construct the command accordingly

% 7zip x    : extract & preserve directory structure
% 7zip -o   : output directory (have append the path to -o like -oC:/bla, I don't like it, it's ugly.)
% 7zip -aoa : overwrite all files without prompt (ok for the current use case, otherwise the function hangs)
    
    if isfile("C:/Program Files/7-zip/7z.exe")
        [~,~] = system(                                                                      ...
            sprintf('"C:/Program Files/7-zip/7z.exe" x -o%s %s -aoa', destination, file)     ...
        );
    elseif isfile("C:/Program Files (x86)/7-zip/7z.exe")
        [~,~] = system(                                                                      ...
            sprintf('"C:/Program Files (x86)/7-zip/7z.exe" x -o%s %s -aoa', destination, file)     ...
        );
    else
        unzip(file, destination)
    end 
end