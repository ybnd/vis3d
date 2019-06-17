function live_A_scan(I, loc, z, smoothf, reflectivity, do_fwhm, do_smooth)
    % Continuous A_scan display ~ mouse hover point
    % Click mouse -> fix current A_scan on the plot, overlay on others / continuous plot
    
    % todo: document
    % fixme: i'm broken inside

    try 
        [Nx, Ny, Nz] = size(I);
    catch
        error('No image cube provided.')
    end
    
    switch nargin
        case 0
            error('No inputs provided!')
        case 1
            do_fwhm = false;
            loc = int32(Nz/2);
            z = 1:Nz;
            smoothf = 5;
            reflectivity = 1;
            do_fwhm = true;
            do_smooth = false;
        case 2
            do_fwhm = false;
            z = 1:Nz;
            smoothf = 5;
            reflectivity = 1;
            do_fwhm = true;
            do_smooth = false;
        case 3
            do_fwhm = false;
            smoothf = 5;
            reflectivity = 1;
            do_fwhm = true;
            do_smooth = false;
        case 4
            do_fwhm = false;
            reflectivity = 1;
            do_fwhm = true;
            do_smooth = false;
        case 5
            reflectivity = 1;
            do_fwhm = true;
            do_smooth = false;
        case 6
            do_fwhm = true;
            do_smooth = false;
        case 7
            do_smooth = false;
    end
    
    dz = mean(diff(z));
    
    hfig = figure;
    set(hfig, 'Position', [50,1080-600,1200,400])
    hsub = subplot(1,3,1);
    him = imshow(rescale(I(:,:,loc)), 'InitialMagnification', 2);
%     impixelinfo(him)
    subplot(1,3,2)
    subplot(1,3,3)
    
    set(hsub.Parent, 'Units', 'pixels');
    set(him.Parent, 'Units', 'pixels');
    set(hfig, 'WindowButtonDownFcn', @clickFig);
    set(hfig, 'WindowButtonMotionFcn', @hoverFig);
    set(hfig, 'UserData', struct('hover', [0,0], 'click', [0,0]));
    
    xy = 0;
    preData = get(hfig, 'UserData');
    rawData = get(hfig, 'UserData');
    while true
        pause(0.01)
        preData = rawData;
        try
            rawData = get(hfig, 'UserData');        
        
            if (~isequal(rawData.hover, preData.hover) || ~isequal(rawData.click, preData.click))
                hover = figPositionToPixel(rawData.hover, him);
                click = figPositionToPixel(rawData.click, him);
                if ~isempty(hover)
                    figure(hfig)
                    subplot(1,3,1)
                    title([num2str(hover(1)), ', ', num2str(hover(2))])
                    subplot(1,3,2)
%                     Iz = normalize(zprof(I, hover, true)) * reflectivity;
                    Iz = rescale(zprof(I, hover, true));
                    plot(z, Iz); hold on
                    
                    if do_smooth
                        plot(z, smooth(Iz, smoothf)); 
                    end
                    
                    hold off
                    
                    ylim([0,1])
                    subplot(1,3,3)
                    dBIz = dB(Iz);
                    dBIz_sm = smooth(dBIz,smoothf);
                    dBIz_sm_norm = dBIz_sm - max(dBIz_sm);
                    plot(z, dBIz, ':'); hold on
                    plot(z, dBIz_sm); hold off
                    ylim([-80,0])
                    title(['Dyn. range = ' num2str(-min(dBIz_sm_norm)) ' dB'])
                    if do_fwhm
                        subplot(1,3,2)
                        title(['FWHM = ' num2str(fwhm(z,smIz)) ' µm'])
                        % Find a way to break out for FWHM specifically, otherwise dB is not reached'
                    end
                end
            end
        catch ME
            if strcmp(ME.identifier, 'MATLAB:class:InvalidHandle')  % shitty way of breaking out
                break
            end
        end
    end    
end