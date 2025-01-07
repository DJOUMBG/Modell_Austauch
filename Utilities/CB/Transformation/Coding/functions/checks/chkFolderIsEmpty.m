function bValid = chkFolderIsEmpty(sFolderpath)
% CHKFOLDERISEMPTY checks if a folder is empty and returns flag.
%
% Syntax:
%   bValid = chkFolderIsEmpty(sFolderpath)
%
% Inputs:
%   sFolderpath - string: folderpath of folder
%
% Outputs:
%   bValid - bool (1x1): flag, if folder is empty (true) or not (false)
%
% Example: 
%   bValid = chkFolderIsEmpty(sFolderpath)
%
%
% See also: fleFilesGet, fleFoldersGet
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2022-12-15

%% check if folder not empty
if isempty(fleFoldersGet(sFolderpath)) && isempty(fleFilesGet(sFolderpath))
    bValid = true;
else
    bValid = false;
end

return

