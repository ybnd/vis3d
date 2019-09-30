classdef ocmCube < Cube   
%  Reader for .bin OCM files
%{  
            Cube:         3d image
            Position:     scan position vector
            Data:         generic additional data
                              e.g.:   fps at scan point; average or time series
                                      extra images
                                      PSI & DAQ settings
%}
    properties(Hidden = true)
        cube_reduced
        header
        overlap                                         % bool: overlap between adjacent data regions?    
        overbytes                                       % bytes of overlap between adjacent data reions
        io_timings                                      % file i/o timing information
        datasets                                        % names of included datasets; what was the point of this?
        dtype = '*uint32';
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

                self.io_timings.writeTime = self.meta.Time.ElapsedTime;
                self.io_timings.dataReadTime = read_time;
                self.io_timings.fullReadTime = toc(full_read);
                self.io_timings.ReadRateMBs = self.filesize_gb / read_time * 1024;
                
                self.is_loaded = true;
            end
        end

        function ij(self, zrange)
            switch nargin
                case 1
                    zrange = 1:length(self.zpos);
            end
            
            if ~exist('MIJ', 'class')
                Miji;
            end
            
            if isempty(self.cube_reduced)
                self.cube_reduced = uint16(rescale(self.cube, 0, 2^16));
            end
            
            MIJ.createImage(self.meta.Main.File.Name, self.cube_reduced(:,:,zrange), true);
        end
    end   
    
    methods(Access = private)
        function parseMetadata(self)      
            
            f = fopen(self.path, 'rb');
            fseek(f, 0, 'bof');
%             self.header = fgetl(f); 

%             self.header = strcat(fread(f, 8192, '*char')');

            header_candidate = strcat(fread(f, 8192, '*char')');
            try
                meta_candidate = jsondecode(header_candidate);
                self.meta = meta_candidate;
                self.header = header_candidate;
            catch err
                try % or JSON oops               
                    header_candidate = strcat(fread(f, 32768, '*char')');  % New file spec - longer header
                    meta_candidate = jsondecode(header_candidate);
                    self.meta = meta_candidate;
                    self.header = header_candidate;
                catch err2 % JSON formatting error or corrupt file
                    warning(err2.identifier, '%s', err2.message);
                    self.meta = jsondecode(normalize_json(self.header));
                end
            end

            fclose(f);            
            
            if isempty(self.header)
                error('File has no header')
            else
            
                % reads single line of file; the first line in the file is the header
                    % However, what if this is not the case? Also: indented header is easier to read...

                % json parser gets confused when it encounters the header padding.
                
                

                if ~isfield(self.meta, 'Data') % rename metadate fields in case older file is loaded
                    self.rename_MD_fields() 
                end
                
                self.name = self.meta.Main.File.Name;
                self.desc = self.meta.Main.File.Description;

                self.meta.Main.Dir = dir(self.path);
                self.filesize = b2relevant(self.meta.Main.Dir.bytes); 
                self.filesize_gb = b2gb(self.meta.Main.Dir.bytes);
                self.meta.Main.File.FileSizeGB = self.filesize_gb;
                self.meta.Main.Dir.path = strcat(self.meta.Main.Dir.folder, '\', self.meta.Main.Dir.name);
                self.meta.Main.Dir.extension = getExtension(self.meta.Main.Dir.name);

                % recast data metadata fields from struct array into struct struct

                dsts = {self.meta.Data.Name};
                index = 1:length(dsts);
                self.datasets = dsts(~cellfun('isempty', dsts));
                index = index(~cellfun('isempty', dsts));
                dmd = struct;

                for i = 1:length(index)
                    dmd.(self.datasets{i}) = self.meta.Data(index(i));
                end

                self.meta.Data = dmd;

                for i = 1:length(self.datasets)
                    dataset = self.datasets{i};
                    self.meta.Data.(dataset).BytesAllocated = ...
                        self.meta.Data.(dataset).Position.StopByte - self.meta.Data.(dataset).Position.StartByte;
                    self.meta.Data.(dataset).BytesWritten = ...
                        self.meta.Data.(dataset).Position.LastByte - self.meta.Data.(dataset).Position.StartByte;
                end
            end
        end  
        
        function rename_MD_fields(self)
           oldfields = fieldnames(self.meta);
            targets = {'DataProperties', 'TimingProperties', 'MainProperties', 'CameraAttributes', 'ScanProperties'};
            replace = {'Data', 'Time', 'Main', 'CMOS', 'Scan'};
            md = struct;
            
            for i = 1:length(oldfields)
                match = strfind(oldfields, targets{i});
                index = find(not(cellfun('isempty', match)));
                md.(replace{i}) = self.meta.(oldfields{index});
            end 
            
            self.meta = md;
        end
        
        function [overlap,overbytes] = checkOverlap(self)
            % Checks the parsed metadata for overlap between separate data regions
            
            if isempty(self.datasets)
                self.datasets = fieldnames(self.meta.Data);
            end
                       
            overlap = zeros(1,length(self.datasets));
            overbytes = zeros(1,length(self.datasets));
            allocbytes = zeros(1,length(self.datasets));
            writtenbytes = zeros(1,length(self.datasets));
            
            for i = 1:length(self.datasets)
                overlap(i) = (self.meta.Data.(self.datasets{i}).Position.LastByte ...
                    > self.meta.Data.(self.datasets{i}).Position.StopByte);
                overbytes(i) = self.meta.Data.(self.datasets{i}).Position.LastByte ...
                    - self.meta.Data.(self.datasets{i}).Position.StopByte;
                allocbytes(i) = self.meta.Data.(self.datasets{i}).BytesAllocated;
                writtenbytes(i) = self.meta.Data.(self.datasets{i}).BytesWritten;
            end
            
            self.overlap = overlap;
            self.overbytes = array2table([allocbytes; writtenbytes; overbytes], ...
                'VariableNames', self.datasets, 'RowNames', {'Allocated', 'Written', 'Overlap'});
            
            if any(overlap)
               warning('Some of the data regions overlap. Average delta in bytes: %d', mean(overbytes(overbytes ~= 0)))  
            end
        end 
        
        function extractData2(self)
            % Extracts data from the .ocmbin file ~region boundaries specified in the metadata
                % load_mode:    files larger than 75% of available RAM are loaded using memmap                
            
            fields = fieldnames(self.meta.Data);
            
            % OCM cube
            start = self.meta.Data.cube.Position.StartByte;
            shape = self.meta.Data.cube.Size';      
            type = ['*' self.meta.Data.cube.dtype];
            
            self.cube = self.readRegion(start, shape, type);
            self.cube = permute(self.cube, [2,1,3]);
            i = find(strcmp(fields,'cube'));
            fields{i} = '';
            
            % Scan position vector
            start = self.meta.Data.position.Position.StartByte;
            shape = self.meta.Data.position.Size;   
            type = ['*' self.meta.Data.position.dtype]; 
           
            self.data.zpos = self.readRegion(start, shape, type);            
            i = find(strcmp(fields,'position'));
            fields{i} = '';
            
            % Generic data            
            for i = 1:length(fields) % rest of the data
                if ~isempty(fields{i}) % better to 'pop' elements from the cell array...
                    start = self.meta.Data.(fields{i}).Position.StartByte;
                    shape = self.meta.Data.(fields{i}).Size';          
                    type = ['*' self.meta.Data.(fields{i}).dtype];
                    
                    self.data.(fields{i}) = self.readRegion(start, shape, type);
                    
                end
            end
            
            % Scan timing data
            start = self.meta.Time.Position.StartByte;
            stop = self.meta.Time.Position.LastByte;
            timing_string = self.readRegion(start, stop-start, 'string');
            
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
                    self.meta.Time.Timings = jsondecode(normalize_json(timing_string));
                    timing_loaded = true;
                catch error
                    % but also catch Scan.Finished == false!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                    warning(getReport(error, 'extended', 'hyperlinks', 'on'))
                    timing_loaded = false;
                end

                if timing_loaded
                    moves = [self.meta.Time.Timings.MoveTick]'; 
                    starts = [self.meta.Time.Timings.StartTick]'; 
                    stops = [self.meta.Time.Timings.StopTick]';

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
        
        function I = readRegion(self, start, shape, dtype)
            % Reads specified region in file            
            switch nargin
                case [0,1,2]
                    error('Data properties not specified')
                case 3
                    dtype = self.dtype;
            end
            
            dimensions = length(shape);
            len = prod(shape);
           
            
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
        end
    end
end