classdef OBSRNXheader
	properties
    	interval (1,1) double
        approxPos (1,3) double
        gnss (1,:) char
		obsTypes struct
		noObsTypes (1,:) double
        version (1,:) char
        path (1,:) char
        filename (1,:) char
        headerSize (1,1) double
    end
   
    methods
    	function obj = OBSRNXheader(filepath)
            [folderpath,filename,ext] = fileparts(filepath);
            s = what(folderpath);
            obj.path = s.path;
            obj.filename = [filename ext];
            absfilepath = fullfile(obj.path, obj.filename);
            obj.obsTypes = struct();

            % Reading raw RINEX data using textscan
            fprintf('Reading header of RINEX: %s\n', absfilepath);
            finp = fopen(absfilepath, 'r');
            fileBuffer = textscan(finp, '%s', 'Delimiter', '\n', 'whitespace', '');
            fileBuffer = fileBuffer{1};
            fclose(finp);
            
            % Parsing header records
            lineIndex = 0;
            
            % Initialize rnx structure
            while 1
                lineIndex = lineIndex + 1;
                line = fileBuffer{lineIndex};
                
                if lineIndex == 1
                    if contains(line,'RINEX VERSION / TYPE') && contains(line,'OBSERVATION DATA')
                        obj.version = strrep(line(1:20),' ','');
                    else
                        error('Input file is not observation RINEX!')
                    end
                end
                
                if contains(line,'APPROX POSITION XYZ')
                    obj.approxPos = sscanf(line(1:60),'%f');
                end
                
                if contains(line,'INTERVAL')
                    obj.interval = sscanf(line(1:60),'%f');
                end
                
                if contains(line,'SYS / # / OBS TYPES')
                    if ~strcmp(line(1),' ')
                        obj.gnss(end+1) = line(1);
                        obj.noObsTypes(end+1) = str2double(line(5:6));
                        
                        obsTypes = strsplit(line(8:60));
                        obsTypes = obsTypes(1:end-1);
                        obj.obsTypes.(line(1)) = obsTypes;
                        
                        if strcmp(fileBuffer{lineIndex+1}(1),' ') && contains(fileBuffer{lineIndex+1},'SYS / # / OBS TYPES')
                            obsTypes = strsplit(fileBuffer{lineIndex+1}(8:60));
                            obsTypes = obsTypes(1:end-1);
                            obj.obsTypes.(line(1))(end+1:end+length(obsTypes)) = obsTypes;
                        end
                    end
                end
                
                % Breaks if lineIndex reaches 'END OF HEADER'
                if contains(line,'END OF HEADER')
                    obj.headerSize = lineIndex;
                    break
                end
            end
            obj.printSummary();
        end
        function printSummary(obj)
            fprintf('RINEX version:              %s\n',obj.version);
            fprintf('RINEX recording interval:   %d s\n',obj.interval);
            fprintf('RINEX available systems:    %s\n',obj.gnss);
            fprintf('RINEX position:             X = %.3f m\n',obj.approxPos(1));
            fprintf('                            Y = %.3f m\n',obj.approxPos(2));
            fprintf('                            Z = %.3f m\n',obj.approxPos(3));
            for i = 1:numel(obj.gnss)
                s = obj.gnss(i);
                fprintf('RINEX %s obs types (%2d):     %s\n',s,obj.noObsTypes(i),strjoin(obj.obsTypes.(s),','));
            end
        end
    end
end