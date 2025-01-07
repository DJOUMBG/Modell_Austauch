function sSubFolderNames = getSubFolders(sDirectoryName)
% GETSUBFOLDERS generates string containing sub directories inside a parent
% directory
%
% Syntax:
%   sSubFolderNames = getSubFolders(sDirectoryName)
%
% Inputs:
% sDirectoryName - string of parent directory whose sub directories have to
%                  be obtained
%
% Outputs:
%       sSubFolderNames - string containting all sub directories of parent
%                         directory. Each sub directory is separated by a
%                         semi colon ";"
% 
% Example: 
%   sAllFolders = getSubFolders('C:\nramach\DiveSysDm\testCases\test_export')
%
% Author: Nagaraj Ramachandra, RD/TBP , MBRDI
%  Phone: +91 80 67686240
% MailTo: nagaraj.ramachandra@daimler.com
%   Date: 2016-July-07

% check input
if nargin < 1
    disp('getSubFolders: No input arguments. Please enter parent directory string as argument')
    return
end
if ~exist(sDirectoryName,'dir')
    disp(['getSubFolders: Parent directory not found ',sDirectoryName])
    return
end

sSubFolderNames = '';% path to be returned

% Check if parent directory has only file
xDirContent = dir(sDirectoryName);
if isempty(xDirContent)
  return
end

% Add parent directory to the path even if it is empty.
sSubFolderNames = [sSubFolderNames sDirectoryName pathsep];
% set logical vector for subdirectory entries in directory
isdir = logical(cat(1,xDirContent.isdir));
% select only directory entries from the current listing
xOnlyDir = xDirContent(isdir); 

% Recursively descend through directories
for nIdxPath = 1:length(xOnlyDir)
   sDirname = xOnlyDir(nIdxPath).name;
   if ~strcmp( sDirname,'.') && ~strcmp( sDirname,'..')
       % recursive call
      sSubFolderNames = [sSubFolderNames getSubFolders(fullfile(sDirectoryName,sDirname))]; %#ok<AGROW> 
   end
end
return