function [handle_XY, handle_XZ, handle_YZ, overlay, pad] = imshow_tight_ortho(...
    cube, slice, M, z_ratio, pad)
% https://nl.mathworks.com/matlabcentral/answers/100366-how-can-i-remove-the-grey-borders-from-the-imshow-plot-in-matlab-7-4-r2007a
    % pad: [bottom, top, left, right] -> dpos [left edge, bottom edge, width, height]
    
    % Should just have this thing in orthofig instead

    default_pad = [5,5,5,5];
    
    switch nargin
        case 2
            M = 0.3;
            z_ratio = 1;
            pad = [0,0,0,0] + default_pad;
        case 3
            z_ratio = 1;
            pad = [0,0,0,0] + default_pad;
        case 4
            pad = [0 0 0 0] + default_pad;
    end
    
    pad = pad + default_pad;
    
    dfpos = [0 0 pad(3)+pad(4) pad(1)+pad(2)];
    dhpos = [pad(3) pad(1) 0 0];
    
    [XY, ~] = cube.slice(slice(3),'z');
    [XZ, ~] = cube.slice(slice(2),'y');
    [YZ, ~] = cube.slice(slice(1),'x');
    
    [Ny,Nx,Nz] = size(cube.cube);
    X = Nx*M;
    Y = Ny*M;
    Z = Nz*M*z_ratio;
    
    overlay_color = [52 235 174]/255;
    overlay_alpha = 0.2;
    
    ax_XY = subplot(2,2,1);
    set(ax_XY, 'units', 'pixels')
    handle_XY = imshow(XY, 'InitialMagnification', M);
    handle_XY_X = patchline([0,0],[0,0], 'EdgeColor', overlay_color, 'EdgeAlpha', overlay_alpha);
    handle_XY_Y = patchline([0,0],[0,0], 'EdgeColor', overlay_color, 'EdgeAlpha', overlay_alpha);
    hold on
    
    ax_XZ = subplot(2,2,2);
    set(ax_XZ, 'units', 'pixels')
    handle_XZ = imshow(XZ, 'InitialMagnification', M);
    handle_XZ_X = patchline([0,0],[0,0], 'EdgeColor', overlay_color, 'EdgeAlpha', overlay_alpha);
    handle_XZ_Z = patchline([0,0],[0,0], 'EdgeColor', overlay_color, 'EdgeAlpha', overlay_alpha);
    hold on
    daspect([1,z_ratio,1])
    
    ax_YZ = subplot(2,2,3);
    set(ax_YZ, 'units', 'pixels')
    handle_YZ = imshow(YZ, 'InitialMagnification', M);
    handle_YZ_Y = patchline([0,0],[0,0], 'EdgeColor', overlay_color, 'EdgeAlpha', overlay_alpha);
    handle_YZ_Z = patchline([0,0],[0,0], 'EdgeColor', overlay_color, 'EdgeAlpha', overlay_alpha);
    hold on
    daspect([z_ratio,1,1])
    
    
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

