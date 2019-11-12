classdef thorCube < Cube
% Reader for Thorlabs .oct files (acquired with ThorImage OCT 4.x and 5.x)
%   * Depends on Thorlabs SpectralRadar MATLAB API; make sure it's included in the MATLAB path
%   * May need to be updated to support newer versions of the .oct format!
        
    properties(Hidden = true)
        h = struct()                                              % Full field perview image
        dz                                                        % Axial step (nm / px)
    end
    
    %% File I/O methods
    methods(Access = public)
        function load(obj) 
            % Load data in .oct format
            if ~obj.check_if_loaded()
                if isempty(fields(obj.h))
                    % Get .oct file handle (can take quite a while to load with the whole unzipping business)
                    % OCTFileOpen7ZIP overrides the original files use of unzip with a system call to 7zip for speed
                    obj.h = OCTFileOpen7ZIP(obj.path);
                end
                
                % Header to bincube metadata
                obj.meta = obj.h.head;     

                % Load intensity cube from .oct file
                cube = single(OCTFileGetIntensity(obj.h));   % .oct stores cube as 32-bit float                        
                % Transform from dB to ~ 'regular' intensity (match OCMCube)            
%                 cube = 10.^(drop(cube)/10);   this is relatively unuseful, and takes a long time
                % Transpose to (X,Y,Z) orientation. If the 'cube' is actually 2d, an error may be thrown.
                obj.cube = permute(cube, [2,3,1]);      

                % Get equivalent of position vector
                [~, ~, Nz] = size(obj.cube);
                obj.dz =  str2num(obj.meta.DataFiles.DataFile{3}.Attributes.RangeZ) * 1e6 / Nz;
                obj.data.zpos = linspace(0, (Nz-1)*obj.dz, Nz)';

                % Read preview image. Scan region is denoted in red
                obj.data.preview_image = OCTFileGetColoredData(obj.h, 'VideoImage');                       
                
                % Close .oct file handle
                OCTFileClose(obj.h)

                % Read name & description   % todo: actually read name & description
                obj.name = obj.path;  
                obj.desc = '...';

                obj.check_if_loaded();
            end
        end
        
        function unload(obj)
            % Close interface to .oct file (see Thorlabs OCT API) and unload data
            if obj.is_loaded
                obj.h = struct();   % Let go of handle to .oct file
                unload@Cube(obj)
            end
        end
    end
    %% High-level interface to thorCube data
    methods(Access = public)
        function preview(obj)
            % Show the preview image (wide FOV + scan region)
            figure('Name', sprintf('%s - preview image', obj.name));
            imshow_tight(obj.data.preview_image);
        end
    end
end