function [bValid,cPathList] = cbtPathLengthOfFilesCheck(sRootFolder,nMaxLength)
% CBTPATHLENGTHOFFILESCHECK checks the full path length of all folders,
% subfolders and its files and returns a list with the too long paths.
%
% Syntax:
%   [bValid,cPathList] = cbtPathLengthOfFilesCheck(sRootFolder,nMaxLength)
%
% Inputs:
%   sRootFolder - string: existing foldername or folderpath  
%    nMaxLength - integer (1x1): positive numer of maximum full path length 
%
% Outputs:
%      bValid - boolean (1x1): false if any path is too long, true if not 
%   cPathList - cell (mx1): list of the too long paths 
%
% Example: 
%   [bValid,cPathList] = cbtPathLengthOfFilesCheck(sRootFolder,nMaxLength)
%
%
% See also: fleAllSubfilesGet, fleAllSubfoldersGet
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2023-01-27

%% check pathlength for folders and files

% init output
bValid = true;
cPathList = {};

% get list of all folders
cFolderpathList = fleAllSubfoldersGet(sRootFolder);

% check path lengths for folders
for nFolder=1:numel(cFolderpathList)
    sFolderpath = cFolderpathList{nFolder};
    if length(sFolderpath) > nMaxLength
    	bValid = false;
        cPathList = [cPathList;{sFolderpath}]; %#ok<AGROW>
    end
end

% get list of all files in folders
cFilepathList = fleAllSubfilesGet(sRootFolder);

% check path lengths for files
for nFile=1:numel(cFilepathList)
    sFilepath = cFilepathList{nFile};
    if length(sFilepath) > nMaxLength
    	bValid = false;
        cPathList = [cPathList;{sFilepath}]; %#ok<AGROW>
    end
end

return