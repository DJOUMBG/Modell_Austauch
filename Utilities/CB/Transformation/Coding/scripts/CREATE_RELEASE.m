close all
clear
clc

cd(fileparts(mfilename('fullpath')));

%% --- PREFERENCES: ---

sDestEnvFolder = 'D:\12_TestDestination';

cMainFunctionList = {'"D:\DIVe\ddc_dev\Utilities\CB\Transformation\Coding\escScripts\fun\escCreateManeuverVariants.m"'};

cSearchPathList = {genpath('D:\DIVe\ddc_dev\Utilities\CB\Transformation\Coding\functions'),...
    genpath('D:\DIVe\ddc_dev\Function'),'D:\DIVe\ddc_dev\Function'};

cIgnoreFileList = {'"D:\DIVe\ddc_dev\Function\DPS\dsxWrite.m"'};

cMainScriptList = {'"D:\DIVe\ddc_dev\Utilities\CB\Transformation\Coding\escScripts\A1_CREATE_MANEUVER_VARIANTS.m"'};

bIgnorePcode = false;


%% Create release environment

rlsBuildReleaseEnv(sDestEnvFolder,cMainFunctionList,cSearchPathList,cIgnoreFileList,cMainScriptList,bIgnorePcode);

