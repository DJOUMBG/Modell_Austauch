function InitSlave(sSlaveModelDir, sModel, sGUI)
%INITSLAVE prepares the matlab environment for the usage of a slave model 
%which will be co-simulated with silver. It adds the required, additional 
%paths to matlab, loads the required set of parameters and opens the slave 
%model. This function is called from the CoSimMaster-Module in Silver.
%
% Syntax:
%   InitSlave(sSlaveModelDir, sModel, sGUI)
%
% Inputs:
%   sSlaveModelDir: directory of the simulink slave model
%   sModel: filename of the simulink slave model 
%   sGUI: string to use matlab gui ('true') or not (otherwise)
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2023-10-23

% check input argument
if strcmpi(strtrim(sGUI),'true')
    bIsGui = true;
else
    bIsGui = false;
end

% create new log file name
sLogFileName = ['SimulinkCosimLog__',datestr(now,'yyyy_mm_dd_HH_MM_SS'),'.log'];

% get folder for logging (result folder relative to model directory of Simulink cosim model)
sResultFolder = fullfile(sSlaveModelDir,'..','results');

% check log folder an recreate it if not exist
if not(exist(sResultFolder,'dir'))
    bStatus = mkdir(sResultFolder);
    if not(bStatus)
        error('Cannot recreate "results" folder for some reasons.');
    end
end

% get log file path
sLogFile = fullfile(sResultFolder,sLogFileName);

% create log file
diary(sLogFile);
oCloseDiary = onCleanup(@() diary('off'));

% user info 
fprintf(1,'InitSlave.m was started.\n');

try
    
    % check path to Silvers matlab functions
    sSilverMatlabDir = fullfile(getenv('SILVER_HOME'),'matlab');
    if not(isequal(exist(sSilverMatlabDir,'dir'),7))
        error('Cannot find path to Silvers matlab functions. Please check environment SILVER_HOME.');
    end

    % add silvers matlab functions to path
    addpath(genpath(sSilverMatlabDir));

    % load silver simulink system
    load_system('Silver');
    fprintf(1,'Silver Simulink system was loaded.\n');

    % get current path of cosim model
    sCurrentPath = pwd;

    % split up path parts
    sSplitPWD = strsplit(fullfile(sCurrentPath),filesep);
    if numel(sSplitPWD) < 4
        error(['The working directory of the cosim model ',sCurrentPath,sprintf('\n'),...
            'does not comply with the folder specifications for DIVe CB.']);
    end

    % check if additional function from DIVe CB workspace exists
    sMatScriptPath = fullfile(sSplitPWD{1:end-3},...
        'Utilities\CB\Transformation\Scripts\addDIVeMatlabScriptingPaths.m');
    if not(isequal(exist(sMatScriptPath,'file'),2))
        error(['Script addDIVeMatlabScriptingPaths.m does not exist in the specified folder.',...
            sprintf('\n'),'Please check if the folder structure is DIVe CB compliant.']);
    end

    % run additional functions
    run(sMatScriptPath);

    % change dirctory to cosim model
    cd(sSlaveModelDir);
    
    % add environment variable for Bosch FMU license server
    %   SEE CHANGES e.g.: Content\ctrl\pti\detail\Support\setLicenceServer\setLicServer.m
    sServer = '27001@cae-truck-lic01.emea.tru.corpintra.net;27001@cae-truck-lic02.emea.tru.corpintra.net;27001@cae-truck-lic03.emea.tru.corpintra.net';
    setenv('RBDSERAD_LICENSE_FILE',sServer);
    fprintf(1,'Set environment variable "RBDSERAD_LICENSE_FILE" to get license for FMUs.\n');

    % load sMP structure
    ssMPStructFilename = fullfile('..','Master','sMP.mat');
    if not(isequal(exist(ssMPStructFilename,'file'),2))
        error('sMP.mat structure can not be found in the Master folder of the sil.');
    end
    load(ssMPStructFilename);

    % load WSForSlave data
    sWSSlaveFilename = fullfile('WSForSlave.mat');
    if not(isequal(exist(sWSSlaveFilename,'file'),2))
        error('WSForSlave.mat data can not be found in cosim model folder');
    end
    evalin('base','load(fullfile(''WSForSlave.mat''));');
    
    % user info
    fprintf(1,'sMP structure was loaded.\n');

    % replace current workspace folder in mPath
    sMP.platform.mPath = replaceWorkspaceRootInMPath(sMP.platform.mPath,...
        sCurrentPath); %#ok

    % add silvers current matlab functions to sMP mPath
    sMP.platform.mPath{end+1, 1} = sSilverMatlabDir;

    % add sMP mPath to matlab path
    cellfun(@(x) addpath(x),sMP.platform.mPath);

    % open Simulik GUI or not
    if bIsGui
        fprintf(1,'Init Simulink model %s with GUI ...\n',sModel);
        open_system(sModel);
    else
        fprintf(1,'Init Simulink model %s without GUI ...\n',sModel);
        load_system(sModel);
    end
    fprintf(1,'Simulink model %s successfully loaded.\n',sModel);
    
    % assign sMP structure into base workspace
    assignin('base', 'sMP', sMP);

    % try baypass connection
    fprintf(1,'Will try to connect to Port: %s\n',getenv('BYPASS_CONNECTION'));

    % run simulink cosim model in base workspace
    fprintf(1,'Start co-simulation with Simulink and Silver ...\n');
    evalin('base','sim(bdroot,[0,Inf]);');
    fprintf(1,'Co-simulation with Simulink and Silver ended.\n');
    
catch ME
    
    % display error message
    fprintf(2,'ERROR: %s',ME.message);
    
end

% close logging
diary('off');
quit force

return

% =========================================================================

function sMPath = replaceWorkspaceRootInMPath(sMPath,sCurrentPath)
% replace DIVe workspace root directory in the mpaths of sMP with
% DIVe workspace root directory of current model path

% get workspace folder of cosim model
sNewWorkspaceFolder = getWorkspaceRootFolder(sCurrentPath,'SiLs');
if isempty(sNewWorkspaceFolder)
   error(['Directory of cosim model ',sCurrentPath,sprintf('\n'),...
       'does not correspond to the specifications of DIVe CB.']);
end

% replace new workspace folder in mPath data
for i=1:numel(sMPath)
    % get original path
    sOrgPath = sMPath{i};
    % get original workspace folder
    sOrgWorkspaceFolder = getWorkspaceRootFolder(sOrgPath,'Content');
    % if path references to a valid workspace, replace workspace root
    if not(isempty(sOrgWorkspaceFolder))
        sNewPath = strrep(sOrgPath,sOrgWorkspaceFolder,sNewWorkspaceFolder);
    else
        sNewPath = sOrgPath;
    end
    % set new path
    sMPath{i} = sNewPath;
end

return

% =========================================================================

function sRootPath = getWorkspaceRootFolder(sPath,sDIVeFolder)
% returns the name of the workspace folder in sPath, by splitting up the
% path at a specific DIVe folder

% split path parts
cPathParts = strsplit(fullfile(sPath),filesep);

% search for the last folder of this name
for i=numel(cPathParts):-1:1
    % if found last folder of this name, create the path before this folder
    if strcmp(cPathParts{i},sDIVeFolder)
        if i > 1
            sRootPath = fullfile(cPathParts{1:i-1});
            break;
        end
    else
        sRootPath = '';
    end
end

return
