function xClient = dpsCosimClientAutoAssign(xConfiguration,xModule,nMode)
% DPSCOSIMCLIENTAUTOASSIGN derives a co-simulation setup from the module
% executionTool and solver requirements within the specified configuration.
%
% Syntax:
%   xClient = dpsCosimClientAutoAssign(xConfiguration,xModule,nMode)
%
% Inputs:
%   xConfiguration - structure with fields of DIVe Configuration
%          xModule - structure vector with fields of DIVe Module XML
%            nMode - integer (1x1) with mode
%                       0: split all modules in own instances
%                       1: group all Matlab/Simulink modules according
%                          version
%                       2: group only open Simulink models 
%
% Outputs:
%   xClient - structure with fields: 
%
% Example: 
%   xClient = dpsCosimClientAutoAssign(xConfiguration,xModule,nMode)
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2017-08-22

% gather information of all modules
cModuleSpecies = {xModule.species};
cModule = cell(numel(xConfiguration.ModuleSetup),6);
for nIdxSetup = 1:numel(xConfiguration.ModuleSetup)
    % determine position in Module XML content structure
    bModule = strcmp(xConfiguration.ModuleSetup(nIdxSetup).species,cModuleSpecies);
    if sum(bModule) ~= 1
        error('dpsCosimClientAutoAssign:inputInconsistency',...
            'ModuleSetup species of configuration not or multiple times found in Module XMLs: %s',...
            xConfiguration.ModuleSetup(nIdxSetup).species);
    end
    
    % determine ModelSet in Module XML
    bModelSet = strcmp(xConfiguration.ModuleSetup(nIdxSetup).Module.ModelSet,...
        {xModule(bModule).Implementation.ModelSet.type});
    
    % combine module information into cell array
    cModule(nIdxSetup,:) = {xConfiguration.ModuleSetup(nIdxSetup).name,...
        xConfiguration.ModuleSetup(nIdxSetup).Module.ModelSet,...
        xModule(bModule).Implementation.ModelSet(bModelSet).executionTool,...
        xModule(bModule).Implementation.ModelSet(bModelSet).executionToolUpwardCompatible,...
        xConfiguration.ModuleSetup(nIdxSetup).Module.maxCosimStepsize,...
        xConfiguration.ModuleSetup(nIdxSetup).Module.solverTypes};
    % cModule: 1: SetupName, 2: ModelSet, 3: executionTool, 4: upwardComp,
    % 5: stepsize, 6: solverType
end

% determine groups
switch nMode 
    case 0
        
    case 1
        
    case 2
         
    otherwise
        
end


% check
return
