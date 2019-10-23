classdef ROI < handle
    % Region of Interest
    
    properties
        C               % Cube instance
        
        position        % ROI position vector
        slice           % ROI slice
        axis = 'z';     % ROI slice axis
        
        image           % Cube image at ROI slice, cropped around ROI
        binary          % Binary image of ROI.image
        
        id
        number
        
        profile
    end
    properties(Hidden = true)
        roi_handle              % todo: currently only works with images.roi.Rectangle, other classes can be implemented https://nl.mathworks.com/help/images/roi-based-processing.html 
        cols
        rows
        Nz
        
        overlay = {}
    end
    
    methods
        function obj = ROI(C, roi_handle, number, slice, overlay_axis)
            switch nargin
                case 4
                    obj.overlay.axis = overlay_axis;
            end
            
            obj.C = C;
            obj.roi_handle = roi_handle;

            obj.position = floor(roi_handle.Position);
            obj.cols = obj.position(1):obj.position(1)+obj.position(3);
            obj.rows = obj.position(2):obj.position(2)+obj.position(4);
            obj.Nz = length(obj.C.position);
            obj.slice = slice;
            % todo: can we trust this not to break? -> nope, we can't, really!
            
            obj.get_binary
            
            obj.compute_intensity; % what is with this dumb syntax

            obj.id = obj.get_id(number);
            obj.number = number;
            
            obj.roi_handle.delete;    % todo: don't delete it: hide it, allow to 'rebuild it' to modify later
        end
        
        function [locs, pks] = get_peaks(obj, MinPeakProminence)
            [pks, locs] = findpeaks(rescale(obj.profile), 'MinPeakProminence', MinPeakProminence);
        end
        
        function show(obj, overlay_axis)
            % Show ROI overlay
            % todo: should build all overlays first, then make them visible to prevent 'snake effect'
            
            switch nargin
                case 2
                    obj.overlay.axis = overlay_axis;
            end
            
            if ~obj.is_shown
                axes(obj.overlay.axis)
                pos = obj.position;
                
                if isempty(get(gca, 'Children'))                    
                    [Nx,Ny,~] = size(obj.C.cube(:,:,1));
                    overlay_mask = ones(Nx,Ny);
                    obj.overlay.mask = imshow(overlay_mask, 'Colormap', [0,0,0;0,1,0]);
                    set(obj.overlay.mask, 'AlphaData', zeros(Nx,Ny));
                else
                    axis_objs = get(gca, 'Children');
                    obj.overlay.mask = axis_objs(end); % todo:  Image is made first -> last object. This is NOT robust!
                end
                
                obj.overlay.rectangle = rectangle('Position', pos, ...
                    'FaceColor', 'none', 'EdgeColor', [0, 0.8, 0.4, 0.4]);
                
                temp_mask = get(obj.overlay.mask, 'AlphaData');
                temp_mask(obj.rows, obj.cols) = single(obj.binary)*0.5;
                set(obj.overlay.mask, 'AlphaData', temp_mask);  
                
                obj.overlay.text = text(pos(1)-10,pos(2)+2, num2str(obj.number), ...
                    'HorizontalAlignment', 'center', 'Color', [0, 0.8, 0.5], 'UserData', obj.id);
            end
            
        end
        
    end
    methods(Access = protected)        
        function in_gca = is_shown(obj)
            in_gca = false;
            children = get(gca, 'Children');
            for i = 1:length(children)
                if strcmp(get(children(i), 'UserData'), obj.id)
                    in_gca = true;
                end
            end 
        end
        
        function get_binary(obj)
            if isempty(obj.image)
                [I, ~] = obj.C.slice(obj.slice,obj.slice);    % Only handles XY slicing for now!
                obj.image = I(obj.rows,obj.cols);
            end
            
            obj.binary = imbinarize(obj.image); % todo: add more options
            
            % Erode & dilate
            SE = strel('square',2);
            obj.binary = imdilate(imerode(obj.binary, SE), SE);                 
        end
        
        function compute_intensity(obj)           
            avgs = zeros(1,obj.Nz);
            for z = 1:obj.Nz
                temp = obj.C.cube(obj.rows,obj.cols,z);
                avgs(z) = mean(temp(obj.binary));
            end
            
            obj.profile = avgs;
        end
    end
    
    methods(Static = true)
        function id = get_id(number)
            switch nargin
                case 0
                    ordinal = '';
                case 1
                    ordinal = [num2str(number) '-'];
            end

            timing = dec2hex(floor(prod(clock)*100),9);
            random = dec2hex(randi([0,floor(1e7)],1,1),6);

            id = [ordinal, timing, '-', random];
        end
    end
end

