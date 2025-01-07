function dveCopyResultsFromSils(sSilsFolder,sResultFolder,cFileExtType)

% get folder list
cFolderList = fleFullpathCreate(sSilsFolder,fleFoldersGet(sSilsFolder));

% create result folder if not exist
if ~chkFolderExists(sResultFolder)
    mkdir(sResultFolder);
end

% run simulation for each folder
for nFolder=1:numel(cFolderList)
    % create folders and files
    sCurrentFolder = cFolderList{nFolder};
    sLocalResultFolder = fullfile(sCurrentFolder,'results');
    % copy result file
    cResultFileList = fleFullpathCreate(sLocalResultFolder,...
        fleFilesGet(sLocalResultFolder,cFileExtType));
    % copy all files
    for nFile=1:numel(cResultFileList)
        [~,sResultName,sResultExt] = fileparts(cResultFileList{nFile});
        copyfile(cResultFileList{nFile},fullfile(sResultFolder,[sResultName,sResultExt]));
    end
end

return
