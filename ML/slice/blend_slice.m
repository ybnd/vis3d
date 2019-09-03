function I = blend_slice(C, slice, axis, args)
%{ 
    Returns a blended slice I of 3D image C. 
        C:      a 3d array
        slice:  integer number to slice from C
        axis:   axis to slice through
        args:   a struct of arguments 
                    args.blendN:    number of slices to blend into I
                    args.window:    windowing function handle (e.g. @gausswin, @boxcar, ...)
                    args.windowpar: windowing function parameter (e.g. @gausswin -> Alpha)

        I:      en-face image: I ~ C(:,:,slice)
%}

    assert(isa('axis','char'));

    switch nargin
        case 2
            args = struct('blendN', 5, 'window', @boxcar);
    end
    
    [Nx,Ny,Nz] = size(C);

    delta = floor(args.blendN/2);
    blend = slice-delta:slice+delta;
    blend = blend(blend > 0 & blend <= Nz);
    
    if isfield(args, 'windowpar')
        window = args.window(args.blendN, args.windowpar);
    else
        window = args.window(args.blendN);
    end
        
    try
        
        switch lower(axis)
            case 'x'
                subC = double(C(blend,:,:)) .* repmat(window(blend > 0),[1,Ny,Nz]);
                subC = permute(subC, [3,2,1]);
            case 'y'
                subC = double(C(:,blend,:)) .* repmat(window(blend > 0),[Nx,1,Nz]);
                subC = permute(subC, [1,3,2]);
            otherwise
                subC = double(C(:,:,blend)) .* repmat(permute(window(blend > 0),[3,2,1]),[Nx,Ny,1]);                
        end
        
        norm_subC = zeros(size(subC));
        for b = 1:length(blend)
            norm_subC(:,:,b) = rescale(double(subC(:,:,b)));
        end

        I = sum(norm_subC,3);         
        
        
    catch error
        I = C(:,:,slice);
        warning(error, 'Blended slice image could not be computed.')
    end    
end