function cFilelist = fleFilesGet(sFolder,cExtensions)
% FLEFILESGET returns a list of all files in folder or of all files with
% specified file extensions.
%
% Syntax:
%   cFilelist = fleFilesGet(sFolder,cExtensions)
%   cFilelist = fleFilesGet(sFolder)
%
% Inputs:
%       sFolder - string of folder path
%   cExtensions - [optional] cell (1xn) of strings with list of possible file extensions with dot (!), e.g. {'.mat','.m'}
%
% Outputs:
%   cFilelist - cell (mx1) of strings as list with file paths
%
% Example: 
%   cFilelist = fleFilesGet(pwd,{'.mat','.m'})
%   cFilelist = fleFilesGet(pwd) % each file
%
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2022-10-06

%% check input arguments

if nargin == 1
    cExtensions = {};
elseif nargin ~= 2
    error('Incorrect number of input arguments.');
end

%% collect files

% init list
cFilelist = {};

% get subfolders and files under folder
xPaths = dir(sFolder);

for i=1:length(xPaths)
    % check if it is file
    if ~xPaths(i).isdir
        sFile = xPaths(i).name;
        % get file parts
        [sDir,sName,sExt] = fileparts(sFile);
        % check for specified extensions
        if isempty(cExtensions) || sum(strcmp(sExt,cExtensions))
            cFilelist = [cFilelist;{fullfile(sDir,[sName,sExt])}]; %#ok
        end
    end
end

return

