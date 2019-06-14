classdef ROI < handle
    %SELECTION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        I
        
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
        function self = ROI(I, rect, number, slice, overlay_axis, slice_method, slice_args)
            switch nargin
                case 4
                    self.overlay.axis = overlay_axis;
                case 5
                    self.overlay.axis = overlay_axis;
                    self.slice_method = slice_method;
                case 6
                    self.overlay.axis = overlay_axis;
                    self.slice_method = slice_method;
                    self.slice_args = slice_args;
            end
            
            self.I = I;

            self.position = floor(rect.getPosition());
            self.cols = self.position(1):self.position(1)+self.position(3);
            self.rows = self.position(2):self.position(2)+self.position(4);
            self.Nz = length(self.I.position);
            self.slice = slice;
            % todo: can we trust this not to break? -> nope, we can't!
            
            self.get_binary
            
            self.compute_intensity; % what is with this dumb syntax

            self.id = get_id(number);
            self.number = number;
        end
        
        function get_image(self)
            self.image = self.slice_method(self.I.cube(self.rows,self.cols,:), self.slice, self.slice_args);
        end
        
        function get_binary(self)
            if isempty(self.image)
                self.get_image
            end
            
            self.binary = imbinarize(self.image); % todo: add more options
            
            % Erode & dilate
            SE = strel('square',2);
            self.binary = imdilate(imerode(self.binary, SE), SE);                 
        end
        
        function compute_intensity(self)           
            avgs = zeros(1,self.Nz);
            for z = 1:self.Nz
                temp = self.I.cube(self.rows,self.cols,z);
                avgs(z) = mean(temp(self.binary));
            end
            
            self.profile = avgs;
        end
        
        function [locs, pks] = get_peaks(self, MinPeakProminence)
            [pks, locs] = findpeaks(normalize2(self.profile), 'MinPeakProminence', MinPeakProminence);
        end
        
        function show(self, overlay_axis)
            switch nargin
                case 2
                    self.overlay.axis = overlay_axis;
            end
            
            if ~self.is_shown
                axes(self.overlay.axis)
                pos = self.position;
                
                if isempty(get(gca, 'Children'))                    
                    [Nx,Ny,~] = size(self.I.cube(:,:,1));
                    overlay_mask = ones(Nx,Ny);
                    self.overlay.mask = imshow(overlay_mask, 'Colormap', [0,0,0;0,1,0]);
                    set(self.overlay.mask, 'AlphaData', zeros(Nx,Ny));
                else
                    axis_objs = get(gca, 'Children');
                    self.overlay.mask = axis_objs(end); % todo:  Image is made first -> last object. This is NOT robust!
                end
                
                self.overlay.rectangle = rectangle('Position', pos, ...
                    'FaceColor', 'none', 'EdgeColor', [0, 0.8, 0.4, 0.4]);
                
                temp_mask = get(self.overlay.mask, 'AlphaData');
                temp_mask(self.rows, self.cols) = single(self.binary)*0.5;
                set(self.overlay.mask, 'AlphaData', temp_mask);  
                
                self.overlay.text = text(pos(1)-10,pos(2)+2, num2str(self.number), ...
                    'HorizontalAlignment', 'center', 'Color', [0, 0.8, 0.5], 'UserData', self.id);
            end
            
        end
        
        function in_gca = is_shown(self)
            in_gca = false;
            children = get(gca, 'Children');
            for i = 1:length(children)
                if strcmp(get(children(i), 'UserData'), self.id)
                    in_gca = true;
                end
            end 
        end
    end
end

