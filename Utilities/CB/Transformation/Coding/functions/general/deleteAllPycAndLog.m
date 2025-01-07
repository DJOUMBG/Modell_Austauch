function deleteAllPycAndLog(sFolder)
% DELETEALLPYCANDLOG deletes each python cache folder and python cache file
% as well as log files appearing in given folder and its subfolders.
%
% Syntax:
%   deleteAllPycAndLog(sFolder)
%
% Inputs:
%   sFolder - string: folder to be cleaned 
%
% Outputs:
%   (deletion of python cache files and log files)
%
% Example: 
%   deleteAllPycAndLog(sFolder)
%
%
% See also: fleAllSubfoldersGet, fleAllSubfilesGet
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2023-02-09

%% delete folders

% get all folder folders
cFolderpathList = fleAllSubfoldersGet(sFolder);

% search for __pycache__ folder and delete them
for nFolder=1:numel(cFolderpathList)
    
    % get folder
    sFolderpath = cFolderpathList{nFolder};
    [~,sFolderName,~] = fileparts(sFolderpath);
    
    % delete if pychache folder
    if strcmp(sFolderName,'__pycache__')
        rmdir(sFolderpath,'s');
    end
    
end


%% delete remaining files

% get all files if any other exists
cFilepathList = fleAllSubfilesGet(sFolder);

% search for *.pyc and *.log files and delete them
for nFile=1:numel(cFilepathList)
    
    % get file
    sFilepath = cFilepathList{nFile};
    [~,~,sExt] = fileparts(sFilepath);
    
    % delete if *pyc and *.log files
    if strcmp(sExt,'.pyc') || strcmp(sExt,'.log')
        delete(sFilepath);
    end
    
end

return