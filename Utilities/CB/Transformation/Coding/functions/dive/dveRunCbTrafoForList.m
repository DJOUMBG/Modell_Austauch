function dveRunCbTrafoForList(cConfigFileList,sWorkspaceRoot,sLogFile,nExecutionType,bShortName)

% input arguments
if nargin < 5
    bShortName = false;
end

if nargin < 4
    % only transformation
    nExecutionType = 2;
end

if nargin < 3
    sLogFile = '';
end


%% check paths

% check workspace folder
if not(chkFolderExists(sWorkspaceRoot))
    error('Workspace folder "%s" does not exist.',sWorkspaceRoot);
end

% check run script folder
sRunScriptFile = fullfile(sWorkspaceRoot,...
    'Utilities\CB\Transformation\Scripts\runDiveCbTrafo.m');
if not(chkFileExists(sRunScriptFile))
    error('Run script file "%s" does not exits.',...
        sRunScriptFile);
end

% check log folder
if not(isempty(sLogFile))
    sLogFolder = fileparts(sLogFile);
    if not(chkFolderExists(sLogFolder))
        mkdir(sLogFolder);
    end
end

% init log text
sLogTxt = '';

% add path of run script
addpath(fileparts(sRunScriptFile));


%% run transformation for files

for nFile=1:numel(cConfigFileList)
    
    % current file
    sConfigXmlFile = cConfigFileList{nFile};
    
    % check file path
    if not(chkFileExists(sConfigXmlFile))
        sLogTxt = sprintf('%sDIVe config xml file "%s" does not exist.\n',...
            sLogTxt,sConfigXmlFile);
    else
        
        % run transformation
        bSuccess = runDiveCbTrafo(sConfigXmlFile,...
            nExecutionType,sWorkspaceRoot,bShortName);
        
        % check flag
        if bSuccess
            sLogTxt = sprintf('%sSuccessfully transformed DIVe config "%s".\n',...
                sLogTxt,sConfigXmlFile);
        else
            sLogTxt = sprintf('%sError with DIVe config "%s".\n',...
                sLogTxt,sConfigXmlFile);
        end
        
    end
    
end % cConfigFileList


%% clean transformation process

% write log file
if not(isempty(sLogTxt)) && not(isempty(sLogFile))
    fleFileWrite(sLogFile,sLogTxt);
end

% remove path
rmpath(fileparts(sRunScriptFile))


end % dveRunCbTrafoForList