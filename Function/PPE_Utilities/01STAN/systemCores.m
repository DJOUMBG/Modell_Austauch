function [nCore,nLogical,nCPU] = systemCores
% SYSTEMCORES determine the physical and logical cores of a Windows system
%
% Syntax:
%   [nCore,nLogical,nCPU] = systemCores
%
% Inputs:
%
% Outputs:
%      nCore - integer (1x1) with physical CPU cores
%   nLogical - integer (1x1) with logical CPU cores (hyperthreading)
%       nCPU - integer (1x1) with CPUs
%
% Example: 
%   [nCore,nLogical,nCPU] = systemCores

% init output
nCore = 0;
nLogical = 0;
nCPU = 0;

% query system
[nStatus,sMsg] = system('WMIC CPU Get DeviceID,NumberOfCores,NumberOfLogicalProcessors');
if nStatus
    error('System query with "WMIC CPU" failed!')
end

% parse output
cLine = strsplitOwn(sMsg,char(10));
for nIdxLine = 2:numel(cLine)
    cSplit = strsplitOwn(cLine{nIdxLine},' ');
    nCPU = nCPU + 1;
    nCore = nCore + str2double(cSplit{2});
    nLogical = nLogical + str2double(cSplit{3});
end
return