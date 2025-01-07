function fleCopyFolderContent(sRootSource,sRootDest)
% FLECOPYFOLDERCONTENT copies the file and folder structure from source
% root folder to destination root folder by force operation (ignore
% read-only state in destination).
%
% Syntax:
%   fleCopyFolderContent(sRootSource,sRootDest)
%
% Inputs:
%   sRootSource - string: folder path of source root folder 
%     sRootDest - string: folder path of destination root folder 
%
% Outputs:
%
% Example: 
%   bSuccess = fleCopyFolderContent(sRootSource,sRootDest)
%
%
% See also: fleAllSubfilesGet, fleRelativePathGet
%
% Author: Elias Rohrer, TE/PTC-H, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2024-05-15

% get full filelist of source root folder, containing all subfiles
cSourceFileList = fleAllSubfilesGet(sRootSource);

% copy each file to destination
for nFile=1:numel(cSourceFileList)
    
    % full path of file in source
    sSourceFile = cSourceFileList{nFile};
    
    % relative path of file
	sRelFilePath = fleRelativePathGet(sRootSource,sSourceFile);
    
    % full path of file in destination
    sDestFile = fullfile(sRootDest,sRelFilePath);
    
    % get folder path of file
    sDestFolder = fileparts(sDestFile);
    
    % make folder if not exist
    if not(chkFolderExists(sDestFolder))
        
        % try to make folder
        [bSuccess,sMessage] = mkdir(sDestFolder);
        
        % check folder creation
        if not(bSuccess)
            error('Folder "%s" could not be created, because of:\n%s',...
                sDestFolder,sMessage);
        end
        
    end
    
    % copy file from source to destination
    [bSuccess,sMessage] = copyfile(sSourceFile,sDestFile,'f');
    
    % check file copy
    if not(bSuccess)
        error('File "%s" could not be copied, because of:\n%s',...
            sDestFile,sMessage);
    end
    
end % cSourceFileList

return
