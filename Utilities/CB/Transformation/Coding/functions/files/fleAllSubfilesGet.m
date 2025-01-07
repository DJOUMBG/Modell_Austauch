function cFilepathList = fleAllSubfilesGet(sRootDir)
% FLEALLSUBFILESGET returns a list of the full filepaths of files in root
% folder and its subfolders.
%
% Syntax:
%   cFilepathList = fleAllSubfilesGet(sRootDir)
%
% Inputs:
%   sRootDir - string: existing foldername or folderpath  
%
% Outputs:
%   cFilepathList - cell of strings (mx1): list with full filepaths all files
%                       in folder and its subfolders  
%
% Example: 
%   cFilepathList = fleAllSubfilesGet(sRootDir)
%
%
% See also: fleAllSubfoldersGet
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2023-01-27

%% get all files in subfolders

% init file list
cFilepathList = {};

% get folderpaths
cFolderpathList = fleAllSubfoldersGet(sRootDir);

% search for files in every subfolder
for nFolder=1:numel(cFolderpathList)
    
    % current folderpath
    sCurFolderpath = cFolderpathList{nFolder};
    
    % all folders and files in current folder
    xDir = dir(sCurFolderpath);
    
    % search for files in current folder
    for nFile=1:numel(xDir)
        % if not is a directory
        if ~xDir(nFile).isdir
            % create filepath
            sCurFilepath = fullfile(sCurFolderpath,xDir(nFile).name);
            % check if it is file
            if chkFileExists(sCurFilepath)
                % append file to file list
                cFilepathList = [cFilepathList;{sCurFilepath}]; %#ok<AGROW>
            end
        end
    end
    
end

return