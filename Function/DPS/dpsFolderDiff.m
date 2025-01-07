function bStatus = dpsFolderDiff(sPathSource,sPathTarget,sOptions)
% DPSFOLDERDIFF uses a diff tool for folder comparison. If DIVe LDYN
% ldBeyondCompare.m is on the MATLAB path, this is used as priority.
% Otherwise a WinMerge installation is searched.
%
% Syntax:
%   bStatus = dpsFolderDiff(sPathSource,sPathTarget,sOptions)
%
% Inputs:
%   sPathSource - string with 
%   sPathTarget - string 
%      sOptions - string 
%
% Outputs:
%   bStatus - boolean for merge tool execution status
%              0: standard program execution
%            >=1: exception during execution
%
% Example: 
%   bStatus = dpsFolderDiff(sPathSource,sPathTarget,sOptions)

% check input
if ~exist(sPathSource,'dir')
    error('dpsFolderDiff:invalidSourceFolder',...
        'The specified source folder is invalid: %s',sPathSource);
end
if ~exist(sPathTarget,'dir')
    error('dpsFolderDiff:invalidTargetFolder',...
        'The specified target folder is invalid: %s',sPathTarget);
end
if nargin < 3
    sOptions = '';
end

% check for winmerge installation
[bExistWinMerge,sFileWinMerge] = dfdWinMergeExist;
% check for BeyondCompare installation
[bExistBeyondCompare,sFileBeyondCompare] = dfdBeyondCompareExist;

if bExistBeyondCompare
    % prep LDYN standard commands for DIVe DB Export call
    if nargin < 3 || isempty(sOptions)
        sCommands = '/leftreadonly /filters=-configuration\;-template\;-pltm\;-.svn\ /expandall &';
    else
        sCommands = sOptions;
    end
    bDiffLocationExist = ~strcmp(sPathSource,sPathTarget);
    if bDiffLocationExist
        % compare folder sPathSource (exported content) with folder sPathTarget
        if ~isempty(sFileBeyondCompare)
            [bStatus,sResult] = dos(['"' sFileBeyondCompare '" ' '"' sPathSource '"' ' "' sPathTarget '" ' sCommands]);
            if bStatus
                % state execution error
                fprintf(2,'dpsFolderDiff: Error during BeyondCompare execution with following message\n');
                fprintf(2,'%s\n',sResult);
            end
        end
    else
        fprintf(2,'dpsFolderDiff: sysDM export folder and current target folder are equal\n')
    end
    
elseif bExistWinMerge
    % execute diff with WinMerge
    sCall = ['"' sFileWinMerge '" /r /e /wl ' sOptions '"' sPathSource '"' ' "' sPathTarget '" &'];
    [bStatus,sResult] = system(sCall);
    if bStatus
        % state execution error
        fprintf(2,'dpsFolderDiff: Error during merge tool execution with following message\n');
        fprintf(2,'%s\n',sResult);
    end
else
    bStatus = true;
    fprintf(2,'dpsFolderDiff: No merge tool found...');
end
return

% =========================================================================

function [bExist,sFile] = dfdWinMergeExist
% DFDWINMERGEEXIST check the existence and location of a winmerge
% installation. (Define possible installation locations in code.)
%
% Syntax:
%   [bExist,sFile] = dfdWinMergeExist
%
% Inputs:
%
% Outputs:
%   bExist - boolean if WinMerge installation is found
%    sFile - string with file path of WinMerge executable
%
% Example: 
%   [bExist,sFile] = dfdWinMergeExist

% define possible installation locations
cInstall = {'C:\Program Files (x86)\sc\Tools' ...
            'C:\Program Files\sc\Tools' ...
            'C:\Programme\sc\Tools' ...
            'C:\Program Files (x86)' ...
            'C:\Program Files' ...
            'C:\Programme'};
        
% search all pathes for WinMerge Installations       
sFile = '';
for nIdxPath = 1:numel(cInstall)
    % search installation path
    cFolder = dirPattern(cInstall{nIdxPath},'WinMerge*','folder');
    if ~isempty(cFolder) 
        % check WinMergeU.exe
        sFileTest = fullfile(cInstall{nIdxPath},cFolder{1},'WinMergeU.exe');
        if exist(sFileTest,'file')
            sFile = sFileTest;
            break
        else
            % search in first subfolder
            cSub = dirPattern(fullfile(cInstall{nIdxPath},cFolder{1}),'*','folder');
            if ~isempty(cSub)
                sFileTest = fullfile(cInstall{nIdxPath},cFolder{1},cSub{1},'WinMergeU.exe');
                if exist(sFileTest,'file')
                    sFile = sFileTest;
                    break
                end % if test file subfolder
            end % if subfolder
        end % if test file
    end % if folder
end % for

% update status
bExist = ~isempty(sFile);
return

% =========================================================================

function [bExist,sFile] = dfdBeyondCompareExist
% DFDBEYONDCOMPAREEXIST check the existence and location of a BeyondCompare
% installation. (Define possible installation locations in code.)
%
% Syntax:
%   [bExist,sFile] = dfdBeyondCompareExist
%
% Inputs:
%
% Outputs:
%   bExist - boolean if BeyondCompare installation is found
%    sFile - string with file path of BeyondCompare executable
%
% Example: 
%   [bExist,sFile] = dfdBeyondCompareExist

% define possible installation locations
cInstall = {'C:\apps\' ...
    'C:\apps\sc\' ...
    'C:\Program Files (x86)' ...
    'C:\Program Files' ...
    'C:\Program Files\sc' ...
    'C:\Programme'};

% search all pathes for BeyondCompare installations       
sFile = '';
for nIdxPath = 1:numel(cInstall)
    % search installation path
    cFolder = dirPattern(cInstall{nIdxPath},'Beyond Compare*','folder');
    if ~isempty(cFolder) 
        % check BComp.exe
        sFileTest = fullfile(cInstall{nIdxPath},cFolder{1},'BComp.exe');
        if exist(sFileTest,'file')
            sFile = sFileTest;
            break
        end
    end
end

% update status
bExist = ~isempty(sFile);
return
