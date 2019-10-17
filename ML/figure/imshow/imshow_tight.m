function handle = imshow_tight(image, magn, pad)
% https://nl.mathworks.com/matlabcentral/answers/100366-how-can-i-remove-the-grey-borders-from-the-imshow-plot-in-matlab-7-4-r2007a
    % pad: [bottom, top, left, right] -> dpos [left edge, bottom edge, width, height]

    default_pad = [5,5,5,5];
    
    switch nargin
        case 1
            magn = 1;
            pad = [0,0,0,0] + default_pad;
        case 2
            pad = [0 0 0 0] + default_pad;
    end
    
    [Nx,~] = size(image);
    magn = magn * Nx; % different behaviour than imshow_tight_orthofig, don't know why, don't care for now
    
    dfpos = [0 0 pad(3)+pad(4) pad(1)+pad(2)];
    dhpos = [pad(3) pad(1) 0 0];
    
    
    handle = imshow(image, 'InitialMagnification', magn);
    set(handle.Parent, 'units', 'pixels') 
       
    hpos = get(handle.Parent, 'position');
    fpos = get(handle.Parent.Parent, 'position');
    
    set(handle.Parent.Parent, 'position', [fpos(1), fpos(2), hpos(3), hpos(4)]+dfpos)
    set(handle.Parent, 'position', [0,0,hpos(3),hpos(4)] + dhpos)
end

