function [bValid,sMsg] = silSilverLicenseCheck
% SILSILVERLICENSECHECK checks if Silver license from flex lm server is 
% available or not.
%
% Syntax:
%   [bValid,sMsg] = silSilverLicenseCheck
%
% Inputs:
%
% Outputs:
%   bValid - boolean (1x1): flag if license server is available (true) or not (false) 
%     sMsg - string: return message of lmutil.exe command
%
% Example: 
%   [bValid,sMsg] = silSilverLicenseCheck
%
%
% See also: chkFileExists
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2022-12-14

%% check license environment

% name of license environment variable
sSilverLicenseEnvName = 'SNPSLMD_LICENSE_FILE';

% get license environment
sSilverLicenseString = getenv(sSilverLicenseEnvName);

% check for empty or not existing environment
if isempty(sSilverLicenseString)
    error('The Silver license environment "%s" is empty or not defined for this system or user.',...
        sSilverLicenseEnvName);
end


%% check license with lmutil

% location of this function
sThisFunctionFolderpath = fileparts(mfilename('fullpath'));

% filepath of lmutil.exe next to this function
sLmutilExeFilepath = fullfile(sThisFunctionFolderpath,'lmutil.exe');

% check if lmutil.exe file exists
if ~chkFileExists(sLmutilExeFilepath)
    error('The "lmutil.exe" file is missing in this function folder. Expected filepath is "%s".',...
        sLmutilExeFilepath);
end


% create license check command
sLicenseCmd = sprintf('%s %s "%s" -a',sLmutilExeFilepath,...
    'lmstat -c',sSilverLicenseString);

% execute silver license check command
[bFailed,sMsg] = system(sLicenseCmd);

% return value
bValid = ~bFailed;

return