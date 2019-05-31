classdef bincube < dynamicprops
% Abstract interface for 3d binary data handling    
%{
%}

    properties
        cube                                                        % 3d dataset in orientation (X,Y,Z)
        position                                                    % vertical position vector
        data                                                        % generic data struct
        MD                                                          % metadata struct
        path                                                        % file path
        name                                                        % measurement name
        description                                                 % measurement description
    end
    properties(Hidden = true)
        dtype
        filesize                                                    % size of file in bytes
        filesize_gb                                                 % size of file in GB
        memory_limit                                                % size limit for loading files into RAM
        slice_fig
        topdown_fig
        ortho_fig
        is_loaded = false
    end
    
    methods (Abstract = true)
        load_data(self);
    end
    
    methods
        function self = bincube(path, do_load, dtype)
            switch nargin
                case 1
                    dtype = '*uint32';
                    do_load = true;
                case 2
                    dtype = '*uint32';
            end
            
            self.path = path;
            self.dtype = dtype;
            
            [~, sys] = memory;            
            self.memory_limit = b2gb(sys.PhysicalMemory.Available * 0.75);
            
            if do_load
                self.load_data
            end
        end
        
        
        function unload_data(self)
            % Flush data from memory, but keep the interface & metadata
            if self.is_loaded
                self.cube = zeros(1,1,1);
                self.position = zeros(1);
                self.data = {};
                
                self.is_loaded = false;
            end
        end
        
        function zprof(self, loc, do_fwhm)
            % Interactive z-profile window
            switch nargin 
                case 1
                    loc = floor(self.position/2);
                    do_fwhm = true;
                case 2
                    do_fwhm = true;
            end
           
            live_A_scan(self.cube, loc, 1:length(self.position), 5, 1, do_fwhm, false);
        end
        
        function plane = zplane(self, k)
            % Returns the xy plane at position z(k)
            if ischar(k)
                switch k
                    case 'start'
                        k = 1;
                    case 'middle'
                        k = round(length(self.position)/2);
                    case 'end'
                        k = length(self.position);
                end
            end
            plane = normalize2(self.cube(:,:,k));
        end
        
        function slice(self, plane)
            % Slice display (scroll to scan through the cube)
            switch nargin
                case 1
                    plane = 'XY';
            end
            
            self.slice_fig = figure('Name', self.name);
            
            switch plane
                case 'XZ'
                    slice_cube = permute(self.cube, [1,3,2]);
                case 'YZ'
                    slice_cube = permute(self.cube, [2,3,1]);
                case 'ZX'
                    slice_cube = permute(self.cube, [3,1,2]);
                case 'ZY'
                    slice_cube = permute(self.cube, [3,2,1]);
                case 'YX'
                    slice_cube = permute(self.cube, [2,1,3]);
                case 'XY'
                    slice_cube = self.cube;
                otherwise
                    slice_cube = self.cube;
            end
            
            slicestack(self.slice_fig, slice_cube, @normalize_slice) % todo: should have same contrast stuff as ortho...
        end
        
        function ortho(self, M, z)
            %{ 
                Orthographic views of the cube
                    Scan over z: Scroll
                              x: Shift + Scroll
                              y: Ctrl + Scroll
            %}

            switch nargin
                case 1
                    [~, cube_Ny, ~] = size(self.cube);
                    r = monitor_resolution();
                    M = r(2) / cube_Ny / 1.8; % Default: XY image -> roughly half of max monitor height // doesn't work well with Thorlabs OCT cubes (muuch more z pixels, need to count other projections also)
                    z = 2;
                case 2
                    z = 2;
            end
            self.ortho_fig = figure('Name', self.name, 'visible', 'off');
            orthofig(self.cube, self.ortho_fig, @normalize_slice, struct(), M, z);
        end
        
        function topdown(self)
            %{
                Summed & normalize topdown projection
            %}
           self.topdown_fig = figure('Name', self.name);
           imshow_tight(normalize(sum(self.cube,3)));
        end
        
        function exlore(self)
            % Open the folder containing current file in explorer
            path_parts = strsplit(self.path, '/');
            folder = path_parts{end-1};
            
            winopen(folder)
        end
    end
end

function x = pass(x); end