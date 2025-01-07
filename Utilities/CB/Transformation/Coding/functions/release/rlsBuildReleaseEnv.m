function rlsBuildReleaseEnv(sDestEnvFolder,cMainFunctionList,cSearchPathList,cIgnoreFileList,cMainScriptList,bIgnorePcode)

%% check input arguments

% bIgnorePcode
if nargin < 6
    bIgnorePcode = false;
else
    if isnumeric(bIgnorePcode)
        bIgnorePcode = logical(bIgnorePcode);
    end
    if ~islogical(bIgnorePcode)
        error('Input argument "bIgnorePcode" must be logical or numeric.');
    end
end

% cMainScriptList
if nargin < 5
    cMainScriptList = {};
else
    if ischar(cMainScriptList)
        cMainScriptList = {cMainScriptList};
    end
    if ~iscell(cMainScriptList)
        error('Input argument "cMainScriptList" must be cell.');
    end
end

% cIgnoreFileList
if nargin < 4
    cIgnoreFileList = {};
else
    if ischar(cIgnoreFileList)
        cIgnoreFileList = {cIgnoreFileList};
    end
    if ~iscell(cIgnoreFileList)
        error('Input argument "cIgnoreFileList" must be cell.');
    end
end

% cSearchPathList
if nargin < 3
    cSearchPathList = {};
else
    if ischar(cSearchPathList)
        cSearchPathList = {cSearchPathList};
    end
    if ~iscell(cSearchPathList)
        error('Input argument "cSearchPathList" must be cell.');
    end
end

% cMainFunctionList
if nargin < 2
    error('Not enough input arguments.');
else
    if ischar(cMainFunctionList)
        cMainFunctionList = {cMainFunctionList};
    end
    if ~iscell(cMainFunctionList)
        error('Input argument "cMainFunctionList" must be cell.');
    end
end

% sDestEnvFolder
if ~ischar(sDestEnvFolder)
    error('Input argument "sDestEnvFolder" must be char.');
end


%% format input arguments

% delete '"'
sDestEnvFolder = strrep(sDestEnvFolder,'"','');
cMainFunctionList = strrep(cMainFunctionList,'"','');
cSearchPathList = strrep(cSearchPathList,'"','');
cIgnoreFileList = strrep(cIgnoreFileList,'"','');
cMainScriptList = strrep(cMainScriptList,'"','');

% reshape
cMainFunctionList = formatFileList(cMainFunctionList);
cIgnoreFileList = formatFileList(cIgnoreFileList);
cMainScriptList = formatFileList(cMainScriptList);


%% individual check of input arguments

% sDestEnvFolder:
if ~fleIsAbsPath(sDestEnvFolder)
    error('Destination folder must be full path.');
end

% cMainFunctionList:
checkFileList(cMainFunctionList)

% cSearchPathList
checkSearchPathList(cSearchPathList);

% cIgnoreFileList:
checkFileList(cIgnoreFileList);

% cIgnoreFileList:
checkFileList(cMainScriptList);


%% build environment

% save and reset user paths, add new paths
sPrePath = matlabPathRestoreSet(strjoin(cSearchPathList,pathsep));

% try build process
try

% create temp folder in working directory
sTempFolder = fullfile(pwd,'buildTemp');
if exist(sTempFolder,'dir')
    error('Folder "%s" must not exist in this working directory.',...
        sTempFolder);
end
fleCreateFolder(sTempFolder);

% build environment for each main file
for nFile=1:numel(cMainFunctionList)
    sMainFile = cMainFunctionList{nFile};
    buildEnvForMainFile(sTempFolder,sMainFile,cIgnoreFileList,bIgnorePcode);
end

% copy all files with extension '*.help' or '*.p' to "source" folder of destination 

% copy all scripts to head of destination and add addpath for "source"

% clean up
cleanUpFunction(sPrePath,sTempFolder);

% error handling
catch ME
    cleanUpFunction(sPrePath,sTempFolder);
    rethrow(ME);
end

return

% =========================================================================

function checkFileList(cFileList)

for nFile=1:numel(cFileList)
    sFile = cFileList{nFile};
    if ~fleIsAbsPath(sFile)
        error('File "%s" must be full path.',sFile);
    end
    if ~exist(sFile,'file')
        error('File "%s" does not exist.',sFile);
    end
end

return

% =========================================================================

function checkSearchPathList(cSearchPathList)

for nPath=1:numel(cSearchPathList)
    sSeriellPath = cSearchPathList{nPath};
    cPathSplit = strStringListClean(strsplit(sSeriellPath,pathsep));
    for nSplit=1:numel(cPathSplit)
        sPath = cPathSplit{nSplit};
        if ~fleIsAbsPath(sPath)
            error('Search path "%s" must be full path.',sPath);
        end
        if ~exist(sPath,'dir')
            error('Search path "%s" is not a directory.',sPath);
        end
    end
end

return

% =========================================================================

function cFileList = formatFileList(cFileList)
cFileList = reshape(cFileList,numel(cFileList),1);
return

% =========================================================================

function buildEnvForMainFile(sTempFolder,sMainFile,cIgnoreFileList,bIgnorePcode)

% get used matlab fils in main file
[cFileList,xMatProducts] = matlab.codetools.requiredFilesAndProducts(sMainFile);
cFileList(ismember(cFileList,sMainFile)) = [];
cFileList = unique(cFileList);
cFileList = formatFileList(cFileList);

% create full ignore list
cSubFileList = getReqSubFileList(cFileList,cIgnoreFileList,bIgnorePcode);

% split subfile list to specific types
[cFctList,cPcodeList,cClassList] = splitSubFiles(cSubFileList);
cLinkFctList = [{sMainFile};cFctList];

% create link file text for functions
[sLinkFileTxt,sSyntaxReport] = createLinkFileTxt(cLinkFctList);

% syntax report
if ~isempty(sSyntaxReport)
fprintf(1,'ATTENTION! Please view syntax report of required functions:\n\n%s',...
    sSyntaxReport);
end

% description from main file
sMainDescr = getDescriptionFromFile(sMainFile);

% create source files for main file
sSyntaxReport = copyEnvFilesToTempFolder(sTempFolder,sMainFile,sMainDescr,sLinkFileTxt,cPcodeList,cClassList);

% syntax report
if ~isempty(sSyntaxReport)
    fprintf(1,'ATTENTION! Please view syntax report of final linked function:\n\n%s',...
        sSyntaxReport);
end

% create file with informations on matlab products "xMatProducts"

return

% =========================================================================

function cSubFileList = getReqSubFileList(cFileList,cIgnoreFileList,bIgnorePcode)

% get subfile to be ignored
cIgnoreSubFiles = {};
for nFile=1:numel(cFileList)
    sFile = cFileList{nFile};
    if ismember(sFile,cIgnoreFileList) || (bIgnorePcode && (exist(sFile) == 6)) %#ok<EXIST>
        cCurSubFileList = matlab.codetools.requiredFilesAndProducts(sFile);
        cCurSubFileList = formatFileList(cCurSubFileList);
        cIgnoreSubFiles = [cIgnoreSubFiles;cCurSubFileList]; %#ok<AGROW>
    end
end
cIgnoreSubFiles = unique(cIgnoreSubFiles);

% delete ignore subfiles from subfile list
cCleanFileList = {};
for nFile=1:numel(cFileList)
    sFile = cFileList{nFile};
    if ~ismember(sFile,cIgnoreSubFiles)
        cCleanFileList = [cCleanFileList;{sFile}]; %#ok<AGROW>
    end
end

% get subfiles from file list
cSubFileList = {};
for nFile=1:numel(cCleanFileList)
    sFile = cCleanFileList{nFile};
    cCurSubFileList = matlab.codetools.requiredFilesAndProducts(sFile);
    cCurSubFileList = formatFileList(cCurSubFileList);
    cSubFileList = [cSubFileList;cCurSubFileList]; %#ok<AGROW>
end
cSubFileList = unique(cSubFileList);

return

% =========================================================================

function [cFctList,cPcodeList,cClassList] = splitSubFiles(cSubFileList)

cFctList = {};
cPcodeList = {};
cClassList = {};
for nFile=1:numel(cSubFileList)
    sFile = cSubFileList{nFile};
    nKey = exist(sFile); %#ok<EXIST>
    switch nKey
        case 2
            cFctList = [cFctList;{sFile}]; %#ok<AGROW>
        case 6
            cPcodeList = [cPcodeList;{sFile}]; %#ok<AGROW>
        case 8
            cClassList = [cClassList;{sFile}]; %#ok<AGROW>
        otherwise
            error('Dependency file "%s" can not be handeled.');
    end
end

return

% =========================================================================

function [sLinkFileTxt,sSyntaxReport] = createLinkFileTxt(cLinkFctList)

sLineSep = ...
'% =========================================================================';

sSyntaxReport = '';
sLinkFileTxt = '';
for nFile=1:numel(cLinkFctList)
    
    sFile = cLinkFctList{nFile};
    
    % check code
    sCheckCodeString = checkcode(sFile,'-string');
    if ~isempty(strtrim(sCheckCodeString))
        sSyntaxReport = sprintf('%sIn "%s":\n%s\n\n',...
            sSyntaxReport,sFile,sCheckCodeString);
    end
    
    % read code
    sTxt = fleFileRead(sFile);
    
    % check for return termination state
    cCleanLines = getCleanMatLines(sTxt);
    if isempty(cCleanLines)
        error('Required subfunction "%s" is empty.',sFile);
    end
    if ~strncmp(cCleanLines{end},'return',length('return'))
        error('Required subfunction "%s" is not terminated with "return".');
    end
    
    % concatenate subfunctions
    if nFile == 1;
        sLinkFileTxt = sprintf('%s\n',sTxt);
    else
        sLinkFileTxt = sprintf('%s\n%s\n\n%s\n',...
            sLinkFileTxt,sLineSep,sTxt);
    end
    
end

return

% =========================================================================

function cCleanLines = getCleanMatLines(sTxt)

% delete all Matlab comments from text string
cCleanLines = {};
cLines = strStringListClean(strStringToLines(sTxt));
for nLine=1:numel(cLines)
    sLine = strtrim(cLines{nLine});
    if ~strcmp(sLine(1),'%')
        cSplit = strsplit(sLine,'%');
        sCleanLine = strtrim(cSplit{1});
        cCleanLines = [cCleanLines;sCleanLine]; %#ok<AGROW>
    end
end

return

% =========================================================================

function sDescr = getDescriptionFromFile(sFile)

sDescr = '';
sTxt = fleFileRead(sFile);
cLines = strStringToLines(sTxt);
if numel(cLines) > 1
    cLines = cLines(2:end);
    for nLine=1:numel(cLines)
        sLine = strtrim(cLines{nLine});
        if ~isempty(sLine)
            if strcmp(sLine(1),'%')
                sDescr = sprintf('%s%s\n',sDescr,sLine);
            else
                % first time of no comment line
                return;
            end
        else
            % first time of empty line
            return;
        end
    end
end

return

% =========================================================================

function sSyntaxReport = copyEnvFilesToTempFolder(sTempFolder,sMainFile,sMainDescr,sLinkFileTxt,cPcodeList,cClassList)

% get current working directoy
sCwd = pwd;
cd(sTempFolder);

% main function name
[~,sMainName] = fileparts(sMainFile);

% write link function
sLinkFilepath = fullfile(sTempFolder,[sMainName,'.m']);
fleFileWrite(sLinkFilepath,sLinkFileTxt);

% check code of link function
sSyntaxReport = '';
sCheckCodeString = checkcode(sLinkFilepath,'-string');
if ~isempty(strtrim(sCheckCodeString))
    fprintf(1,'\nIn linked file of "%s":\n%s\n\n',sLinkFilepath,sCheckCodeString);
end

% create pcode of link function
pcode(sLinkFilepath,'-inplace');

% write desciption file
fleFileWrite(fullfile(sTempFolder,[sMainName,'.help']),sMainDescr);

% create pcodes for classes
for nClass=1:numel(cClassList)
    sClassFile = cClassList{nClass};
    [~,sClassName,sClassExt] = fileparts(sClassFile);
    sTempClassFilepath = fullfile(sTempFolder,[sClassName,sClassExt]);
    copyfile(sClassFile,sTempClassFilepath);
    pcode(sTempClassFilepath,'-inplace');
end

% copy other pcodes
for nPcode=1:numel(cPcodeList)
    sPcodeFile = cPcodeList{nPcode};
    [~,sPcodeName,sPcodeExt] = fileparts(sPcodeFile);
    sPcodeFilepath = fullfile(sTempFolder,[sPcodeName,sPcodeExt]);
    copyfile(sPcodeFile,sPcodeFilepath);
end

% change back
cd(sCwd);

return

% =========================================================================

function cleanUpFunction(sPrePath,sTempFolder)
matlabPathRestoreSet(sPrePath);
rmdir(sTempFolder,'s');
return

