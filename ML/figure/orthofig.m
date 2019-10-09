classdef orthofig < cubefig 
    
    properties
        current_slice = [1,1,1];
        previous_slice = [1,1,1];   
    end
    
    properties (Access = private)                
        z_ratio = 2;
        pad = [75 0 0 0]
        
        roaming = false;
        
        
        border = 5;     % border distance (v,h)
        w_img = 80;     % image controls width
        d_img_xyz = 20; % distance between image controls and axis controls
        w_lab = 40;     % axis control label width
        w_db = 45;      % width of db button
        
        histograms = struct('bins', 200);
        show_histograms = false;
        ui_histograms;
    end
    
    methods 
        function self = orthofig(C, fig, M, z_ratio, slice_method)
            switch nargin
                case 1
                    fig = figure;
                    M = 0.3;
                    z_ratio = 2;
                    slice_method = @slice;
                case 2
                    M = [560 420];
                    z_ratio = 2;
                    slice_method = @slice;
                case 3
                    z_ratio = 2;
                    slice_method = @slice;
                case 4
                    slice_method = @slice;
            end
            
            self.C = C;
            self.size = size(C);
            
            self.f = fig; 
            
            self.M = M;
            if ~isnan(z_ratio) && self.z_ratio > 0
                self.z_ratio = z_ratio;
            else
                self.z_ratio = 1;
            end
            
            self.slice_method = slice_method;
            
            self.build;
        end
        
        function build(self)
            build@cubefig(self);
            
            Nx = self.size(1); Ny = self.size(2); Nz = self.size(3);  
            
            [self.image.XY, self.image.XZ, self.image.YZ, self.image.overlay, self.pad] = imshow_tight_ortho( ...
                self.C, self.current_slice, self.slice_method, self.slice_args, ...
                self.M, self.z_ratio, self.pad ...
            );
        
            aXY = copyobj(self.image.XY.Parent, self.f); cla(aXY);
            aXZ = copyobj(self.image.XZ.Parent, self.f); cla(aXZ);
            aYZ = copyobj(self.image.YZ.Parent, self.f); cla(aYZ);

            ap = get(aXY, 'Position');
            w_xy = ap(3);   % width of XY image
            

            self.control.Z_slider = uicontrol('style', 'slider', ...
                'Position', [self.border + self.w_img + self.d_img_xyz + self.w_lab, ...
                                5, w_xy - self.w_img - self.d_img_xyz - self.w_lab, 20] ,...
                'Value', self.current_slice(3), 'min', 1, 'max', Nz, ...
                'SliderStep', [1/Nz, 1/Nz] ...
                );
            self.control.Z_text = uicontrol('style', 'text', ...
                'Position', [self.border + self.w_img + self.d_img_xyz, 3, self.w_lab,20], ...
                'String', sprintf('z(%d)',self.current_slice(3)));
            addlistener(self.control.Z_slider, 'Value', 'PostSet', @self.Z_slider_callback);

            self.control.Y_text = uicontrol('style', 'text', ...
                'Position', [self.border + self.w_img + self.d_img_xyz, 25, self.w_lab,20], ...
                'String', sprintf('y(%d)',self.current_slice(2)));
            self.control.Y_slider = uicontrol('style', 'slider', ...
                'Position', [self.border + self.w_img + self.d_img_xyz + self.w_lab, ...
                                27, w_xy - self.w_img - self.d_img_xyz - self.w_lab,20] ,...
                'Value', self.current_slice(2), 'min', 1, 'max', Ny, ...
                'SliderStep', [1/Ny, 1/Ny] ...
                );
            addlistener(self.control.Y_slider, 'Value', 'PostSet', @self.Y_slider_callback);

            self.control.X_text = uicontrol('style', 'text', ...
                'Position', [self.border + self.w_img + self.d_img_xyz, 47, self.w_lab, 20], ...
                'String', sprintf('x(%d)',self.current_slice(1)));
            self.control.X_slider = uicontrol('style', 'slider', ...
                'Position', [self.border + self.w_img + self.d_img_xyz + self.w_lab, ...
                                49, w_xy - self.w_img - self.d_img_xyz - self.w_lab,20] ,...
                'Value', self.current_slice(1), 'min', 1, 'max', Nx, ...
                'SliderStep', [1/Nx, 1/Nx] ...
                );
            addlistener(self.control.X_slider, 'Value', 'PostSet', @self.X_slider_callback);

            set(self.f, 'WindowScrollWheelFcn', @self.scroll);

            set(self.image.XY, 'ButtonDownFcn', @self.XY_ButtonDownFcn);
            set(self.image.XZ, 'ButtonDownFcn', @self.XZ_ButtonDownFcn);
            set(self.image.YZ, 'ButtonDownFcn', @self.YZ_ButtonDownFcn);
            set(self.f, 'WindowButtonUpFcn', @self.WindowButtonUpFcn);
            set(self.f, 'WindowButtonMotionFcn', @self.WindowButtonMotionFcn);

            positions = struct(                                                 ...
                'ui_slice_method', [self.border, 58, self.w_img, 12],                         ...
                'ui_db', [self.border-1, self.border+20, self.w_db, 20],                          ...
                'ui_db_floor', [self.border + self.w_db, self.border, self.w_img - self.w_db-1,20],    ...
                'ui_db_ceil', [self.border+self.w_db, self.border+1+20, self.w_img-self.w_db-1, 20]    ...
            );
            images = [self.image.XY.Parent, self.image.XZ.Parent, self.image.YZ.Parent];
        
            self.imagecontrol = postprocon(self, positions, @self.ui_update_images, images);
            
            dfpos = [0 0 self.pad(3)+self.pad(4) self.pad(1)+self.pad(2)];
            dhpos = [self.pad(3) self.pad(1) 0 0];

            X = Ny*self.M; % Notice: X and Y switched (!!!)
            Y = Nx*self.M;
            Z = Nz*self.M*self.z_ratio;

            set(self.f, 'Position', [self.f.Position(1), self.f.Position(2), X+Z, Y+Z] + dfpos);
            set(self.image.XY.Parent, 'Position', [0,Z+2,X,Y] + dhpos);
            set(self.image.XZ.Parent, 'Position', [X+2,Z+2,Z,Y] + dhpos);
            set(self.image.YZ.Parent, 'Position', [0,0,X,Z] + dhpos);  
            
            self.ui_histograms = uicontrol('Style', 'togglebutton', 'String', 'Histo', ...
                'Position', [positions.ui_db(1), self.border, positions.ui_db(3), positions.ui_db(4)], ...
                'Value', self.show_histograms, 'callback', @self.ui_toggle_histograms);
            
            self.ui_update_images;
            self.place_overlay;
            self.ui_update_histograms;
            set(self.f, 'visible', 'on')
        end    
    
    %% Callbacks
    
            

        function Z_slider_callback(self, ~, eventdata)            
            self.previous_slice = self.current_slice;
            new_Z_slice = floor(get(eventdata.AffectedObject, 'Value'));
            self.current_slice(3) = new_Z_slice;
            self.control.Z_text.String = sprintf('z(%d)',new_Z_slice);
            
            self.image.temp.XY = self.slice_method(self.C,self.current_slice(3),'z',self.slice_args);           
            
            if self.do_db
                self.image.temp.XY_db = dBs(self.image.temp.XY, self.noise_floor, self.signal_ceil);
                self.image.XY.set('CData', rescale(self.image.temp.XY_db));
            else
                self.image.XY.set('CData', self.image.temp.XY);
            end

            self.place_overlay;
            self.ui_update_histograms;
        end

        function Y_slider_callback(self, ~, eventdata)
            self.previous_slice = self.current_slice;
            new_Y_slice = floor(get(eventdata.AffectedObject, 'Value'));
            self.current_slice(2) = new_Y_slice;
            self.control.Y_text.String = sprintf('y(%d)',new_Y_slice);
            
            self.image.temp.XZ = self.slice_method(self.C,self.current_slice(2),'y',self.slice_args);         
            
            if self.do_db
                self.image.temp.XZ_db = dBs(self.image.temp.XZ, self.noise_floor, self.signal_ceil);
                self.image.XZ.set('CData', rescale(self.image.temp.XZ_db)); 
            else
                self.image.XZ.set('CData', self.image.temp.XZ);
            end
            
            self.place_overlay;
            self.ui_update_histograms;
        end

        function X_slider_callback(self, ~, eventdata)
            self.previous_slice = self.current_slice;
            new_X_slice = floor(get(eventdata.AffectedObject, 'Value'));
            self.current_slice(1) = new_X_slice;
            self.control.X_text.String = sprintf('x(%d)', new_X_slice);
            
            self.image.temp.YZ = self.slice_method(self.C,self.current_slice(1),'x',self.slice_args);            
            
            if self.do_db
                self.image.temp.YZ_db = dBs(self.image.temp.YZ, self.noise_floor, self.signal_ceil);   
                self.image.YZ.set('CData', rescale(self.image.temp.YZ_db));  
            else
                self.image.YZ.set('CData', self.image.temp.YZ);
            end

            self.place_overlay;
            self.ui_update_histograms;
        end

        function place_overlay(self)    
            Nx = self.size(1); Ny = self.size(2); Nz = self.size(3);
            
            self.image.overlay.XY.X.XData = [0,Ny];
            self.image.overlay.XY.X.YData = [self.current_slice(1), self.current_slice(1)];
            self.image.overlay.XZ.X.XData = [0,Nz];
            self.image.overlay.XZ.X.YData = [self.current_slice(1), self.current_slice(1)];
            
            self.image.overlay.XY.Y.YData = [0,Ny];
            self.image.overlay.XY.Y.XData = [self.current_slice(2), self.current_slice(2)];
            self.image.overlay.YZ.Y.YData = [0,Nz];
            self.image.overlay.YZ.Y.XData = [self.current_slice(2), self.current_slice(2)];
            
            self.image.overlay.XZ.Z.YData = [0,Nx];
            self.image.overlay.XZ.Z.XData = [self.current_slice(3), self.current_slice(3)];
            self.image.overlay.YZ.Z.XData = [0,Ny];
            self.image.overlay.YZ.Z.YData = [self.current_slice(3), self.current_slice(3)];
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
                case 'alt'
                    new_value = get(self.control.Y_slider, 'Value') - 1 * eventdata.VerticalScrollCount*10;
                    if new_value <= get(self.control.Y_slider, 'max') && new_value >= get(self.control.Y_slider, 'min')
                        set(self.control.Y_slider, 'Value', new_value);
                    end
                case 'control'
                    new_value = self.M * (1 - 0.05*eventdata.VerticalScrollCount);
                    Nx = self.size(1); Ny = self.size(2); Nz = self.size(3);
                    
                    if any([Nx,Ny] * new_value < monitor_resolution * 0.5) && any([Nx,Ny] * new_value > monitor_resolution * 0.25)
                        self.M = new_value;

                        dfpos = [0 0 self.pad(3)+self.pad(4) self.pad(1)+self.pad(2)];
                        dhpos = [self.pad(3) self.pad(1) 0 0];

                        X = Ny*self.M; % Notice: X and Y switched (!!!)
                        Y = Nx*self.M;
                        Z = Nz*self.M*self.z_ratio;

                        set(self.f, 'Position', [self.f.Position(1), self.f.Position(2), X+Z, Y+Z] + dfpos);
                        set(self.image.XY.Parent, 'Position', [0,Z+2,X,Y] + dhpos);
                        set(self.image.XZ.Parent, 'Position', [X+2,Z+2,Z,Y] + dhpos);
                        set(self.image.YZ.Parent, 'Position', [0,0,X,Z] + dhpos);  
                        
                        ap = get(self.image.XY.Parent, 'Position');
                        w_xy = ap(3);   % width of XY image
                        
                        set(self.control.Z_slider, 'Position', [self.border + self.w_img + self.d_img_xyz + self.w_lab, 5, w_xy - self.w_img - self.d_img_xyz - self.w_lab, 20])
                        set(self.control.Y_slider, 'Position', [self.border + self.w_img + self.d_img_xyz + self.w_lab, 27, w_xy - self.w_img - self.d_img_xyz - self.w_lab,20])
                        set(self.control.X_slider, 'Position', [self.border + self.w_img + self.d_img_xyz + self.w_lab, 49, w_xy - self.w_img - self.d_img_xyz - self.w_lab,20])
                        self.ui_update_histograms
                    end
                otherwise
                    new_value = get(self.control.Z_slider, 'Value') - 1 * eventdata.VerticalScrollCount;
                    if new_value <= get(self.control.Z_slider, 'max') && new_value >= get(self.control.Z_slider, 'min')
                        set(self.control.Z_slider, 'Value', new_value);
                    end                        
            end

        end
        
        function WindowButtonUpFcn(self, ~, ~)
            self.roaming = false;
        end
        
        function WindowButtonMotionFcn(self, stuff, eventdata)
            if self.roaming
                self.f.CurrentObject.ButtonDownFcn(stuff, eventdata)                              
            end
        end

        function XY_ButtonDownFcn(self, ~, eventdata)    
            self.roaming = true;
            pos = floor(eventdata.IntersectionPoint);

            if ~any(isnan(pos)) && 1 < pos(2) < self.size(1) && 1 < pos(1) < self.size(2)
                self.previous_slice = self.current_slice;
                self.current_slice(1) = pos(2); self.current_slice(1) = pos(1);
                try
                    set(self.control.Y_slider, 'Value', pos(1));
                    set(self.control.X_slider, 'Value', pos(2));

                    self.update()
                catch err
                   pass
                end
            end
        end

        function XZ_ButtonDownFcn(self, ~, eventdata)     
            self.roaming = true;
            pos = floor(eventdata.IntersectionPoint);  
            
            if ~any(isnan(pos))  && 1 < pos(2) < self.size(1) && 1 < pos(1) < self.size(3)
                self.previous_slice = self.current_slice;
                self.current_slice(1) = pos(2); self.current_slice(3) = pos(1);
                try
                    set(self.control.X_slider, 'Value', pos(2));
                    set(self.control.Z_slider, 'Value', pos(1));

                    self.update();
                catch err
                    pass
                end
            end
        end

        function YZ_ButtonDownFcn(self, ~, eventdata)
            self.roaming = true;
            pos = floor(eventdata.IntersectionPoint);
            
            if ~any(isnan(pos))  && 1 < pos(2) < self.size(3) && 1 < pos(1) < self.size(2)
                self.previous_slice = self.current_slice;
                self.current_slice(2) = pos(1); self.current_slice(3) = pos(2);
                try
                    set(self.control.Y_slider, 'Value', pos(1));
                    set(self.control.Z_slider, 'Value', pos(2));

                    self.update();
                catch err
                    pass
                end
            end
        end
        
        function ui_toggle_histograms(self, ~, eventdata)       
            self.show_histograms = eventdata.Source.Value;

            if self.show_histograms
               self.ui_update_histograms 
            end 
            
            if any(strcmp(fieldnames(self.histograms), 'axes'))
                for axis = [self.histograms.axes.XY, self.histograms.axes.XZ, self.histograms.axes.YZ]
                    set(axis, 'Visible', self.show_histograms);
                    set(get(axis, 'Children'), 'Visible', self.show_histograms);
                end
            end
        end        
    end
    
    methods(Access = public)  % Actually, why are these even public at all?
        function update(self)
            update@cubefig(self)
            self.ui_update_images
            self.ui_update_histograms
            self.place_overlay
        end
        
        function ui_update_images(self)
            self.image.temp.XY = self.slice_method(self.C,self.current_slice(3),'z',self.slice_args);
            self.image.temp.XZ = self.slice_method(self.C,self.current_slice(2),'y',self.slice_args);
            self.image.temp.YZ = self.slice_method(self.C,self.current_slice(1),'x',self.slice_args);            
            
            if self.do_db
                self.image.temp.XY_db = dBs(self.image.temp.XY, self.noise_floor, self.signal_ceil);
                self.image.temp.XZ_db = dBs(self.image.temp.XZ, self.noise_floor, self.signal_ceil);
                self.image.temp.YZ_db = dBs(self.image.temp.YZ, self.noise_floor, self.signal_ceil);   
                self.image.XY.set('CData', rescale(self.image.temp.XY_db));
                self.image.XZ.set('CData', rescale(self.image.temp.XZ_db));
                self.image.YZ.set('CData', rescale(self.image.temp.YZ_db));  
            else
                self.image.XY.set('CData', self.image.temp.XY);
                self.image.XZ.set('CData', self.image.temp.XZ);
                self.image.YZ.set('CData', self.image.temp.YZ);
            end
        end    
        
        function ui_update_histograms(self)            
            if self.show_histograms
                % Don't do global histogram: takes too long, but parallel pool takes even longer to start up :)                    
                if ~any(strcmp(fieldnames(self.histograms), 'axes'))
                    

                    self.histograms.axes.YZ = axes(self.f);       
                    self.histograms.axes.XZ = axes(self.f);       
                    self.histograms.axes.XY = axes(self.f);
                     
                    self.histograms.xscale = [rmin(self.C), rmax(self.C)];
                end
                
                % Only need to do this when building or rescaling
                posXZ = self.image.XZ.Parent.Position;
                posYZ = self.image.YZ.Parent.Position;
                    
                dh = 12;
                w0 = posXZ(1); h0 = posYZ(2)+dh; w = posXZ(3); h = (posYZ(4) - 4 - dh)/3; % 2px gap between axes
                setpixelposition(self.histograms.axes.YZ, [w0, h0, w, h]);
                setpixelposition(self.histograms.axes.XZ, [w0, h0+2+h, w, h]);
                setpixelposition(self.histograms.axes.XY, [w0, h0+2+h+2+h, w, h]);
                
                if self.do_db % Replace with call to CubePostprocess
                   xscale = 10*log10(self.histograms.xscale-min(self.histograms.xscale)+1); 
                else
                   xscale = self.histograms.xscale;
                end

                axes(self.histograms.axes.XY);
                
                if self.do_db % Replace with call to CubePostprocess
                    self.histograms.XY = histogram(dBs(self.image.temp.XY), self.histograms.bins, ...
                        'LineStyle', 'none', 'FaceColor', 'k', 'FaceAlpha', 0.1);
                    hold on
                    histogram(self.image.temp.XY_db, self.histograms.bins, 'LineStyle', 'none', 'FaceColor', 'k');
                    hold off
                else
                    self.histograms.XY = histogram(self.image.temp.XY, self.histograms.bins, ...
                    'LineStyle', 'none', 'FaceColor', 'k');
                end
                set(gca, 'YScale', 'Log');
                set(gca, 'YTick', []);
                set(gca, 'YLabel', []);
                set(gca, 'XTick', []);
                set(gca, 'XLabel', []);
                xlim(xscale);

                axes(self.histograms.axes.XZ);
                
                if self.do_db
                    self.histograms.XZ = histogram(dBs(self.image.temp.XZ), self.histograms.bins, ...
                        'LineStyle', 'none', 'FaceColor', 'k', 'FaceAlpha', 0.1);
                    hold on
                    histogram(self.image.temp.XZ_db, self.histograms.bins, 'LineStyle', 'none', 'FaceColor', 'k');
                    hold off
                else
                    self.histograms.XZ = histogram(self.image.temp.XZ, self.histograms.bins, ...
                        'LineStyle', 'none', 'FaceColor', 'k');
                end
                set(gca, 'YScale', 'Log');
                set(gca, 'YTick', []);
                set(gca, 'YLabel', []);
                set(gca, 'XTick', []);
                set(gca, 'XLabel', []);
                xlim(xscale);

                axes(self.histograms.axes.YZ);
                
                if self.do_db
                    self.histograms.YZ = histogram(dBs(self.image.temp.YZ), self.histograms.bins, ...
                        'LineStyle', 'none', 'FaceColor', 'k', 'FaceAlpha', 0.1);
                    hold on
                    histogram(self.image.temp.YZ_db, self.histograms.bins, 'LineStyle', 'none', 'FaceColor', 'k');
                    hold off
                else
                    self.histograms.YZ = histogram(self.image.temp.YZ, self.histograms.bins, ...
                        'LineStyle', 'none', 'FaceColor', 'k');
                end
                set(gca, 'YScale', 'Log');
                set(gca, 'YTick', []);
                set(gca, 'YLabel', []);
                xlim(xscale);
            end
        end
    end
end

