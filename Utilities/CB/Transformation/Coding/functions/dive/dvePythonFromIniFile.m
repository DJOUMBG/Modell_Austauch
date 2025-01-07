function [sPython3ExeFilepath,sPythonVersion] = dvePythonFromIniFile(sWorkspaceRootFolderpath)
% DVEPYTHONFROMINIFILE returns the Python 3 executable and version number
% of defined python.exe path in preferences ini-File of given DIVe
% workspace.
%
% Syntax:
%   [sPython3ExeFilepath,sPythonVersion] = dvePythonFromIniFile(sWorkspaceRootFolderpath)
%
% Inputs:
%   sWorkspaceRootFolderpath - string: folderpath of DIVe workspace 
%
% Outputs:
%   sPython3ExeFilepath - string: filepath of Python 3 executable file 
%        sPythonVersion - string: version number of Python executable  
%
% Example: 
%   [sPython3ExeFilepath,sPythonVersion] = dvePythonFromIniFile(sWorkspaceRootFolderpath)
%
%
% See also: chkFolderExists, fleIniFileGetValues, fleIniFileRead, silPythonVersionCheck
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2023-02-23

%% preferences

% define relevant parameters from ini file
cIniFileParameters = {'pythonpath'};

% define ini file ignore characters
cIniFileIgnoreChars = {'[','#',';','!'};


%% create paths

% create preference folder path
sPreferencesFolderpath = fullfile(sWorkspaceRootFolderpath,'Preferences');

% check if folder exists
if ~chkFolderExists(sPreferencesFolderpath)
    error('dvePythonFromIniFile:MissingPrefFolder',...
        'Folder "%s" does not exist.',sPreferencesFolderpath);
end

% create file path of preference ini file
sPreferenceIniFilepath = fullfile(sPreferencesFolderpath,'myDIVeCB.ini');

% check if ini file exists
if ~chkFileExists(sPreferenceIniFilepath)
    error('dvePythonFromIniFile:MissingIniFile',...
        'ini-File "%s" does not exist.',sPreferencesFolderpath);
end


%% get values from ini file

% name-value pairs of ini file
cPrefIniNameValues = fleIniFileRead(sPreferenceIniFilepath,cIniFileIgnoreChars);
[cIniFileValues,sMsg,bValid] = fleIniFileGetValues(cPrefIniNameValues,cIniFileParameters);

% check ini file parameters
if ~bValid
    error('dvePythonFromIniFile:IniValuesError',...
        '%s.\nIn ini-File "%s".',sMsg,sPreferenceIniFilepath);
end

% get parameter values from ini files
sPython3ExeFilepath = cIniFileValues{1};


%% check python executable

% check python exe exists
if ~chkFileExists(sPython3ExeFilepath)
    error('dvePythonFromIniFile:PythonExeNotExist',...
        'The Python executable "%s" does not exist.\nDefined in ini-File "%s".',...
        sPython3ExeFilepath,sPreferenceIniFilepath);
end

% check for valid Python version
[bValid,sPythonVersion] = silPythonVersionCheck(sPython3ExeFilepath);
if ~bValid
    error('dvePythonFromIniFile:PythonVersionNotValid',...
        'The Python executable "%s" is not a valid Python.\nDefined in ini-File "%s".',...
        sPython3ExeFilepath,sPreferenceIniFilepath);
end

% check for Python 3 version
if ~strcmp(sPythonVersion(1),'3')
    error('dvePythonFromIniFile:NoPython3Version',...
        'The Python executable "%s" is not a Python 3 version, but version "%s".\nDefined in ini-File "%s".',...
        sPython3ExeFilepath,sPythonVersion,sPreferenceIniFilepath);
end

return