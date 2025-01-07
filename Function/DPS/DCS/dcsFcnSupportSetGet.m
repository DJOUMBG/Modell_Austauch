function xSupportSet = dcsFcnSupportSetGet(sPathContent,xModule,bVersionReq,bPathP4)
% DCSFCNSUPPORTSETGET return a SupportSet structure for a DIVe Configuration.
%
% Syntax:
%   xSupportSet = dcsFcnSupportSetGet(sPathContent,xModule)
%   xSupportSet = dcsFcnSupportSetGet(sPathContent,xModule,bVersionReq)
%   xSupportSet = dcsFcnSupportSetGet(sPathContent,xModule,bVersionReq,bPathP4)
%
% Inputs:
%   sPathContent - string base path of DIVe Contetn
%        xModule - structure with fields: 
%         .context - string with DIVe context (logical hierarchy)
%         .species - string with DIVe species (logical hierarchy)
%         .family  - string with DIVe family (logical hierarchy)
%         .type    - string with DIVe type (logical hierarchy)
%         .Implementation.SupportSet - structure (1xn) with fields:
%            .name  - string with name of SupportSet
%            .level - string with level of SupportSet species|family|type
%   bVersionReq - boolean (1x1) if version shall be requested 
%       bPathP4 - boolean if basepath is Helix workspace
%
% Outputs:
%   xSupportSet - structure (1xn) with fields: 
%     .name - string with support set name
%     .level - string with level in logical hierarchy
%     .versionId - string with versionId (or path of folder for which the 
%                  version ID needs to be determined in case of 
%                  bVersionReq = 0)
%
% Example: 
%   xSupportSet = dcsFcnSupportSetGet(sPathContent,xModule)
%   xSupportSet = dcsFcnSupportSetGet(sPathContent,xModule,1,1)
%
% See also: p4changeFolderHave, strGlue, structInit
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2017-10-17

% check input
if nargin < 3
    bVersionReq = 1;
end
if nargin < 4
    bPathP4 = 1;
end
if strcmp(sPathContent(1:8),'//DIVe/d')
    sCon = 'p4'; % info via Perforce HelixCore
    sSep = '/';
elseif sum(sPathContent == '\') > sum(sPathContent == '/')
    sCon = 'win'; % info via file in Windows file system
    sSep = '\';
else
    sCon = 'lnx'; % info via file in Linux file system (or UNC?)
    sSep = '/';
end

% init output
xSupportSet = structInit({'name','level','versionId'});

% get support sets
if isfield(xModule.Implementation,'SupportSet')
    for nIdxSet = 1:numel(xModule.Implementation.SupportSet)
        % get basic info
        xSupportSet(nIdxSet).name = xModule.Implementation.SupportSet(nIdxSet).name;
        xSupportSet(nIdxSet).level = xModule.Implementation.SupportSet(nIdxSet).level;
        
        % define logical hierchy of support set
        cLogHier = {xModule.context,xModule.species,xModule.family,xModule.type};
        cLevelMatch = {'species','family','type'};
        nMatch = find(strcmp(xModule.Implementation.SupportSet(nIdxSet).level,cLevelMatch));
        sPathSet = strGlue({sPathContent,cLogHier{1:1+nMatch},'Support',...
                                xModule.Implementation.SupportSet(nIdxSet).name},sSep);
                            
        % determine versionId
        if bPathP4
            if bVersionReq
                xSupportSet(nIdxSet).versionId = p4changeFolderHave(sPathSet);
            else
                % just specify path for version determination in larger P4 call
                xSupportSet(nIdxSet).versionId = sPathSet;
            end
        else % nothing needed - anyway no Perforce Workspace path
            xSupportSet(nIdxSet).versionId = '';
        end
    end
end
return