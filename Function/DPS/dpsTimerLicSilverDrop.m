function dpsTimerLicSilverDrop(vTimeDelay)
% PMSTIMERCLEARMEX start a one-time timer to execute the silver license
% release after the simulation model ended. Needed for SBS ECU models of
% old silver versions.
%
% Syntax:
%   pmsTimerClearMex(vTimeDelay)
%
% Inputs:
%   vTimeDelay - value [s] with the time delayuntil the drop is executed
%
% Outputs:
%
% Example: 
%   dpsTimerLicSilverDrop(1)
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2022-02-24

% default value of input
if nargin < 1
    vTimeDelay = 5;
end

% timer definition
hMexTimer = timer(...
    'Name','dpsLicSilverDrop',...
    'TimerFcn',@dropFcn,...
    'StartDelay',vTimeDelay,...
    'BusyMode','queue',...
    'ExecutionMode','singleShot',...
    'Period',15,...
    'TasksToExecute',1,...
    'Tag','dpsLicSilverDrop');

% start timer
start(hMexTimer);
return

% =========================================================================

function dropFcn(varargin)
% DROPFCN call the Silver mex function to release the license
%
% Syntax:
%   dropFcn(varargin)
%
% Inputs:
%   varargin - (none)

% determine Silver installation path
sPath = getenv('SILVER_HOME');
if isempty(sPath)
    sPath = getenv('SILVER_RUNTIME_LICENSE_HOME');
end
if isempty(sPath)
    fprintf(1,['dpsTimerLicSilverDrop: Could not determine Silver ' ...
        'installation from env variable - license not released.\n']);
    return
end
% fprintf(1,'%s\n',sPath);
disp(['Silver version determined by dpsTimerLicSilverDrop:',sPath])

% add silver Matlab libs
addpath(fullfile(sPath,'matlab'));
if strcmp(computer('arch'), 'win32')
    addpath(fullfile(sPath,'matlab','x86'));
end

% perform drop
if exist('release_legacy_silver_license','file')
    release_legacy_silver_license;
else
    fprintf(1,['dpsTimerLicSilverDrop: "release_legacy_silver_license" not ' ...
        'found in <Silver installation>\\matlab - license not released.\n']);
end
return

