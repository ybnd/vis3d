classdef tagStringParser < handle
%{
    Parsing of a simple tag string fromat
        Complementary with .ocmbin/header VIs for encoding cluster information
        
        -- format description --
%}
    
    properties
        tagString                       % Indented (readable) tagString
        tagStruct                       % Parsed tagString structure
        associatedFile                  % Parent file of tagString
    end
    properties(Access = private)
        inString                        % Original input string
        tagStringFlat                   % Flattened input string
        nestSearchDepthDefault = 3;     % Depth to stop searching for subsections
    end
    properties(Constant, Access = private)
        % Regular expressions
        rgx = struct(                                                                           ...
            'numerical',        '<num>([a-zA-Z_0-9 ]*)=([\s*]?[+-]?\d+\.?\d*)</num>',           ...
            'string',           '<str>([a-zA-Z_0-9 ]*)=([a-zA-Z_0-9 ]*)</str>',                 ...
            'timestamp',        '<tms>([a-zA-Z_0-9 ]*)=([a-zA-Z_0-9 / : .]*)</tms>',            ...
            'array1D',          '<arr>([a-zA-Z_0-9 ]*)=([0-9;]*)</arr>',                        ...
            'section',          '<section=([a-zA-Z_0-9 ]*)>.*</\1>',                            ...
            'element',          '<elm([a-zA-Z_0-9 ]*)>(.*)</elm\1>'                             ... 
        )
    
        % Starting characters to eliminate (comply with MATLAB syntax for struct fields)
        illegal_starting_char = { ...
            '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '_'
        }
    end
    
    methods
        function self = tagStringParser(tagString, path)
            % Parses the provided tagString, reads from path if no string given
            switch nargin
                case 0
                    error('No string or file provided');
                case 1
                    path = '';
            end
            
            self.associatedFile = path;
            [~,~,ext] = fileparts(self.associatedFile);
            
            if isempty(tagString)
                switch ext
                    case '.txt'
                        tagString = fileread(self.associatedFile);
                    otherwise
                        f = fopen(self.associatedFile);
                        tagString = fgetl(f); % reads single line of file; the first line in the file is the header
                        fclose(f);
                end    
            end
            
            self.inString = tagString;
            self.flattenString();
            self.indentString();
            
            self.parse();
        end
        
        function flattenString(self, inString)
            % Flattens input string to a single line
            outString = flattenString(inString);
            self.tagStringFlat = outString;
        end
        
        function outString = indentString(self, inString)
            % Indents flattened string for readability
            switch nargin
                case 1
                    if ~isempty(self.tagStringFlat)
                        inString = self.tagStringFlat;
                    else
                        self.flattenString();
                        inString = self.tagStringFlat;
                    end
            end
            
            outString = inString;
            
            outString = regexprep(outString, '<(\w)', [newline self.tab(5) '<$1']);
            outString = regexprep(outString, '<section=', [newline '<section=']);
            outString = regexprep(outString, '<subsection=', [newline self.tab(1) '<subsection=']);
            outString = regexprep(outString, '<subsubsection=', [newline self.tab(2) '<subsubsection=']);
            outString = regexprep(outString, '<subsubsubsection=', [newline self.tab(3) '<subsubsubsection=']);
            outString = regexprep(outString, '<subsubsubsubsection=', [newline self.tab(4) '<subsubsubsubsection=']);
            
            self.tagString = outString;
            
        end

        function tagStruct = parse(self, inString, nestSearchDepth)
            % Parses the flattened tagString
            switch nargin
                case 1
                    if ~isempty(self.tagStringFlat)
                        inString = self.tagStringFlat;
                    else
                        self.flattenString();
                        inString = self.tagStringFlat;
                    end
                    nestSearchDepth = self.nestSearchDepthDefault;
                case 2
                    nestSearchDepth = self.nestSearchDepthDefault;   
            end
            
            tagStruct = struct();
            mangleString = inString;
            flatStruct = struct();
            sections = cell(nestSearchDepth,1);
            
            % Distribute properties over N*(sub)sections
            for level = nestSearchDepth:-1:1
                
                [subsections, subsubstrings, garble] = self.getNsubSections(level-1, mangleString);
                mangleString(garble) = '*';                
                
                for i = 1:length(subsections)
                    props = self.getProperties(subsubstrings{i});
                    flatStruct.(subsections{i}{1}) = self.addProperties(props);                    
                end               
                    
                if level == 1
                    props = self.getProperties(mangleString);
                    tagStruct = self.addProperties(props, tagStruct);
                    why = 'not?';
                end
                
                % Current level:
%                 level = strcat(repmat('sub',[1,N]), 'sections');
                sections{level} = subsections;
            end
            
            % Nest the fields in flatStruct according to order of appearance relative to supersections            
            for N = length(sections):-1:1 
                if N > 1
                % Iterate over found subsections (@level)
                for i = 1:length(sections{N})
                    % Determine the corresponding supersections (@level-1)
                    for j = 1:length(sections{N-1})

                        % For readability               %   
                        A = sections{N-1}{j}{3};  %   A        supersection        B
                        B = sections{N-1}{j}{4};  %   |----------------------------|
                        a = sections{N}{i}{3};    %           |----------------|                      
                        b = sections{N}{i}{4};    %           a   subsection   b

                        if  ( a > A && a < B ) && ( b > A && b < B )
                            flatStruct.(sections{N-1}{j}{1}).(sections{N}{i}{1}) ...
                                = flatStruct.(sections{N}{i}{1});
                            break
                        elseif ( a > A && a < B ) || ( b > A && b < B )
                            warning('Offset subsection/supersection tags. Results may be inconsistent.')
                        end
                    end
                end
                elseif N == 1
                    % Add all sections (level 1) to tStruct
                    for i = 1:length(sections{N})
                        tagStruct.(sections{N}{i}{1}) = flatStruct.(sections{N}{i}{1});
                    end
                end
            end
            
            % Add level-0 properties            
            self.tagStruct = tagStruct;
        end
        
        function elmStruct = parseArray(self, inString)
            % Parses tagString arrays // currently separate from main parsing method; to be integrated
            switch nargin
                case 1
                    if ~isempty(self.tagStringFlat)
                        inString = self.tagStringFlat;
                    else
                        self.flattenString();
                        inString = self.tagStringFlat;
                    end   
            end
            
            elms = self.getRegExp(inString, self.rgx.element);
            
            try
                elm1_string = elms{1}{2};
                elm1_string = elm1_string(~isspace(elm1_string)); % eliminate whitespace (confuses num tag)
                elm1 = self.addProperties(self.getProperties(elm1_string), struct());
                elmStruct = elm1;
                
                for i = 1:size(elms,2)
                    elm_str = elms{i}{2}(~isspace(elms{i}{2})); % eliminate whitespace (confuses num tag)
                    elmStruct(i) = self.addProperties(self.getProperties(elm_str), struct());
                end                
            catch
                warning('Array properties are probably not identical')
            end 
        end
        
        function [sections, substrings] = getSections(self, inString)
            % Returns sections & corresponding sub-tagStrings (section contents) from inString
            switch nargin 
                case 1
                    inString = self.tagString;
                    do_mangle = false;
                case 2
                    do_mangle = false;
            end
            
            sections = self.getRegExp(inString, self.rgx.section);
            substrings = cell(size(sections));
            for i = 1:length(sections)
                sections{i}{1} = regexprep(sections{i}{1}, ' ([a-z])', '${upper($0)}');
                sections{i}{1} = regexprep(sections{i}{1}, ' ', '');
                sections{i}{3} = str2num(sections{i}{3});
                sections{i}{4} = str2num(sections{i}{4});
                
                if ~do_mangle % legacy?
                    substrings{i} = inString(sections{i}{3}:sections{i}{4});
                else
                    substring = inString(sections{i}{3}:sections{i}{4});
                    substring(sections{i}{3}+1) = '*';
                    substrings{i} = substring;
                end
            end
        end
        
        function [Nsubsections, Nsubstrings, garble] = getNsubSections(self, N, inString)
            % Returns N-level subsections & corresponding sub-tagStrings (section contents) from inString
            switch nargin 
                case 1
                    inString = self.tagString;
                    N = 1;
                    do_mangle = false;
                case 2
                    inString = self.tagString;
                    do_mangle = false;
                case 3
                    do_mangle = false;
            end
            
            expression = strcat('<', repmat('sub', [1,N]), self.rgx.section(2:end));
            
            Nsubsections = self.getRegExp(inString, expression);
            
            Nsubstrings = cell(size(Nsubsections));            
            garble = [];
            for i = 1:length(Nsubsections)
                % Replace space-separated words with camelCase
                Nsubsections{i}{1} = regexprep(Nsubsections{i}{1}, ' ([a-z])', '${upper($0)}');
                Nsubsections{i}{1} = regexprep(Nsubsections{i}{1}, ' ', '');
                Nsubsections{i}{3} = str2num(Nsubsections{i}{3});
                Nsubsections{i}{4} = str2num(Nsubsections{i}{4});
                
                span = Nsubsections{i}{3}:Nsubsections{i}{4};
                garble = [garble, span]; %#ok<AGROW>
                
                if ~do_mangle % legacy?
                    Nsubstrings{i} = inString(span);
                else
                    substring = inString(span);
                    substring(Nsubsections{i}{3}+1) = '*';
                    Nsubstrings{i} = substring;
                end
            end
            
        end
        
        function props = getProperties(self, inString)
            % Returns property names & values from inString
            if nargin == 0
                inString = self.tagString;
            end
            
            num = self.getRegExp(inString, self.rgx.numerical);
            arb = self.getRegExp(inString, self.rgx.string);
            arr = self.getRegExp(inString, self.rgx.array1D);
            tms = self.getRegExp(inString, self.rgx.timestamp);
            % todo: integrate structure arrays
            
            props = [num, arb, arr, tms];
            props = vertcat(props{:});
            try
                props = sortrows(props,3);
            catch
                props = cell(0);
            end
        end             
    end
    
    methods(Static)
        function tokens = getRegExp(inString, expression)
            % regexp wrapper
            [tokens, starts, ends] = regexp(inString, expression, 'tokens', 'start', 'end');
            for j = 1:length(tokens)
                tokens{j}{3} = num2str(starts(j));
                tokens{j}{4} = num2str(ends(j));
            end
        end
        
        function props = convertNumerical(props)
            % Convert numeric strings to numeric values
            for i = 1:length(props)
                props{i}{2} = str2num(props{i}{2});
            end
        end
        
        function target = addProperties(props, target)
            % Add properties to a struct, deal with illegal property names & convert value strings
            switch nargin
                case 1
                    target = struct();
            end
            for i = 1:size(props,1)
                % Capitalize letters after spaces
                propName = regexprep(props{i,1}, ' ([a-z])', '${upper($0)}');
                propName = regexprep(propName, ' ', '');
                
                % Catch (suspected) timestamps - contain ':' and '/'
                if contains(props{i,2}, {':', '/'})
                    prop_value = [];
                else
                    % Catch & convert numeric values & arrays (magic)
                    prop_value = [str2num(props{i,2})];
                end
                if ~isempty(prop_value)
                    try
                        target.(propName) = prop_value;
                    catch
                        if any(strcmp(propName(1), tagStringParser.illegal_starting_char))
                            propName = [propName(2:end), propName(1)];
                        end
                        target.(propName) = prop_value;
                    end
                else                       
                    try
                        target.(propName) = props{i,2};
                    catch
                        if any(strcmp(propName(1), tagStringParser.illegal_starting_char))
                            propName = [propName(2:end), propName(1)];
                        end
                        target.(propName) = props{i,2};
                    end
                end
            end
        end
        
        function string = repeatString(character, N)
            % Repeats string; repmat wrapper
            string = repmat(character, 1, N);
        end
        
        function string = tab(N)
            % Spacetab
            string = tagStringParser.repeatString(' ', N*4);
        end
        
    end
end
