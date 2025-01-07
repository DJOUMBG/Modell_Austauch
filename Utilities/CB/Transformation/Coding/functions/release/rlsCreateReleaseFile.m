function rlsCreateReleaseFile(sReleaseFunctionFolder,sMainFile,sDestFolder)
% RLSCREATERELEASEFILE builds a pcode file for given main file by linking
% each user defined function as subfunctions.
%
% Syntax:
%   rlsCreateReleaseFile(sReleaseFunctionFolder,sMainFile,sDestFolder)
%   rlsCreateReleaseFile(sReleaseFunctionFolder,sMainFile)
%
% Inputs:
%   sReleaseFunctionFolder - string: folder with specific release build function from Rainer Frey 
%                sMainFile - string: main matlab function for witch the pcode should be cerated 
%              sDestFolder - string [optional]: destination folder, where the the pcode file should be created  
%
% Outputs:
%
% Example: 
%   rlsCreateReleaseFile(sReleaseFunctionFolder,sMainFile,sDestFolder)
%
%
% See also: fleIsAbsPath
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2023-04-04

%% check input arguments

% check release build function folder
if ~chkFolderExists(sReleaseFunctionFolder)
    error('Given release build function folder "%s" does not exist.',...
        sReleaseFunctionFolder);
end

% check main file
sMainFile = strrep(sMainFile,'"','');
if ~fleIsAbsPath(sMainFile);
    error('Main file must be a full file path.');
end
if ~chkFileExists(sMainFile)
    error('Main file does not exist.');
end

% check destination folder
if nargin < 3
    sDestFolder = '';
else
    if ~chkFolderExists(sDestFolder)
        error('Given destination folder "%s" does not exist.',sDestFolder);
    end
end


%% create link file

% add path with release functions
addpath(sReleaseFunctionFolder);

% create linked file
try
    sLinkedFile = buildRelease(sMainFile,'_linked');
    rmpath(sReleaseFunctionFolder);
catch ME
    rmpath(sReleaseFunctionFolder);
    rethrow(ME);
end


%% create p-code file

% file parts of original and linked file
[~,sOrgName,~] = fileparts(sMainFile);
[sLinkedPath,sLinkedName,sLinkedExt] = fileparts(sLinkedFile);

% current path
sCurPath = pwd;

% copy to destinatnion folder if any exist
if ~isempty(sDestFolder) && ~strcmp(sDestFolder,sLinkedPath)
    sNewLinkedFile = fullfile(sDestFolder,[sLinkedName,sLinkedExt]);
    copyfile(sLinkedFile,sNewLinkedFile);
    delete(sLinkedFile);
    sLinkedFile = sNewLinkedFile;
    sLinkedPath = sDestFolder;
end

% create p-code in destination folder
cd(sLinkedPath);
pcode(sLinkedFile,'-inplace');
cd(sCurPath);

% rename pcode file with original name
sOrgPCode = fullfile(sLinkedPath,[sLinkedName,'.p']);
copyfile(sOrgPCode,fullfile(sLinkedPath,[sOrgName,'.p']));
delete(sOrgPCode);

return
