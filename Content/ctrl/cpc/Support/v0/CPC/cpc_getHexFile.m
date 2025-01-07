function [sFileCDS] = cpc_getHexFile(sCDS, sDir)
% CPC_GETHEXFILE get CDS hex file name
%
%
% Syntax:  [sFileCDS] = cpc_getHexFile(sCDS)
%
% Inputs:
%    sCDS - [''] name which must be part of the hex file (String, optional)
%    sDir - [''] directory of the hex files (String, optional)
%
% Outputs:
%    sFileCDS - [''] hex file name (String)
%
% Example: 
%    sFileCDS = cpc_getHexFile;
%    sFileCDS = cpc_getHexFile('');
%    sFileCDS = cpc_getHexFile('SFTP', pwd);
%    sFileCDS = cpc_getHexFile('EVOBUS', sDir);
%    sFileCDS = cpc_getHexFile('', sDir.cds);
%    sFileCDS = cpc_getHexFile(sCDS, sDir.cds);
%
%
% Author: PLOCH37
% Date:   12-Aug-2022

%% ------------- BEGIN CODE --------------

% Default inputs
switch nargin
    case 0
        sCDS = '';
        sDir = pwd;
    case 1
        sDir = pwd;
end

% Search for file
if isempty(sCDS)
    % Newer Matlab interpret ** wildcard in a specific way,
    % and doesn't combine them
    sFileCDS = dir(fullfile(sDir, '*.hex'));
else
    sFileCDS = dir(fullfile(sDir, ['*' sCDS '*.hex']));
end

% Select file name
if isempty(sFileCDS)
    error('no CDS file ''%s'' found', sCDS)
elseif length(sFileCDS) > 1
    warning('more than one CDS file ''%s'' found:', sCDS)
    for k = 1:length(sFileCDS)
        disp(sFileCDS(k).name);
    end
    disp('Use last one');
    sFileCDS = sFileCDS(end).name;
else
    sFileCDS = sFileCDS.name;
end