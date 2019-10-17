classdef ocmCube < Cube   
%  Reader for ocmbin 3d image files (deprecated format, use to open files from 2017-2019)
    properties(Hidden = true)
        cube_reduced
        header
        overlap                                         % bool: overlap between adjacent data regions?    
        overbytes                                       % bytes of overlap between adjacent data reions
        io_timings                                      % file i/o timing information
        datasets                                        % names of included datasets; what was the point of this?
        dtype = '*uint32';
    end
    
 
    
    %% File I/O methods
    
    methods(Access = public)            
        function load(obj)
            % Overrides Cube.load
            % Load data in ocmbin format
            if ~obj.is_loaded
                full_read = tic;            
                obj.parseMetadata();           
                obj.checkOverlap();

                data_read = tic;
    %             try
                    obj.extractData2()                
    %             catch
    %                 warning('Data cannot be loaded')
    %             end

                read_time = toc(data_read);

                obj.io_timings.writeTime = obj.meta.Time.ElapsedTime;
                obj.io_timings.dataReadTime = read_time;
                obj.io_timings.fullReadTime = toc(full_read);
                obj.io_timings.ReadRateMBs = obj.filesize_gb / read_time * 1024;
                
                obj.is_loaded = true;
            end
        end
    end  
    
    methods(Access = private)
        function parseMetadata(obj)      
            % Read & parse metadata string from .bin file
            
            f = fopen(obj.path, 'rb');
            fseek(f, 0, 'bof');
%             obj.header = fgetl(f); 

%             obj.header = strcat(fread(f, 8192, '*char')');

            header_candidate = strcat(fread(f, 8192, '*char')');
            try
                meta_candidate = jsondecode(header_candidate);
                obj.meta = meta_candidate;
                obj.header = header_candidate;
            catch err
                try % or JSON oops               
                    header_candidate = strcat(fread(f, 32768, '*char')');  % New file spec - longer header
                    meta_candidate = jsondecode(header_candidate);
                    obj.meta = meta_candidate;
                    obj.header = header_candidate;
                catch err2 % JSON formatting error or corrupt file
                    warning(err2.identifier, '%s', err2.message);
                    obj.meta = jsondecode(normalize_json(obj.header));
                end
            end

            fclose(f);            
            
            if isempty(obj.header)
                error('File has no header')
            else
            
                % reads single line of file; the first line in the file is the header
                    % However, what if this is not the case? Also: indented header is easier to read...

                % json parser gets confused when it encounters the header padding.
                
                

                if ~isfield(obj.meta, 'Data') % rename metadate fields in case older file is loaded
                    obj.rename_MD_fields() 
                end
                
                obj.name = obj.meta.Main.File.Name;
                obj.desc = obj.meta.Main.File.Description;

                obj.meta.Main.Dir = dir(obj.path);
                obj.filesize = b2relevant(obj.meta.Main.Dir.bytes); 
                obj.filesize_gb = b2gb(obj.meta.Main.Dir.bytes);
                obj.meta.Main.File.FileSizeGB = obj.filesize_gb;
                obj.meta.Main.Dir.path = strcat(obj.meta.Main.Dir.folder, '\', obj.meta.Main.Dir.name);
                obj.meta.Main.Dir.extension = getExtension(obj.meta.Main.Dir.name);

                % recast data metadata fields from struct array into struct struct

                dsts = {obj.meta.Data.Name};
                index = 1:length(dsts);
                obj.datasets = dsts(~cellfun('isempty', dsts));
                index = index(~cellfun('isempty', dsts));
                dmd = struct;

                for i = 1:length(index)
                    dmd.(obj.datasets{i}) = obj.meta.Data(index(i));
                end

                obj.meta.Data = dmd;

                for i = 1:length(obj.datasets)
                    dataset = obj.datasets{i};
                    obj.meta.Data.(dataset).BytesAllocated = ...
                        obj.meta.Data.(dataset).Position.StopByte - obj.meta.Data.(dataset).Position.StartByte;
                    obj.meta.Data.(dataset).BytesWritten = ...
                        obj.meta.Data.(dataset).Position.LastByte - obj.meta.Data.(dataset).Position.StartByte;
                end
            end
        end  
        
        function rename_MD_fields(obj)
            % Rename metadata fields to be more human-friendly
           oldfields = fieldnames(obj.meta);
            targets = {'DataProperties', 'TimingProperties', 'MainProperties', 'CameraAttributes', 'ScanProperties'};
            replace = {'Data', 'Time', 'Main', 'CMOS', 'Scan'};
            md = struct;
            
            for i = 1:length(oldfields)
                match = strfind(oldfields, targets{i});
                index = find(not(cellfun('isempty', match)));
                md.(replace{i}) = obj.meta.(oldfields{index});
            end 
            
            obj.meta = md;
        end
        
        function [overlap,overbytes] = checkOverlap(obj)
            % Checks the parsed metadata for overlap between separate data regions
            
            if isempty(obj.datasets)
                obj.datasets = fieldnames(obj.meta.Data);
            end
                       
            overlap = zeros(1,length(obj.datasets));
            overbytes = zeros(1,length(obj.datasets));
            allocbytes = zeros(1,length(obj.datasets));
            writtenbytes = zeros(1,length(obj.datasets));
            
            for i = 1:length(obj.datasets)
                overlap(i) = (obj.meta.Data.(obj.datasets{i}).Position.LastByte ...
                    > obj.meta.Data.(obj.datasets{i}).Position.StopByte);
                overbytes(i) = obj.meta.Data.(obj.datasets{i}).Position.LastByte ...
                    - obj.meta.Data.(obj.datasets{i}).Position.StopByte;
                allocbytes(i) = obj.meta.Data.(obj.datasets{i}).BytesAllocated;
                writtenbytes(i) = obj.meta.Data.(obj.datasets{i}).BytesWritten;
            end
            
            obj.overlap = overlap;
            obj.overbytes = array2table([allocbytes; writtenbytes; overbytes], ...
                'VariableNames', obj.datasets, 'RowNames', {'Allocated', 'Written', 'Overlap'});
            
            if any(overlap)
               warning('Some of the data regions overlap. Average delta in bytes: %d', mean(overbytes(overbytes ~= 0)))  
            end
        end 
        
        function extractData2(obj)
            % Extracts data from the .ocmbin file ~region boundaries specified in the metadata
                % load_mode:    files larger than 75% of available RAM are loaded using memmap                
            
            fields = fieldnames(obj.meta.Data);
            
            % OCM cube
            start = obj.meta.Data.cube.Position.StartByte;
            shape = obj.meta.Data.cube.Size';      
            type = ['*' obj.meta.Data.cube.dtype];
            
            obj.cube = obj.readRegion(start, shape, type);
            obj.cube = permute(obj.cube, [2,1,3]);
            i = find(strcmp(fields,'cube'));
            fields{i} = '';
            
            % Scan position vector
            start = obj.meta.Data.position.Position.StartByte;
            shape = obj.meta.Data.position.Size;   
            type = ['*' obj.meta.Data.position.dtype]; 
           
            obj.data.zpos = obj.readRegion(start, shape, type);            
            i = find(strcmp(fields,'position'));
            fields{i} = '';
            
            % Generic data            
            for i = 1:length(fields) % rest of the data
                if ~isempty(fields{i}) % better to 'pop' elements from the cell array...
                    start = obj.meta.Data.(fields{i}).Position.StartByte;
                    shape = obj.meta.Data.(fields{i}).Size';          
                    type = ['*' obj.meta.Data.(fields{i}).dtype];
                    
                    obj.data.(fields{i}) = obj.readRegion(start, shape, type);
                    
                end
            end
            
            % Scan timing data
            start = obj.meta.Time.Position.StartByte;
            stop = obj.meta.Time.Position.LastByte;
            timing_string = obj.readRegion(start, stop-start, 'string');
            
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
                    obj.meta.Time.Timings = jsondecode(normalize_json(timing_string));
                    timing_loaded = true;
                catch error
                    % but also catch Scan.Finished == false!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                    warning(getReport(error, 'extended', 'hyperlinks', 'on'))
                    timing_loaded = false;
                end

                if timing_loaded
                    moves = [obj.meta.Time.Timings.MoveTick]'; 
                    starts = [obj.meta.Time.Timings.StartTick]'; 
                    stops = [obj.meta.Time.Timings.StopTick]';

                    delta_move = starts - moves;
                    delta_scan = stops - starts;
                    delta_total = stops - moves;
                    delta_log = circshift(moves,-1) - stops;

                    obj.io_timings.moveTime = median(delta_move)*1e-6;
                    obj.io_timings.scanTime = median(delta_scan)*1e-6;
                    obj.io_timings.stepTime = median(delta_total)*1e-6;
                    obj.io_timings.logTime = median(delta_log(1:end-1))*1e-6;
                end
            end
        end
        
        function I = readRegion(obj, start, shape, dtype)
            % Reads specified region in file            
            switch nargin
                case [0,1,2]
                    error('Data properties not specified')
                case 3
                    dtype = obj.dtype;
            end
            
            dimensions = length(shape);
            len = prod(shape);
           
            
                 switch dimensions
                        case 1                            
                            if strcmp(dtype, 'string') 
                                f = fopen(obj.path, 'r');
                                fseek(f, start, -1);
                                I = fread(f, len, '*char');
                                I = I';
                            else
                                f = fopen(obj.path, 'r');
                                fseek(f, start, -1);
                                I = fread(f, len, dtype);
                            end
                            fclose(f);
                        case 2
                            f = fopen(obj.path, 'r');
                            fseek(f, start, -1);
                            A = fread(f, len, dtype);
                            I = reshape(A, shape)';
                            fclose(f);
                        case 3
                            f = fopen(obj.path, 'r');
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