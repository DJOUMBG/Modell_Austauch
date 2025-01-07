function sMP = silCreateSlave(sMP,sDIVeContentPath,nIdClient,sPathRunDirSlave,nSetup,sExecutionTool) %#ok<INUSL>


%% sMP configuration part

%For DIVe CB it is always 1:
nIdServer = 1;

%Silver library path
sSilverPathLib32 = fullfile([getenv('SILVER_HOME') '\matlab']);
sSilverPathLib64 = fullfile([getenv('SILVER_HOME') '\matlab\x64']);

% paths
cStartPath = strsplitOwn(path,pathsep);

%load sMP from path
cOldPath = cell(0);
if isfield(sMP,'platform') && isfield(sMP.platform,'mPath')
	cOldPath = sMP.platform.mPath;
end

% additional stuff in sMP
sMP.platform.version = 'DIVeCBversion'; % TODO add DIVe CB version string
sMP.cfg.build(1).path = sPathRunDirSlave;
sMP.cfg.build.username = getenvOwn('username');
sMP.cfg.build.computername = getenvOwn('computername');

% adapt configuration information for Slave/Client instance
sMP.cfg.Configuration.name = sprintf('%s_S%iClient%i',...
			sMP.cfg.Configuration.name,nIdServer,nIdClient);
        
sMP.cfg.Configuration.description = 'Co-simulation client';

% create linking structure
sMP.link = pmsPortInfo(sMP.cfg);


%% Other

% set server stuff
nIdServer = 1;
sMP.cfg.cosim(nIdServer).type = 'Silver';
sMP.cfg.cosim(nIdServer).client(nIdClient).nSetup = nSetup;
sMP.cfg.cosim(nIdServer).client(nIdClient).path = 'Slave1';
sMP.cfg.cosim(nIdServer).server.port = 2000; % port or dummy for main server instance
sMP.cfg.cosim(nIdServer).server.ip = '127.0.0.1'; % port or dummy for main server instance
sMP.cfg.cosim(nIdServer).middleware = csmMiddlewareSilver(nIdServer,sSilverPathLib32,sSilverPathLib64);

% set current
xVer = ver('Matlab');

%not working as of now
[sRelease,~,~] = versionAliasMatlab(xVer.Version,'all');
sArchitecture = strrep(computer('arch'),'win','w');
sMP.cfg.cosim(nIdServer).automation = 0;
sMP.cfg.cosim(nIdServer).current.name =  sprintf('S%iClient%i',nIdServer,nIdClient); % current instance name
sMP.cfg.cosim(nIdServer).current.mode = 'Slave'; % for Silver
sMP.cfg.cosim(nIdServer).current.executionTool = strGlue({'Simulink',sArchitecture,sRelease},'_');
sMP.cfg.cosim(nIdServer).current.ip = '127.0.0.1';
sMP.cfg.cosim(nIdServer).current.maxStepSize = ...
sMP.cfg.Configuration.MasterSolver.maxCosimStepsize; % for master instance

% create slave model
try
    evalc('pmsSlaveCreate(sMP,nIdServer,nSetup,sDIVeContentPath);');
catch ME
    error('Error while creating Simulink cosim model:\n%s',ME.message);
end
pause(0.1);

% add matlab path details to sMP struct
cStopPath = strsplitOwn(path,pathsep);
cPathToAdd = setdiff(cStopPath,cStartPath);
cPathToAdd = unique(cPathToAdd);
sMP.platform.mPath = unique(union(cPathToAdd,cOldPath));

% cleare variables for saving
clear sPathToMat sConfigFile sDIVeContentPath nIdClient nSetup ...
sSilverPathLib32 sSilverPatgLib64 sUtilScriptspath xConfiguration xModule ...
nIdServer xVer sRelease sVersion cBit fid1

%save DIVeMB model as SlaveModel for DIVe CB
save_system('DIVeMB_Model',fullfile(sPathRunDirSlave,sExecutionTool));
close_system(sExecutionTool);

return % silCreateSlave
