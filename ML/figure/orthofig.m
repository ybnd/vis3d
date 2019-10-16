classdef orthofig < cubefig 
    
    properties
        current_slice = [1,1,1];
        previous_slice = [1,1,1];   
    end
    
    properties (Access = private)      
        range;
        
        z_ratio = 2;
        pad = [75 0 0 0]
        
        roaming = false;
       
        slice = false;          % Placeholder for slice InteractiveMethodSelector
        postprocess = false;    % Placeholder for postprocess InteractiveMethodSelector
        
        border = 5;     % border distance (v,h)
        w_img = 160;     % image controls width
        d_img_xyz = 20; % distance between image controls and axis controls
        w_lab = 40;     % axis control label width
        w_db = 82;      % width of db button
        
        histograms = struct('bins', 200, 'samples', 50000);
        show_histograms = false;
        ui_histograms;
    end
    
    methods 
        function obj = orthofig(C, fig, M, z_ratio)
            switch nargin
                case 1
                    fig = figure;
                    M = 0.3;
                    z_ratio = 2;
                case 2
                    M = [560 420];
                    z_ratio = 2;
                case 3
                    z_ratio = 2;
            end
            
            obj.C = C;
            obj.size = size(C.cube);
            
            obj.f = fig; 
            
            obj.M = M;
            if ~isnan(z_ratio) && obj.z_ratio > 0
                obj.z_ratio = z_ratio;
            else
                obj.z_ratio = 1;
            end
            
            obj.range = [rmin(C.cube), rmax(C.cube)];
            obj.build;
        end
        
        function build(obj)
            build@cubefig(obj);
            
            Nx = obj.size(1); Ny = obj.size(2); Nz = obj.size(3);  
            
            [obj.image.XY, obj.image.XZ, obj.image.YZ, obj.image.overlay, obj.pad] = imshow_tight_ortho( ...
                obj.C, obj.current_slice, obj.M, obj.z_ratio, obj.pad ...
            );
        
            aXY = copyobj(obj.image.XY.Parent, obj.f); cla(aXY);
            aXZ = copyobj(obj.image.XZ.Parent, obj.f); cla(aXZ);
            aYZ = copyobj(obj.image.YZ.Parent, obj.f); cla(aYZ);

            ap = get(aXY, 'Position');
            w_xy = ap(3);   % width of XY image
            
            gui = interactive_methods_gui;
            
            obj.w_img = gui.selector_width + gui.controls_max_width + 3*gui.gap;

            obj.slice = obj.C.im.selectors.slice;
            obj.postprocess = obj.C.im.selectors.postprocess;
            
            obj.slice.build_gui(obj.f, [obj.border, 47], @obj.ui_update_images, {'position', 'axis'});
            obj.postprocess.build_gui(obj.f, [obj.border, 47-gui.height-gui.gap], @obj.ui_update_images, {'global range'});
            obj.postprocess.select('dBs_global');
            obj.postprocess.set('global range', obj.range);
            
            

            obj.control.Z_slider = uicontrol('style', 'slider', ...
                'Position', [obj.border + obj.w_img + obj.d_img_xyz + obj.w_lab, ...
                                5, w_xy - obj.w_img - obj.d_img_xyz - obj.w_lab, 20] ,...
                'Value', obj.current_slice(3), 'min', 1, 'max', Nz, ...
                'SliderStep', [1/Nz, 1/Nz] ...
                );
            obj.control.Z_text = uicontrol('style', 'text', ...
                'Position', [obj.border + obj.w_img + obj.d_img_xyz, 3, obj.w_lab,20], ...
                'String', sprintf('z(%d)',obj.current_slice(3)));
            addlistener(obj.control.Z_slider, 'Value', 'PostSet', @obj.Z_slider_callback);

            obj.control.Y_text = uicontrol('style', 'text', ...
                'Position', [obj.border + obj.w_img + obj.d_img_xyz, 25, obj.w_lab,20], ...
                'String', sprintf('y(%d)',obj.current_slice(2)));
            obj.control.Y_slider = uicontrol('style', 'slider', ...
                'Position', [obj.border + obj.w_img + obj.d_img_xyz + obj.w_lab, ...
                                27, w_xy - obj.w_img - obj.d_img_xyz - obj.w_lab,20] ,...
                'Value', obj.current_slice(2), 'min', 1, 'max', Ny, ...
                'SliderStep', [1/Ny, 1/Ny] ...
                );
            addlistener(obj.control.Y_slider, 'Value', 'PostSet', @obj.Y_slider_callback);

            obj.control.X_text = uicontrol('style', 'text', ...
                'Position', [obj.border + obj.w_img + obj.d_img_xyz, 47, obj.w_lab, 20], ...
                'String', sprintf('x(%d)',obj.current_slice(1)));
            obj.control.X_slider = uicontrol('style', 'slider', ...
                'Position', [obj.border + obj.w_img + obj.d_img_xyz + obj.w_lab, ...
                                49, w_xy - obj.w_img - obj.d_img_xyz - obj.w_lab,20] ,...
                'Value', obj.current_slice(1), 'min', 1, 'max', Nx, ...
                'SliderStep', [1/Nx, 1/Nx] ...
                );
            addlistener(obj.control.X_slider, 'Value', 'PostSet', @obj.X_slider_callback);

            set(obj.f, 'WindowScrollWheelFcn', @obj.scroll);

            set(obj.image.XY, 'ButtonDownFcn', @obj.XY_ButtonDownFcn);
            set(obj.image.XZ, 'ButtonDownFcn', @obj.XZ_ButtonDownFcn);
            set(obj.image.YZ, 'ButtonDownFcn', @obj.YZ_ButtonDownFcn);
            set(obj.f, 'WindowButtonUpFcn', @obj.WindowButtonUpFcn);
            set(obj.f, 'WindowButtonMotionFcn', @obj.WindowButtonMotionFcn);

            positions = struct(                                                 ...
                'ui_slice_method', [obj.border, 58, obj.w_img, 12],                         ...
                'ui_db', [obj.border-1, obj.border+20, obj.w_db, 20],                          ...
                'ui_db_floor', [obj.border + obj.w_db, obj.border, obj.w_img - obj.w_db-1,20],    ...
                'ui_db_ceil', [obj.border+obj.w_db, obj.border+1+20, obj.w_img-obj.w_db-1, 20]    ...
            );
            
            dfpos = [0 0 obj.pad(3)+obj.pad(4) obj.pad(1)+obj.pad(2)];
            dhpos = [obj.pad(3) obj.pad(1) 0 0];

            X = Ny*obj.M; % Notice: X and Y switched (!!!)
            Y = Nx*obj.M;
            Z = Nz*obj.M*obj.z_ratio;

            set(obj.f, 'Position', [obj.f.Position(1), obj.f.Position(2), X+Z, Y+Z] + dfpos);
            set(obj.image.XY.Parent, 'Position', [0,Z+2,X,Y] + dhpos);
            set(obj.image.XZ.Parent, 'Position', [X+2,Z+2,Z,Y] + dhpos);
            set(obj.image.YZ.Parent, 'Position', [0,0,X,Z] + dhpos);  
            
            obj.ui_histograms = uicontrol('Style', 'togglebutton', 'String', 'Histogram', ...
                'Position', [positions.ui_db(1), obj.border, positions.ui_db(3), positions.ui_db(4)], ...
                'Value', obj.show_histograms, 'callback', @obj.ui_toggle_histograms);
            
               

            obj.ui_update_images;
            obj.place_overlay;
            obj.ui_update_histograms;
            set(obj.f, 'visible', 'on')    
        end    
    
    %% Callbacks
    
            

        function Z_slider_callback(obj, ~, eventdata)            
            obj.previous_slice = obj.current_slice;
            new_Z_slice = floor(get(eventdata.AffectedObject, 'Value'));
            obj.current_slice(3) = new_Z_slice;
            obj.control.Z_text.String = sprintf('z(%d)',new_Z_slice);

            [obj.image.temp.XY, obj.image.temp.rawXY] = obj.C.slice(obj.current_slice(3),'z');
            obj.image.XY.set('CData',obj.image.temp.XY);

            obj.place_overlay;
            obj.ui_update_histograms;
        end

        function Y_slider_callback(obj, ~, eventdata)
            obj.previous_slice = obj.current_slice;
            new_Y_slice = floor(get(eventdata.AffectedObject, 'Value'));
            obj.current_slice(2) = new_Y_slice;
            obj.control.Y_text.String = sprintf('y(%d)',new_Y_slice);
                        
            [obj.image.temp.XZ, obj.image.temp.rawXZ] = obj.C.slice(obj.current_slice(2),'y');
            obj.image.XZ.set('CData', obj.image.temp.XZ);
            
            obj.place_overlay;
            obj.ui_update_histograms;
        end

        function X_slider_callback(obj, ~, eventdata)
            obj.previous_slice = obj.current_slice;
            new_X_slice = floor(get(eventdata.AffectedObject, 'Value'));
            obj.current_slice(1) = new_X_slice;
            obj.control.X_text.String = sprintf('x(%d)', new_X_slice);
            
            [obj.image.temp.YZ, obj.image.temp.rawYZ] = obj.C.slice(obj.current_slice(1),'x');
            obj.image.YZ.set('CData', obj.image.temp.YZ);

            obj.place_overlay;
            obj.ui_update_histograms;
        end

        function place_overlay(obj)    
            Nx = obj.size(1); Ny = obj.size(2); Nz = obj.size(3);
            
            obj.image.overlay.XY.X.XData = [0,Ny];
            obj.image.overlay.XY.X.YData = [obj.current_slice(1), obj.current_slice(1)];
            obj.image.overlay.XZ.X.XData = [0,Nz];
            obj.image.overlay.XZ.X.YData = [obj.current_slice(1), obj.current_slice(1)];
            
            obj.image.overlay.XY.Y.YData = [0,Ny];
            obj.image.overlay.XY.Y.XData = [obj.current_slice(2), obj.current_slice(2)];
            obj.image.overlay.YZ.Y.YData = [0,Nz];
            obj.image.overlay.YZ.Y.XData = [obj.current_slice(2), obj.current_slice(2)];
            
            obj.image.overlay.XZ.Z.YData = [0,Nx];
            obj.image.overlay.XZ.Z.XData = [obj.current_slice(3), obj.current_slice(3)];
            obj.image.overlay.YZ.Z.XData = [0,Ny];
            obj.image.overlay.YZ.Z.YData = [obj.current_slice(3), obj.current_slice(3)];
        end

        function scroll(obj, source, eventdata)
            method = get(source, 'CurrentModifier');
            if isempty(method); method = {''}; end

            switch method{1}
                case 'shift'
                    new_value = get(obj.control.X_slider, 'Value') - 1 * eventdata.VerticalScrollCount*10;
                    if new_value <= get(obj.control.X_slider, 'max') && new_value >= get(obj.control.X_slider, 'min')
                        set(obj.control.X_slider, 'Value', new_value);
                    end
                case 'alt'
                    new_value = get(obj.control.Y_slider, 'Value') - 1 * eventdata.VerticalScrollCount*10;
                    if new_value <= get(obj.control.Y_slider, 'max') && new_value >= get(obj.control.Y_slider, 'min')
                        set(obj.control.Y_slider, 'Value', new_value);
                    end
                case 'control'
                    new_value = obj.M * (1 - 0.05*eventdata.VerticalScrollCount);
                    Nx = obj.size(1); Ny = obj.size(2); Nz = obj.size(3);
                    
                    if any([Nx,Ny] * new_value < monitor_resolution * 0.5) && any([Nx,Ny] * new_value > monitor_resolution * 0.25)
                        obj.M = new_value;

                        dfpos = [0 0 obj.pad(3)+obj.pad(4) obj.pad(1)+obj.pad(2)];
                        dhpos = [obj.pad(3) obj.pad(1) 0 0];

                        X = Ny*obj.M; % Notice: X and Y switched (!!!)
                        Y = Nx*obj.M;
                        Z = Nz*obj.M*obj.z_ratio;

                        set(obj.f, 'Position', [obj.f.Position(1), obj.f.Position(2), X+Z, Y+Z] + dfpos);
                        set(obj.image.XY.Parent, 'Position', [0,Z+2,X,Y] + dhpos);
                        set(obj.image.XZ.Parent, 'Position', [X+2,Z+2,Z,Y] + dhpos);
                        set(obj.image.YZ.Parent, 'Position', [0,0,X,Z] + dhpos);  
                        
                        ap = get(obj.image.XY.Parent, 'Position');
                        w_xy = ap(3);   % width of XY image
                        
                        set(obj.control.Z_slider, 'Position', [obj.border + obj.w_img + obj.d_img_xyz + obj.w_lab, 5, w_xy - obj.w_img - obj.d_img_xyz - obj.w_lab, 20])
                        set(obj.control.Y_slider, 'Position', [obj.border + obj.w_img + obj.d_img_xyz + obj.w_lab, 27, w_xy - obj.w_img - obj.d_img_xyz - obj.w_lab,20])
                        set(obj.control.X_slider, 'Position', [obj.border + obj.w_img + obj.d_img_xyz + obj.w_lab, 49, w_xy - obj.w_img - obj.d_img_xyz - obj.w_lab,20])
                        obj.ui_update_histograms
                    end
                otherwise
                    new_value = get(obj.control.Z_slider, 'Value') - 1 * eventdata.VerticalScrollCount;
                    if new_value <= get(obj.control.Z_slider, 'max') && new_value >= get(obj.control.Z_slider, 'min')
                        set(obj.control.Z_slider, 'Value', new_value);
                    end                        
            end

        end
        
        function WindowButtonUpFcn(obj, ~, ~)
            obj.roaming = false;
        end
        
        function WindowButtonMotionFcn(obj, stuff, eventdata)
            if obj.roaming
                obj.f.CurrentObject.ButtonDownFcn(stuff, eventdata)                              
            end
        end

        function XY_ButtonDownFcn(obj, ~, eventdata)    
            obj.roaming = true;
            pos = floor(eventdata.IntersectionPoint);

            if ~any(isnan(pos)) && 1 < pos(2) < obj.size(1) && 1 < pos(1) < obj.size(2)
                obj.previous_slice = obj.current_slice;
                obj.current_slice(1) = pos(2); obj.current_slice(1) = pos(1);
                try
                    set(obj.control.Y_slider, 'Value', pos(1));
                    set(obj.control.X_slider, 'Value', pos(2));

                    obj.update()
                catch err
                   pass
                end
            end
        end

        function XZ_ButtonDownFcn(obj, ~, eventdata)     
            obj.roaming = true;
            pos = floor(eventdata.IntersectionPoint);  
            
            if ~any(isnan(pos))  && 1 < pos(2) < obj.size(1) && 1 < pos(1) < obj.size(3)
                obj.previous_slice = obj.current_slice;
                obj.current_slice(1) = pos(2); obj.current_slice(3) = pos(1);
                try
                    set(obj.control.X_slider, 'Value', pos(2));
                    set(obj.control.Z_slider, 'Value', pos(1));

                    obj.update();
                catch err
                    pass
                end
            end
        end

        function YZ_ButtonDownFcn(obj, ~, eventdata)
            obj.roaming = true;
            pos = floor(eventdata.IntersectionPoint);
            
            if ~any(isnan(pos))  && 1 < pos(2) < obj.size(3) && 1 < pos(1) < obj.size(2)
                obj.previous_slice = obj.current_slice;
                obj.current_slice(2) = pos(1); obj.current_slice(3) = pos(2);
                try
                    set(obj.control.Y_slider, 'Value', pos(1));
                    set(obj.control.Z_slider, 'Value', pos(2));

                    obj.update();
                catch err
                    pass
                end
            end
        end
        
        function ui_toggle_histograms(obj, ~, eventdata)       
            obj.show_histograms = eventdata.Source.Value;
            
            if any(strcmp(fieldnames(obj.histograms), 'axes'))
                for axis = [obj.histograms.axes.XY, obj.histograms.axes.XZ, obj.histograms.axes.YZ]
                    set(axis, 'Visible', obj.show_histograms);
                    set(get(axis, 'Children'), 'Visible', obj.show_histograms);
                end
            end
            
            if obj.show_histograms
               obj.ui_update_histograms 
            end 
        end        
    end
    
    methods(Access = public)  % Actually, why are these even public at all?
        function update(obj)
            update@cubefig(obj)
            obj.ui_update_images
            obj.ui_update_histograms
            obj.place_overlay
        end
        
        function ui_update_images(obj)
            [obj.image.temp.XY, obj.image.temp.rawXY] = obj.C.slice(obj.current_slice(3),'z');
            [obj.image.temp.XZ, obj.image.temp.rawXZ] = obj.C.slice(obj.current_slice(2),'y');
            [obj.image.temp.YZ, obj.image.temp.rawYZ] = obj.C.slice(obj.current_slice(1),'x');

            obj.image.XY.set('CData', obj.image.temp.XY);
            obj.image.XZ.set('CData', obj.image.temp.XZ);
            obj.image.YZ.set('CData', obj.image.temp.YZ);
            
            obj.ui_update_histograms;         
        end    
        
        function ui_update_histograms(obj)            
            if obj.show_histograms
                
                % Don't do global histogram: takes too long, but parallel pool takes even longer to start up :)                    
                if ~any(strcmp(fieldnames(obj.histograms), 'axes'))
                    
                    obj.histograms.axes.YZ = axes(obj.f);       
                    obj.histograms.axes.XZ = axes(obj.f);       
                    obj.histograms.axes.XY = axes(obj.f);
                    
                    set(obj.histograms.axes.YZ, 'YTick', []);
                    set(obj.histograms.axes.YZ, 'XTick', []);
                    set(obj.histograms.axes.XZ, 'YTick', []);
                    set(obj.histograms.axes.XZ, 'XTick', []);
                    set(obj.histograms.axes.XY, 'YTick', []);
                    set(obj.histograms.axes.XY, 'XTick', []);
                     
                    title(obj.histograms.axes.XY, 'XY', 'Position', [1,1,0])
                    
                    obj.histograms.xscale = obj.range;
                end
                
                % Only need to do this when building or rescaling
                posXZ = obj.image.XZ.Parent.Position;
                posYZ = obj.image.YZ.Parent.Position;
                    
                dh = 0;
                gap = -1;
                w0 = posXZ(1); h0 = posYZ(2)+dh; w = posXZ(3); h = (posYZ(4) - 2*gap - dh)/3;
                setpixelposition(obj.histograms.axes.YZ, [w0, h0, w, h]);
                setpixelposition(obj.histograms.axes.XZ, [w0, h0+gap+h, w, h]);
                setpixelposition(obj.histograms.axes.XY, [w0, h0+gap+h+gap+h, w, h]);
                
                xscale = obj.postprocess.do(obj.histograms.xscale-min(obj.histograms.xscale)+1); 

                axes(obj.histograms.axes.XY);
                
                
                obj.histograms.XY = histogram( ...
                    obj.image.temp.XY(randi(numel(obj.image.temp.XY),obj.histograms.samples,1)), ...
                    obj.histograms.bins, 'LineStyle', 'none', 'FaceColor', 'k', 'FaceAlpha', 0.5 ...
                );

                set(gca, 'YScale', 'Log');
                set(gca, 'YTick', []);
                set(gca, 'XTick', []);
                set(gca, 'XColor', [0.5, 0.5, 0.5]);
                set(gca, 'YColor', [0.5, 0.5, 0.5]);
                xlim(xscale);

                axes(obj.histograms.axes.XZ);
                
                obj.histograms.XZ = histogram( ...
                    obj.image.temp.XZ(randi(numel(obj.image.temp.XZ),obj.histograms.samples,1)), ...
                    obj.histograms.bins, 'LineStyle', 'none', 'FaceColor', 'k', 'FaceAlpha', 0.5 ...
                );

                set(gca, 'YScale', 'Log');
                set(gca, 'YTick', []);
                set(gca, 'XTick', []);
                set(gca, 'XColor', [0.5, 0.5, 0.5]);
                set(gca, 'YColor', [0.5, 0.5, 0.5]);
                xlim(xscale);

                axes(obj.histograms.axes.YZ);
                
                obj.histograms.XY = histogram( ...
                    obj.image.temp.YZ(randi(numel(obj.image.temp.YZ),obj.histograms.samples,1)), ...
                    obj.histograms.bins, 'LineStyle', 'none', 'FaceColor', 'k', 'FaceAlpha', 0.5 ...
                );

                set(gca, 'YScale', 'Log');
                set(gca, 'YTick', []);
                set(gca, 'XTick', []);
                set(gca, 'XColor', [0.5, 0.5, 0.5]);
                set(gca, 'YColor', [0.5, 0.5, 0.5]);
                xlim(xscale);
            end
        end
    end
end

