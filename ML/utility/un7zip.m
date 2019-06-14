function un7zip(file, destination)
% Unzip file with 7zip (faster than builtin unzip function)

% Please sure the command below correctly points to the 7zip executable.

% Notice: order of ' and " matters! 
% cmd.exe can't interpret ' when launching executables, so command string must be defined with '' in MATLAB!

% 7zip x    : extract & preserve directory structure
% 7zip -o   : output directory (have append the path to -o like -oC:/bla, I don't like it, it's ugly.)
% 7zip -aoa : overwrite all files without prompt (ok for the current use case, otherwise the function hangs)

    [~,~] = system(                                                                 ...
        sprintf('"C:/Program Files/7-zip/7z.exe" x -o%s %s -aoa', destination, file)     ...
    );
end