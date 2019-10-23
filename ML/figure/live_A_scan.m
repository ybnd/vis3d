function live_A_scan(I, loc, z, smoothf, reflectivity, do_fwhm, do_smooth)
    % Continuous A_scan display ~ mouse hover point
    % Click mouse -> fix current A_scan on the plot, overlay on others / continuous plot
    
    % todo: maybe document
    % fixme: i'm broken inside
    % No: this thing is only occasionally useful, and it seems to kinda work. whatever.

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
    
    function hoverFig(src, ~)
        % Get the coordinates of the clicked point
    %     hax = ancestor(src, 'axes');
        point = get(src, 'CurrentPoint');
        point = round(point(1,1:2));

        % Make it so we can't click on the image multiple times
        set(src, 'ButtonDownFcn', '')

        % Store the point in the UserData which will cause the outer function to resume
    %     set(src, 'UserData', point);

        userData = get(src, 'UserData');
        userData.hover = point;
        set(src, 'UserData', userData);
    end

    function clickFig(src, ~)
        % Get the coordinates of the clicked point
    %     hax = ancestor(src, 'axes');
        point = get(src, 'CurrentPoint');
        point = round(point(1,1:2));

        % Make it so we can't click on the image multiple times
        set(src, 'ButtonDownFcn', '')

        % Store the point in the UserData which will cause the outer function to resume
    %     set(src, 'UserData', point);

        userData = get(src, 'UserData');
        userData.click = point;
        set(src, 'UserData', userData);
    end

    function [img_xy] = figPositionToPixel(fig_xy, img)
    % todo: document me

        switch nargin
            case 0
                error('No positon input given.')
            case 1
                img = gca(); fig = gcf();
            case 2
                fig = gcf();
        end
        if ~isempty(fig_xy)
            x = fig_xy(1); y = fig_xy(2);

            resolution = [img.XData(2), img.YData(2)];
            AR = resolution(1)/resolution(2);

            % Position vectors: [left bottom width height]        
            axe = img.Parent;

            left = axe.Position(1);
            width = axe.Position(3);
            right = left + width;        

    %         bottom = axe.Position(2);
    %         height = axe.Position(4);
    %         top = bottom + height;
            height = width / AR;
            bottom = axe.Position(2) + axe.Position(4)/2 - height/2; 
            top = bottom + height;    

            if ( (left < x)&&(x < right) ) && ( (bottom< y)&&(y < top) )  
                % cursor is over image box    


                img_xy = uint16([ (x-left)/width (y-bottom)/height ].*resolution);

                if img_xy(1) >= resolution(1)-2
                    img_xy(1) = resolution(1);
                end
                if img_xy(2) >= resolution(2)
                    img_xy(2) = resolution(2)-2;
                end

                if img_xy(1) == 0
                    img_xy(1) = 2;
                end
                if img_xy(2) == 0
                    img_xy(2) = 2;
                end
            else
                img_xy = [];
            end
        else        
            img_xy = [];
        end
    end
    
end