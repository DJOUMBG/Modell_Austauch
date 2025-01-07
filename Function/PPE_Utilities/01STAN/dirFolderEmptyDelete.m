function dirFolderEmptyDelete(sPath)
% DIRFOLDEREMPTYDELETE deletes all empty folders from a specified folder tree. 
%
% Syntax:
%   dirFolderEmptyDelete(sPath)
%
% Inputs:
%   sPath - string with folder path
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2016-02-24

% get path content
cFile = dirPattern(sPath,'*','file');
cFolder = dirPattern(sPath,'*','folder');

% reccursion for folder delete
for nIdxFolder = 1:numel(cFolder)
    dirFolderEmptyDelete(fullfile(sPath,cFolder{nIdxFolder}));
end

% get folders again
cFolder = dirPattern(sPath,'*','folder');

% remove empty folder 
if isempty(cFile) && isempty(cFolder)
    try
        rmdir(sPath);
    catch
        fprintf(2,'Directory delete failed: %s\n',sPath);
    end
end
return
