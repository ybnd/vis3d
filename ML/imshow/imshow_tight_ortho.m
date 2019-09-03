function [handle_XY, handle_XZ, handle_YZ] = imshow_tight_ortho(image, slice, slice_method, slice_args, M, z, pad)
% https://nl.mathworks.com/matlabcentral/answers/100366-how-can-i-remove-the-grey-borders-from-the-imshow-plot-in-matlab-7-4-r2007a
    % pad: [bottom, top, left, right] -> dpos [left edge, bottom edge, width, height]

    default_pad = [5,5,5,5];
    
    switch nargin
        case 4
            M = 1;
            z = M;
            pad = [0,0,0,0] + default_pad;
        case 5
            z = M;
            pad = [0,0,0,0] + default_pad;
        case 6
            pad = [0 0 0 0] + default_pad;
    end
    
    pad = pad + default_pad;
    
    dfpos = [0 0 pad(3)+pad(4) pad(1)+pad(2)];
    dhpos = [pad(3) pad(1) 0 0];
    
    XY = slice_method(image,slice(3),'z',slice_args);
    XZ = slice_method(image,slice(2),'y',slice_args);
    YZ = slice_method(image,slice(1),'x',slice_args);
    
    [Ny,Nx,Nz] = size(image);
    X = Nx*M;
    Y = Ny*M;
    Z = Nz*M*z;
    
    ax_XY = subplot(2,2,1);
    handle_XY = imshow(XY, 'InitialMagnification', M);
    hold on
    set(ax_XY, 'units', 'pixels')
    ax_XZ = subplot(2,2,2);
    handle_XZ = imshow(XZ, 'InitialMagnification', M);
    hold on
    daspect([1,z,1])
    set(ax_XZ, 'units', 'pixels')
    ax_YZ = subplot(2,2,3);
    handle_YZ = imshow(YZ, 'InitialMagnification', M);
    hold on
    daspect([z,1,1])
    set(ax_YZ, 'units', 'pixels')
    
    set(gcf, 'Position', [50, 50, X+Z, Y+Z] + dfpos);
    set(ax_XY, 'Position', [0,Z+2,X,Y] + dhpos);
    set(ax_XZ, 'Position', [X+2,Z+2,Z,Y] + dhpos);
    set(ax_YZ, 'Position', [0,0,X,Z] + dhpos);  
end

