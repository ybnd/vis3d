% vis3d: some examples
% Execute section per section with Ctrl+Shift+Enter

clear all; close all; clc;
folder = [pwd '\vis3d\ML\examples']; % Current folder should include vis3d

%% Loading 3d image files: json/binary

A = loadcube([folder '\example']);

% The most important stuff's in the help string!
help A

%% Loading 3d image files: .tif stacks

T = loadcube([folder '\example.tif']);

if rprod(A.cube == T.cube)
    disp('A.cube and T.cube are equal, as they should be.')
else
    disp('A.cube and T.cube are not equal. Someone has been messing with these files!')
end

%% Looking at 3d images

% Slice figures
A.sf('xy'); 

%% Working with InteractiveMethods

% Selecting methods
A.im_select('blur_slice', 'dBs_global')
% Working with parameters
A.im_set('XY sigma', A.im_get('Z sigma'))

% Open a new figure
A.of

%% Working with CubeROIs

% Initialize a CubeROIs instance; region_thickness.m is a subclass of CubeROIs with some methods to compute layer
% thickness over the regions of interest
B = region_thickness(A);

% Select some ROIs
B.select;

% Show profiles
B.profiles;

% Calculate distances
d = B.distances();
disp(d)


%% Saving 3d image files

% Add a new field to the metadata, denoting that the file was replaced
A.meta.(fieldsafe(['at ' datestr(datetime('now'))])) = 'replaced file';

% Save as json/binary
savecube(A, [folder '\example']);

% Save as .tif
savecube(A, [folder '\example.tif']);



