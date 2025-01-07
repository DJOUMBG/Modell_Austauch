function dveRunCbTrafoForFolder(sConfigTestcaseFolder,varargin)


%% check input arguments

if ~chkFolderExists(sConfigTestcaseFolder)
    error('Folder %s with testcase configurations does not exist.',...
        sConfigTestcaseFolder);
end
if chkFolderIsEmpty(sConfigTestcaseFolder)
	error('Folder %s with tescase configurations is empty.',...
        sConfigTestcaseFolder);
end


%% create testcase list

% get testcase list
cTestcaseList = fleFilesGet(sConfigTestcaseFolder,{'.xml'});

% create full paths
hFull = @(x) fullfile(sConfigTestcaseFolder,x);
cTestcaseList = cellfun(hFull,cTestcaseList,'UniformOutput',false);


%% run transformation

dveRunCbTrafoForList(cTestcaseList,varargin{:});


end % dveRunCbTrafoForFolder