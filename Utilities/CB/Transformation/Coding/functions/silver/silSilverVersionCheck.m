function [bValid,sVersionString] = silSilverVersionCheck
% SILSILVERVERSIONCHECK returns the version of silver installation when
% silver is installed correctly.
%
% Syntax:
%   [bValid,sVersionString] = silSilverVersionCheck
%
% Inputs:
%
% Outputs:
%           bValid - boolean (1x1): flag, if version check was successful (true) and silver is correctly installed 
%   sVersionString - string: string with Silver version, if Silver is correctly installed,
%                           otherwise error message from system command is returned 
%
% Example: 
%   [bValid,sVersionString] = silSilverVersionCheck
%
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2022-12-14

%% ask for Silver version

% version command
sCmd = sprintf('%s %s','silversim','--version');

% execute command
[bFailed,sVersionString] = system(sCmd);

% format silver version string
if ~bFailed
    sVersionString = strtrim(sVersionString);
end

% convert output
bValid = ~bFailed;

return