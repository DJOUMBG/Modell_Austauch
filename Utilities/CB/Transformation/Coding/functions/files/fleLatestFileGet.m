function sLatestFile = fleLatestFileGet(sFolderpath,cExt)
% FLELATESTFILEGET returns the latest file with given extensions in given 
% folder. 
%
% Syntax:
%   sLatestFile = fleLatestFileGet(sFolderpath,cExt)
%
% Inputs:
%   sFolderpath - string: folderpath of folder with file 
%          cExt - cell (1xn): cell-array list of file extensions 
%
% Outputs:
%   sLatestFile - string: fullpath of latest file in folder 
%
% Example: 
%   sLatestFile = fleLatestFileGet(sFolderpath,cExt)
%
%
% See also: fleLatestFileGet
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2023-04-03


% get files with extensions
xFiles = struct([]);
for nExt=1:numel(cExt)
    xFiles = [xFiles;dir(fullfile(sFolderpath,['*',cExt{nExt}]))]; %#ok<AGROW>
end

% check if any file exists
if isempty(xFiles)
    error('No files in result folder "%s" for given extensions.',sFolderpath);
end

% check for latest mat file
xSortFiles = sortStructByField(xFiles,'datenum');

% full path of latest file
cLatestFile = fleFullpathCreate(sFolderpath,{xSortFiles(end).name});

% latest file path
sLatestFile = cLatestFile{1};

return