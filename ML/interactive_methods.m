% This script defines a global struct of InteractiveMethod instances.

% The methods in 'im' will appear in the appropriate method selection interfaces in the GUI or CLI of select
% scripts (e.g. orthofig, savecube, ...)

% To add new interactive methods, just append them to the struct (see below)

%       - In order to avoid errors due to name/parameter changes, don't use these methods explicitly, i.e. calling im.<...>.do(...)
%           * Instead, InteractiveMethods should be called only through handles provided by InteractiveMethodSelector instances

global im
global gui

if isempty(im)
    im = struct();
    
    % GUI geometry
    gui = struct( ...
        'height', 22, 'gap', 2, 'selector_width', 80, 'controls_max_width', 160 ...     % popupmenu uicontrol height is fixed at 22px
    );

    % Slice methods
    im.slice = struct( ...
        'slice', ...
            InteractiveMethod(@slice, {'position', 'axis'}, {1, 'z'}), ...
        'lift_slice', ...
            InteractiveMethod(@lift_slice, {'position', 'axis'}, {1, 'z'}), ...
        'normalize_slice', ...
            InteractiveMethod(@normalize_slice, {'position', 'axis'}, {1, 'z'}), ...  
        'blur_slice', ...
            InteractiveMethod(@blur_slice, {'position', 'axis', 'sigma'}, {1, 'z', [3 3 1]}) ...
    );

    % Postprocess methods
    im.postprocess = struct( ...
    );

    im.selectors = struct( ...
        'slice', InteractiveMethodSelector('slice', im.slice), ...
        'postprocess', InteractiveMethodSelector('postprocess', im.postprocess) ...
    );
end


function [I] = slice(C, s, axis)
    assert(isa('axis','char'));
    switch lower(axis)
        case 'x'
            I = permute(C(s,:,:), [3,2,1]);
        case 'y'
            I = permute(C(:,s,:), [1,3,2]);
        otherwise
            I = C(:,:,s);
    end
end

function I = lift_slice(C,s,axis)
    I = slice(C,s,axis);
    I = double(C(:,:,s));
    I = I - min(min(I));
end

function I = normalize_slice(C,s,axis)
    I = slice(C,s,axis);    
    I = rescale(single(I));
end

function I = blur_slice(C,s,axis,sigma)
    % based on sigma & location, extract a subset of cube (enough slices around the actual slice + handle edge cases)
    % blur with imgaussfilt3
    % get slice from the correct position (keep in mind the edge cases!)
end