% This script defines a global struct of InteractiveMethod instances.

% The methods in 'im' will appear in the appropriate method selection interfaces in the GUI or CLI of select
% scripts (e.g. orthofig, savecube, ...)

% To add new interactive methods, just append them to the struct (see below)

%       - In order to avoid errors due to name/parameter changes, don't use these methods explicitly, i.e. calling im.<...>.do(...)
%           * Instead, InteractiveMethods should be called only through handles provided by InteractiveMethodSelector instances

global im
global gui

im = struct();

% GUI geometry
gui = struct( ...
    'selector_fontsize', 7, 'fontsize', 9, 'height', 19, 'gap', 2, 'selector_width', 80, 'controls_max_width', 120 ...     
);  % popupmenu uicontrol height is determined by font size. 
    


% Slice methods
im.slice = struct( ...
    'slice', ...
        InteractiveMethod(@slice, {'position', 'axis'}, {1, 'z'}), ...
    'blur_slice', ...
        InteractiveMethod(@blur_slice, {'position', 'axis', 'XY sigma', 'Z sigma'}, {1, 'z', 2, 1}) ...
);

% Postprocess methods
im.postprocess = struct( ...
    'none', ...
        InteractiveMethod(@none, {}, {}), ...
    'dBs_global', ...
        InteractiveMethod(@dBs_global, {'floor', 'ceiling', 'global range'}, {5, 60, [0 2^16]}), ...
    'dBs_local', ...
        InteractiveMethod(@dBs_local, {'floor', 'ceiling'}, {5, 60}), ...
    'normalize_global', ...
        InteractiveMethod(@normalize_global, {'global range'}, {[0 2^16]}), ...
    'normalize_local', ...
        InteractiveMethod(@normalize_local, {}, {}) ...
);

im.selectors = struct( ...
    'slice', InteractiveMethodSelector('slice method', im.slice), ...
    'postprocess', InteractiveMethodSelector('postprocess method', im.postprocess) ...
);

%% Slice methods -> return an XY image I at position s from a cube C

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

function I = blur_slice(C,s,axis,XY_sigma,Z_sigma)
    % based on sigma & location, extract a subset of cube (enough slices around the actual slice + handle edge cases)
    % blur with imgaussfilt3
    % get slice from the correct position (keep in mind the edge cases!)
    
    if Z_sigma <= 0
       Z_sigma = 0.1; 
    end
 
    size_C = size(C);
    switch lower(axis)
        case 'x'
            sigma = [Z_sigma, XY_sigma, XY_sigma];
            limit = size_C(1);
        case 'y'
            sigma = [XY_sigma, Z_sigma, XY_sigma];
            limit = size_C(2);
        otherwise
            sigma = [XY_sigma, XY_sigma, Z_sigma];
            limit = size_C(3);            
    end
    
    dz = ceil(Z_sigma/2);
    extent = max(s-dz,1):min(s+dz,limit);
    
    C = slice(C,extent,axis);
    C = imgaussfilt3(C, sigma);
    
    I = C(:,:,1);
end

%% Postprocess methods -> modify an XY / XYZ image I

function [I] = none(I)
end

function [I] = normalize_global(I, global_range)
    I = (I - min(global_range)) ./ abs(diff(global_range));
end

function [I] = normalize_local(I)
    I = rescale(I);
end

function [I] = dBs_local(I, floor, ceil)
    I = rescale(dBs(I, floor, ceil));
end

function [I] = dBs_global(I, floor, ceil, global_range)
    I = (dBs(I, floor, ceil) - min(dBs(global_range, floor, ceil))) ./ ...
        abs(diff(dBs(global_range, floor, ceil)));
end