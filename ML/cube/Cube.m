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
        im
        filesize                                                    % size of file in bytes
        filesize_gb                                                 % size of file in GB
        figures = [];
        is_loaded = false
        mfmt = 'ieee-le';
        minsize = 640 * 480;                                        % everything smaller than a VGA image -> save in .json to limit number of separate files
        
%         postprocess = struct( ...  % define a set of postprocessing methods (see CubePostprocess.m for details)
%             'dBs', CubePostprocess({@(I,floor,ceil) dBs(I,floor,ceil)}, {{0,90}}, @single) , ...
%             'norm_u16', CubePostprocess({@(I) rescale(I,0,2^16-1), @uint16}, {{},{}}, @single, 'cube') ...
%         )    
% TODO: should be implemented as a stand-alone function instead;
% TODO: should slice/postprocess be a Cube-level thing, or a cubefig-level thing?
% TODO:    ...right now, Cube-level makes more sense...
% TODO:    ...specifics (like default settings, possible methods) can be overridden in Cube subclasses, e.g. ocmCube may have different default settings for the 'dBs' PostprocessMethod, or thorCube may have a different list of PostprocessMethods to begin with
    
    end
    
    methods(Access = public)
        function check_path(obj)
            if ~isfile(obj.path) && ~isfile(sprintf('%s.json', obj.path)) && ~isempty(obj.path)
                error('File does not exist: %s', obj.path);
            end
        end
        
        function sobj = saveobj(obj)
            sobj = obj;  
            sobj.unload_data()                              
        end
        
        
        
        function save_data(obj, path, options)
            switch nargin
                case 1
                    path = '';
                    options = struct();
                case 2
                    options = struct();
            end
            
            [do_save, path, ~] = obj.resolve_save(path, options);

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
                dataspec{1} = struct('name', 'cube', 'size', size(obj.cube), 'type', class(obj.cube));      

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
                        if prod(dataspec{i}.size) > obj.minsize 
                            if strcmp(dataspec{i}.name, 'cube') % todo: maybe reverse order of check; never try to save cube in .json
                                id = 'cube';
                                data_i = obj.cube;
                            else
                                id = sprintf('data%s', num2str(i-2));  % i.e. cube is dataset 0;
                                data_i = obj.data.(dataspec{i}.name);
                            end
                            
                            if ~isfield(dataspec{i}, 'mfmt')
                               dataspec{i}.mfmt = 'ieee-le'; % Little-endian encoding by default
                            end

                            savepath = sprintf('%s.%s', path, id);
                            [~, savename, saveext] = fileparts(savepath);
                            dataspec{i}.path = [savename, saveext];
                            
                            fid = fopen(savepath, 'wb+');
                            fwrite(fid, data_i, dataspec{i}.type, dataspec{i}.mfmt);
                            fclose(fid);
                        else
                            dataspec{i}.(dataspec{i}.name) = obj.data.(dataspec{i}.name);
                            dataspec{i} = rmfield(dataspec{i}, {'size', 'type', 'name'});                              
                        end
                    catch err
                        warning('Could not process dataspec %d \n %s', i, err.message);
                    end
                end

                meta_struct.data = dataspec;
                meta_struct.meta = obj.meta;  

                fid = fopen(sprintf('%s.json', path), 'w+');
                fprintf(fid, '%s', prettyjson(jsonencode(meta_struct)));
                fclose(fid);    
            end
        end
    end
    
    methods
        function obj = Cube(path, do_load)
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
            
            obj.im = interactive_methods;
            
            if do_load
                obj.load_data
            end
        end        
             
        function unload(obj)   % todo: refactor everything to load / unload!
            % Flush data from memory, but keep the interface & metadata
            if obj.is_loaded
                obj.cube = zeros(1,1,1);
                obj.data = {};
                close(obj.figures)
                
                obj.is_loaded = false;
            end
        end
        
        function unload_data(obj)
           obj.unload(); 
        end
        
        function z = position(obj)
            z = obj.data.zpos;
        end
        
        function z = zpos(obj)
            if isfield(obj.data, 'zpos')
                z = obj.data.zpos;
            else
                [~,~,Nz] = size(obj.cube);
                z = 1:Nz;
            end
        end
        
        function zprof(obj, loc, do_fwhm)
            % Interactive z-profile window
            % todo: doesn't work anymore
            switch nargin 
                case 1
                    loc = floor(length(obj.zpos/2));
                    do_fwhm = true;
                case 2
                    do_fwhm = true;
            end
           
            live_A_scan(obj.cube, loc, obj.zpos, 5, 1, do_fwhm, false);
        end
        
        function [slice, raw_slice] = slice(obj, k, axis)
            % todo: this will probably break if GUI is not initialized!
            raw_slice = obj.im.selectors.slice.selected.do(obj.cube, k, axis);
            slice = obj.im.selectors.postprocess.selected.do(raw_slice);
        end
        
        function of = ortho(obj, M, z)
            %{ 
                Orthographic views of the cube
                    Scan over z: Scroll
                              x: Shift + Scroll
                              y: Ctrl + Scroll
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
        
        function explore(obj)
            % Open the folder containing current file in explorer
            path_parts = strsplit(obj.path, '/');
            folder = strjoin(path_parts(1:end-1), '/');
            
            if isfolder(folder)
                winopen(folder)
            else
                warning('Folder does not exist: %s', folder);
            end
        end
        
        function load_data(obj)  % todo: refactor everything to load / unload!
            [folder, file, ~] = fileparts(obj.path);            
            header = jsondecode(fileread(sprintf('%s/%s.json', folder, file)));
            
            obj.name = header.name; obj.desc = header.desc; obj.meta = header.meta;
            
            for i = 1:length(header.data)
                try
                    d = header.data{i};
                catch
                    d = header.data;
                end
                if isfield(d,'name') && isfield(d,'data')
                    obj.data.(d.name) = d.data;
                elseif isfield(d,'name') && isfield(d,'size') && isfield(d,'type') && isfield(d,'path')
                    fid = fopen([folder '/' d.path], 'rb+');
                    
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
                    end
                    
                    A = cast(fread(fid, prod(d.size), d.type, 0, machinefmt), d.type);
                    fclose(fid);
                    A = reshape(A, d.size');
                    
                    switch d.name
                        case 'cube'
                            obj.cube = A;
                        otherwise
                            obj.data.A = A;
                    end                    
                elseif length(fields(d)) == 1
                    dfields = fields(d);
                    obj.data.(dfields{1}) = d.(dfields{1});
                else
                    warning('Unrecognized specification for data field %s', d);                    
                end
            end            
        end
        
        function [do_save, path, options] = resolve_save(obj, path, options)
            do_save = true;
            
            switch nargin
                case 1
                    path = '';
                    options = struct();
                case 2
                    options = struct();
            end
            
            if isempty(path)
                    path = remove_extension(obj.path);
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
        
        function save(obj, fmt, process, path, options)
            switch nargin
                case 1
                    fmt = ''; process = @pass_data; path = ''; options = struct();
                case 2
                    process = @pass_data; path = ''; options = struct();
                case 3
                    path = ''; options = struct();
                case 4
                    options = struct();
            end
            
            switch lower(fmt)
                case {'tif', 'tiff'}
                    tempCube = tifCube(obj.path, false);
                case {'', '.cube', '.json'}
                    tempCube = Cube(obj.path, false);
            end

            try
                tempCube.cube = process(obj.cube);
            catch err
                warning(err.identifier, '%s', err.message);
            end
            tempCube.save_data(path, options);
        end
    end
end