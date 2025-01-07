function sMP = dpsInitIOLoad(sMP,xModuleSetup,sPathContent)
% DPSINITIOLOAD loads the the initIO datasets of all modules specified in
% the configuration.
% Part of the DIVe platform standard package (dps).
%
% Syntax:
%   dpsInitIOLoad(xConfiguration,sPathContent)
%
% Inputs:
%              sMP - structure with DIVe standard model parameters e.g.
%               .bdry.env - structure with all boundary/env parameters
%                         ...
%     xModuleSetup - structure (1xn) with fields according DIVe 
%                    configuration XML: 
%       .Module    - structure with module information and fields:
%         .context - string with module context
%         .species - string with module species
%         .family  - string with module family
%         .type    - string with module type
%         ...
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
%              sMP - structure with DIVe standard model parameters e.g.
%               .bdry.env - structure with all boundary/env parameters
%                       .in  - structure with all inport init values
%                       .out - structure with all outport init values
%                         .env_Temperature - init value of module (exemplary) 
%                         ...
%
% Example: 
%  a = dpsInitIOLoad(struct(),sMP.cfg.Configuration.ModuleSetup,fullfile(sMP.platform.path,'Content'))
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2016-06-22

% loop over all modules
for nIdxModule = 1:numel(xModuleSetup)
    % determine initIO dataset entries within module init
    bClass = strcmp('initIO',{xModuleSetup(nIdxModule).DataSet.classType});
    
    % code shortcuts
    xModule = xModuleSetup(nIdxModule).Module;
    xInit = xModuleSetup(nIdxModule).DataSet(bClass);
    
    % generate path to dataset variant XML
    sInfo = dpsModuleSetupInfoGlue(xModuleSetup(nIdxModule),filesep);
    sPathLevel = dpsPathLevel(fullfile(sPathContent,fileparts(sInfo)),xInit.level);
    sFileXml = fullfile(sPathLevel,'Data',xInit.classType,xInit.variant,...
        [xInit.variant '.xml']);
    
    % load dataset variant
    xData = dpsLoadStandard(sFileXml);
    sMP.(xModule.context).(xModule.species).in  = xData.in;
    sMP.(xModule.context).(xModule.species).out = xData.out;
end % for all ModuleSetups
return
