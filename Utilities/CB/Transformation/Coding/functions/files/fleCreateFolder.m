function fleCreateFolder(sFolderpath)
% FLECREATEFOLDER creates a new folder for given folder path if it does not
% already exists. If the folder cannot be created, an error is thrown.
%
% Syntax:
%   fleCreateFolder(sFolderpath)
%
% Inputs:
%   sFolderpath - string: folderpath of folder to be created 
%
% Outputs: (create folder on system)
%
% Example: 
%   fleCreateFolder(sFolderpath)
%
%
% See also: chkFolderExists
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2022-12-19

%% create folder if not exists

if ~chkFolderExists(sFolderpath)
    nStatus = mkdir(sFolderpath);
    if ~nStatus
        error('fleCreateFolder:CouldNotCreateFolder',...
            'Could not create folder "%s". Possibly missing write permissions.',...
            sFolderpath);
    end
end

return