function fleDeleteFolder(sFolderpath)
% FLEDELETEFOLDER deletes the given folder and all its subfolders and
% subfiles if it exists.
%
% Syntax:
%   fleDeleteFolder(sFolderpath)
%
% Inputs:
%   sFolderpath - string: folderpath of folder to be deleted 
%
% Outputs: (delete folder on system)
%
% Example: 
%   fleDeleteFolder(sFolderpath)
%
%
% See also: chkFolderExists
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2023-10-12

%% create folder if not exists

if chkFolderExists(sFolderpath)
	nStatus = rmdir(sFolderpath,'s');
    if ~nStatus
        error('Folder "%s" could not be deleted.',sFolderpath);
    end
end

return