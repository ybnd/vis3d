classdef Cube < dynamicprops
% Interface to 3d data   

%{
Description:
============
    - Image cubes are Z-stacks of XY images (images are confusing, so can be YX too, but that doesn't matter really)
        * obj.cube                     3d matrix
    - Additional data in obj.data
        * obj.data.zpos                physical position of each cube in the stack
                                            does not take into account the units; this is up to you & common sense
        * ...
    - Optional metadata in obj.meta

    
File format & i/o:
==================
    - Consists of a <path>.json header file, a <path>.cube file (binary) and i optional <path>.data<i> files (binary)
        * The dimensions and data types of the binary files are listed in the header
        * Additional data arrays with dimensions smaller than 640x480 are stored directly in the header
        * Measurement name, description and optional metadata are listed in the header
%}

    properties
        path                                                        % file path
        name = 'cube'                                               % measurement name
        desc = '...'                                                % measurement description
        cube = zeros(1,1,1);                                        % 3d dataset in orientation (X,Y,Z)  (don't make obj.cube() method to access obj.data.cube() for performance & memory management reasons; otherwise it wil get copied multiple times when referenced!)
        data = struct();                                            % cell array of generic data (vectors & matrices)
        meta = struct();                                            % metadata struct    
    end
    properties(Hidden = true)
        range
        
        selectors                                                   % Struct of InteractiveMethodSelector instances: see interactive_methods.m
        filesize                                                    % size of file in bytes
        filesize_gb                                                 % size of file in GB
        figures = [];                                               % handles to open figures
        is_loaded = false           
        mfmt = 'ieee-le';
        minsize = 640 * 480;                                        % everything smaller than a VGA image -> save in .json to limit number of separate files
    end
    
    %% Initialization
    methods
        function obj = Cube(path, do_load)
            % Initializes a Cube instance. 
            % To create an interface to a 3d image file without opening it, call with do_load=false
            
            switch nargin
                case 0
                    path = '';
                    do_load = false;
                case 1
                    do_load = true;
            end

            % Cast path to char
            obj.path = char(path);
            
            obj.check_path
            
            obj.selectors = interactive_methods;
            
            if do_load
                obj.load
                obj.get_range()
            end
        end    
    end
    
    %% File I/O methods    
    methods(Access = public)        
        function sobj = saveobj(obj)
            % Invoked when saving a Cube instance to a .mat file
            %   * Cube instances loaded from .mat files can be used after calling obj.load to load their data
            %   * Keep in mind that old .mat files contain OLD IMPLEMENTATIONS, and will not work 
            
            sobj = obj;  
            sobj.unload()                              
        end
        
        function load(obj)
            % Load data in json/binary format
            
            [folder, file, ~] = fileparts(obj.path);    
            
            % Read & load the .json header file
            header = jsondecode(fileread(sprintf('%s/%s.json', folder, file)));            
            obj.name = header.name; obj.desc = header.desc; obj.meta = header.meta;
            
            % Load datasets in header's 'data' field
            for i = 1:length(header.data)
                try
                    d = header.data{i};
                catch
                    d = header.data;
                end
                if isfield(d,'name') && isfield(d,'size') && isfield(d,'type') && isfield(d,'path')
                    % Large dataset -> load from binary file
                    
                    try
                        machinefmt = d.mfmt;
                    catch err
                        warning(err.message)
                        sprintf('Default machinefmt: %s', obj.mfmt);
                        machinefmt = obj.mfmt;
                    end
                    
                    switch lower(machinefmt)
                        case {'little-endian', 'le', 'ieee-le'}
                            machinefmt = 'ieee-le';
                        case {'big-endian', 'be', 'ieee-be'}
                            machinefmt = 'ieee-be';
                    end
                    
                    % Read from binary file & trasnform to correct shape
                    fid = fopen([folder '/' d.path], 'rb+');   
                    A = cast(fread(fid, prod(d.size), d.type, 0, machinefmt), d.type);
                    fclose(fid);
                    A = reshape(A, d.size');
                    
                    switch d.name
                        case 'cube'
                            obj.cube = A;
                        otherwise
                            obj.data.(d.name) = A;
                    end                    
                elseif length(fields(d)) == 1
                    % Small dataset -> load from header
                    dfields = fields(d);
                    obj.data.(dfields{1}) = d.(dfields{1});
                else
                    warning('Unrecognized specification for data field %s', d);                    
                end
            end            
        end        
        
        function unload(obj)
            % Flush data from memory, but keep the interface & metadata
            if obj.is_loaded
                obj.cube = zeros(1,1,1);
                obj.data = {};
                close(obj.figures)
                
                obj.is_loaded = false;
            end
        end
        
        function save(obj, path)
            % Save obj data in json/binary format
            
            switch nargin
                case 1
                    path = '';
            end
            
            if isempty(path)
               path = remove_extension(obj.path); 
            end
            
            [do_save, path] = obj.resolve_save(path);

            if do_save
                path = remove_extension(path);

                meta_struct = {};
                meta_struct.name = obj.name;
                meta_struct.desc = obj.desc;

                % For each dataset (obj.cube and all datasets in obj.data), return
                %       - dataset name
                %       - size vector
                %       - datatype

                dataspec = cell(length(obj.data)+1,1);

                % Cube data
                dataspec{1} = struct( ...
                    'name', 'cube', 'size', size(obj.cube), 'type', class(obj.cube), 'mfmt', obj.mfmt ...
                );      

                % Arbitrary data
                datasets = fields(obj.data);
                for i = 1:length(datasets)
                    d = datasets{i};
                    dataspec{1+i} = struct( ...
                        'name', datasets{i}, 'size', size(obj.data.(d)), ...
                        'type', class(obj.data.(d)), 'mfmt', obj.mfmt);
                end

                % Remove empty fields from dataspec
                dataspec = dataspec(~cellfun('isempty', dataspec));

                
                for i = 1:length(dataspec)
                    try
                        if prod(dataspec{i}.size) > obj.minsize || strcmp(dataspec{i}.name, 'cube')
                            % Large dataset -> save to a binary file (always save obj.cube to binary)
                            if strcmp(dataspec{i}.name, 'cube')
                                id = 'cube';
                                data_i = obj.cube;
                            else
                                id = sprintf('data%s', num2str(i-2));  % i.e. cube is dataset 0;
                                data_i = obj.data.(dataspec{i}.name);
                            end
                            
                            savepath = sprintf('%s.%s', path, id);
                            [~, savename, saveext] = fileparts(savepath);
                            dataspec{i}.path = [savename, saveext];
                            
                            fid = fopen(savepath, 'wb+');
                            fwrite(fid, data_i, dataspec{i}.type, dataspec{i}.mfmt);
                            fclose(fid);
                        else
                            % Small dataset -> save to .json
                            dataspec{i}.(dataspec{i}.name) = obj.data.(dataspec{i}.name);
                            dataspec{i} = rmfield(dataspec{i}, {'size', 'type', 'name', 'mfmt'});                              
                        end
                    catch err
                        warning('Could not process dataspec %d \n %s', i, err.message);
                    end
                end

                meta_struct.data = dataspec;
                meta_struct.meta = obj.meta;  

                % Write .json file
                fid = fopen(sprintf('%s.json', path), 'w+');
                fprintf(fid, '%s', prettyjson(jsonencode(meta_struct)));
                fclose(fid);    
            end
        end
    end
    
    methods(Access = protected)        
        function [do_save, path] = resolve_save(obj, path)
            % Save to obj.path if 'path' not specified.            
            do_save = true;
            
            switch nargin
                case 1
                    path = remove_extension(obj.path);
            end
            
            % If 'path' already exists, prompt user whether to overwrite
            if exist(path, 'file') == 2 || exist([path, '.json'], 'file') == 2
                switch lower(input(sprintf('Overwrite file %s? (y/n) \n', strrep(path, '\', '\\')), 's'))
                    case {'y', 't', '1'}
                        do_save = true;
                    case {'n', 'f', '0'}      
                        do_save = false;
                end
            end
        end
        
        function check_path(obj)
            if ~isfile(obj.path) && ~isfile(sprintf('%s.json', obj.path)) && ~isempty(obj.path)
                error('File does not exist: %s', obj.path);
            end
        end
    end
    
    %% High-level interface to Cube data
    methods(Access=public)                
        function of = of(obj, M, z)
            %{ 
                Orthographic views of obj.cube
                    Scan over z: Scroll
                              x: Shift + Scroll
                              y: Alt + Scroll
                    Figsize +/-: Ctrl + Scroll
            %}
            
            switch nargin
                case 1
                    M = NaN;  % todo: triggers the following if statement (ugly ugh)
                    z = NaN;     
                case 2
                    z = NaN;
            end
            
            if isnan(M) && isnan(z)
                [~, cube_Ny, cube_Nz] = size(obj.cube);
                r = monitor_resolution();
                z = min([2, r(2) / cube_Nz * (2/5)]); % Default: XZ image -> 1/3 of max monitor height or 2 if too large
                if z == 2
                    M = r(2) / cube_Ny * (3/5); % Default: XY image -> 2/3 of max monitor height // doesn't work well with Thorlabs OCT cubes (muuch more z pixels, need to count other projections also)
                else
                    M = r(2) / cube_Ny * (2/5); % Default: XY image -> 2/3 of max monitor height // doesn't work well with Thorlabs OCT cubes (muuch more z pixels, need to count other projections also)
                end
            elseif isnan(z)
                z = 2;
            end
            
            f = figure('Name', obj.name, 'visible', 'off');
            obj.figures = [obj.figures, f];
            
            of = orthofig(obj, f, M, z);
        end
        
        function sf = sf(obj, plane, M, f)
            % Slice view of obj.cube (scroll to scan through the cube)
            
            switch nargin
                case 1
                    plane = 'XY';
                    M = NaN;
                    f = figure('Name', sprintf('%s (%s)', obj.name, upper(plane)));
                    obj.figures = [obj.figures, f];
                case 2
                    M = NaN;
                    f = figure('Name', sprintf('%s (%s)', obj.name, upper(plane)));
                    obj.figures = [obj.figures, f];
                case 3
                    f = figure('Name', sprintf('%s (%s)', obj.name, upper(plane)));
                    obj.figures = [obj.figures, f];
            end         
            
            switch lower(plane)
                case {'xz', 'zx'}
                    slice_axis = 'y';
                case {'yz', 'zy'}
                    slice_axis = 'x';
                case 'x'
                    slice_axis = 'x';
                case 'y' 
                    slice_axis = 'y';
                otherwise
                    slice_axis = 'z';
            end
            
            if isnan(M)
                switch slice_axis
                    case {'z','y'}
                        [~, vertical, ~] = size(obj.cube);
                    case 'x'
                        [~, ~, vertical] = size(obj.cube);
                end
                r = monitor_resolution();
                M = r(2) / vertical * (3/7); % Default: XY image -> 2/3 of max monitor height // doesn't work well with Thorlabs OCT cubes (muuch more z pixels, need to count other projections also)
            end
  
            sf = slicefig(obj, f, M, slice_axis); % todo: should have same contrast stuff as ortho...
        end
        
        function zprof(obj, loc, do_fwhm)
            % Interactive z-profile figure
            % Move the cursor over the leftmost figure to plot profiles at those coordinates (XY) in the other figures
            switch nargin 
                case 1
                    loc = floor(length(obj.zpos/2));
                    do_fwhm = true;
                case 2
                    do_fwhm = true;
            end
           
            live_A_scan(obj.cube, loc, obj.zpos, 5, 1, do_fwhm, false);
        end
        
        function explore(obj)
            % Open the folder containing obj.path in explorer
            path_parts = strsplit(obj.path, '/');
            folder = strjoin(path_parts(1:end-1), '/');
            
            if isfolder(folder)
                winopen(folder)
            else
                warning('Folder does not exist: %s', folder);
            end
        end
    end
    
    %% Lower-level interface to Cube data
    methods(Access=public)               
        function z = zpos(obj)
            % Returns the Z-position vector
            %   * If there is no explicit Z-position vector, returns a vector of indeces in the Z axis
            
            if isfield(obj.data, 'zpos')
                z = obj.data.zpos;
            else
                [~,~,Nz] = size(obj.cube);
                z = 1:Nz;
            end
        end
        
        function z = position(obj)
            % Alias for obj.zpos
            z = obj.zpos();
        end
        
        function get_range(obj)
            if isempty(obj.range)
                if ~isempty(obj.cube)
                    obj.range = [rmin(obj.cube), rmax(obj.cube)];
                    obj.im_set('global range', obj.range);
                else
                    obj.range = [0 2^32];
                    warning('Could not get global range: data not loaded!')
                end
            end
        end
    end
    
    %% Interface to InteractiveMethods
    methods(Access=public)
        function [slice, raw_slice] = slice(obj, k, axis, slice, postprocess)
            % Returns a slice of obj.cube at index k on axis using the selected slicing method
            %   * Postprocess using the selected postprocess method; also return a 'raw' slice.
            
            switch nargin
                case 3
                    slice = obj.selectors.slice;
                    postprocess = obj.selectors.postprocess;
            end
            
            raw_slice = slice.selected.do(obj.cube, k, axis);
            slice = postprocess.selected.do(raw_slice);
        end
        
        function [slice, postprocess] = copy_selectors(obj)
            % Returns handles to 'slice' and 'postprocess' InteractiveMethodSelectors
            %   * Should be used when adding InteractiveMethodSelector UI elements for a Cube instance to a figure
            slice = copy(obj.selectors.slice);
            postprocess = copy(obj.selectors.postprocess);
        end
        
        function im_update(obj)
            % Update selectors (keep current)
            try
                slice_method = obj.selectors.slice.get_state();
                postprocess_method = obj.selectors.postprocess.get_state();

                obj.selectors = interactive_methods;

                obj.selectors.slice.set_state(slice_method);
                obj.selectors.postprocess.set_state(postprocess_method);
            catch err
                warning(err.message)
                obj.selectors = interactive_methods;
            end
            
            % Set global range for postprocess methods
            
            obj.selectors.postprocess.set('global range', obj.range);
        end
        
        function im_select(obj, varargin) 
            % For InteractiveMethodSelector 'selector', select InteractiveMethod 'method' 
            %   * 'selector' and 'method' must match exactly; see interactive_methods.m for details.
            found_match = false;            
            selector_fields = fields(obj.selectors);
            for i = 1:length(selector_fields)               
               selector = obj.selectors.(selector_fields{i});    
               
               for j = 1:(length(varargin))
                   if any(strcmp(varargin{j},fields(selector.items)))
                       selector.select(varargin{j});
                       found_match = true;
                   end
               end
            end
            
            if ~found_match
                warning('InteractiveMethod(s) %s is/are not defined in InteractiveMethodSelector(s) %s', ...
                    strjoin(varargin, ', '), strjoin(selector_fields, ', '))
            end
        end
        
        function im_set(obj, varargin)
            % Sets any number of InteractiveMEthod parameters, specified as 'parameter', value
            %   * Searches for 'parameter' in all InteractiveMethods in all InteractiveMethodSelectors
            %       -> setting values through GUI is more efficient
            %   * 'parameter' must match exactly, see innteractive_methods.m for details.
            for i = 1:length(fields(obj.selectors))
               selector_fields = fields(obj.selectors);
               selector = obj.selectors.(selector_fields{i});
               
               for j = 1:(length(varargin)/2)
                   selector.set(varargin{2*(j-1)+1}, varargin{2*(j-1)+2})
               end
            end
        end
        
        function im_reset(obj, varargin)
            % Resets InteractiveMethod parameters (separated by commas) to their default value
            %   'selector' and 'method' must match exactly; see interactive_methods.m for details.
            
            % todo: if varargin is empty: reset everything to default
            for i = 1:length(fields(obj.selectors))
               selector_fields = fields(obj.selectors);
               selector = obj.selectors.(selector_fields{i});
               
               for j = 1:length(varargin)
                   selector.reset(varargin{j})
               end
            end
        end
        
        function [values] = im_get(obj, varargin)
            % Returns current values of parameters (separated by comma) of all InteractiveMethod instances in all 
            % InteractiveMethodSelector instances in a structure array
            
            % For a 'readable' overview: prettyjson(jsonencode(Cube.im_get()))
            
            values = cell(1,length(varargin));
            for i = 1:length(fields(obj.selectors))
               
               selector_fields = fields(obj.selectors);
               selector = obj.selectors.(selector_fields{i});
               
               for j = 1:length(varargin)
                   v = selector.get(varargin{j});
                   if ~isempty(v)
                       values{j} = v;
                   end
               end
            end
            
            if length(values) == 1
               values = values{1}; 
            end
        end
    end
end