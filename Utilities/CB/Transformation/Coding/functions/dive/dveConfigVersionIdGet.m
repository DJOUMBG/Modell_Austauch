function xSetup = dveConfigVersionIdGet(xSetup,sPathContent,bIdQuery)
% DVECONFIGVERSIONIDGET patch a DIVe Configuration ModuleSetup structure in
% empty version ID with the respective element XML path, so the version ID
% in Helix can be queried from the server with dcsFcnStructVersionId.
%
% Syntax:
%   xSetup = dveConfigVersionIdGet(xSetup,sPathContent)
%
% Inputs:
%         xSetup - structure with fields of ModuleSetup in Configurations
%   sPathContent - string with path of DIVe Content used
%       bIdQuery - boolean if version IDs should be completely retrieved
%                  from Perforce Helix  
%
% Outputs:
%   xSetup - structure with fields of ModuleSetup in Configurations
%
% Example: 
%   xSetup = dveConfigVersionIdGet(xSetup,sPathContent)
%
% See also: dcsFcnStructVersionId
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2020-03-18

% loop over setups
for nIdxSetup = 1:numel(xSetup)
    % determine Module Path
    xModule = xSetup(nIdxSetup).Module;
    cModulePath = {xModule.context,xModule.species,xModule.family,...
                   xModule.type,'Module',xModule.variant};
    sPathXml = fullfile(sPathContent,cModulePath{:});
    
    % check Module version ID
    if isempty(xModule.versionId) || bIdQuery
       xSetup(nIdxSetup).Module.versionId = sPathXml;
    end
    
    % check DataSet variant version IDs
    for nIdxData = 1:numel(xSetup(nIdxSetup).DataSet)
        if isempty(xSetup(nIdxSetup).DataSet(nIdxData).versionId) || bIdQuery
            xSetup(nIdxSetup).DataSet(nIdxData).versionId = fullfile(...
                dpsPathLevel(fileparts(sPathXml),xSetup(nIdxSetup).DataSet(nIdxData).level),...
                'Data',xSetup(nIdxSetup).DataSet(nIdxData).classType,...
                xSetup(nIdxSetup).DataSet(nIdxData).variant);
        end
    end
    
    % check SupportSet version IDs
    if isfield(xSetup(nIdxSetup),'SupportSet')
        for nIdxSupport = 1:numel(xSetup(nIdxSetup).SupportSet)
            if isempty(xSetup(nIdxSetup).SupportSet(nIdxSupport).versionId) || bIdQuery
                xSetup(nIdxSetup).SupportSet(nIdxSupport).versionId = fullfile(...
                    dpsPathLevel(fileparts(sPathXml),xSetup(nIdxSetup).SupportSet(nIdxSupport).level),...
                    'Support',xSetup(nIdxSetup).SupportSet(nIdxSupport).name);
            end
        end
    end
    
end % for ModuleSetups

return
