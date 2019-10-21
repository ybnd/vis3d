function [im] = interactive_methods()
%% This function returns a struct of InteractiveMethodSelector instances.
%{
Any methods included in 'im' will appear in the appropriate method selection interfaces in the GUI scripts (e.g. orthofig, savecube, ...)
To add new interactive methods, just append them to im as shown below
    - Initialization call signature:
        InteractiveMethod(
            method handle (@method)
            parameter names (cell array of strings)
            parameter defaults (cell array of 0d numerics or strings. other values work in principle, but don't play well with GUI elements)
            parameter lower limit (must match the 'defaults' cell array)
            parameter upper limit (must match the 'defaults' cell array)
        );
    - In order to avoid errors due to name/parameter changes, don't use InteractiveMethods explicitly, i.e. calling <InteractiveMethod instance>.do(...)
        * Instead, InteractiveMethods should be called only through handles provided by InteractiveMethodSelector instances

Slice and postprocess InteractiveMethods should follow the following function signatures:
    im.slice:          [I] = <function>(C,k,axis, ...) with C <- Cube.cube, k <- slice index, axis <- slice axis
    im.postprocess:    [I] = <function>(I, ...) with I <- output of an InteractiveMethod from im.slice

!!! PLEASE MAKE SURE ALL PARAMETERS YOU MAY WANT TO ADDRESS INDIVIDUALLY HAVE UNIQUE NAMES !!!
%}
    
    % Slice methods
    im_slice = struct( ...
        'slice', ...
            InteractiveMethod(@slice, {'position', 'axis'}, {1, 'z'}), ...
        'blur_slice', ...
            InteractiveMethod(@blur_slice, {'position', 'axis', 'XY sigma', 'Z sigma'}, ...
                {1, 'z', 1.5, 0.5}, {1, [], 0.01, 0.01}, {Inf, [], 50, 50}) ...
    );

    % Postprocess methods
    im_postprocess = struct( ...
        'normalize_local', ...
            InteractiveMethod(@normalize_local), ...
        'normalize_global', ...
            InteractiveMethod(@normalize_global, {'global range'}, {[0 2^32]}), ...
        'dBs_local', ...
            InteractiveMethod(@dBs_local, {'local floor', 'local ceiling'}, {0, 60}), ...
        'dBs_global', ...
            InteractiveMethod(@dBs_global, {'global floor', 'global ceiling', 'global range'}, {0, 60, [0 2^32]}), ...
        'none', ...
            InteractiveMethod(@none)...
    );

    im = struct( ...
        'slice', InteractiveMethodSelector('slice method', im_slice), ...
        'postprocess', InteractiveMethodSelector('postprocess method', im_postprocess) ...
    );

    %% Slice methods -> return an XY image I at position s from a cube C
    % Function signature: [I] = <function>(C,k,axis ...) with C <- Cube.cube, k <- slice index, axis <- slice axis

    function [I] = slice(C, k, axis)
        assert(isa('axis','char'));
        switch lower(axis)
            case 'x'
                I = permute(C(k,:,:), [3,2,1]);
            case 'y'
                I = permute(C(:,k,:), [1,3,2]);
            otherwise
                I = C(:,:,k);
        end
    end

    function I = blur_slice(C,k,axis,XY_sigma,Z_sigma)
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
        extent = max(k-dz,1):min(k+dz,limit);

        C = slice(C,extent,axis);
        C = imgaussfilt3(C, sigma);

        I = C(:,:,1);
    end

    %% Postprocess methods -> modify an XY / XYZ image I
    % Function signature: [I] = <function>(I, ...) with I <- output of an InteractiveMethod from im.slice

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
end