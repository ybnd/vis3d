function [r] = monitor_resolution()

% Adapted from https://nl.mathworks.com/matlabcentral/answers/100792-in-matlab-how-do-i-obtain-information-about-my-screen-resolution-and-screen-size

%Sets the units of your root object (screen) to pixels
set(0,'units','pixels');
%Obtains this pixel information
resolution = get(0,'screensize');
r = resolution(3:4);
end