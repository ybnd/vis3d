classdef ocmbin < bincube   
%  Reader for .bin OCM files
%{  
            Cube:         3d image
            Position:     scan position vector
            Data:         generic additional data
                              e.g.:   fps at scan point; average or time series
                                      extra images
                                      PSI & DAQ settings
%}
    properties
        tifs                                            % references to generated .tif files (for external viewing)
    end
    properties(Hidden = true)
        cube_reduced
        header
        headerParser                                    % header tagStringParser object
        overlap                                         % bool: overlap between adjacent data regions?    
        overbytes                                       % bytes of overlap between adjacent data reions
        io_timings                                      % file i/o timing information
        datasets                                        % names of included datasets; what was the point of this?
    end
    
    methods          
        function load_data(self)
            if ~self.is_loaded
                full_read = tic;            
                self.parseMetadata();           
                self.checkOverlap();

                data_read = tic;
    %             try
                    self.extractData2()                
    %             catch
    %                 warning('Data cannot be loaded')
    %             end

                read_time = toc(data_read);     

                self.descale            

                self.io_timings.writeTime = self.MD.Time.ElapsedTime;
                self.io_timings.dataReadTime = read_time;
                self.io_timings.fullReadTime = toc(full_read);
                self.io_timings.ReadRateMBs = self.filesize_gb / read_time * 1024;
                
                self.is_loaded = true;
            end
        end
        
        function unload_data(self)
            if self.is_loaded
                self.cube = zeros(1,1,1);
                self.cube_reduced = zeros(1,1,1);
                self.position = zeros(1);
                self.data = {};
                
                self.is_loaded = false;
            end
        end
        
        function parseMetadata(self)      
            
            f = fopen(self.path, 'rb');
            fseek(f, 0, 'bof');
%             self.header = fgetl(f); 

            self.header = strcat(fread(f, 8192, '*char')');
            fclose(f);            
            
            if isempty(self.header)
                error('File has no header')
            else
            
                % reads single line of file; the first line in the file is the header
                    % However, what if this is not the case? Also: indented header is easier to read...

                % json parser gets confused when it encounters the header padding.
                
                try % or JSON oops               
                    self.MD = jsondecode(self.header);
                catch err % JSON formatting error or corrupt file
                    self.MD = jsondecode(normalize_json(self.header));
                end

                if ~isfield(self.MD, 'Data') % rename metadate fields in case older file is loaded
                    self.rename_MD_fields() 
                end
                
                self.name = self.MD.Main.File.Name;
                self.description = self.MD.Main.File.Description;

                self.MD.Main.Dir = dir(self.path);
                self.filesize = b2relevant(self.MD.Main.Dir.bytes); 
                self.filesize_gb = b2gb(self.MD.Main.Dir.bytes);
                self.MD.Main.File.FileSizeGB = self.filesize_gb;
                self.MD.Main.Dir.path = strcat(self.MD.Main.Dir.folder, '\', self.MD.Main.Dir.name);
                self.MD.Main.Dir.extension = getExtension(self.MD.Main.Dir.name);
                self.tifs = {};

                [~, sys] = memory;            
                self.memory_limit = b2gb(sys.PhysicalMemory.Available * 0.75);

                % recast data metadata fields from struct array into struct struct

                dsts = {self.MD.Data.Name};
                index = 1:length(dsts);
                self.datasets = dsts(~cellfun('isempty', dsts));
                index = index(~cellfun('isempty', dsts));
                dmd = struct;

                for i = 1:length(index)
                    dmd.(self.datasets{i}) = self.MD.Data(index(i));
                end

                self.MD.Data = dmd;

                for i = 1:length(self.datasets)
                    dataset = self.datasets{i};
                    self.MD.Data.(dataset).BytesAllocated = ...
                        self.MD.Data.(dataset).Position.StopByte - self.MD.Data.(dataset).Position.StartByte;
                    self.MD.Data.(dataset).BytesWritten = ...
                        self.MD.Data.(dataset).Position.LastByte - self.MD.Data.(dataset).Position.StartByte;
                end
            end
        end  
        
        function rename_MD_fields(self)
           oldfields = fieldnames(self.MD);
            targets = {'DataProperties', 'TimingProperties', 'MainProperties', 'CameraAttributes', 'ScanProperties'};
            replace = {'Data', 'Time', 'Main', 'CMOS', 'Scan'};
            md = struct;
            
            for i = 1:length(oldfields)
                match = strfind(oldfields, targets{i});
                index = find(not(cellfun('isempty', match)));
                md.(replace{i}) = self.MD.(oldfields{index});
            end 
            
            self.MD = md;
        end
        
        function [overlap,overbytes] = checkOverlap(self)
            % Checks the parsed metadata for overlap between separate data regions
            
            if isempty(self.datasets)
                self.datasets = fieldnames(self.MD.Data);
            end
                       
            overlap = zeros(1,length(self.datasets));
            overbytes = zeros(1,length(self.datasets));
            allocbytes = zeros(1,length(self.datasets));
            writtenbytes = zeros(1,length(self.datasets));
            
            for i = 1:length(self.datasets)
                overlap(i) = (self.MD.Data.(self.datasets{i}).Position.LastByte ...
                    > self.MD.Data.(self.datasets{i}).Position.StopByte);
                overbytes(i) = self.MD.Data.(self.datasets{i}).Position.LastByte ...
                    - self.MD.Data.(self.datasets{i}).Position.StopByte;
                allocbytes(i) = self.MD.Data.(self.datasets{i}).BytesAllocated;
                writtenbytes(i) = self.MD.Data.(self.datasets{i}).BytesWritten;
            end
            
            self.overlap = overlap;
            self.overbytes = array2table([allocbytes; writtenbytes; overbytes], ...
                'VariableNames', self.datasets, 'RowNames', {'Allocated', 'Written', 'Overlap'});
            
            if any(overlap)
               warning('Some of the data regions overlap. Average delta in bytes: %d', mean(overbytes(overbytes ~= 0)))  
            end
        end 
        
        function extractData2(self, load_mode)
            % Extracts data from the .ocmbin file ~region boundaries specified in the metadata
                % load_mode:    files larger than 75% of available RAM are loaded using memmap                
            switch nargin
                case 1 
                    load_mode = 'read';
            end
            
            fields = fieldnames(self.MD.Data);
            N = length(fields); 
            
            % OCM cube
            start = self.MD.Data.cube.Position.StartByte;
            shape = self.MD.Data.cube.Size';                    
            
            self.cube = self.readRegion(start, shape, load_mode);
            self.cube = permute(self.cube, [2,1,3]);
            i = find(strcmp(fields,'cube'));
            fields{i} = '';
            
            % Scan position vector
            start = self.MD.Data.position.Position.StartByte;
            shape = self.MD.Data.position.Size;                
           
            self.position = self.readRegion(start, shape, load_mode);            
            i = find(strcmp(fields,'position'));
            fields{i} = '';
            
            % Generic data            
            for i = 1:length(fields) % rest of the data
                if ~isempty(fields{i}) % better to 'pop' elements from the cell array...
                    start = self.MD.Data.(fields{i}).Position.StartByte;
                    shape = self.MD.Data.(fields{i}).Size';                
                    
                    self.data.(fields{i}) = self.readRegion(start, shape, load_mode);
                    
                end
            end
            
            % Scan timing data
            start = self.MD.Time.Position.StartByte;
            stop = self.MD.Time.Position.LastByte;
            timing_string = self.readRegion(start, stop-start, load_mode, 'string');
            
            try 
                sss = strsplit(timing_string, '[');
                timing_string = ['[', sss{2}];
                
                has_timing = true;
            catch
                timing_string = '';
                has_timing = false;
            end
            
            if has_timing
                try
                    self.MD.Time.Timings = jsondecode(normalize_json(timing_string));
                    timing_loaded = true;
                catch error
                    % but also catch Scan.Finished == false!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                    warning(getReport(error, 'extended', 'hyperlinks', 'on'))
                    timing_loaded = false;
                end

                if timing_loaded
                    moves = [self.MD.Time.Timings.MoveTick]'; 
                    starts = [self.MD.Time.Timings.StartTick]'; 
                    stops = [self.MD.Time.Timings.StopTick]';

                    delta_move = starts - moves;
                    delta_scan = stops - starts;
                    delta_total = stops - moves;
                    delta_log = circshift(moves,-1) - stops;

                    self.io_timings.moveTime = median(delta_move)*1e-6;
                    self.io_timings.scanTime = median(delta_scan)*1e-6;
                    self.io_timings.stepTime = median(delta_total)*1e-6;
                    self.io_timings.logTime = median(delta_log(1:end-1))*1e-6;
                end
            end
        end
        
        function I = readRegion(self, start, shape, load_mode, dtype)
            % Reads specified region in file            
            switch nargin
                case [0,1,2]
                    error('Data properties not specified')
                case 3
                    if self.size_GB < self.memory_limit
                        load_mode = 'read';
                    else
                        load_mode = 'memmap';
                    end
                    dtype = self.dtype;
                case 4
                    dtype = self.dtype;
            end
            
            
            
            dimensions = length(shape);
            len = prod(shape);
           
            
            if strcmp(load_mode, 'read')
                 switch dimensions
                        case 1                            
                            if strcmp(dtype, 'string') 
                                f = fopen(self.path, 'r');
                                fseek(f, start, -1);
                                I = fread(f, len, '*char');
                                I = I';
                            else
                                f = fopen(self.path, 'r');
                                fseek(f, start, -1);
                                I = fread(f, len, dtype);
                            end
                            fclose(f);
                        case 2
                            f = fopen(self.path, 'r');
                            fseek(f, start, -1);
                            A = fread(f, len, dtype);
                            I = reshape(A, shape)';
                            fclose(f);
                        case 3
                            f = fopen(self.path, 'r');
                            fseek(f, start, -1);
                            A = fread(f, len, dtype);
                            I = reshape(A, shape);
                            I = permute(I, [2,1,3]);
                            fclose(f);
                        otherwise
                            error('Not implemented; dimensions must be 1-3')
                 end   
                 
%                  if dimensions == 2
%                      I = I'; % transpose 2d arrays (assuming timing -> vertical)
%                  end
            elseif strcmp(load_mode, 'memmap')
                error('Size over 8 GB, to be implemented with memmap')
            end
        end
        
        function descale(self)     
            %%% Divide by MD.Data.(...).factor if needed. %%%            
        end
         
        function ij(self, zrange)
            switch nargin
                case 1
                    zrange = 1:length(self.position);
            end
            
            if ~exist('MIJ', 'class')
                Miji;
            end
            
            if isempty(self.cube_reduced)
                self.cube_reduced = uint16(rescale(self.cube, 0, 2^16));
            end
            
            MIJ.createImage(self.MD.Main.File.Name, self.cube_reduced(:,:,zrange), true);
        end
        
        function export_tif(self, normz, dB, name, path, cube) % would be easier if could see whether it was a name or not
            
            default_name = '';
            [~,~,ext] = fileparts(self.path);
            default_path = strcat(                                                                      ...
                        erase(self.path, ext), '.tif'    ...
                    );
            default_normz = 'volume';
            default_dB = false;
            
            switch nargin
                case 1
                    normz = default_normz;
                    dB = false;
                    name = default_name;
                    path = default_path;
                    cube = self.cube;
                case 2
                    dB = default_dB;
                    name = default_name;
                    path = default_path;
                    cube = self.cube;
                case 3
                    name = '';
                    path = default_path;
                    cube = self.cube;   
                case 4
                    path = appendName(default_path, name);
                    cube = self.cube;
                case 5
                    cube = self.cube;
            end          
            
            switch normz % this could be its own 3D normalization function
                case false
                    pass
                case strcmp(normz, 'volume')
                    cube = normalize(cube);
                case strcmp(normz, 'xy')
                    warning('Not implemented.')
                case strcmp(normz, 'xz')
                    warning('Not implemented.')
                case strcmp(normz, 'yz')
                    warning('Not implemented.')
                case strcmp(normz, 'z')
                    warning('Not implemented.')
            end
            
            switch dB % this could be its own 3D dB function
                case false
                    pass
                case  strcmp(dB, 'volume')
                    cube = dB(cube);
            end
            
            options.overwrite = true; % add option: save file or open saved file
            
            if self.filesize_gb > 4
                options.big = true;
            else
                options.big = false;
            end
                        
            saveastiff(cube, path, options);
            
            if ~isfield(self.MD.Main.File, 'tifs')
                self.tifs = {};
            end
            N = length(self.tifs);
            self.tifs{N+1} = path;
            
        end
        
        function tif(self, varargin)
            
            switch length(varargin)
                case 0
                    arg = 1;
                case 1
                    arg = varargin{1};
                otherwise
                    arg = 0;
            end
                       
            if isnumeric(arg)
                % numeric identifier: index in M.FileProperties.tifs list
                warning('Not yet implemented: open specified .tif file with Fiji or MIJI');
            elseif isstring(arg) || ischar(arg)
                switch arg
                    case ''
                        % select by identifier case: path or name
                        warning('Not yet implemented: open specified .tif file with Fiji or MIJI');
                end                        
            end
            
            if ~arg
                if isempty(self.tifs)
                    self.export_tif(varargin{:});
                    self.tif;
                end
            end
        end
        
        function explore(self)
            winopen(self.MD.Main.File.folder)
        end
    end    
end