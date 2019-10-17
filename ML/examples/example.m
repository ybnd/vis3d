% vis3d: some examples
% Execute section per section with Ctrl+Shift+Enter

clear all; close all; clc;
folder = [pwd '\ML\examples']; % Current folder should be vis3d

%% Loading 3d image files: json/binary

A = loadcube([folder '\example']);

%% Loading 3d image files: .tif stacks

T = loadcube([folder '\example.tif']);

if rprod(A.cube == T.cube)
    disp('A.cube and T.cube are equal, as they should be.')
else
    disp('A.cube and T.cube are not equal. Someone has been messing with these files!')
end

%% Looking at 3d images I

% Slice figures
A.sf('xy'); A.sf('yz'); 


%% Looking at 3d images II

% Ortographic figure
A.of; 

%% 

%% Saving 3d image files

% Add a new field to the metadata, denoting that the file was replaced
A.meta.(['at' fieldsafe(datestr(datetime('now')))]) = 'replaced file';

% Save as json/binary
savecube(A, [folder '\example']);

% Save as .tif
savecube(A, [folder '\example.tif']);



