function sMP = dpsInitTransfer(sMP,xConfiguration)
% DPSINITTRANSFER transfer the initial values of a signal from the connected outport
% to all connected inports according the DIVe rules.
% Part of the DIVe platform standard package (dps).
%
% Syntax:
%   sMP = dpsInitTransfer(sMP,xConfiguration)
%
% Inputs:
%             sMP - structure with DIVe standard model parameters e.g.
%               .bdry.env - structure with all boundary/env parameters
%                       .in  - structure with all inport init values
%                       .out - structure with all outport init values
%                         .env_Temperature - init value of module (exemplary) 
%                         ...
%   xConfiguration - structure with fields according DIVe configuration XML:  
%     .ModuleSetup - structure (1xn) with fields according DIVe 
%                    configuration XML: 
%       .Module    - structure with module information and fields:
%         .context - string with module context
%         .species - string with module species
%         .family  - string with module family
%         .type    - string with module type
%        ...
%       .Interface - structure with signal information
%         .Signal  - structure (1xm) with fields:
%           .name  - string with signal name
%           .modelRefSource - string with source ModuleSetup name
%           .source - structure (1x1) with fields:
%             .name - string with outport name at source module
%             .modelRef - string with source ModuleSetup name
%           .destination - structure (1xo) with fields:
%             .name - string with inport name at destination module
%             .modelRef - string with destination ModuleSetup name
%         ...
%
% Outputs:
%             sMP - structure with DIVe standard model parameters e.g.
%               .bdry.env - structure with all boundary/env parameters
%                       .in  - structure with all inport init values
%                       .out - structure with all outport init values
%                         .env_Temperature - init value of module (exemplary) 
%                         ...
%
% Example: 
%   sMP = dpsInitTransfer(sMP,xConfiguration)
%
% See also: dpsModuleInit, dpsLoadStandard, dbc 
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2016-01-19

% create index vector for module setup name info within parameter structure
for nIdxModule = 1:numel(xConfiguration.ModuleSetup)
    xSetup.(xConfiguration.ModuleSetup(nIdxModule).name).index = nIdxModule;
    xSetup.(xConfiguration.ModuleSetup(nIdxModule).name).context = ...
        xConfiguration.ModuleSetup(nIdxModule).Module.context;
    xSetup.(xConfiguration.ModuleSetup(nIdxModule).name).species = ...
        xConfiguration.ModuleSetup(nIdxModule).Module.species;
end

% transfer outport initial values to inport initial values
if isfield(xConfiguration.Interface,'Signal');
    xSignal = xConfiguration.Interface.Signal;
    for nIdxSignal = 1:numel(xSignal)
        % get outport value reference
        sNameOut = xSignal(nIdxSignal).source.name;
        sRefOut = xSignal(nIdxSignal).source.modelRef;
        
        % for all signal destinations
        for nIdxDest = 1:numel(xConfiguration.Interface.Signal(nIdxSignal).destination)
            % get inport value reference
            sNameIn = xSignal(nIdxSignal).destination(nIdxDest).name;
            sRefIn = xSignal(nIdxSignal).destination(nIdxDest).modelRef;
            
            % assign value
            sMP.(xSetup.(sRefIn).context).(xSetup.(sRefIn).species).in.(sNameIn) = ...
                sMP.(xSetup.(sRefOut).context).(xSetup.(sRefOut).species).out.(sNameOut);
        end
    end
end
return
