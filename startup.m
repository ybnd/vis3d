% Copy this file to your MATLAB path or add this to your own startup.m file

% Add vis3d MATLAB code to path
addpath(genpath('vis3d/ML'));

% If applicable, remove the PLS Toolbox from path (interferes with the use of built-in function rescale.m, maybe others)
if ~isempty(ls([toolboxdir('') '\PLS*']))
    rmpath([toolboxdir('') '\' ls([toolboxdir('') '\PLS*'])])
end