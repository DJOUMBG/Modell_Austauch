function cFolderpathList = fleAllSubfoldersGet(sRootDir)
% FLEALLSUBFOLDERSGET returns a list of the full folderpaths of root folder
% and all its subfolders.
%
% Syntax:
%   cFolderpathList = fleAllSubfoldersGet(sRootDir)
%
% Inputs:
%   sRootDir - string: existing foldername or folderpath 
%
% Outputs:
%   cFolderpathList - cell of strings (mx1): list with full folderpaths of root folder and its subfolders 
%
% Example: 
%   cFolderpathList = fleAllSubfoldersGet(sRootDir)
%
%
% See also: strStringListClean
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2023-01-27

%% get all folderpaths

% check if root folder exists
if ~chkFolderExists(sRootDir)
    error('fleAllSubfoldersGet:FolderNotExists',...
        'Folder "%s" does not exist.',sRootDir);
end

% get list of subfolders
cFolderpathList = strsplit(genpath(sRootDir),{';',pathsep},'CollapseDelimiters',false)';
cFolderpathList = strStringListClean(cFolderpathList);

return