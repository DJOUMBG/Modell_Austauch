function [sConfigName,sDepotFilepath,nChangeNum] = dveGetPerforceInfoData(sConfigXmlFilepath)
% DVEGETPERFORCEINFODATA returns the config name, the full depot path and
% the latest changelist number of given config xml file.
% In any case of errors this function returns the given filepath and name
% and the changelist ID is NaN.
%
% Syntax:
%   [sConfigName,sDepotFilepath,nChangeNum] = dveGetPerforceInfoData(sConfigXmlFilepath)
%   [sConfigName,sDepotFilepath] = dveGetPerforceInfoData(__)
%   sConfigName = dveGetPerforceInfoData(__)
%
% Inputs:
%   sConfigXmlFilepath - string:
%       full filepath of config xml file
%
% Outputs:
%	sConfigName - string:
%       file name of configuration without extension
%   sDepotFilepath - string:
%       filepath of config xml file in DIVe depot (depot path)
%	nChangeNum - integer (1x1):
%       Perforce changelist number of file in clients workspace
%
% Example: 
%   [sConfigName,sDepotFilepath,nChangeNum] = dveGetPerforceInfoData(sConfigXmlFilepath)
%
%
% See also: chkFileExists, dveGetPerforceInfoData, fleIsAbsPath, p4, p4switch
%
% Author: Elias Rohrer, TE/PTC-H, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2024-08-12


% init output
[~,sConfigName] = fileparts(sConfigXmlFilepath);
sDepotFilepath = sConfigXmlFilepath;
nChangeNum = NaN;

% check file exists
if not(chkFileExists(sConfigXmlFilepath))
    return
end

% check full path
if not(fleIsAbsPath(sConfigXmlFilepath))
    return
end

% switch to perforce workspace
[~,nStatus] = evalc(sprintf('p4switch(%s%s%s,0);',...
    '''',sConfigXmlFilepath,''''));
if nStatus ~= 1
    return
end

% get p4 output with depot path of file
cOut = hlxOutParse(p4('have %s',sConfigXmlFilepath),' ',1,true);
cSplit = strsplit(cOut{1},'#');
sDepotFilepath = strtrim(cSplit{1});

% split up depot path and file name
[~,sConfigName] = fileparts(sDepotFilepath);

% check for empty filepath
if isempty(sDepotFilepath)
    return
end

% get changelist number of file
cOut = hlxOutParse(p4('changes -m 1 %s#have',sDepotFilepath),' ',2,true);
if numel(cOut) < 2
    return
end
sChangeListNum = strtrim(cOut{2});

% convert changelist number to double
if not(isempty(sChangeListNum))
    nChangeNum = str2double(sChangeListNum);
end

return % dveGetPerforceInfoData
