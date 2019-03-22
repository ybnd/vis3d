classdef orthofig < handle 
    %todo: maybe just inherit from figure? Or even an inheritance tree, where this inherits from slice...
    
    %ORTHOFIG Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        C        
        
        current_slice = [1,1,1];
        previous_slice = [1,1,1];   
    end
    
    properties (Access = private)
        figure;
        
        image = struct();
        overlay = struct('alpha', 0.2, 'colormap', [0 0 0; 0 1 0]);
        control = struct();
        
        contrast_method = @pass;
        slice_method = @normalize_slice;
        slice_args = struct();     
        contrast_args = struct();
        
        do_db = false;
        noise_floor = -30;
        
        
        M = 1;
        z = 2;
        pad = [75 0 0 0]
    end
    
    methods 
        function self = orthofig(C, fig, slice_method, slice_args, M, z) % todo: change signature!
            switch nargin
                case 5
                    self.z = 2;
                case 4
                    self.M = 1;
                    self.z = 2;
                case 3
                    slice_args = struct();
                    M = 1;
                    z = 2;
                case 2
                    slice_method = @normalize_slice;
                    slice_args = struct();
                    M = 1;
                    z = 2;
                case 1
                    fig = figure;
                    slice_method = @normalize_slice;
                    slice_args = struct();        
                    M = 1;
                    z = 2;
            end
            
            self.C = C;
            self.slice_method = slice_method;
            self.slice_args = slice_args;
            
            self.figure = fig; 
            set(self.figure, 'visible', 'off');
            set(self.figure, 'UserData', self);
            set(self.figure, 'MenuBar', 'none');
            set(self.figure, 'Resize', 'off');
            
            self.M = M;
            self.z = z;
            
            self.build(self.M,self.z);
        end
        
        function build(self, M, z)
            switch nargin
                case 1
                    self.M = M;
                case 2
                    self.M = M;
                    self.z = z;
            end
            [Nx, Ny, Nz] = size(self.C);
            
            [self.image.XY, self.image.XZ, self.image.YZ] = imshow_tight_ortho( ...
                self.C, self.current_slice, self.slice_method, self.slice_args, ...
                self.M, self.z, self.pad ...
            );
        
            aXY = copyobj(self.image.XY.Parent, self.figure); cla(aXY);
            aXZ = copyobj(self.image.XZ.Parent, self.figure); cla(aXZ);
            aYZ = copyobj(self.image.YZ.Parent, self.figure); cla(aYZ);
            
            oXY = zeros(Nx, Ny); oXZ = zeros(Nx, Nz); oYZ = zeros(Nz,Ny);
            oXY(self.current_slice(1),:) = self.overlay.alpha;
            oXY(:,self.current_slice(2)) = self.overlay.alpha;
            oXZ(self.current_slice(1),:) = self.overlay.alpha;
            oXZ(:,self.current_slice(3)) = self.overlay.alpha;
            oYZ(self.current_slice(3),:) = self.overlay.alpha;
            oYZ(:,self.current_slice(2)) = self.overlay.alpha;
            
            set(self.figure, 'CurrentAxes', aXY); 
            self.overlay.XY = imshow(ones(Nx,Ny), 'Colormap', self.overlay.colormap);
            aXY.DataAspectRatio = self.image.XY.Parent.DataAspectRatio;
            set(self.figure, 'CurrentAxes', aXZ);
            self.overlay.XZ = imshow(ones(Nx,Nz), 'Colormap', self.overlay.colormap);
            aXZ.DataAspectRatio = self.image.XZ.Parent.DataAspectRatio;
            set(self.figure, 'CurrentAxes', aYZ);
            self.overlay.YZ = imshow(ones(Nz,Ny), 'Colormap', self.overlay.colormap);
            aYZ.DataAspectRatio = self.image.YZ.Parent.DataAspectRatio;
            set(self.overlay.XY, 'AlphaData', oXY);
            set(self.overlay.XZ, 'AlphaData', oXZ);
            set(self.overlay.YZ, 'AlphaData', oYZ);

            self.control.Z_text = uicontrol('style', 'text', ...
                'Position', [5,3,35,20], ...
                'String', sprintf('z(%d)',self.current_slice(3)));
        
            ap = get(gca, 'Position');

            self.control.Z_slider = uicontrol('style', 'slider', ...
                'Position', [45,5,ap(3)-40,20] ,...
                'Value', self.current_slice(3), 'min', 1, 'max', Nz, ...
                'SliderStep', [1/Nz, 1/Nz] ...
                );
            addlistener(self.control.Z_slider, 'Value', 'PostSet', @self.Z_slider_callback);

            self.control.Y_text = uicontrol('style', 'text', ...
                'Position', [5,25,35,20], ...
                'String', sprintf('y(%d)',self.current_slice(2)));
            ap = get(gca, 'Position');
            self.control.Y_slider = uicontrol('style', 'slider', ...
                'Position', [45,27,ap(3)-40,20] ,...
                'Value', self.current_slice(2), 'min', 1, 'max', Ny, ...
                'SliderStep', [1/Ny, 1/Ny] ...
                );
            addlistener(self.control.Y_slider, 'Value', 'PostSet', @self.Y_slider_callback);

            self.control.X_text = uicontrol('style', 'text', ...
                'Position', [5,47,35,20], ...
                'String', sprintf('x(%d)',self.current_slice(1)));
            ap = get(gca, 'Position');
            self.control.X_slider = uicontrol('style', 'slider', ...
                'Position', [45,49,ap(3)-40,20] ,...
                'Value', self.current_slice(1), 'min', 1, 'max', Nx, ...
                'SliderStep', [1/Nx, 1/Nx] ...
                );
            addlistener(self.control.X_slider, 'Value', 'PostSet', @self.X_slider_callback);

            self.control.ui_contrast = uicontrol('Style', 'popupmenu', 'String', ...
                {'none', 'imadjust', 'adapthisteq'}, 'Position', [ap(3)+10, 58, 100, 12]);
            addlistener(self.control.ui_contrast, 'Value', 'PostSet', @self.ui_contrast_callback);

            self.control.ui_contrast = uicontrol('Style', 'popupmenu', 'String', ...
                {'gray', 'winter', 'parula'}, 'Position', [ap(3)+10, 38, 100, 12]);
            addlistener(self.control.ui_contrast, 'Value', 'PostSet', @self.ui_colormap_callback);
            
            self.control.ui_db = uicontrol('Style', 'togglebutton', 'String', 'dB?', ...
                'Position', [ap(3)+10, 5, 50, 22], 'callback', @self.ui_toggle_db);
            
            
            self.control.ui_db_floor = uicontrol('Style', 'edit', 'String', num2str(self.noise_floor), ...
                'Position', [ap(3)+70, 5, 40, 24], 'KeyReleaseFcn', @self.ui_floor_callback);

            set(self.figure, 'WindowScrollWheelFcn', @self.scroll);

            self.overlay.XY.Parent.ButtonDownFcn = @XY_ButtonDownFcn;
            self.overlay.XZ.Parent.ButtonDownFcn = @XZ_ButtonDownFcn;
            self.overlay.YZ.Parent.ButtonDownFcn = @YZ_ButtonDownFcn;
            
            set(self.figure, 'visible', 'on')
        end
        
        
%         function magnify(self, M, z) % todo: would require re-drawing of imshow axes?
%             p = self.pad + [5 5 5 5];
%             dfpos = [0 0 p(3)+p(4) p(1)+p(2)];
%             dhpos = [p(3) p(1) 0 0];
%             
%             [Ny,Nx,Nz] = size(self.C);
%             X = Nx*M/100.0;
%             Y = Ny*M/100.0;
%             Z = Nz*M*z/100.0;
% 
%             set(gcf, 'Position', [50, 50, X+Z, Y+Z] + dfpos);
%             set(self.image.XY.Parent, 'Position', [0,Z+2,X,Y] + dhpos);
%             set(self.image.XZ.Parent, 'Position', [X+2,Z+2,Z,Y] + dhpos);
%             set(self.image.YZ.Parent, 'Position', [0,0,X,Z] + dhpos);
%         end
    
    
    %% Callbacks

        function Z_slider_callback(self, ~, eventdata)            
            self.previous_slice = self.current_slice;
            new_Z_slice = floor(get(eventdata.AffectedObject, 'Value'));
            self.current_slice(3) = new_Z_slice;
            self.control.Z_text.String = sprintf('z(%d)',new_Z_slice);
            
            if self.do_db
                self.image.XY.set('CData', self.contrast_method(dB(self.slice_method(self.C,new_Z_slice,self.slice_args),self.noise_floor, true)));
            else
                self.image.XY.set('CData', self.contrast_method(self.slice_method(self.C,new_Z_slice,self.slice_args)));
            end

            self.place_overlay;
        end

        function Y_slider_callback(self, ~, eventdata)
            self.previous_slice = self.current_slice;
            new_Y_slice = floor(get(eventdata.AffectedObject, 'Value'));
            self.current_slice(2) = new_Y_slice;
            self.control.Y_text.String = sprintf('y(%d)',new_Y_slice);
            
            if self.do_db
                self.image.XZ.set('CData', self.contrast_method(dB(self.slice_method(permute(self.C,[1,3,2]),new_Y_slice,self.slice_args),self.noise_floor, true)));
            else
                self.image.XZ.set('CData', self.contrast_method(self.slice_method(permute(self.C,[1,3,2]),new_Y_slice,self.slice_args)));
            end
            
            self.place_overlay;
        end

        function X_slider_callback(self, ~, eventdata)
            self.previous_slice = self.current_slice;
            new_X_slice = floor(get(eventdata.AffectedObject, 'Value'));
            self.current_slice(1) = new_X_slice;
            self.control.X_text.String = sprintf('x(%d)', new_X_slice);
            
            if self.do_db
                self.image.YZ.set('CData', self.contrast_method(dB(self.slice_method(permute(self.C,[3,2,1]),new_X_slice,self.slice_args), self.noise_floor, true)));
            else
                self.image.YZ.set('CData', self.contrast_method(self.slice_method(permute(self.C,[3,2,1]),new_X_slice,self.slice_args)));
            end
            

            self.place_overlay;        
        end

        function place_overlay(self)
            alpha_XY = get(self.overlay.XY, 'AlphaData');
            alpha_XZ = get(self.overlay.XZ, 'AlphaData');
            alpha_YZ = get(self.overlay.YZ, 'AlphaData');

            alpha_XY(self.previous_slice(1),:) = 0; alpha_XY(self.current_slice(1),:) = self.overlay.alpha;
            alpha_XY(:,self.previous_slice(2)) = 0; alpha_XY(:,self.current_slice(2)) = self.overlay.alpha;

            alpha_XZ(:,self.previous_slice(3)) = 0; alpha_XZ(:,self.current_slice(3)) = self.overlay.alpha;
            alpha_XZ(self.previous_slice(1),:) = 0; alpha_XZ(self.current_slice(1),:) = self.overlay.alpha;

            alpha_YZ(:,self.previous_slice(2)) = 0; alpha_YZ(:,self.current_slice(2)) = self.overlay.alpha;
            alpha_YZ(self.previous_slice(3),:) = 0; alpha_YZ(self.current_slice(3),:) = self.overlay.alpha;   

            set(self.overlay.XY, 'AlphaData', alpha_XY);
            set(self.overlay.XZ, 'AlphaData', alpha_XZ);
            set(self.overlay.YZ, 'AlphaData', alpha_YZ);
        end

        function scroll(self, source, eventdata)
            method = get(source, 'CurrentModifier');
            if isempty(method); method = {''}; end

            switch method{1}
                case 'shift'
                    new_value = get(self.control.X_slider, 'Value') - 1 * eventdata.VerticalScrollCount*10;
                    if new_value <= get(self.control.X_slider, 'max') && new_value >= get(self.control.X_slider, 'min')
                        set(self.control.X_slider, 'Value', new_value);
                    end
                case 'control'
                    new_value = get(self.control.Y_slider, 'Value') - 1 * eventdata.VerticalScrollCount*10;
                    if new_value <= get(self.control.Y_slider, 'max') && new_value >= get(self.control.Y_slider, 'min')
                        set(self.control.Y_slider, 'Value', new_value);
                    end
                otherwise
                    new_value = get(self.control.Z_slider, 'Value') - 1 * eventdata.VerticalScrollCount;
                    if new_value <= get(self.control.Z_slider, 'max') && new_value >= get(self.control.Z_slider, 'min')
                        set(self.control.Z_slider, 'Value', new_value);
                    end                        
            end

        end

        function XY_ButtonDownFcn(self, ~, eventdata)         
            pos = floor(eventdata.IntersectionPoint);
            
            set(self.control.X_slider, 'Value', pos(2));
            set(Y_slider, 'Value', pos(1));
        end

        function XZ_ButtonDownFcn(self, ~, eventdata)         
            pos = floor(eventdata.IntersectionPoint);
            
            set(self.control.X_slider, 'Value', pos(2));
            set(self.control.Z_slider, 'Value', pos(1));
        end

        function YZ_ButtonDownFcn(self, ~, eventdata)

            pos = floor(eventdata.IntersectionPoint);
            
            set(self.control.Y_slider, 'Value', pos(1));
            set(self.control.Z_slider, 'Value', pos(2));
        end
        
        function ui_toggle_db(self, ~, eventdata)
           self.do_db = eventdata.Source.Value;
           self.ui_update_images()
        end

        function ui_contrast_callback(self, ~, eventdata)   

            switch eventdata.AffectedObject.String{get(eventdata.AffectedObject, 'Value')}
                case 'none'
                    self.contrast_method = @pass;
                case 'imadjust'
                    self.contrast_method = @imadjust;
                case 'adapthisteq'
                    self.contrast_method = @adapthisteq;
            end

            self.ui_update_images()
        end
        
        function ui_update_images(self)
            if self.do_db
                self.image.XY.set('CData', self.contrast_method(dB(self.slice_method(self.C, self.current_slice(3),self.slice_args), self.noise_floor, true)));
                self.image.XZ.set('CData', self.contrast_method(dB(self.slice_method(permute(self.C,[1,3,2]),self.current_slice(2),self.slice_args), self.noise_floor, true)));
                self.image.YZ.set('CData', self.contrast_method(dB(self.slice_method(permute(self.C,[3,2,1]),self.current_slice(1),self.slice_args), self.noise_floor, true)));  
            else
                self.image.XY.set('CData', self.contrast_method(self.slice_method(self.C, self.current_slice(3),self.slice_args)));
                self.image.XZ.set('CData', self.contrast_method(self.slice_method(permute(self.C,[1,3,2]),self.current_slice(2),self.slice_args)));
                self.image.YZ.set('CData', self.contrast_method(self.slice_method(permute(self.C,[3,2,1]),self.current_slice(1),self.slice_args)));
            end
        end
        
        function ui_floor_callback(self, ~, eventdata)
            key = get(gcf,'CurrentKey');
            if (strcmp (key , 'return'))
                self.noise_floor = str2num( eventdata.Source.String);
                self.slice_args.floor = self.noise_floor;

                self.ui_update_images()
            end
        end

        function ui_colormap_callback(self, ~, eventdata)            
            map = eventdata.AffectedObject.String{get(eventdata.AffectedObject, 'Value')};

            colormap(self.image.XY.Parent, map)
            colormap(self.image.XZ.Parent, map)
            colormap(self.image.YZ.Parent, map)
        end    
    
    end
    
end


%% Contrast functions
function I = pass(I); end

function J = imadjust_dB(I)
        dBI = dB(I);
        J = imadjust(imgaussfilt(normalize(single(dB(I)) + max2(abs(dBI))), 0.5));
end

function J = floor_dB(I, args)
    noise_floor = -30;
    try 
       noise_floor = args.floor;
    catch         
    end
    J = normalize2(dB(I, noise_floor));
    
    disp('oop')
end

