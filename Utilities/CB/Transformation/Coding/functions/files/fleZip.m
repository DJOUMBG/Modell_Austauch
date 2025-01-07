function sDestFile = fleZip(sFolderpath,sDestFile)

% check input arguments
if nargin < 2
    sDestFile = [sFolderpath,'.zip'];
    sPreZipFile = sDestFile;
else
    [sFolder,sFilename] = fileparts(sDestFile);
    sPreZipFile = fullfile(sFolder,[sFilename,'.zip']);
end

% check destination file
if chkFileExists(sDestFile)
    error('Destination zip file "%s" does already exist.',...
        sDestFile);
end

% check pre zip file
if chkFileExists(sPreZipFile)
    error('Destination zip file "%s" does already exist.',...
        sDestFile);
end

% get list of files and folder on first folder level
cPaths = getFileFolderList(sFolderpath);

% zip folder to file
zip(sPreZipFile,cPaths);
pause(0.1);

% move pre zip file to finale result file
if not(strcmp(sDestFile,sPreZipFile))
    movefile(sPreZipFile,sDestFile);
end

end % fleZip

% =========================================================================

function cPaths = getFileFolderList(sFolder)

    % init output
    cPaths = {};

    % get directory structure of folder
    xPaths = dir(sFolder);

    % get each file and folder
    for nPath=1:numel(xPaths)

        % get path name
        sPath = xPaths(nPath).name;

        % check for valid path
        if ~strcmp(sPath,'.') && ~strcmp(sPath,'..')
            cPaths = [cPaths;fullfile(sFolder,sPath)]; %#ok<AGROW>
        end

    end % xPaths

end % getFileFolderList
