function cList = fleGetPathListFromFile(sFilepath)

%% read and format lines from file

% read file to text
sTxt = fleFileRead(sFilepath);

% convert text to list
cLines = strStringToLines(sTxt);

% clean-up empty lines
cLines = strStringListClean(cLines);

% remove quotation marks 
cLines = strrep(cLines,'"','');


%% check file paths

% init list
cList = {};

for nFile=1:numel(cLines)
    
    % current file
    sCurFile = cLines{nFile};
    
    % check for comments
    if ~strcmp(sCurFile(1),'#') && ~strcmp(sCurFile(1),'%')
    
        % check if file exists
        if ~chkFileExists(sCurFile)
            error('File "%s" does not exist.',sCurFile);
        else
            cList = [cList;{sCurFile}]; %#ok<AGROW>
        end
        
    end
end

return