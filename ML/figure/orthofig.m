classdef orthofig < cubefig 
    
    properties
        current_slice = [1,1,1];
        previous_slice = [1,1,1];   
    end
    
    properties (Access = private)        
        overlay = struct('alpha', 0.2, 'colormap', [0 0 0; 0 1 0]);
        
        z = 2;
        pad = [75 0 0 0]
    end
    
    methods 
        function self = orthofig(C, fig, M, z, slice_method)
            switch nargin
                case 1
                    fig = figure;
                    M = 100;
                    z = 2;
                    slice_method = @slice;
                case 2
                    M = 100;
                    z = 2;
                    slice_method = @slice;
                case 3
                    z = 2;
                    slice_method = @slice;
                case 4
                    slice_method = @slice;
            end
            
            self.C = C;
            
            self.figure = fig; 
            set(self.figure, 'visible', 'off');
            set(self.figure, 'UserData', self);
            set(self.figure, 'MenuBar', 'none');
            set(self.figure, 'Resize', 'off');
            
            self.M = M;
            self.z = z;
            self.slice_method = slice_method;
            
            self.build;
        end
        
        function build(self)
            [Nx, Ny, Nz] = size(self.C);
            
            [self.image.XY, self.image.XZ, self.image.YZ] = imshow_tight_ortho( ...
                self.C, self.current_slice, self.slice_method, self.slice_args, ...
                self.M, self.z, self.pad ...
            );
        
            aXY = copyobj(self.image.XY.Parent, self.figure); cla(aXY);
            aXZ = copyobj(self.image.XZ.Parent, self.figure); cla(aXZ);
            aYZ = copyobj(self.image.YZ.Parent, self.figure); cla(aYZ);
            
            % Create overlay images
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

            ap = get(gca, 'Position');
            
            w_xy = ap(3);   % width of XY image
            border = 5;     % border distance (v,h)
            w_img = 80;     % image controls width
            d_img_xyz = 20; % distance between image controls and axis controls
            w_lab = 40;     % axis control label width
            w_db = 45;      % width of db button

            self.control.Z_slider = uicontrol('style', 'slider', ...
                'Position', [border + w_img + d_img_xyz+w_lab,5,w_xy - w_img - d_img_xyz-w_lab,20] ,...
                'Value', self.current_slice(3), 'min', 1, 'max', Nz, ...
                'SliderStep', [1/Nz, 1/Nz] ...
                );
            self.control.Z_text = uicontrol('style', 'text', ...
                'Position', [border + w_img + d_img_xyz,3,w_lab,20], ...
                'String', sprintf('z(%d)',self.current_slice(3)));
            addlistener(self.control.Z_slider, 'Value', 'PostSet', @self.Z_slider_callback);

            self.control.Y_text = uicontrol('style', 'text', ...
                'Position', [border + w_img + d_img_xyz,25,w_lab,20], ...
                'String', sprintf('y(%d)',self.current_slice(2)));
            self.control.Y_slider = uicontrol('style', 'slider', ...
                'Position', [border + w_img + d_img_xyz+w_lab,27,w_xy - w_img - d_img_xyz-w_lab,20] ,...
                'Value', self.current_slice(2), 'min', 1, 'max', Ny, ...
                'SliderStep', [1/Ny, 1/Ny] ...
                );
            addlistener(self.control.Y_slider, 'Value', 'PostSet', @self.Y_slider_callback);

            self.control.X_text = uicontrol('style', 'text', ...
                'Position', [border + w_img + d_img_xyz,47,w_lab,20], ...
                'String', sprintf('x(%d)',self.current_slice(1)));
            self.control.X_slider = uicontrol('style', 'slider', ...
                'Position', [border + w_img + d_img_xyz+w_lab,49,w_xy - w_img - d_img_xyz-w_lab,20] ,...
                'Value', self.current_slice(1), 'min', 1, 'max', Nx, ...
                'SliderStep', [1/Nx, 1/Nx] ...
                );
            addlistener(self.control.X_slider, 'Value', 'PostSet', @self.X_slider_callback);

            set(self.figure, 'WindowScrollWheelFcn', @self.scroll);

            self.overlay.XY.Parent.ButtonDownFcn = @XY_ButtonDownFcn;
            self.overlay.XZ.Parent.ButtonDownFcn = @XZ_ButtonDownFcn;
            self.overlay.YZ.Parent.ButtonDownFcn = @YZ_ButtonDownFcn;
            
            positions = struct(                                                 ...
                'ui_colormap', [border, 58, w_img, 12],                         ...
                'ui_db', [border-1, border+20, w_db, 22],                          ...
                'ui_db_floor', [border+w_db, border, w_img-w_db-1,20],    ...
                'ui_db_ceil', [border+w_db, border+1+20, w_img-w_db-1, 20]    ...
            );
            images = [self.image.XY.Parent, self.image.XZ.Parent, self.image.YZ.Parent];
        
            self.imagecontrol = postprocon(self, positions, @self.ui_update_images, images);
            
            self.ui_update_images;
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
                self.image.XY.set('CData', dBs(self.slice_method(self.C,new_Z_slice,'z',self.slice_args),self.noise_floor, self.signal_ceil));
            else
                self.image.XY.set('CData', self.slice_method(self.C,new_Z_slice, 'z',self.slice_args));
            end

            self.place_overlay;
        end

        function Y_slider_callback(self, ~, eventdata)
            self.previous_slice = self.current_slice;
            new_Y_slice = floor(get(eventdata.AffectedObject, 'Value'));
            self.current_slice(2) = new_Y_slice;
            self.control.Y_text.String = sprintf('y(%d)',new_Y_slice);
            
            if self.do_db
                self.image.XZ.set('CData', dBs(self.slice_method(self.C,new_Y_slice,'y',self.slice_args),self.noise_floor, self.signal_ceil));
            else
                self.image.XZ.set('CData', self.slice_method(self.C,new_Y_slice,'y',self.slice_args));
            end
            
            self.place_overlay;
        end

        function X_slider_callback(self, ~, eventdata)
            self.previous_slice = self.current_slice;
            new_X_slice = floor(get(eventdata.AffectedObject, 'Value'));
            self.current_slice(1) = new_X_slice;
            self.control.X_text.String = sprintf('x(%d)', new_X_slice);
            
            if self.do_db
                self.image.YZ.set('CData', dBs(self.slice_method(self.C,new_X_slice,'x',self.slice_args), self.noise_floor, self.signal_ceil));
            else
                self.image.YZ.set('CData', self.slice_method(self.C,new_X_slice,'x',self.slice_args));
            end
            

            self.place_overlay;        
        end

        function place_overlay(self)
%             alpha_XY = get(self.overlay.XY, 'AlphaData');
%             alpha_XZ = get(self.overlay.XZ, 'AlphaData');
%             alpha_YZ = get(self.overlay.YZ, 'AlphaData');
% 
%             alpha_XY(self.previous_slice(1),:) = 0; alpha_XY(self.current_slice(1),:) = self.overlay.alpha;
%             alpha_XY(:,self.previous_slice(2)) = 0; alpha_XY(:,self.current_slice(2)) = self.overlay.alpha;
% 
%             alpha_XZ(:,self.previous_slice(3)) = 0; alpha_XZ(:,self.current_slice(3)) = self.overlay.alpha;
%             alpha_XZ(self.previous_slice(1),:) = 0; alpha_XZ(self.current_slice(1),:) = self.overlay.alpha;
% 
%             alpha_YZ(:,self.previous_slice(2)) = 0; alpha_YZ(:,self.current_slice(2)) = self.overlay.alpha;
%             alpha_YZ(self.previous_slice(3),:) = 0; alpha_YZ(self.current_slice(3),:) = self.overlay.alpha;   
% 
%             set(self.overlay.XY, 'AlphaData', alpha_XY);
%             set(self.overlay.XZ, 'AlphaData', alpha_XZ);
%             set(self.overlay.YZ, 'AlphaData', alpha_YZ);
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
        
        
    end
    
    methods(Access = public)
        function ui_update_images(self)
            if self.do_db
                self.image.XY.set('CData', dBs(self.slice_method(self.C,self.current_slice(3),'z',self.slice_args), self.noise_floor, self.signal_ceil));
                self.image.XZ.set('CData', dBs(self.slice_method(self.C,self.current_slice(2),'y',self.slice_args), self.noise_floor, self.signal_ceil));
                self.image.YZ.set('CData', dBs(self.slice_method(self.C,self.current_slice(1),'x',self.slice_args), self.noise_floor, self.signal_ceil));  
            else
                self.image.XY.set('CData', self.slice_method(self.C,self.current_slice(3),'z',self.slice_args));
                self.image.XZ.set('CData', self.slice_method(self.C,self.current_slice(2),'y',self.slice_args));
                self.image.YZ.set('CData', self.slice_method(self.C,self.current_slice(1),'x',self.slice_args));
            end
        end    
    end
end