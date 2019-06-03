classdef thorcube < bincube
% Reader for Thorlabs .oct files (acquired with ThorImage OCT 4.x and 5.x)
% Depends on Thorlabs SpectralRadar MATLAB API
    
    properties
        h = struct()
        preview_image                                             % Full field perview image
        dz                                                        % Axial step (nm / px)
    end
    
    methods
        function load_data(self)          
            if ~self.is_loaded
                if isempty(fields(self.h))
                    % Get .oct file handle (can take quite a while to load with the whole unzipping business)
                    % OCTFileOpen7ZIP overrides the original files use of unzip with a system call to 7zip for speed
                    self.h = OCTFileOpen7ZIP(self.path);
                end
                
                % Header to bincube metadata
                self.MD = self.h.head;     

                % Load intensity cube from .oct file
                cube = OCTFileGetIntensity(self.h);                              
                % Transform from dB to ~ 'regular' intensity (match bincube)            
%                 cube = 10.^(drop(cube)/10);   this is relatively unuseful, and takes a long time
                % Transpose to (X,Y,Z) orientation. If the 'cube' is actually 2d, an error may be thrown.
                self.cube = permute(cube, [2,3,1]);      

                % Get equivalent of position vector
                [~, ~, Nz] = size(self.cube);
                self.dz =  str2num(self.MD.DataFiles.DataFile{3}.Attributes.RangeZ) * 1e6 / Nz;
                self.position = linspace(0, (Nz-1)*self.dz, Nz);

                % Read preview image. Scan region is denoted in red
                self.preview_image = OCTFileGetColoredData(self.h, 'VideoImage');                       
                
                % Close .oct file handle
                OCTFileClose(self.h)

                % Read name & description   % todo: actually read name & description
                self.name = self.path;  
                self.description = '...';

                self.is_loaded = true;
            end
        end
        
        function unload_data(self)
            if self.is_loaded
                self.preview_image = zeros(1,1);
                self.h = struct();
                unload_data@bincube(self)
            end
        end
        
        function preview(self)
            imshow_tight(self.preview_image, 'Name', self.name);
        end
    end
end

