function [handle_XY, handle_XZ, handle_YZ, overlay, pad] = imshow_tight_ortho(...
    image, slice, slice_method, slice_args, M, z_ratio, pad)
% https://nl.mathworks.com/matlabcentral/answers/100366-how-can-i-remove-the-grey-borders-from-the-imshow-plot-in-matlab-7-4-r2007a
    % pad: [bottom, top, left, right] -> dpos [left edge, bottom edge, width, height]

    default_pad = [5,5,5,5];
    
    switch nargin
        case 4
            M = 0.3;
            z_ratio = 1;
            pad = [0,0,0,0] + default_pad;
        case 5
            z_ratio = 1;
            pad = [0,0,0,0] + default_pad;
        case 6
            pad = [0 0 0 0] + default_pad;
    end
    
    pad = pad + default_pad;
    
    dfpos = [0 0 pad(3)+pad(4) pad(1)+pad(2)];
    dhpos = [pad(3) pad(1) 0 0];
    
    XY = slice_method(image,slice(3),'z',slice_args);
    XZ = slice_method(permute(image,[1,3,2]),'y',slice(2),slice_args);
    YZ = slice_method(permute(image,[3,2,1]),'x',slice(1),slice_args);
    
    [Ny,Nx,Nz] = size(image);
    X = Nx*M;
    Y = Ny*M;
    Z = Nz*M*z_ratio;
    
    overlay_color = [52 235 174]/255;
    overlay_alpha = 0.2;
    
    ax_XY = subplot(2,2,1);
    handle_XY = imshow(XY, 'InitialMagnification', M);
    handle_XY_X = patchline([0,0],[0,0], 'EdgeColor', overlay_color, 'EdgeAlpha', overlay_alpha);
    handle_XY_Y = patchline([0,0],[0,0], 'EdgeColor', overlay_color, 'EdgeAlpha', overlay_alpha);
    hold on
    set(ax_XY, 'units', 'pixels')
    ax_XZ = subplot(2,2,2);
    handle_XZ = imshow(XZ, 'InitialMagnification', M);
    handle_XZ_X = patchline([0,0],[0,0], 'EdgeColor', overlay_color, 'EdgeAlpha', overlay_alpha);
    handle_XZ_Z = patchline([0,0],[0,0], 'EdgeColor', overlay_color, 'EdgeAlpha', overlay_alpha);
    hold on
    daspect([1,z_ratio,1])
    set(ax_XZ, 'units', 'pixels')
    ax_YZ = subplot(2,2,3);
    handle_YZ = imshow(YZ, 'InitialMagnification', M);
    handle_YZ_Y = patchline([0,0],[0,0], 'EdgeColor', overlay_color, 'EdgeAlpha', overlay_alpha);
    handle_YZ_Z = patchline([0,0],[0,0], 'EdgeColor', overlay_color, 'EdgeAlpha', overlay_alpha);
    hold on
    daspect([z_ratio,1,1])
    set(ax_YZ, 'units', 'pixels')
    
    set(gcf, 'Position', [30,30, X+Z, Y+Z] + dfpos);
    set(ax_XY, 'Position', [0,Z+2,X,Y] + dhpos);
    set(ax_XZ, 'Position', [X+2,Z+2,Z,Y] + dhpos);
    set(ax_YZ, 'Position', [0,0,X,Z] + dhpos);  
    
    % https://nl.mathworks.com/matlabcentral/answers/276630-buttondownfcn-for-axes-not-working
    for h = [handle_XY, handle_XZ, handle_YZ]
        set(h.Parent, 'HitTest', 'off');
        set(h.Parent, 'PickableParts', 'all')
        set(h, 'HitTest', 'on');
        set(h, 'PickableParts', 'all');
    end
    for h = [handle_XY_X, handle_XY_Y, handle_XZ_X, handle_XZ_Z, handle_YZ_Y, handle_YZ_Z]
        set(h, 'HitTest', 'off');
    end
    
    overlay = struct();
    overlay.XY.X = handle_XY_X;
    overlay.XY.Y = handle_XY_Y;
    overlay.XZ.X = handle_XZ_X;
    overlay.XZ.Z = handle_XZ_Z;
    overlay.YZ.Y = handle_YZ_Y;
    overlay.YZ.Z = handle_YZ_Z;  
end

