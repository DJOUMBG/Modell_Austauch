function [sSilverHomeFolderpath,sSilverVersion,sSilverPython3ExeFilepath,sPythonVersion] = silSilverInstallationCheck
% SILSILVERINSTALLATIONCHECK checks if Silver is correctly installed, the
% environment of Silver is set correctly, the flex lm license server could
% be reached and the silver python.exe is installed.
%
% Syntax:
%   [sSilverHomeFolderpath,sSilverVersion,sSilverPython3ExeFilepath,sPythonVersion] = silSilverInstallationCheck
%
% Inputs:
%
% Outputs:
%       sSilverHomeFolderpath - string: folderpath of Silver home 
%              sSilverVersion - string: installed Silver version as string 
%   sSilverPython3ExeFilepath - string: filepath of Silvers python 3 executable file 
%              sPythonVersion - string: used Python version as string 
%
% Example: 
%   [sSilverHomeFolderpath,sSilverVersion,sSilverPython3ExeFilepath,sPythonVersion] = silSilverInstallationCheck
%
%
% See also: chkFolderExists, chkFolderIsEmpty, chkFileExists, strStringListClean, 
%   silSilverLicenseCheck, silSilverVersionCheck, silPythonVersionCheck
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2022-12-14

%% constants

sSilverHomeEnvName = 'SILVER_HOME';
sPathEnvName = 'Path';


%% check environment for Silver > 2022

% get environment variables for silver
sSilverHomeFolderpath = fullfile(getenv(sSilverHomeEnvName));
sPathEnv = getenv(sPathEnvName);

% check if not is empty or not exist
if isempty(sSilverHomeFolderpath)
    error('silSilverInstallationCheck:SilverHomeEnv',...
        'The Silver home environment "%s" is empty or not defined for this system or user.',...
        sSilverHomeEnvName);
end
if isempty(sPathEnv)
    error('silSilverInstallationCheck:PathEnv',...
        'The path environment "%s" is empty or not defined for this system or user.',...
        sPathEnvName);
end

% split Path environment
cSystemPaths = strStringListClean(strsplit(sPathEnv,pathsep));

% convert path strings in correct format
cSystemPaths = cellfun(@(x) fullfile(x),cSystemPaths,'UniformOutput',false);


%% check for silver.exe

% check if silver home exists
if ~chkFolderExists(sSilverHomeFolderpath)
	error('silSilverInstallationCheck:SilverHomeFolder',...
        'The folder "%s" from environment variable "%s" does not exist.',...
        sSilverHomeFolderpath,sSilverHomeEnvName);
end
if chkFolderIsEmpty(sSilverHomeFolderpath)
	error('silSilverInstallationCheck:SilverHomeFolder',...
        'The Silver home folder "%s" is empty.',sSilverHomeFolderpath);
end

% silver bin folderpath 
sSilverBinFolderpath = fullfile(sSilverHomeFolderpath,'bin');

% check if sil bin exists
if ~chkFolderExists(sSilverBinFolderpath)
	error('silSilverInstallationCheck:SilverBinFolder',...
        'The Silver bin folder "%s" does not exist.',sSilverBinFolderpath);
end
if chkFolderIsEmpty(sSilverBinFolderpath)
	error('silSilverInstallationCheck:SilverBinFolder',...
        'The Silver bin folder "%s" is empty.',sSilverBinFolderpath);
end

% check, if silver bin is defined in path environment
if ~ismember(sSilverBinFolderpath,cSystemPaths)
    error('silSilverInstallationCheck:SilverBinNotInPath',...
        'The Silver bin folder "%s" is not defined in path environment "%s".',...
        sSilverBinFolderpath,sPathEnvName);
end

% check if silver.exe exists
sSilverExeFilepath = fullfile(sSilverBinFolderpath,'silver.exe');
if ~chkFileExists(sSilverExeFilepath)
    error('silSilverInstallationCheck:SilverExeFile',...
        'Silver executable filepath "%s" does not exist.',...
        sSilverExeFilepath);
end

% check if silversim.exe exists
sSilverSimExeFilepath = fullfile(sSilverBinFolderpath,'silversim.exe');
if ~chkFileExists(sSilverSimExeFilepath)
    error('silSilverInstallationCheck:SilversimExeFile',...
        'Silversim executable filepath "%s" does not exist.',...
        sSilverSimExeFilepath);
end


%% check for Silver license

% ping flex lm license server
[bValid,~] = silSilverLicenseCheck;

% error handling !!! => only warning because of DTICI license server
% problems
% if ~bValid
%     error('silSilverInstallationCheck:SilverLicense',...
%         'No connection to Silver flexmLM license server. Please check "[bValid,sMsg] = silSilverLicenseCheck".');
% end

if ~bValid
    fprintf(1,'WARNING: Problems to connect with Silver flexmLM license server!\n');
end


%% check for Silver python

% create filepath to Silvers python exe
sSilverPython3ExeFilepath = fullfile(sSilverHomeFolderpath,...
    'common','ext-tools','python3','python.exe');

% check python.exe file
if ~chkFileExists(sSilverPython3ExeFilepath)
    error('silSilverInstallationCheck:PythonExeFile',...
        'Silver-Python executable Filepath "%s" does not exist.',...
        sSilverPython3ExeFilepath);
end

% get version of Silver Python
[bValid,sPythonVersion] = silPythonVersionCheck(sSilverPython3ExeFilepath);

% error handling
if ~bValid
    error('silSilverInstallationCheck:PythonVersion',...
        'Version of Silver-Python could not be returned. Please check with function "silPythonVersionCheck".');
end

% check if python exe is min. Python 3
if ~strcmp(sPythonVersion(1),'3')
    error('silSilverInstallationCheck:PythonVersion',...
        'Silver-Python "%s" is not a Python 3 version.',sSilverPython3ExeFilepath);
end


%% check silver version

% check for correct installation and version of Silver
[bValid,sSilverVersion] = silSilverVersionCheck;

% error handling
if ~bValid
    error('silSilverInstallationCheck:SilverVersion',...
        'Version of Silver could not be returned. Silver may not be installed correctly.');
end

return