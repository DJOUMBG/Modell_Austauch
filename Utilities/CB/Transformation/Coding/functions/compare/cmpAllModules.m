function cmpAllModules(cModuleXmlFileList,sTemplateConfigXmlFile,sWorkspaceRoot,bWithOpen)

for nMod=1:numel(cModuleXmlFileList)
    
    % get current module xml filepath
    sModuleXmlFile = cModuleXmlFileList{nMod};
    
    % check module xml file
    if ~chkFileExists(sModuleXmlFile)
        error('Module xml file "%s" does not exist.',sModuleXmlFile);
    end
    
    % read module xml file
    xModule = dsxRead(sModuleXmlFile);
    
    % get list of all modelSet setups
    xModuleSetupList = dvePatchModule2Setup(xModule.Module,bWithOpen);
    
    % read template config xml file
    xConfig = dsxRead(sTemplateConfigXmlFile);
    
    % replace module data
    for nSet=1:numel(xModuleSetupList)
        xCurConfig = xConfig;
        xCurConfig.Configuration.ModuleSetup(end+1) = xModuleSetupList(nSet);
        xCurConfig.Configuration.ModuleSetup = ...
            dveUpdateVersionIds(xCurConfig.Configuration.ModuleSetup,...
            fullfile(sWorkspaceRoot,'Content'));
        runTrafoCompare(xCurConfig,sWorkspaceRoot);
    end
        
end

return

% =========================================================================

function runTrafoCompare(xConfig,sWorkspaceRoot)

% default name for folder and configuration
sStdTempName = 'tempCOMP';

% create temporary conbfig xml file
sTempFolder = fullfile(pwd,sStdTempName);
sTempFile = fullfile(sTempFolder,[sStdTempName,'.xml']);
mkdir(sTempFolder);

% save temporary configuration file
xConfig.Configuration.name = sStdTempName;
dsxWrite(sTempFile,xConfig);

% run transformations
cmpCompareTrafoTypes(sTempFile,sWorkspaceRoot);

% delete temporaray file
rmdir(sTempFolder,'s');

return
