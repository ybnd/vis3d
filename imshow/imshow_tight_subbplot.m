function handle = imshow_tight_subbplot(image, magn, pad)
% https://nl.mathworks.com/matlabcentral/answers/100366-how-can-i-remove-the-grey-borders-from-the-imshow-plot-in-matlab-7-4-r2007a
    % pad: [bottom, top, left, right] -> dpos [left edge, bottom edge, width, height]

    default_pad = [5,5,5,5];
    
    switch nargin
        case 1
            magn = 200;
            pad = [0,0,0,0] + default_pad;
        case 2
            pad = [0 0 0 0] + default_pad;
    end
    
    dfpos = [0 0 pad(3)+pad(4) pad(1)+pad(2)];
    dhpos = [pad(3) pad(1) 0 0];
    
    handle = imshow(image, 'InitialMagnification', magn);
    
    set(gca, 'unit', 'pixels')    
%     hpos = get(gca, 'position');
%     fpos = get(gcf, 'position');
    
%     set(gcf, 'position', [fpos(1), fpos(2), hpos(3), hpos(4)]+dfpos)
%     set(gca, 'position', [0,0,hpos(3),hpos(4)] + dhpos)   
end

