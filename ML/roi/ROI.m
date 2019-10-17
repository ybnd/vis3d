classdef ROI < handle
    % Region of Interest
    
    properties
        C
        
        rect % todo: maybe add option to select ellipse instead of rectangle
        position

        id
        number
        
        cols % todo: hide thise ones
        rows
        Nz
        slice
        
        slice_method = @normalize_slice
        slice_args = []
        image
        binary
        mask
        
        profile
        
        overlay = {}
    end
    
    methods
        function obj = ROI(C, rect, number, slice, overlay_axis)
            switch nargin
                case 4
                    obj.overlay.axis = overlay_axis;
            end
            
            obj.C = C;
            obj.rect = rect;

            obj.position = floor(rect.Position);
            obj.cols = obj.position(1):obj.position(1)+obj.position(3);
            obj.rows = obj.position(2):obj.position(2)+obj.position(4);
            obj.Nz = length(obj.C.position);
            obj.slice = slice;
            % todo: can we trust this not to break? -> nope, we can't!
            
            obj.get_binary
            
            obj.compute_intensity; % what is with this dumb syntax

            obj.id = get_id(number);
            obj.number = number;
            
            obj.rect.delete;    % what if: don't delete it, make it modifyable?
        end
        
        function get_image(obj)
            [I, ~] = obj.C.slice(obj.slice,'z');    % Only handles XY slicing
            obj.image = I(obj.rows,obj.cols);
        end
        
        function get_binary(obj)
            if isempty(obj.image)
                obj.get_image
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
        
        function [locs, pks] = get_peaks(obj, MinPeakProminence)
            [pks, locs] = findpeaks(normalize2(obj.profile), 'MinPeakProminence', MinPeakProminence);
        end
        
        function show(obj, overlay_axis)
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
        
        function in_gca = is_shown(obj)
            in_gca = false;
            children = get(gca, 'Children');
            for i = 1:length(children)
                if strcmp(get(children(i), 'UserData'), obj.id)
                    in_gca = true;
                end
            end 
        end
    end
end

