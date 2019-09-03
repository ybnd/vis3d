classdef postprocon < dynamicprops
    properties  
       parent
       figure
       update_callback = @pass_data;
       
       ui_contrast
       ui_colormap
       ui_db
       ui_db_floor
       ui_db_ceil
       
       positions = struct();
       
       contrast_method
       slice_method
       slice_args
       contrast_args
       
       do_db
       noise_floor
       signal_ceil
    end
    
    properties(Hidden = true)
       defaults = struct(); 
       images = [];
    end
    
    methods
        function self = postprocon(parent, positions, update_callback, images, defaults)
            switch nargin
                case 4
                    defaults = struct(                              ...
                        'contrast_method', @pass_data,                   ...
                        'slice_method', @slice,           ...
                        'contrast_args', struct(),                  ...
                        'slice_args', struct(),                     ...
                        'do_db', true,                              ...
                        'noise_floor', 0,                           ...
                        'signal_ceil', 90                           ...
                    );
            end
            
            self.parent = parent;
            self.figure = self.parent.figure;
            self.positions = positions;
            self.update_callback = update_callback;
            self.defaults = defaults;
            self.images = images;
            
            self.load_defaults
            self.set_parent_methods
            self.infer_positions            
            self.build
        end
        
        function build(self)
            self.ui_colormap = uicontrol('Style', 'popupmenu', 'String', ...
                {'gray', 'winter', 'parula'}, 'Position',  self.positions.ui_colormap);
            addlistener(self.ui_colormap, 'Value', 'PostSet', @self.ui_colormap_callback);
            
            self.ui_db = uicontrol('Style', 'togglebutton', 'String', '10log10', ...
                'Position', self.positions.ui_db, 'Value', self.do_db, 'callback', @self.ui_toggle_db);
            
            
            self.ui_db_floor = uicontrol('Style', 'edit', 'String', num2str(self.noise_floor), ...
                'Position', self.positions.ui_db_floor, 'KeyReleaseFcn', @self.ui_floor_callback);
            
            self.ui_db_ceil = uicontrol('Style', 'edit', 'String', num2str(self.signal_ceil), ...
                'Position', self.positions.ui_db_ceil, 'KeyReleaseFcn', @self.ui_ceil_callback);
        end
        
        function load_defaults(self)
            properties = fields(self.defaults);
            for i = 1:length(properties)
                self.(properties{i}) = self.defaults.(properties{i});             
            end
        end
        
        function infer_positions(self)
           % Infer positions from figure, 'make room' if necessary. 
        end
        
        function set_parent_methods(self)
            self.parent.slice_method = @self.slice_method;
            self.parent.contrast_args = self.contrast_args;
            self.parent.slice_args = self.slice_args;
            self.parent.do_db = self.do_db;
            self.parent.noise_floor = self.noise_floor; 
            self.parent.signal_ceil = self.signal_ceil; 
        end
        
        function update_parent(self)
            self.set_parent_methods
            self.update_callback()
        end
        
        function ui_toggle_db(self, ~, eventdata)
           self.do_db = eventdata.Source.Value;
           if self.do_db
               self.slice_method = @slice;
           else
               self.slice_method = @normalize_slice;
           end
           self.update_parent
        end
        
        function ui_floor_callback(self, ~, eventdata)
            key = get(gcf,'CurrentKey');
            if (strcmp(key , 'return'))
                self.noise_floor = str2num(eventdata.Source.String);
                self.slice_args.floor = self.noise_floor;

                self.update_parent
            end
        end
        
        function ui_ceil_callback(self, ~, eventdata)
            key = get(gcf,'CurrentKey');
            if (strcmp(key , 'return'))
                self.signal_ceil = str2num(eventdata.Source.String);
                self.slice_args.ceil = self.signal_ceil;

                self.update_parent
            end
        end

        function ui_colormap_callback(self, ~, eventdata)            
            map = eventdata.AffectedObject.String{get(eventdata.AffectedObject, 'Value')};

            for image = self.images
                colormap(image, map);
            end
        end 
    end
end