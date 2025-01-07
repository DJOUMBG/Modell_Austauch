function nPID = getPIDMatlab
% GETMATLABPID get the Windows process ID of this Matlab instance.
%
% Syntax:
%   nPID = getPIDMatlab
%
% Inputs:
%
% Outputs:
%   nPID - integer (1x1) with Windows process ID of this MATLAB instance
%
% Example: 
%   nPID = getPIDMatlab
%
% See also: getPIDAll, feature('getpid')
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-8485-3325
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2016-05-18

% get process ID by feature
try
    nPID = feature('getpid');
    bSuccess = true;
catch ME
    fprintf(2,'%s\n',ME.message);
    bSuccess = false;
end

if ~bSuccess
    % get process ID string of java instance
    sProcess = java.lang.management.ManagementFactory.getRuntimeMXBean.getName.char;
    
    % derive process ID (PID) from string
    nPID = str2double(regexp(sProcess,'^\d+','match','once'));
end
return
    