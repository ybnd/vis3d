classdef Cube < dynamicprops
% Abstract interface for 3d data   
%{
    - Image cubes are considered as Z-stacks of XY images
    
%}

    properties
        path                                                        % file path
        name = 'cube'                                               % measurement name
        desc = '...'                                                % measurement description
        cube = zeros(1,1,1);                                        % 3d dataset in orientation (X,Y,Z)  (don't make self.cube() to access self.data.cube() for performance & memory management reasons; otherwise it wil get copied multiple times when referenced)
        data = struct();                                            % cell array of generic data (vectors & matrices)
        meta = struct();                                            % metadata struct    
    end
    properties(Hidden = true)
        filesize                                                    % size of file in bytes
        filesize_gb                                                 % size of file in GB
        memory_limit                                                % size limit for loading files into RAM
        figures = [];
        is_loaded = false
    end
    
    methods(Access = private)
        function check_path(self)
            if ~isfile(self.path) && ~isfile(sprintf('%s.json', self.path)) && ~isempty(self.path)
                error('File does not exist: %s', self.path);
            end
        end
        
        function sobj = saveobj(self)
            sobj = self;  
            sobj.unload_data()                              
        end
        
        function [do_save, path, options] = resolve_save(self, path, options)
            do_save = true;
            
            switch nargin
                case 1
                    path = self.path;
                    options = struct();
                case 2
                    options = struct();
            end
            
            if isempty(path)
                    path = self.path;
            end
            
            if exist(path, 'file') == 2
                switch lower(input('Overwrite file? (y/n) \n', 's'))
                    case {'y', 't', '1'}
                        do_save = true;
                    case {'n', 'f', '0'}      
                        do_save = false;
                end
            end
        end
        
        function save_data(self, path, options)
            [do_save, path, ~] = self.resolve_save(path, options);

            if do_save
                path = remove_extension(path);

                meta_struct = {};
                meta_struct.name = self.name;
                meta_struct.desc = self.desc;

                dataspec = self.data_specification;

                for i = 1:length(dataspec)
                    try
                        if prod(dataspec{i}.size) > 1000
                            if strcmp(dataspec{i}.name, 'cube')
                                id = 'cube';
                                data_i = self.cube;
                            else
                                id = sprintf('data%s', num2str(i-1));  % i.e. cube is dataset 0;
                                data_i = self.data.(dataspec{i}.name);
                            end

                            savepath = sprintf('%s.%s.bin', path, id);
                            [~, savename, saveext] = fileparts(savepath);
                            dataspec{i}.path = [savename, saveext];
                            
                            fid = fopen(savepath, 'wb+');
                            fwrite(fid, data_i, dataspec{i}.dtype);
                            fclose(fid);
                        else
                            dataspec{i} = rmfield(dataspec{i}, {'size', 'dtype'});  
                            dataspec{i}.data = self.data.(dataspec{i}.name);
                        end
                    catch err
                        warning('Could not process dataspec %d \n %s', i, err.message);
                    end
                end

                meta_struct.data = dataspec;
                meta_struct.meta = self.meta;  

                fid = fopen(sprintf('%s.json', path), 'w+');
                fprintf(fid, '%s', prettyjson(jsonencode(meta_struct)));
                fclose(fid);    
            end
        end
        
        function dataspec = data_specification(self)
            % For each dataset (self.cube and all datasets in self.data), return
            %       - dataset name
            %       - size vector
            %       - datatype

            dataspec = cell(length(self.data)+1,1);

            % Cube data
            dataspec{1} = struct('name', 'cube', 'size', size(self.cube), 'dtype', class(self.cube));      

            % Arbitrary data
            datasets = fields(self.data);
            for i = 1:length(datasets)
                d = datasets{i};
                dataspec{1+i} = struct('name', datasets{i}, 'size', size(self.data.(d)), 'dtype', class(self.data.(d)));
            end
            
            % Remove empty fields from dataspec
            dataspec = dataspec(~cellfun('isempty', dataspec));
        end
    end
    
    methods
        function self = Cube(path, do_load)
            switch nargin
                case 0
                    path = '';
                    do_load = false;
                case 1
                    do_load = true;
            end

            self.path = path;
            
            [~, sys] = memory;            
            self.memory_limit = b2gb(sys.PhysicalMemory.Available * 0.75); 
             % Files larger than this limit should be opened with memmap instead of fopen

            self.check_path
            
            if do_load
                self.load_data
            end
        end        
             
        function unload(self)   % todo: refactor everything to load / unload!
            % Flush data from memory, but keep the interface & metadata
            if self.is_loaded
                self.cube = zeros(1,1,1);
                self.data = {};
                close(self.figures)
                
                self.is_loaded = false;
            end
        end
        
        function unload_data(self)
           self.unload(); 
        end
        
        function z = position(self)
            z = self.data.zpos;
        end
        
        function z = zpos(self)
            z = self.data.zpos;
        end
        
        %{
        function zprof(self, loc, do_fwhm)
            % Interactive z-profile window
            % todo: doesn't work anymore
            switch nargin 
                case 1
                    loc = floor(self.zpos/2);
                    do_fwhm = true;
                case 2
                    do_fwhm = true;
            end
           
            live_A_scan(self.cube, loc, 1:length(self.zpos), 5, 1, do_fwhm, false);
        end
        %}
        
        function plane = zplane(self, k)
            % Returns the xy plane at position z(k)
            if ischar(k)
                switch k
                    case 'start'
                        k = 1;
                    case 'middle'
                        k = round(length(self.zpos)/2);
                    case 'end'
                        k = length(self.zpos);
                end
            end
            plane = normalize2(self.cube(:,:,k));
        end
        
        function sf = slice(self, plane, method)
            % Slice display (scroll to scan through the cube)
            switch nargin
                case 1
                    plane = 'XY';
                    method = @normalize_slice;
                case 2
                    method = @normalize_slice;
            end
            
            switch lower(plane)
                case {'xz', 'zx'}
                    slice_cube = permute(self.cube, [3,1,2]);
                    plane = 'XZ';
                case {'yz', 'zy'}
                    slice_cube = permute(self.cube, [3,2,1]);
                    plane = 'YZ';
                otherwise
                    slice_cube = self.cube;
                    plane = 'XY';
            end

            f = figure('Name', sprintf('%s (%s)', self.name, plane));
            self.figures = [self.figures, f];
            
            sf = slicefig(slice_cube, f, method, struct()); % todo: should have same contrast stuff as ortho...
        end
        
        function of = ortho(self, M, z)   % todo: set default M & z ~ cube size & monitor size
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
            f = figure('Name', self.name, 'visible', 'off');
            self.figures = [self.figures, f];
            
            of = orthofig(self.cube, f, M, z);
        end
        
        function topdown(self)
            %{
                Summed & normalized topdown projection
            %}
           f = figure('Name', self.name);
           self.figures = [self.figures, f];
           
           imshow_tight(normalize(sum(self.cube,3)));
        end
        
        function explore(self)
            % Open the folder containing current file in explorer
            path_parts = strsplit(self.path, '/');
            folder = strjoin(path_parts(1:end-1), '/');
            
            if isfolder(folder)
                winopen(folder)
            else
                warning('Folder does not exist: %s', folder);
            end
        end
        
        function load_data(self)  % todo: refactor everything to load / unload!
            [folder, file, ~] = fileparts(self.path);            
            hdr = jsondecode(fileread(sprintf('%s/%s.json', folder, file)));
            
            self.name = hdr.name; self.desc = hdr.desc; self.meta = hdr.meta;
            
            for i = 1:length(hdr.data)
                try
                    d = hdr.data{i};
                catch
                    d = hdr.data;
                end
                if isfield(d,'name') && isfield(d,'data')
                    self.data.(d.name) = d.data;
                elseif isfield(d,'name') && isfield(d,'size') && isfield(d,'dtype') && isfield(d,'path')
                    fid = fopen([folder '/' d.path], 'rb+');
                    A = fread(fid, prod(d.size), d.dtype);
                    fclose(fid);
                    A = reshape(A, d.size');
                    
                    switch d.name
                        case 'cube'
                            self.cube = A;
                        otherwise
                            self.data.A = A;
                    end                    
                else
                    warning('Unrecognized specification for data field %s', d.name);                    
                end
            end            
        end
        
        function save(self, format, process, path, options)
            switch nargin
                case 1
                    format = ''; process = @pass_data; path = ''; options = struct();
                case 2
                    process = @pass_data; path = ''; options = struct();
                case 3
                    path = ''; options = struct();
                case 4
                    options = struct();
            end
            
            switch lower(format)
                case {'tif', 'tiff'}
                    tempCube = tifCube(self.path, false);
                case {'', 'bin'}
                    tempCube = Cube(self.path, false);
            end

            try
                tempCube.cube = process(self.cube);
            catch err
                warning(err.identifier, '%s', err.message);
            end
            tempCube.save_data(path, options);
        end
    end
end