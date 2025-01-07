function cFolderList = fleFoldersGet(sFolder)
% FLEFOLDERSGET returns a list of all subfolders on first level in folder.
%
% Syntax:
%   cFolderList = fleFoldersGet(sFolder)
%
% Inputs:
%   sFolder - string with folder path
%
% Outputs:
%   cFolderList - cell (mx1) of strings as list with folder paths
%
% Example: 
%   cFolderList = fleFoldersGet(pwd)
%
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2022-10-06

%% check input arguments

if nargin ~= 1
    error('Incorrect number of input arguments.');
end

%% collect folders

% init list
cFolderList = {};

% get subfolders and files under folder
xPaths = dir(sFolder);

for i=1:length(xPaths)
    % check if it is folder
    if xPaths(i).isdir
        sFolder = xPaths(i).name;
        % check for valid folders
        if ~strcmp(sFolder,'.') && ~strcmp(sFolder,'..')
            cFolderList = [cFolderList;sFolder]; %#ok
        end
    end
end

return

