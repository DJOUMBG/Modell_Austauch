function cFile = getFilesAll(cPath,bPath)
% GETFILESALL generates a reccursive list of all files in that folder path
% and its subfolders.
%
% Syntax:
%   cFile = getFilesAll(cPath)
%
% Inputs:
%   cPath - cell with strings of folder path
%   bPath - boolean if files should be returned with full path
%
% Outputs:
%   cFile - cell (1xn) with strings of all files within path 
%
% Example: 
%   cFile = getFilesAll(pwd)
%
% See also: dirPattern
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2017-01-09

% check input
if nargin < 2
    bPath = true;
end
if ~iscell(cPath)
    cPath = {cPath};
end

cFile = {};
for nIdxPath = 1:numel(cPath) % for all specified pathes
    if ~exist(cPath{nIdxPath},'dir')
        warning('getFilesAll:noValidPath',...
            'The specified path is no folder on the file system: %s',sPath);
        continue
    end
    
    % get path content
    cFileAdd = dirPattern(cPath{nIdxPath},'*','file');
    cFolder = dirPattern(cPath{nIdxPath},'*','folder');
    
    % add path
    if bPath
        cFileAdd = cellfun(@(x)fullfile(cPath{nIdxPath},x),cFileAdd,'UniformOutput',false);
    end
    cFile = [cFile cFileAdd];
    
    % reccursive call for subfolders
    for nIdxFolder = 1:numel(cFolder)
        cFileAdd2 = getFilesAll(fullfile(cPath{nIdxPath},cFolder{nIdxFolder}));
        cFile = [cFile cFileAdd2]; %#ok<AGROW>
    end
end
return