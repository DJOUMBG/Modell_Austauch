function [bValid,sVersionString] = silPythonVersionCheck(sPythonExeFilepath)
% SILSILVERVERSIONCHECK returns the version of specific Python executable.
%
% Syntax:
%   [bValid,sVersionString] = silPythonVersionCheck
%   [bValid,sVersionString] = silPythonVersionCheck(sPythonExeFilepath)
%
% Inputs:
%   sPythonExeFilepath - string (optional): filepath to specific Python executable file 
%
% Outputs:
%           bValid - boolean (1x1): flag, if version check was successful (true) 
%   sVersionString - string: string with Python version, if correct Python executable,
%       otherwise error message from system command is returned 
%
% Example: 
%   [bValid,sVersionString] = silPythonVersionCheck
%   [bValid,sVersionString] = silPythonVersionCheck(sPythonExeFilepath)
%
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2022-12-15

%% check input arguments

% number of arguments
if nargin > 1
    error('silPythonVersionCheck:NumberOfArgs',...
        'Incorrect number of input arguments.');
end

% optional argument
if nargin < 1
   	sPythonExeFilepath = 'python.exe';
end


%% ask for Python version

% version command
sCmd = sprintf('"%s" %s',sPythonExeFilepath,'--version');

% execute command
[bFailed,sVersionString] = system(sCmd);

% format Python version string
if ~bFailed
    sVersionString = strtrim(strrep(sVersionString,'Python',''));
end

% convert output
bValid = ~bFailed;

return