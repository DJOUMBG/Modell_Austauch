function xModule = dpsXmlModuleLoad(xConfiguration,sPathContent)
% DPSXMLMODULELOAD read the XML of all modules specified in a configuration
% into one structure.
%
% Syntax:
%   xModule = dpsXmlModuleLoad(xConfiguration,sPathContent)
%
% Inputs:
%   xConfiguration - structure with fields according DIVe configuration XML
%                    (only ModuleSetup section needed):
%     .ModuleSetup - structure (1xn) with fields according DIVe 
%                    configuration XML: 
%       .Module    - structure with module information and fields:
%         .context - string with module context
%         .species - string with module species
%         .family  - string with module family
%         .type    - string with module type
%        ...
%       .DataSet   - structure with module's dataset information and fields:
%         .level   - string with sharing level of dataset
%         .classType - string with dataset classType 
%         .className - string with dataset className
%         .variant   - string with dataset variant selection
%         ...
% 
%     sPathContent - string with path of DIVe Content (contains context 
%                    level folder trees (e.g. phys) with modules and
%                    datasets) 
%
% Outputs:
%   xModule - structure (1xn) with fields of DIVe module XML
%
% Example: 
%   xModule = dpsXmlModuleLoad(xConfiguration,sPathContent)
%
% See also: dsxRead, structConcat
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2016-06-22

% initialize structure
xXml.Module = struct('xmlns',{},'name',{},'type',{},'family',{},...
    'species',{},'context',{},'specificationVersion',{},'moduleVersion',{},...
    'maxCosimStepsize',{},'solverType',{},'description',{},...
    'Implementation',{},'Interface',{});

% get module XMLs
for nIdxModule = 1:numel(xConfiguration.ModuleSetup)
    % code shortcuts
    xModule = xConfiguration.ModuleSetup(nIdxModule).Module;
    
    % read xml
    sPathXml = fullfile(sPathContent,xModule.context,...
                        xModule.species,xModule.family,xModule.type,'Module',...
                        xModule.variant,[xModule.variant '.xml']);
    xXmlModule = dsxRead(sPathXml);
            
    % add Module xml to structure
    xXml.Module = structConcat(xXml.Module,xXmlModule.Module);
end
xModule = xXml.Module;
return