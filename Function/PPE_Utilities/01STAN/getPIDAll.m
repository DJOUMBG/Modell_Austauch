function  [nPID] = getPIDAll(sExecutable)
% GETPIDALL get all Windows process IDs with the specified executable name.
%
% Syntax:
%   nPID = getPIDAll(sExecutable)
%
% Inputs:
%   sExecutable - string with name of process executable
%
% Outputs:
%   nPID - integer (1xn) with windows process IDs
%
% Example: 
%   nPID = getPIDAll('Matlab.exe')
%   nPID = getPIDAll('QTronic-license-service.exe')
%
% See also: getPIDMatlab, system
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-8485-3325
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2016-08-15

% init output
nPID = [];

% retrieve current tasklist
[nStatus,sMsg] = system(sprintf('tasklist.exe /NH /FI "imagename eq %s', sExecutable));
nRetry = 0;
while nStatus ~= 0 && nRetry<60
    nRetry = nRetry + 1;
    warning([mfilename ':getProcessIDs'],['Could not execute ''tasklist.exe'': ' sMsg '. Trying again...']);
    pause(1);
    [nStatus,sMsg] = system('tasklist.exe /NH');
end

% parse process ID from tasklist
ccField = textscan(sMsg, '%s %s %*[^\n]');
for nIdxField = 1:length(ccField{1})
    if strncmpi(ccField{1}{nIdxField},sExecutable,24) % limit compare lenght - Win10 21H2 returns max 25 chars
        nPIDAdd = str2double(ccField{2}{nIdxField});
        % check ID
        if ~isnan(nPIDAdd)
            % add to list
            nPID(end+1) = nPIDAdd; %#ok<AGROW>
        end
    end
end
return