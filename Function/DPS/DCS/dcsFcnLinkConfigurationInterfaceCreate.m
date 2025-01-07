function xInterface = dcsFcnLinkConfigurationInterfaceCreate(xLink)
% DCSFCNLINKCONFIGURATIONINTERFACECREATE create the interface substructure
% of a configuration from the GUI data.cfg.link structure.
% Part of DIVe Configuration Standard for reuse in platform/configurator.
%
% Syntax:
%   xInterface = dcsFcnLinkConfigurationInterfaceCreate(xLink)
%
% Inputs:
%   xLink - structure with fields: 
%     .port  - structure vector with fields:
%       .name  - string with name of port
%       .unit  - string with unit of port
%       .moduleSetup - string with ModuleSetup name of port
%       .state - string with port state information
%       .log   - boolean for 0: none , 1: port logging
%          ... and others
%     .functionalChain - structure vector with fields
%     .signal  - structure vector with fields
%
% Outputs:
%   xInterface - structure according DIVe Configuraiton with fields: 
%     .Signal   - structure according DIVe Configuration with fields
%     .Constant - structure according DIVe Configuration with fields
%     .OpenPort - structure according DIVe Configuration with fields
%     .FunctionalChain - structure according DIVe Configuration with fields
%     .Logging   - structure according DIVe Configuration with fields
%
% Example: 
%   xInterface = dcsFcnLinkConfigurationInterfaceCreate(xLink)
%
% See also: structConcat, structInit
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2016-06-29

% prepare sort vectors
nConstant = strcmp('const',{xLink.port.state});
nOpen = strcmp('open',{xLink.port.state});
bLog = [xLink.port.log];

% prepare functional chain
xChain = structInit({'name','Connector'});
for nIdxChain = 1:numel(xLink.functionalChain)
    xChainAdd = struct('name',{xLink.functionalChain(nIdxChain).name},...
                       'Connector',{struct('name',{xLink.functionalChain(nIdxChain).Connector.name},...
                                           'moduleSetup',{xLink.functionalChain(nIdxChain).Connector.moduleSetup},...
                                           'chainPosition',{xLink.functionalChain(nIdxChain).Connector.chainPosition})});
    xChain = structConcat(xChain,xChainAdd);
end

% create structure entries
if isempty(xLink.signal)
    xInterface.Signal = structInit({'name','source','destination'});
else
    xInterface.Signal = rmfield(xLink.signal,{'type','unit'});
end
if isempty(nConstant)
    xInterface.Constant = structInit({'name','modelRef'});
else
    xInterface.Constant = struct('name',{xLink.port(nConstant).name},...
                                 'modelRef',{xLink.port(nConstant).moduleSetup});
end
if isempty(nOpen)
    xInterface.OpenPort = structInit({'name','modelRef'});
else
    xInterface.OpenPort = struct('name',{xLink.port(nOpen).name},...
                                 'modelRef',{xLink.port(nOpen).moduleSetup});
end
xInterface.FunctionalChain = xChain;
if any(bLog)
    xInterface.Logging = struct('name',{xLink.port(bLog).name},...
                                'unit',{xLink.port(bLog).unit},...
                                'modelRef',{xLink.port(bLog).moduleSetup});
else
    xInterface.Logging = structInit({'name','unit','modelRef'});
end
return