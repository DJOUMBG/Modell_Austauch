function Update_AngTorq_20230310

close all
clear
clc

cd(fileparts(mfilename('fullpath')));

%% ### description ###
% Script updates each template in given config folder:
%   Replace mec3d.mbsrtm module variants with "*_inStwAng" and "*_inStwTorq"
%   with the new version: 
%       - new variant without suffix "*_inStwAng" or "*_inStwTorq"
%       - DataSet variant steer is changed:
%           - if "*_inStwAng":
%           - if "*_inStwTorq": 
%
% If there are versionIDs for Modules and DataSets, they will be replaced
% as well from current perforce online workspace


%% *** Define folder list ***
% -------------------------------------------------------------------------

% cFolderList(1,1) = {'D:\DIVe\drc_dec_mec3d\Configuration\Vehicle_Truck3D\Basic'};
% cFolderList(2,1) = {'D:\DIVe\drc_dec_mec3d\Configuration\Vehicle_Truck3D\D4A'};
% cFolderList(3,1) = {'D:\DIVe\drc_dec_mec3d\Configuration\Vehicle_Truck3D\SilTesting'};
% cFolderList(4,1) = {'D:\DIVe\drc_dec_mec3d\Configuration\Vehicle_Other\DIVeCBdev'};
% cFolderList(5,1) = {'D:\DIVe\drc_dec_mec3d\Configuration\Vehicle_Other\DIVeCBdev_Matlab2020'};

cFolderList(1,1) = {'D:\DIVe\drc_dec_mec3d\Configuration\Vehicle_EBS\sBSP'};

% -------------------------------------------------------------------------

%% Get files from folders

cFileList = getListOfConfigFiles(cFolderList);


%% read files, make changes, write file

for i=1:numel(cFileList)
    
    % file name
    sFileName = cFileList{i};
    % user info
    fprintf(1,'Update config xml "%s".\n',sFileName);
    
    % read config xml
    evalc('xConfig = dsxRead(sFileName);');
    
    % get number of mec3d module setup
    nNumMec3d = getModuleSetupNumberOfSpecies(xConfig.Configuration.ModuleSetup,...
        'mec3d');
    % check if config has module
    if ~nNumMec3d
        fprintf(1,'\tConfig has no module with species "mec3d".\n');
        continue;
    end
    
    % make changes
    xConfig.Configuration.ModuleSetup(nNumMec3d) = ...
        doIndividualChangesInModuleSetup(...
        xConfig.Configuration.ModuleSetup(nNumMec3d));
    
    % write updated config xml
    dsxWrite(sFileName,xConfig);
end

return

% =========================================================================


%##########################################################################

function xModuleSetup = doIndividualChangesInModuleSetup(xModuleSetup)

%--------------------------------------------------------------------------
% steer type suffix
sVariantSuffix_ang = '_inStwAng';
sVariantSuffix_torq = '_inStwTorq';

% aps type suffix
sApsDataSuffix_ext = '_apsExt';
sApsDataSuffix_no = '_noAps';

%--------------------------------------------------------------------------

% get module variant
sCurModuleVariant = xModuleSetup.Module.variant;

% get vehicel name of variant and DataSets
sVehicelName = strrep(sCurModuleVariant,sVariantSuffix_ang,'');
sVehicelName = strrep(sVehicelName,sVariantSuffix_torq,'');

% check DataClass steer
nSteerNum = getDataSetNumberOfClassType(xModuleSetup.DataSet,'steer');
if ~nSteerNum
    fprintf(2,'\tConfig has no DataClass "steer" in mec3d Module!\n');
    return;
end

% get DataSet variant of steer
sCurDataSetSteerVariant = xModuleSetup.DataSet(nSteerNum).variant;

%--------------------------------------------------------------------------

% get current state of steer type
%   => nStateSteerType: [0 = not found, 1 = inStwAng, 2 = inStwTorq]
if strcontain(sCurModuleVariant,sVariantSuffix_ang)
    nStateSteerType = 1;
elseif strcontain(sCurModuleVariant,sVariantSuffix_torq)
    nStateSteerType = 2;
else
    nStateSteerType = 0;
end

% get current state of aps type
%   => nStateApsType: [0 = aps intern, 1 = aps extern, 2 = no aps]
if strcontain(sCurDataSetSteerVariant,sApsDataSuffix_ext)
    nStateApsType = 1;
elseif strcontain(sCurDataSetSteerVariant,sApsDataSuffix_no)
    nStateApsType = 2;
else
    nStateApsType = 0;
end

%--------------------------------------------------------------------------

% new module variant name
sNewModuleVariant = sVehicelName;

% legend:
%	=> nStateSteerType: [0 = not found, 1 = inStwAng, 2 = inStwTorq]
%   => nStateApsType: [0 = aps intern, 1 = aps extern, 2 = no aps]

% inStwAng && aps intern
if nStateSteerType == 1 && nStateApsType == 0
    sNewDataSetSteerVariant = [lower(sVehicelName),'_inStwAng','_apsIntern'];
% inStwAng && aps extern
elseif nStateSteerType == 1 && nStateApsType == 1
	sNewDataSetSteerVariant = [lower(sVehicelName),'_inStwAng','_apsExtern'];
% inStwAng && no aps 
elseif nStateSteerType == 1 && nStateApsType == 2
    sNewDataSetSteerVariant = [lower(sVehicelName),'_inStwAng','_noAps'];
% inStwTorq && aps intern
elseif nStateSteerType == 2 && nStateApsType == 0
    sNewDataSetSteerVariant = [lower(sVehicelName),'_inStwTorq','_apsIntern'];
% inStwTorq && aps extern
elseif nStateSteerType == 2 && nStateApsType == 1
    sNewDataSetSteerVariant = [lower(sVehicelName),'_inStwTorq','_apsExtern'];
% inStwTorq && no aps
elseif nStateSteerType == 2 && nStateApsType == 2
    sNewDataSetSteerVariant = [lower(sVehicelName),'_inStwTorq','_noAps'];
% no valid changes
else
    fprintf(1,'\tNo update possible. The changes may already have been made.\n');
    return;
end

%--------------------------------------------------------------------------

% assign changes
xModuleSetup.Module.variant = sNewModuleVariant;
xModuleSetup.DataSet(nSteerNum).variant = sNewDataSetSteerVariant;

return

%##########################################################################


% =========================================================================

function cFileList = getListOfConfigFiles(cFolderList)

cFileList = {};
for i=1:numel(cFolderList)
    cFilesInFolder = fleFilesGet(cFolderList{i},{'.xml'});
    cFullpathList = fleFullpathCreate(cFolderList{i},cFilesInFolder);
    cFileList = [cFileList;cFullpathList]; %#ok<AGROW>
end

return

% =========================================================================

function nNum = getModuleSetupNumberOfSpecies(xModuleSetupList,sSpecies)

nNum = 0;
for i=1:numel(xModuleSetupList)
    if strcmp(xModuleSetupList(i).Module.species,sSpecies)
        nNum = i;
        return;
    end
end

return

% =========================================================================

function nNum = getDataSetNumberOfClassType(xDataSetList,sClassType)

nNum = 0;
for i=1:numel(xDataSetList)
    if strcmp(xDataSetList(i).classType,sClassType)
        nNum = i;
        return;
    end
end

return
