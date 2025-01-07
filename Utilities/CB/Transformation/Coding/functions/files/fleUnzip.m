function sDestFolder = fleUnzip(sFilepath,sDestFolder)

% check input arguments
if nargin < 2
    [sDir,sName] = fileparts(sFilepath);
    sDestFolder = fullfile(sDir,sName);
end

% check destination folder
if chkFolderExists(sDestFolder)
    error('Destination unzip folder "%s" does already exist.',...
        sDestFolder);
end

% unzip file
unzip(sFilepath,sDestFolder);
pause(0.1);

end % fleUnzip
