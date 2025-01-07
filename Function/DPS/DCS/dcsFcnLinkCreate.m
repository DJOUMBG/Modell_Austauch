function [xConfiguration,xLink] = dcsFcnLinkCreate(xConfiguration,xModule,xLink,bChainReset)
% DCSFCNLINKCREATE creates the Interface part of a DIVe Configuration and
% an xLink structure based on the ModuleSetup part of a DIVe configuration.
% Part of DIVe Configuration Standard for reuse in platform/configurator.
%
% Syntax:
%   [xConfiguration,xLink] = dcsFcnLinkCreate(xConfiguration,xModule)
%   [xConfiguration,xLink] = dcsFcnLinkCreate(xConfiguration,xModule,xLink)
%   [xConfiguration,xLink] = dcsFcnLinkCreate(xConfiguration,xModule,xLink,bChainReset)
%
% Inputs:
%   xConfiguration - structure with fields:
%     .ModuleSetup - structure vector of configured modules with fields:
%          xModule - structure vector of DIVe Module XML content with fields: 
%            xLink - [optional] structure with fields:
%              .port - structure with port properties, which shall be
%                      preserved (e.g. from old confgiguration state)
%               .name  - string with port name
%               .type  - string with port type (physics,control,sensor,actuator,boundary,hmi,info)
%               .connectorName        - string with connector name
%               .connectorType        - string connector type (DIVe predefied type)
%               .connectorOrientation - string connector orientation (positive/ 
%                             negative)
%               .quantity             - string with quantity of port value
%               .functionalChain      - string name of functional chain
%               .chainPosition        - string with integer of connector default
%                             position
%               .moduleSpecies  - string with name module species
%               .moduleSetup    - string of containing module in setup
%               .ioType         - string with port I/O type (inport,outport)
%               .state          - string with (open, const, signal, openOut?)
%               .log            - boolean, if port should be logged
%               .select         - boolean, if port is currently selected
%                ... (further unused)
%     bChainReset - [optional] boolean (1x1) to exempt functionalChain
%                    attributes from transfer to link structure
%
% Outputs:
%   xConfiguration - structure with fields:
%     .ModuleSetup - structure vector of configured modules with fields:
%     .Interface   - structure of configuration interface with fields:
%       .Signal    - structure vector of configuration signals with fields:
%       .Constant  - structure vector of configuration constants with fields:
%       .OpenPort  - structure vector of configuration open ports with fields:
%       .Logging   - structure vector of configuration open ports with fields:
%   xLink   - structure with fields: 
%     .port - structure with fields: 
%       .name            - string with port name
%       .connectorName   - string with connector name
%       .connectorType   - string with connector type (DIVe predefied type)
%       .connectorOrientation - string with connector orientation  
%                          (positive/negative)
%       .quantity        - string with unique port name
%       .functionalChain - string name of functional chain
%       .chainPosition   - string with integer of connector default
%                          position
%       .moduleSetup     - string with moduleSetup of port
%       .nameUnique      - string with unique port name
%       .ioType          - string with port I/O type (inport,outport)
%       .state           - string with (open, const, signal)
%         ... and others
%     .subPort           - structure with fields: 
%       .physics         - boolean (1xn) with port type 
%                          0: non-physics, 1:physics
%       .inport          - boolean (1xn) with port I/O type 
%                          0: outport, 1:inport
%       .nSignal         - integer (1xn) (length matching the .port struct)
%                          structure with index of signal, were port is
%                          used
%     .signal   - structure with fields: 
%       .name   - string with name of signal (equals outport name)
%       .type   - string with type of signal (equals outport type)
%       .unit   - string with unit of signal (equals outport unit)
%       .modelRefSource - string with model reference of source port
%          .source      - structure with fields:
%            .name      - string with outport name
%            .modelRef  - string with moduleSetup name of the outport
%          .destination - structure vector with fields:
%            .name      - string with inport name
%            .modelRef  - string with moduleSetup name of the inport
%    .connector - structure with fields: 
%      .name            - string with name of connector
%      .type            - string with connector type (DIVe predefied type)
%      .orientation     - string with connector orientation  
%      .moduleSetup     - string with moduleSetup of connector
%      .nameUnique      - string with unique connector name
%      .functionalChain - string name of functional chain
%      .chainPosition   - string with integer of connector default position
%      .nPort           - integer vector with port indices of all ports in 
%                         the connector
%    .functionalChain - structure with fields: 
%      .name            - string with name of functionalChain
%      .type            - string with connector type (DIVe predefied type)
%      .Connector       - structure with fields:
%        .name          - string with connector name 
%        .moduleSetup   - string with moduleSetup of connector
%        .chainPosition - string with integer of connector default position
%        .nConnector    - integer with connector index in connector struct
%      ... and more.
%
% Example: 
%   [xConfiguration,xLink] = dcsFcnLinkCreate(xConfiguration,xModule) % example for newLdyn 
%   [data.cfg.Configuration,data.cfg.link] = dcsFcnLinkCreate(data.cfg.Configuration,data.cfg.xml.Module,data.cfg.link)
%
%
% Subfunctions: dcsFcnConnectorPortCheck, dcsFcnConnectorQuantityCheck, ,
% dcsFcnLinkFuncChainCreate, dcsFcnLinkNonPhysicsState,
% dcsFcnLinkPhysicsState, dcsFcnLinkPortAttributeUpdate
%
% See also: dcsFcnLinkPortAllGet, structConcat, structInit, dcsFcnLinkConfigurationInterfaceCreate 
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2016-06-29

% empty configuration
if isempty(xConfiguration.ModuleSetup)
    % reset link structure in base structure and configuration
    xLink = structInit({'port','signal','connector','functionalChain',...
                            'subPort','subSignal'});
    xConfiguration.Interface.Signal = struct('name',{},'modelRefSource',{},'source',{},'destination',{});
    xConfiguration.Interface.Constant = struct('name',{},'modelRef',{});
    xConfiguration.Interface.OpenPort = struct('name',{},'modelRef',{});
    xConfiguration.Interface.FunctionalChain = struct('name',{},'Connector',{});
    
   return
end

% check input
if nargin < 3
    xLink = struct('port',{}); % triggers recreation of link structure
end
if nargin < 4
    bChainReset = false; 
end

% detect GUI states
hDbc = findobj('Tag','DIVeBasicConfigurator');
hCfgAdapt = findobj('Tag','DIVeCfgAdaption');

% get central list of all ports from Module XMLs (main source Module XML
% with ModuleSetup of Configuration structure)
xPort = dcsFcnLinkPortAllGet(xConfiguration,xModule);

if isempty(xLink)
    % initialize xLink.port according Module XMLs
    xLink = struct('port',{xPort});
    bUpdate = false;
else
    % update the flexible attributes according old port settings
    xLinkOld = xLink;
    bUpdate = true;
    % build xLink.port from xPort(from Module XML) + udpates by xLink argument 
    xLink.port = dcsFcnLinkPortAttributeUpdate(xLinkOld.port,xPort,bChainReset,hDbc,hCfgAdapt);
end

% define CAN prefixes
xLink.subPort.cPrefix = {'as','cc','ch','chrg','dg','ed','ev','ex','hy','iso11992','nrg','pt','pti','pump'};

% update subset index vectors part 1
xLink.subPort.physics = strcmp('physics',{xLink.port.type});
xLink.subPort.inport = strcmp('inport',{xLink.port.ioType});
xLink.subPort.control = strcmp('control',{xLink.port.type});
xLink.subPort.nSignal = zeros(1,numel(xLink.port));

% reset signal structure (due to new function based signal generation)
xLink.signal = struct('name',{},'modelRefSource',{},'source',{},'destination',{});

% update information on non-physics link states
xLink = dcsFcnLinkNonPhysicsState(xLink);

% update information on control link states (includes prefix flexibility)
xLink = dcsFcnLinkControlState(xLink);

% update functional chain & connectors
xLink = dcsFcnLinkFuncChainCreate(xLink,hDbc,hCfgAdapt);

% update & merge physical signal states
xLink = dcsFcnLinkPhysicsState(xLink,hDbc,hCfgAdapt);

% update subset index vectors part 2
if isempty(xLink.signal)
    xLink.subSignal.physics = [];
else
    xLink.subSignal.physics = strcmp('physics',{xLink.signal.type});
end

% set all open inports to constant
bOpen = strcmp('open',{xLink.port.state});
[xLink.port(bOpen&xLink.subPort.inport).state] = deal('const');

% check integrity of functionalChains after update
% e.g. connector removal from chain due to name change of ports
if bUpdate
    dcsFcnLinkFunctionChainConservationCheck(xLink,xLinkOld,hDbc,hCfgAdapt);
end

% recreate configuration interface from link structure (except logsetup)
xConfiguration.Interface = structUnify(xConfiguration.Interface,...
                                        dcsFcnLinkConfigurationInterfaceCreate(xLink));
% resort fields
cInterface = {'Signal','Constant','OpenPort','FunctionalChain','LogSetup','Logging'};
bKeep = ismember(cInterface,fieldnames(xConfiguration.Interface));
xConfiguration.Interface = orderfields(xConfiguration.Interface,cInterface(bKeep));
return

% =========================================================================

function xPort = dcsFcnLinkPortAttributeUpdate(xPortOld,xPort,bChainReset,hDbc,hCfgAdapt)
% DCSFCNLINKPORTATTRIBUTEUPDATE updates the configurable port attributes of
% a new port structure with the ones of an old port structure if portname
% and moduleSetup name matches.
%
% Syntax:
%   xPort = dcsFcnLinkPortAttributeUpdate(xPortOld,xPort,bChainReset,hDbc,hCfgAdapt)
%
% Inputs:
%   xPortOld - structure with fields: 
%     .name  - string with port name
%     .type  - string with port type (physics,control,sensor,actuator,boundary,hmi,info)
%     .unit  - string with port unit
%     .manualDescription    - string with manual port description
%     .autoDescription      - string with automatic port description
%     .connectorName        - string with connector name
%     .connectorType        - string connector type (DIVe predefied type)
%     .connectorOrientation - string connector orientation (positive/ 
%                             negative)
%     .quantity             - string with quantity of port value
%     .functionalChain      - string name of functional chain
%     .chainPosition        - string with integer of connector default
%                             position
%     .moduleSpecies  - string with name module species
%     .moduleSetup    - string of containing module in setup
%     .ioType         - string with port I/O type (inport,outport)
%     .nameUnique     - string with configuration-wide unique port name by
%                       combination of ModuleSetup name and port name
%     .state          - string with (open, const, signal, openOut?)
%     .log            - boolean, if port should be logged
%     .select         - boolean, if port is currently selected
%     .minPhysicalRange - scalar with minimal physical value range
%     .maxPhysicalRange - scalar with maximal physical value range
%   xPort - structure with fields: see xPortOld
%   bChainReset - [optional] boolean (1x1) to exempt functionalChain
%                 attributes from transfer to link structure
%   hDbc - handle of DIVe Basic Configurator GUI
%   hCfgAdapt - handle of Adapt Configurations GUI
%
% Outputs:
%   xPort - structure with fields:  see xPortOld
%
% Example: 
%   xPort = dcsFcnLinkPortAttributeUpdate(xPortOld,xPort)

% check input
if nargin < 3
    bChainReset = false; 
end

% match ports
[bPort,nPort] = ismember({xPort.nameUnique},{xPortOld.nameUnique});

% transfer attributes
for nIdxPort = 1:numel(nPort)
    if bPort(nIdxPort) % if this port is matched -> name and moduleSetup are identical
        % check equality of fix port attributes
        if ~strcmp(xPort(nIdxPort).type,xPortOld(nPort(nIdxPort)).type) ||...
                ~strcmp(xPort(nIdxPort).ioType,xPortOld(nPort(nIdxPort)).ioType)
            % ~strcmp(xPort(nIdxPort).unit,xPortOld(nPort(nIdxPort)).unit) ||...
            
            sMsg = sprintf(['The port "%s" of module %s.%s (%s) does not ' ...
                'match the previous basic attributes of the port '...
                'with same name. Previous settings are omitted.\n'],...
                xPort(nIdxPort).name,xPort(nIdxPort).moduleContext,...
                xPort(nIdxPort).moduleSpecies,xPort(nIdxPort).moduleSetup);
            if isempty(hCfgAdapt) && ~isempty(hDbc)
                umsMsg('Configurator',4,sMsg);
            else
                fprintf(1,sMsg);
            end
            continue % proceed with next port, this one does not match
        else % basic port attributes match
            % check equality of fix physics signal attributes
            if strcmp(xPort(nIdxPort).type,'physics')&&...
                    (~strcmp(xPort(nIdxPort).connectorType,xPortOld(nPort(nIdxPort)).connectorType) ||...
                    ~strcmp(xPort(nIdxPort).connectorOrientation(1:7),xPortOld(nPort(nIdxPort)).connectorOrientation(1:7))||...
                    ~strcmp(xPort(nIdxPort).quantity,xPortOld(nPort(nIdxPort)).quantity))
                sMsg = sprintf(['The port "%s" of module %s.%s (%s) does not ' ...
                    'match the previous physics attributes of the port '...
                    'with same name. Previous settings are omitted.\n'],...
                    xPort(nIdxPort).name,xPort(nIdxPort).moduleContext,...
                    xPort(nIdxPort).moduleSpecies,xPort(nIdxPort).moduleSetup);
                if isempty(hCfgAdapt) && ~isempty(hDbc)
                    umsMsg('Configurator',4,sMsg);
                else
                    fprintf(1,sMsg);
                end
                continue % proceed with next port, this one does not match
            end
        end
        
        % transfer flexible port attributes
        if ~bChainReset
            xPort(nIdxPort).functionalChain = xPortOld(nPort(nIdxPort)).functionalChain;
            xPort(nIdxPort).chainPosition = xPortOld(nPort(nIdxPort)).chainPosition;
        end
        if strcmp(xPortOld(nPort(nIdxPort)).state,'const')
            xPort(nIdxPort).state = xPortOld(nPort(nIdxPort)).state;
        end
        xPort(nIdxPort).log = xPortOld(nPort(nIdxPort)).log;
        xPort(nIdxPort).select = xPortOld(nPort(nIdxPort)).select;
    end
end
return

% =========================================================================

function dcsFcnLinkFunctionChainConservationCheck(xLink,xLinkOld,hDbc,hCfgAdapt)
% DCSFCNLINKFUNCTIONCHAINCONSERVATIONCHECK checks for lost connections of
% functionalChains during update of port properties (e.g. in case of
% double rename of ports and their functionalChains).
%
% Syntax:
%   dcsFcnLinkFunctionChainConservationCheck(xLink,xLinkOld,hDbc,hCfgAdapt)
%
% Inputs:
%      xLink - structure with fields: (minimum as xLinkOld)
%   xLinkOld - structure with fields: 
%    .functionalChain - structure with fields: 
%      .name            - string with name of functionalChain
%      .Connector       - string with connector type (DIVe predefied type)
%        .name          - string with connector type (DIVe predefied type)
%        .chainPosition - string with integer of connector default position
%      ... and more.
%   hDbc - handle of DIVe Basic Configurator GUI
%   hCfgAdapt - handle of Adapt Configurations GUI
%
% Outputs:
%
% Example: 
%   dcsFcnLinkFunctionChainConservationCheck(xLink,xLinkOld)

% check input
if ~isfield(xLink,'functionalChain') || ...
        ~isfield(xLinkOld,'functionalChain')
    % at least one functionalChain struct missing - no functionalChain
    % conservation check possible/necessary (most first creation of link
    % structure)
    return
end

% shortcut
cChain = {xLink.functionalChain.name};

for nIdxChain = 1:numel(xLinkOld.functionalChain)
    % shortcut
    xOld = xLinkOld.functionalChain(nIdxChain);
    
    % match this old chain in actual (new) chains
    bMatch = strcmp(xOld.name,cChain);
    if ~any(bMatch)
        % chain does not exist anymore
        % do nothing (assumption - one or more modules have been
        % removed/changed, no break up of chain)
        continue % stop check for this connector
    end
    
    % shortcut
    xNew = xLink.functionalChain(bMatch);
    
    if numel(xOld.Connector) <= numel(xNew.Connector)
        % the number of connectors in this chain has not changed or
        % even increased
        % -> works as in original setup or is extended
        continue % stop check for this connector
    end
    
    % check start and end of chain
    cPosOld = {xOld.Connector.chainPosition};
    cPosNew = {xNew.Connector.chainPosition};
    cMissing = setdiff(cPosOld,cPosNew);
    cStartEnd = {'1','100'};
    nMiss = find(ismember(cStartEnd,cMissing));
    if ~isempty(nMiss) % front or end position is broken
       for nIdxMiss = nMiss
            % determine connector in old chain
            bCon = strcmp(cStartEnd{nMiss},cPosOld);
            % only start or end of chain is missing
            sMsg = sprintf(['CAUTION: Broken functionalChain "%s" after link ' ...
                're-creation. Missing chainOrder "%s" was previously occupied ' ...
                'by connector "%s". To reset functionalChains use the ' ...
                '"Reset" button on FunctionalChain tab.\n'],...
                xOld.name,cStartEnd{nMiss},xOld.Connector(bCon).name);
            if isempty(hCfgAdapt) && ~isempty(hDbc)
                umsMsg('Configurator',3,sMsg);
            else
                fprintf(1,sMsg);
            end
        end
    end
end % for all functionalChains of old link structure
return

% =========================================================================

function xLink = dcsFcnLinkControlState(xLink)
% DCSFCNLINKCONTROLSTATE derive signals, open ports and constant inports
% from current control ports and attributes.
%
% Syntax:
%   xLink = dcsFcnLinkControlState(xLink)
%
% Inputs:
%          xLink - structure with fields: 
%          .port - structure with fields: 
%            .name        - string with port name
%            .moduleSetup - string with moduleSetup name
%            .ioType      - string with port type (inport/outport)
%            .nameUnique  - string with unique port name
%            ... and others
%          .subPort - structure with fields: 
%            .physics     - boolean (1xn) with port type 
%                           0: non-physics, 1:physics
%            .inport      - boolean (1xn) with port I/O type 
%                           0: outport, 1:inport
%
% Outputs:
%         xLink - structure with fields: 
%          .port - structure with fields: 
%            .name        - string with port name
%            .moduleSetup - string with moduleSetup name
%            .ioType      - string with port type (inport/outport)
%            .nameUnique  - string with unique port name
%            .state       - string with (open, const, signal)
%            ... and others
%          .subPort - structure with fields: 
%            .physics     - boolean (1xn) with port type 
%                           0: non-physics, 1:physics
%            .inport      - boolean (1xn) with port I/O type 
%                           0: outport, 1:inport
%            .control     - boolean (1xn) with port/signal type==control
%                           0: other, 1:control
%            .nSignal     - integer (1xn) with index of signal
%          .signal - structure with fields: 
%           .name   - string with name of signal (equals outport name)
%           .type   - string with type of signal (equals outport type)
%           .unit   - string with unit of signal (equals outport unit)
%           .modelRefSource   - string with model reference of source port
%           .source - structure with fields:
%              .name      - string with outport name
%              .modelRef  - string with moduleSetup name of the outport
%           .destination  - structure vector with fields:
%              .name      - string with inport name
%              .modelRef  - string with moduleSetup name of the inport
%
% Example: 
%   xLink = dcsFcnLinkControlState(xLink)

% stop linking when no control signals are available
if ~any(xLink.subPort.control)
    return
end

% get non-physics ports inport & outports
bInport = xLink.subPort.inport & xLink.subPort.control;
bOutport = ~xLink.subPort.inport & xLink.subPort.control;
nInport = find(bInport); % index of inports in xLink.port
nOutport = find(bOutport); % index of outports in xLink.port
cInport = {xLink.port(bInport).name};
cOutport = {xLink.port(bOutport).name};

% get port names without CAN prefix
cReplace = cellfun(@(x)['^' x '_'],xLink.subPort.cPrefix,'UniformOutput',false);
cInportNopref = regexprep(cInport,cReplace,'');
cOutportNopref = regexprep(cOutport,cReplace,'');
% ports, which are originally without prefix
nInportRedOrgNopref = find(strcmp(cInport,cInportNopref));
nOutportRedOrgNopref = find(strcmp(cOutport,cOutportNopref));
bInportRedOrgNopref = strcmp(cInport,cInportNopref);
bOutportRedOrgNopref = strcmp(cOutport,cOutportNopref);

% check for gateways (same signal at inport and outport), output based on
% xLink.port indices to be applied on nOutportSignal
[nGatewayAlias,nDisconnect] = dcsFcnLinkGatewayCheck(xLink,cInportNopref,cOutportNopref,nInport,nOutport);
% transform Alias from xLink.port index to nOutport index
[bGAinPort,nGatewayAliasRedInd] = ismember(nGatewayAlias(:,1),nOutport); %#ok<ASGLU>
[bGArefinPort,nGatewayAliasRedRef] = ismember(nGatewayAlias(:,2),nOutport); %#ok<ASGLU>
[bDisinPort,nDisconnectRed] = ismember(nDisconnect,nOutport); %#ok<ASGLU>
nGatewayAliasRed = [nGatewayAliasRedInd,nGatewayAliasRedRef];

% matching inports and outports directly (exact name)
[bSignal,nOutRed] = ismember(cInport,cOutport); % prefix -> prefix, blank -> blank
% remove blank->blank direct hits for alias curation
bRemoveMatch = bInportRedOrgNopref & bSignal;
[bSignal(bRemoveMatch)] = deal(false);
[nOutRed(bRemoveMatch)] = deal(0);

% matching inports and outports with optional prefix 
[bSignalInNoPref,nOutRedInNoPref] = ismember(cInportNopref,cOutport); % prefix -> blank
[bSignalOutNoPref,nOutRedOutNoPref] = ismember(cInport,cOutportNopref);  % blank -> prefix
[bSignalAllNoPref,nOutRedAllNoPref] = ismember(cInportNopref,cOutportNopref);  % blank -> blank

% clean direct matching from optional prefix matching
% direct matches need to be preserved from GatewayAlias and
% self-reference disconnection
bRemove = (bSignalInNoPref & bSignal) | (bSignalInNoPref & bSignal);
bSignalInNoPrefRem = bSignalInNoPref & ~bRemove;
bSignalOutNoPrefRem = bSignalOutNoPref & ~bRemove;
[nOutRedInNoPref(bRemove)] = deal(false);
[nOutRedOutNoPref(bRemove)] = deal(false);

% limit blank -> blank matches to inports unmatched in other runs
bUnmatched = ~bSignal & ~bSignalInNoPrefRem  & ~bSignalOutNoPrefRem;
bBlankMatch = bUnmatched & bSignalAllNoPref; % remaining blank matches for sofar unmatched
[nOutRedAllNoPref(~bBlankMatch)] = deal(0); % reset all entries except blank match

% merge results of optional prefix and blank matching
bSignalNoPref = bSignalInNoPrefRem | bSignalOutNoPrefRem | bBlankMatch;
nOutRedNoPref = max([nOutRedInNoPref;nOutRedOutNoPref;nOutRedAllNoPref]);

% apply Gateway alias from Gateway outport to direct source outport 
% (only ports matched through prefix flexibilisation)
[bAliasHit,nAliasHit] = ismember(nOutRedNoPref,nGatewayAliasRed(:,1));
[nOutRedNoPref(bAliasHit)] = deal(nGatewayAliasRed(nAliasHit(bAliasHit),2));
% [nOutRedNoPref(bAliasHit)] = deal(nGatewayAlias(nAliasHit(bAliasHit),2));

% disconnect ports, which find their own outport (may happen on gateways
% with partially remove prefixes through optional prefix matching, gateways
% with completely removed prefixes (not reasonable, but never underestimate
% Module devleopers))
bDisconnect = ismember(nOutRedNoPref,nDisconnectRed);
[nOutRedNoPref(bDisconnect)] = deal(0);
[bSignalNoPref(bDisconnect)] = deal(false);

% merge results
% bSignalMerge = bSignal | bSignalInNoPref | bSignalOutNoPref; % complete merge - obsolete 
% nOutRedMerge = max([nOutRed;nOutRedInNoPref;nOutRedOutNoPref]); % complete merge - obsolete 
bSignalMerge = bSignal | bSignalNoPref;
nOutRedMerge = max([nOutRed;nOutRedNoPref]);

% create indices on port structure
nInportSignal = nInport(bSignalMerge); % index (1xm) of inports in xLink.port with state "signal" 
nOutRedMerge = nOutRedMerge(bSignalMerge); % index (1xm) of reduced non-physics outport with state "signal"
nOutportSignal = nOutport(nOutRedMerge); % index (1xm) of outports in xLink.port with state "signal" 

% hard removal on self-references
bSelf = strcmp({xLink.port(nInportSignal).moduleSpecies},{xLink.port(nOutportSignal).moduleSpecies});
nInportSignal = nInportSignal(~bSelf);
nOutportSignal = nOutportSignal(~bSelf);

% create signal structure entries
xLink = dcsFcnLinkSignalCreate(xLink,nInportSignal,nOutportSignal);
return 

% =========================================================================

function [nGatewayAlias,nDisconnect] = dcsFcnLinkGatewayCheck(xLink,cInportNopref,cOutportNopref,nInport,nOutport)
% DCSFCNLINKGATEWAYCHECK generate an alias list for gateway outports
% (Modules that have the sime signal as inport and outport) with the
% original source outport and a disconnection list
%
% Syntax:
%   [nGatewayAlias,nDisconnect] = dcsFcnLinkGatewayCheck(xLink,cInportNopref,cOutportNopref,nOutport,nInport)
%
% Inputs:
%         xLink - structure with fields: 
%          .port - structure with fields: 
%            .name        - string with port name
%            .moduleSetup - string with moduleSetup name
%            .ioType      - string with port type (inport/outport)
%            .nameUnique  - string with unique port name
%            .state       - string with (open, const, signal)
%            ... and others
%    nInportSignal - integer (1xm) with index of inports in xLink.port with state "signal"
%   nOutportSignal - integer (1xm) with index of outports in xLink.port with state "signal" 
%         nOutport - integer (1x1) with index of inports in xLink.port (only outport & control)
%          nInport - integer (1x1) with index of outports in xLink.port (only (inport & control) 
%
% Outputs:
%   nGatewayAlias - integer (nx2) with outport indices
%                       (:,1) outport of a gateway
%                       (:,2) outport of matching signal source
%     nDisconnect - integer (1xm) with outport indices, which should not be
%                   connected as all outports and inports of this name
%                   belong only to gateways (prevent connection and loops
%                   of gateways) - no real signal source is available
%
% Example: 
%   [nGatewayAlias,nDisconnect] = dcsFcnLinkGatewayCheck(xLink,cInportNopref,cOutportNopref,nOutport,nInport)

% create species identifier cell for inports
cInportSpecies = {xLink.port(nInport).moduleSpecies};

% create reference alias for outports
% identifation of double name in outports - create alias list for true
% source ports -> apply already to existing coniguration with old notation?
[cTrash,nSource2Unique] = unique(cOutportNopref); %#ok<ASGLU>
nOutportDouble = setxor(nSource2Unique,(1:numel(cOutportNopref))); % identify double entries
nGatewayAlias = zeros(0,2);
nDisconnect = [];
if isempty(nOutportDouble) % stop alias list generation logic without prefix signals
    return
end
for nIdDouble = nOutportDouble'
    % get all occurences of outport name in control signals
    bSame = strcmp(cOutportNopref{nIdDouble},cOutportNopref); % bool on control outports
    nOutportSame = nOutport(bSame); % indices of xLink.port
    
    % loop over outports of same name (but different Module species)
    bGateway = false(size(nOutportSame));
    for nIdxSame = 1:numel(nOutportSame)
        % check for inports of same species and same name without prefix
        bInportSame = strcmp(xLink.port(nOutportSame(nIdxSame)).moduleSpecies,cInportSpecies) & ...
                  strcmp(cOutportNopref{nIdDouble},cInportNopref); % bool on control inports
        bGateway(nIdxSame) = any(bInportSame);
    end
    
    % determine default outport
    switch sum(~bGateway)
        case 1 % single outport (non-gateway) -> set as default source
            nGatewayAlias = [nGatewayAlias; ...
                nOutportSame(bGateway)' repmat(nOutportSame(~bGateway),sum(bGateway),1)]; %#ok<AGROW>
            
        case 0 % only gateways available -> disconnect all
            nDisconnect = [nDisconnect nOutportSame]; %#ok<AGROW>
            
        otherwise % multiple outport avialable
            if all(strcmp(xLink.port(nOutportSame(find(~bGateway,1))).moduleSpecies, ...
                          {xLink.port(nOutportSame(~bGateway)).moduleSpecies}))
                % all non-gateway outports of this name belong to the same Module species 
                % (= module is source of signal and routed signal to mulitple CANs)
                nNoGateway = find(~bGateway);
                
                nGatewayAlias = [nGatewayAlias; ...
                    nOutportSame(nNoGateway(2:end))' repmat(nOutportSame(nNoGateway(1)),sum(~bGateway)-1,1)]; %#ok<AGROW>
            else
                % error
                fprintf(2,['dcsFcnLinkCreate: Encountered multiple control ' ...
                    'outports of same name (except CAN prefix), which are not ' ...
                    'from a gateway (inport of same name exists on same species):\n']);
                for nIdPort = nOutportSame(~bGateway)
                    fprintf(2,'   %s - %s\n',xLink.port(nIdPort).moduleSpecies,xLink.port(nIdPort).name);
                end
            end
    end
end
return 

% =========================================================================

function xLink = dcsFcnLinkSignalCreate(xLink,nInportSignal,nOutportSignal)
% DCSFCNLINKSIGNALCREATE create entries to Signal structure in link and
% update port signal state including indexing in Signal structure.
%
% Syntax:
%   xLink = dcsFcnLinkSignalCreate(xLink,nInportSignal,nOutportSignal)
%
% Inputs:
%         xLink - structure with fields: 
%          .port - structure with fields: 
%            .name        - string with port name
%            .moduleSetup - string with moduleSetup name
%            .ioType      - string with port type (inport/outport)
%            .nameUnique  - string with unique port name
%            .state       - string with (open, const, signal)
%            ... and others
%          .subPort - structure with fields: 
%            .nSignal     - integer (1xn) with index of signal
%          .signal - structure with fields: 
%           .name   - string with name of signal (equals outport name)
%           .type   - string with type of signal (equals outport type)
%           .unit   - string with unit of signal (equals outport unit)
%           .modelRefSource   - string with model reference of source port
%           .source - structure with fields:
%              .name      - string with outport name
%              .modelRef  - string with moduleSetup name of the outport
%           .destination  - structure vector with fields:
%              .name      - string with inport name
%              .modelRef  - string with moduleSetup name of the inport
%    nInportSignal - integer (1xm) with index of inports in xLink.port with state "signal"
%   nOutportSignal - integer (1xm) with index of outports in xLink.port with state "signal" 
%
% Outputs:
%         xLink - structure with fields: 
%          .port - structure with fields: 
%            .name        - string with port name
%            .moduleSetup - string with moduleSetup name
%            .ioType      - string with port type (inport/outport)
%            .nameUnique  - string with unique port name
%            .state       - string with (open, const, signal)
%            ... and others
%          .subPort - structure with fields: 
%            .nSignal     - integer (1xn) with index of signal
%          .signal - structure with fields: 
%           .name   - string with name of signal (equals outport name)
%           .type   - string with type of signal (equals outport type)
%           .unit   - string with unit of signal (equals outport unit)
%           .modelRefSource   - string with model reference of source port
%           .source - structure with fields:
%              .name      - string with outport name
%              .modelRef  - string with moduleSetup name of the outport
%           .destination  - structure vector with fields:
%              .name      - string with inport name
%              .modelRef  - string with moduleSetup name of the inport
%
% Example: 
%   xLink = dcsFcnLinkSignalCreate(xLink,nInportSignal,nOutportSignal)

% initilize minimum output
if ~isfield(xLink,'signal')
    xLink.signal = struct('name',{},'modelRefSource',{},'source',{},'destination',{});
end

% stop signal creation if, there are no matches
if (isempty(nInportSignal) || isempty(nOutportSignal))
    return
end

% create signal information
xSignal = struct('name',{},'modelRefSource',{},'source',{},'destination',{});
nOutportSort = unique(nOutportSignal); % create unique vector of outport indices
cSignalSource = cell(1,numel(nOutportSort));
cSignalDestination = cell(1,numel(nOutportSort));
nSignalCell = 0;
for nIdxOutport = nOutportSort
    % generate cells for destination info
    bInportSignal = nIdxOutport == nOutportSignal; % get all inport hits of current outport
    cName = {xLink.port(nInportSignal(bInportSignal)).name};
    cModelRef = {xLink.port(nInportSignal(bInportSignal)).moduleSetup};
    
    % generate cells for subsequent structs
    nSignalCell = nSignalCell + 1;
    cSignalSource{nSignalCell} = struct('name',{xLink.port(nIdxOutport).name},...
                                        'modelRef',{xLink.port(nIdxOutport).moduleSetup});
    cSignalDestination{nSignalCell} = struct('name',cName,...
                                              'modelRef',cModelRef);
    
    % set signal index in port structure
    nPortSignal = [nIdxOutport nInportSignal(bInportSignal)];
    [xLink.port(nPortSignal).state] = deal('signal');
    [xLink.subPort.nSignal(nPortSignal)] = deal(numel(xSignal));
end

% generate signal structure
xSignalAdd = struct('name',{xLink.port(nOutportSort).name},...
    'type',{xLink.port(nOutportSort).type},...
    'unit',{xLink.port(nOutportSort).unit},...
    'modelRefSource',{xLink.port(nOutportSort).moduleSetup},...
    'source',cSignalSource,...
    'destination',cSignalDestination);
xSignal = structConcat(xSignal,xSignalAdd);
% append signal structure
xLink.signal = structConcat(xLink.signal,xSignal);

% TODO REMINDER: in case of user sets a connected non-physical signal to
% constant input (results in constant inports and an open outport) code has
% to be added here for:
% - remove signals with constant inports, add the inport and outport to
% open ports
return

% =========================================================================

function xLink = dcsFcnLinkNonPhysicsState(xLink)
% DCSFCNLINKNONPHYSICS derive signals, open ports and constant inports from
% current non-physics and non-control ports and attributes.
%
% Syntax:
%   [xLink] = dbcFcnLinkNonPhysics(xLink)
%
% Inputs:
%          xLink - structure with fields: 
%          .port - structure with fields: 
%            .name        - string with port name
%            .moduleSetup - string with moduleSetup name
%            .ioType      - string with port type (inport/outport)
%            .nameUnique  - string with unique port name
%            ... and others
%          .subPort - structure with fields: 
%            .physics     - boolean (1xn) with port type 
%                           0: non-physics, 1:physics
%            .inport      - boolean (1xn) with port I/O type 
%                           0: outport, 1:inport
%
% Outputs:
%         xLink - structure with fields: 
%          .port - structure with fields: 
%            .name        - string with port name
%            .moduleSetup - string with moduleSetup name
%            .ioType      - string with port type (inport/outport)
%            .nameUnique  - string with unique port name
%            .state       - string with (open, const, signal)
%            ... and others
%          .subPort - structure with fields: 
%            .physics     - boolean (1xn) with port type 
%                           0: non-physics, 1:physics
%            .inport      - boolean (1xn) with port I/O type 
%                           0: outport, 1:inport
%            .control     - boolean (1xn) with port/signal type==control
%                           0: other, 1:control
%            .nSignal     - integer (1xn) with index of signal
%          .signal - structure with fields: 
%           .name   - string with name of signal (equals outport name)
%           .type   - string with type of signal (equals outport type)
%           .unit   - string with unit of signal (equals outport unit)
%           .modelRefSource   - string with model reference of source port
%           .source - structure with fields:
%              .name      - string with outport name
%              .modelRef  - string with moduleSetup name of the outport
%           .destination  - structure vector with fields:
%              .name      - string with inport name
%              .modelRef  - string with moduleSetup name of the inport
%
% Example: 
%   [xLink] = dbcFcnLinkNonPhysics(xLink)

% get non-physics ports inport & outports
bInport = xLink.subPort.inport & ~xLink.subPort.physics & ~xLink.subPort.control;
bOutport = ~xLink.subPort.inport & ~xLink.subPort.physics & ~xLink.subPort.control;
nInport = find(bInport); % index of inports in xLink.port
nOutport = find(bOutport); % index of outports in xLink.port
cInport = {xLink.port(bInport).name};
cOutport = {xLink.port(bOutport).name};

% search for signal connections
[bSignal,nOutRed] = ismember(cInport,cOutport);
nInportSignal = nInport(bSignal); % index (1xm) of inports in xLink.port with state "signal" 
nOutRed = nOutRed(bSignal); % index (1xm) of reduced non-physics outport with state "signal"
nOutportSignal = nOutport(nOutRed); % index (1xm) of outports in xLink.port with state "signal" 

% create signal structure entries
xLink = dcsFcnLinkSignalCreate(xLink,nInportSignal,nOutportSignal);
return

% =========================================================================

function xLink = dcsFcnLinkFuncChainCreate(xLink,hDbc,hCfgAdapt)
% DCSFCNLINKFUNCCHAINCREATE create connectors and functional chains
% according the current port information.
%
% Syntax:
%   xLink = dcsFcnLinkFuncChainCreate(xLink,hDbc,hCfgAdapt)
%
% Inputs:
%          xLink - structure with fields: 
%          .port - structure with fields: 
%            .name            - string with port name
%            .connectorName   - string with connector name
%            .connectorType   - string with connector type (DIVe predefied type)
%            .connectorOrientation - string with connector orientation  
%                               (positive/negative)
%            .quantity        - string with unique port name
%            .functionalChain - string name of functional chain
%            .chainPosition   - string with integer of connector default
%                               position
%            .moduleSetup     - string with moduleSetup of port
%            .nameUnique      - string with unique port name
%            .ioType          - string with port I/O type (inport,outport)
%            ... and others
%          .subPort - structure with fields: 
%            .physics     - boolean (1xn) with port type 
%                           0: non-physics, 1:physics
%            .inport      - boolean (1xn) with port I/O type 
%                           0: outport, 1:inport
%           hDbc - handle of DIVe Basic Configurator GUI
%      hCfgAdapt - handle of Adapt Configurations GUI
%
% Outputs:
%   xLink       - structure with fields: 
%    .port      - structure with fields: see above
%    .connector - structure with fields: 
%      .name            - string with name of connector
%      .type            - string with connector type (DIVe predefied type)
%      .orientation     - string with connector orientation  
%      .moduleSetup     - string with moduleSetup of connector
%      .nameUnique      - string with unique connector name
%      .functionalChain - string name of functional chain
%      .chainPosition   - string with integer of connector default position
%      .nPort           - integer vector with port indices of all ports in 
%                         the connector
%    .functionalChain - structure with fields: 
%      .name            - string with name of connector
%      .type            - string with connector type (DIVe predefied type)
%      .Connector       - string with connector type (DIVe predefied type)
%        .name          - string with connector type (DIVe predefied type)
%        .moduleSetup   - string with moduleSetup of connector
%        .chainPosition - string with integer of connector default position
%        .nConnector    - integer with connector index in connector struct
%
% Example: 
%   xLink = dcsFcnLinkFuncChainCreate(xLink)

%% create connectors
% get all connectors of configuration
nPhysics = find([xLink.subPort.physics]); % index of physics ports in xLink.port
cConName = {xLink.port(xLink.subPort.physics).connectorName};
cConModule = {xLink.port(xLink.subPort.physics).moduleSetup};
cConNameUnique = cellfun(@(x,y)[x '_' y],cConModule,cConName,'UniformOutput',false);
[cConUnique,nConUnique2Phys,nPhys2ConUnique] = unique(cConNameUnique); %#ok<ASGLU>

% recreate all connectors in data structure
xConnector = structInit({'name','type','orientation','moduleSetup',...
                         'nameUnique','functionalChain','chainPosition','nPort'});
for nIdxCon = 1:numel(cConUnique)
    % identify ports of a single connector
    nPort = nPhysics(nPhys2ConUnique == nIdxCon);
    
    % check integrity of single connector
    bState = dcsFcnConnectorPortCheck(xLink.port(nPort),{'connectorType',...
        'connectorOrientation','moduleSetup','chainPosition'});
    
    if bState % if connector is consistent
        % create connector entry
        xConAdd = struct('name',{xLink.port(nPort(1)).connectorName},...
                         'type',{xLink.port(nPort(1)).connectorType},...
                         'orientation',{xLink.port(nPort(1)).connectorOrientation},...
                         'moduleSetup',{xLink.port(nPort(1)).moduleSetup},...
                         'nameUnique',{[xLink.port(nPort(1)).moduleSetup '_' xLink.port(nPort(1)).name]},...
                         'functionalChain',{xLink.port(nPort(1)).functionalChain},...
                         'chainPosition',{xLink.port(nPort(1)).chainPosition},...
                         'nPort',{nPort});
        xConnector = structConcat(xConnector,xConAdd);
    else
        
        % do not create - give message
        sMsg = sprintf(['Connector "%s" of module "%s" was not created due to '...
                   'inconsistent port attributes!\n'],...
                xLink.port(nPort(1)).connectorName,xLink.port(nPort(1)).moduleSetup);
        if isempty(hCfgAdapt) && ~isempty(hDbc)
            umsMsg('Configurator',2,sMsg);
        else
            fprintf(2,sMsg);
        end
    end
end
xLink.connector = xConnector;

% check consistency of all connectors of one type
cConType = {xLink.connector.type};
[cTypeUnique,nTypeUnique2Con,nCon2TypeUnique] = unique(cConType); %#ok<ASGLU>
for nIdxType = 1:numel(cTypeUnique)
    % identify connectors of a same type
    nCon = find(nCon2TypeUnique == nIdxType);
    
    % check the quantity consistency of same type connectors
    dcsFcnConnectorQuantityCheck(xLink.connector(nCon),xLink.port,hDbc,hCfgAdapt);
end

%% create functional chains
% get all functional chains of configuration
xChain = structInit({'name','type','Connector'});
cFunctionalChain = {xLink.connector.functionalChain};
[cFunctionalChainUnique,nCon2FcUnique,nFcUnique2Con] = unique(cFunctionalChain); %#ok<ASGLU>
for nIdxChain = 1:numel(cFunctionalChainUnique)
    % get connectors of this functional chain
    nConChain = find(nIdxChain == nFcUnique2Con);
    bChainSet = ~cellfun(@isempty,{xLink.connector(nConChain).chainPosition});
    nConChainSet = nConChain(bChainSet);
    nConChainUnset = nConChain(~bChainSet);
    
    % check and correct double positions
    nPos = cell2mat(cellfun(@str2double,{xLink.connector(nConChainSet).chainPosition},'UniformOutput',false));
    [nPosUnique,nPosUnique2Con,nCon2PosUnique] = unique(nPos); %#ok<ASGLU>
    if numel(nPos) > numel(nPosUnique) % if double entry for chainPosition exists
        % remove chainPosition entries from excessive connectors with same chainPosition 
        for nIdxPos = 1:numel(nPosUnique) % for all occurring positions in chain
            % get all connectors in nConChainSet with the same default chainPosition
            nPosCurrent = find(nIdxPos == nCon2PosUnique);
            
            % reset all default chainPosition except of the first connector
            for nIdxCon = 2:numel(nPosCurrent)
                % shortcut of ID
                nConCurrent = nConChainSet(nPosCurrent(nIdxCon));
                
                % report to user
                sMsg = sprintf(['CAUTION: The functionChain "%s" is overpopulated on chainPosition %s. \n' ...
                    'The connector "%s" of Module "%s" is reset to an empty position and will not be connected.'],...
                    xLink.connector(nConCurrent).functionalChain,...
                    xLink.connector(nConCurrent).chainPosition,...
                    xLink.connector(nConCurrent).name,...
                    xLink.connector(nConCurrent).moduleSetup);
                if isempty(hCfgAdapt) && ~isempty(hDbc)
                    umsMsg('Configurator',3,sMsg);
                else
                    fprintf(1,sMsg);
                end
                
                % reset connector entry
                xLink.connector(nConCurrent).chainPosition = '';
                
                % reset ports of reset connector
                nPortReset = xLink.connector(nConCurrent).nPort;
                [xLink.port(nPortReset).chainPosition] = deal('');
            end
        end % for all occurring positions in chain
        
        % re-evaluate set/unset state of connectors
        bChainSet = ~cellfun(@isempty,{xLink.connector(nConChain).chainPosition});
        nConChainSet = nConChain(bChainSet);
        nConChainUnset = nConChain(~bChainSet);
    end
    
    % create functional chain entry
    if isempty(nConChainSet)
        continue
    end
    if isempty(nConChainSet)
        nConChainSet = []; % reset to 0x0 from 0x1 matrix due for MATLAB version compatibility
    end
    if size(nConChainSet,1) > size(nConChainSet,2)
        nConChainSet = nConChainSet'; % ensure row vector
    end
    if isempty(nConChainUnset)
        nConChainUnset = []; % reset to 0x0 from 0x1 matrix due for MATLAB version compatibility
    end
    xChainAdd = struct('name',{xLink.connector(nConChainSet(1)).functionalChain},...
                       'type',{xLink.connector(nConChainSet(1)).type},...
                       'Connector',{struct('name',{xLink.connector(nConChainSet).name},...
                                           'moduleSetup',{xLink.connector(nConChainSet).moduleSetup},...
                                           'chainPosition',{xLink.connector(nConChainSet).chainPosition},...
                                           'orientation',{xLink.connector(nConChainSet).orientation},...
                                           'nConnector',num2cell(nConChainSet))},...
                       'ConnectorUnset',{struct('name',{xLink.connector(nConChainUnset).name},...
                                           'moduleSetup',{xLink.connector(nConChainUnset).moduleSetup},...
                                           'chainPosition',{xLink.connector(nConChainUnset).chainPosition},...
                                           'orientation',{xLink.connector(nConChainUnset).orientation},...
                                           'nConnector',num2cell(nConChainUnset'))});
    
    % resort connectors according chainPosition
    nChainPos = cell2mat(cellfun(@str2double,{xChainAdd.Connector.chainPosition},'UniformOutput',false));
    [nChainPos,nSort] = sort(nChainPos); %#ok<ASGLU>
    xChainAdd.Connector = xChainAdd.Connector(nSort);
    
    % add functionalChain to structure vector
    xChain = structConcat(xChain,xChainAdd);
end
xLink.functionalChain = xChain;
return

% =========================================================================

function xLink = dcsFcnLinkPhysicsState(xLink,hDbc,hCfgAdapt)
% DCSFCNLINKPHYSICSSTATE set the port state of signals, open ports and
% constants with physics signals according the current state of
% functionalChains.
%
% Syntax:
%   xLink = dcsFcnLinkPhysicsState(xLink)
%
% Inputs:
%   xLink   - structure with fields: 
%     .port - structure with fields: 
%       .name            - string with port name
%       .connectorName   - string with connector name
%       .connectorType   - string with connector type (DIVe predefied type)
%       .connectorOrientation - string with connector orientation  
%                          (positive/negative)
%       .quantity        - string with unique port name
%       .functionalChain - string name of functional chain
%       .chainPosition   - string with integer of connector default
%                          position
%       .moduleSetup     - string with moduleSetup of port
%       .nameUnique      - string with unique port name
%       .ioType          - string with port I/O type (inport,outport)
%       .state           - string with (open, const, signal)
%         ... and others
%     .subPort           - structure with fields: 
%       .physics         - boolean (1xn) with port type 
%                          0: non-physics, 1:physics
%       .inport          - boolean (1xn) with port I/O type 
%                          0: outport, 1:inport
%     .signal   - structure with fields: 
%       .name   - string with name of signal (equals outport name)
%       .type   - string with type of signal (equals outport type)
%       .unit   - string with unit of signal (equals outport unit)
%       .modelRefSource - string with model reference of source port
%          .source      - structure with fields:
%            .name      - string with outport name
%            .modelRef  - string with moduleSetup name of the outport
%          .destination - structure vector with fields:
%            .name      - string with inport name
%            .modelRef  - string with moduleSetup name of the inport
%    .connector - structure with fields: 
%      .name            - string with name of connector
%      .type            - string with connector type (DIVe predefied type)
%      .orientation     - string with connector orientation  
%      .moduleSetup     - string with moduleSetup of connector
%      .nameUnique      - string with unique connector name
%      .functionalChain - string name of functional chain
%      .chainPosition   - string with integer of connector default position
%      .nPort           - integer vector with port indices of all ports in 
%                         the connector
%    .functionalChain - structure with fields: 
%      .name            - string with name of connector
%      .type            - string with connector type (DIVe predefied type)
%      .Connector       - string with connector type (DIVe predefied type)
%        .name          - string with connector type (DIVe predefied type)
%        .moduleSetup   - string with moduleSetup of connector
%        .chainPosition - string with integer of connector default position
%        .nConnector    - integer with connector index in connector struct
%      ... and more.
%
% Outputs:
%   xLink - structure with fields: see above
%
% Example: 
%   xLink = dcsFcnLinkPhysicsState(xLink)

% init index vectors for 
nConSetPositive = []; % positive connector for signal
nConSetNegative = []; % negative connector for signal
nConUnset = []; % unset connector with open ports

%% process all functional chains for linked connectors
for nIdxChain = 1:numel(xLink.functionalChain)
    % process all connectors of chain with set position
    nIdxCon = 0;
    while nIdxCon < numel(xLink.functionalChain(nIdxChain).Connector)
        nIdxCon = nIdxCon + 1;
        if nIdxCon < numel(xLink.functionalChain(nIdxChain).Connector) && ...
                strcmp(xLink.functionalChain(nIdxChain).Connector(nIdxCon).orientation(1:7),'positiv') && ...
                strcmp(xLink.functionalChain(nIdxChain).Connector(nIdxCon+1).orientation(1:7),'negativ')
            % store connector indices for signal creation
            nConSetPositive = [nConSetPositive xLink.functionalChain(nIdxChain).Connector(nIdxCon).nConnector]; %#ok<AGROW>
            nConSetNegative = [nConSetNegative xLink.functionalChain(nIdxChain).Connector(nIdxCon+1).nConnector];  %#ok<AGROW>
            
            % increment, as follow connector is already stored
            nIdxCon = nIdxCon + 1;
        else
            % store connector index for open port/constant
            nConUnset = [nConUnset xLink.functionalChain(nIdxChain).Connector(nIdxCon).nConnector]; %#ok<AGROW>
        end
    end
    
    % determine open ports from functional chains
    for nIdxCon = 1:numel(xLink.functionalChain(nIdxChain).ConnectorUnset)
        % store connector index for open port/constant
        nConUnset = [nConUnset xLink.functionalChain(nIdxChain).ConnectorUnset(nIdxCon).nConnector]; %#ok<AGROW>
    end
end

%% create signals and set port state for set connectors
xSignal = struct('name',{},'source',{},'destination',{});
for nIdxVec = 1:numel(nConSetPositive)
    % shortcut for connctor indices
    nPos = nConSetPositive(nIdxVec);
    nNeg = nConSetNegative(nIdxVec);
    
    % process all ports for signals
    for nIdxPort = 1:numel(xLink.connector(nPos).nPort)
        % get matching quantity port index of negative connector
        [bPortNegId,nPortNegId] = ismember(xLink.port(xLink.connector(nPos).nPort(nIdxPort)).quantity,...
                                      {xLink.port(xLink.connector(nNeg).nPort).quantity});
        
        % check correct matching of port
        if bPortNegId
            nPortNeg = xLink.connector(nNeg).nPort(nPortNegId);
        else
            % report error with hints to user
            sMsg = sprintf(...
                ['Error on physics connection:\n' ...
                 'All Connectors of same type must have the same quantities and port orientations.\n' ...
                 'In Module "%s" and connector "%s" a port is missing for the quantity "%s".\n' ... 
                 '(Counterpart to Module "%s" connector "%s" Port "%s")\n' ...
                 'You need to add a port for the quantity "%s" on Module "%s".\n' ...
                 'Currently existing quantities of Module "%s" and connector "%s":\n%s'],...
                 xLink.connector(nNeg).moduleSetup,...
                 xLink.connector(nNeg).name,...
                 xLink.port(xLink.connector(nPos).nPort(nIdxPort)).quantity,...
                 xLink.connector(nPos).moduleSetup,...
                 xLink.connector(nPos).name,...
                 xLink.port(xLink.connector(nPos).nPort(nIdxPort)).name,...
                 xLink.port(xLink.connector(nPos).nPort(nIdxPort)).quantity,...
                 xLink.connector(nNeg).moduleSetup,...
                 xLink.connector(nNeg).moduleSetup,...
                 xLink.connector(nNeg).name,...
                 sprintf('   %s\n',xLink.port(xLink.connector(nNeg).nPort).quantity)); 
            if isempty(hCfgAdapt) && ~isempty(hDbc)
                umsError('Configurator','dbc:dcsFcnLinkPhysicsState:quantityMismatch',sMsg);
            elseif ~isempty(hCfgAdapt)
                fprintf(2,sMsg);
            else
                error('dbc:dcsFcnLinkPhysicsState:quantityMismatch',sMsg); %#ok<SPERR>
            end
        end
        
        % assign indices to get outport and inport
        if strcmp(xLink.port(xLink.connector(nPos).nPort(nIdxPort)).ioType,'outport')
            % set connector and port index for outport/inport
            nPortOut = xLink.connector(nPos).nPort(nIdxPort);
            nPortIn = nPortNeg;
        elseif strcmp(xLink.port(xLink.connector(nPos).nPort(nIdxPort)).ioType,'inport')
            % set connector and port index for outport/inport
            nPortOut = nPortNeg;
            nPortIn = xLink.connector(nPos).nPort(nIdxPort);
        end
        
        % generate signal structure
        xSignalAdd = struct(...
            'name',{xLink.port(nPortOut).name},...
            'type',{xLink.port(nPortOut).type},...
            'unit',{xLink.port(nPortOut).unit},...
            'modelRefSource',{xLink.port(nPortOut).moduleSetup},...
            'source',{struct('name',{xLink.port(nPortOut).name},...
                             'modelRef',{xLink.port(nPortOut).moduleSetup})},...
            'destination',{struct('name',{xLink.port(nPortIn).name},...
                                  'modelRef',{xLink.port(nPortIn).moduleSetup})});
        xSignal = structConcat(xSignal,xSignalAdd);
    
        % set port states to signal
        nPort = [nPortIn nPortOut]; % create port index list for this signal
        [xLink.port(nPort).state] = deal('signal');
        [xLink.subPort.nSignal(nPort)] = deal(numel(xSignal)+numel(xLink.signal));
    end
end
if isfield(xLink,'signal')
    xLink.signal = structConcat(xLink.signal,xSignal);
else
    xLink.signal = xSignal;
end

%% set port state for unset connectors
% create candidate vector for open ports
nPort = [];
for nIdxVec = 1:numel(nConUnset) % for all unset connctors & open end connectors
    nPort = [nPort xLink.connector(nConUnset(nIdxVec)).nPort]; %#ok<AGROW>
end

% check for constant states
bConstant = ismember({xLink.port(nPort).state},'const');
nPort = nPort(~bConstant);

% set open port states
[xLink.port(nPort).state] = deal('open');
return

% =========================================================================

function bState = dcsFcnConnectorQuantityCheck(xConnector,xPort,hDbc,hCfgAdapt)
% DCSFCNCONNECTORQUANTITYCHECK check the connectors of same type for
% consistency in quantity ports and port io type.
%
% Syntax:
%   bState = dcsFcnConnectorQuantityCheck(xConnector,xPort,hDbc,hCfgAdapt)
%
% Inputs:
%   xConnector - structure with fields: 
%         .name  - string with name of connector
%         .nPort - integer (1xn) with port indices of connector
%        xPort - structure vector for all ports with fields: 
%           see structure documentation Excel sheet
%           hDbc - handle of DIVe Basic Configurator GUI
%      hCfgAdapt - handle of Adapt Configurations GUI
%
% Outputs:
%   bState - boolean 
%
% Example: 
%   bState = dcsFcnConnectorQuantityCheck(xConnector,xPort)

% initialze output
bState = true;

% loop over connectors
for nIdxCon = 1:numel(xConnector)
    % get quantities of each connector
    xConnector(nIdxCon).cQuantity = {xPort(xConnector(nIdxCon).nPort).quantity};
    xConnector(nIdxCon).cIO = {xPort(xConnector(nIdxCon).nPort).ioType};
    
    % resort connector quantities
    if nIdxCon > 1
        [bContain,nSort] = ismember(xConnector(1).cQuantity,xConnector(nIdxCon).cQuantity);
        if all(bContain)
            % resort connector quantities according first template connector
            xConnector(nIdxCon).cQuantity = xConnector(nIdxCon).cQuantity(nSort);
            xConnector(nIdxCon).cIO = xConnector(nIdxCon).cIO(nSort);
        end
    else
        bContain = true;
    end
    
    % invert negative connector orientations for comparison
    if strcmp(xConnector(nIdxCon).orientation(1:7),'negativ')
        xConnector(nIdxCon).cIO = strrep(xConnector(nIdxCon).cIO,'inport','inportinv');
        xConnector(nIdxCon).cIO = strrep(xConnector(nIdxCon).cIO,'outport','inport');
        xConnector(nIdxCon).cIO = strrep(xConnector(nIdxCon).cIO,'inportinv','outport');
    end
    
    % check quantities match
    if ~all(bContain)
        % update state
        bState = false;
        cQuantMiss = setxor(xConnector(1).cQuantity,xConnector(nIdxCon).cQuantity);
        if ~isempty(cQuantMiss)
            % display inconsistency message
            sMsg = sprintf(['Error on connector check: \n' ...
                'All connectors of the same connectorType must have the same quantities. \n' ...
                'The connector "%s" of module "%s" and another connector "%s" of module "%s" \n' ...
                'are of the same connectorType, but do not have the same quantities.\n' ...
                'Check DIVe_signals.xlsx for correct implmentation of connectorType.\n' ...
                'Unique quantities: \n' ...
                strGlue(cQuantMiss,' \n')],...
                xConnector(nIdxCon).name,xConnector(nIdxCon).moduleSetup,...
                xConnector(1).name,xConnector(1).moduleSetup);
            if isempty(hCfgAdapt) && ~isempty(hDbc)
                umsMsg('Configurator',2,sMsg);
            else
                fprintf(2,sMsg);
            end
        end
        
    elseif numel(xConnector(1).cIO) == numel(xConnector(nIdxCon).cIO)
        % check port orientation
        bIO = strcmp(xConnector(1).cIO,xConnector(nIdxCon).cIO);
        if ~all(bIO)
            % update state
            bState = false;

            % display inconsistency message
            sMsg = sprintf(['Error on connector check: \n' ...
                'All connectors of the same connectorType must have the same port orientations. \n' ...
                'The connector "%s" of module "%s" and another connector "%s" of module "%s" are of the \n' ...
                'same connectorType, but do not have the same port orientations for their quantities.\n' ...
                'Check DIVe_signals.xlsx for correct implmentation of connectorType.\n' ...
                'Quantities with wrong orientation: \n' ...
                strGlue(xConnector(nIdxCon).cQuantity(~bIO),' \n')],...
                xConnector(nIdxCon).name,xConnector(nIdxCon).moduleSetup,...
                xConnector(1).name,xConnector(1).moduleSetup);
            if isempty(hCfgAdapt) && ~isempty(hDbc)
                umsMsg('Configurator',2,sMsg);
            else
                fprintf(2,sMsg);
            end
        end
    
    end % if ~all(bContain)
end % for all connectors
return

% =========================================================================

function bState = dcsFcnConnectorPortCheck(xPort,cAttribute,hDbc,hCfgAdapt)
% DCSFCNCONNECTORPORTCHECK check all ports of a connector for consistent
% attribute settings
%
% Syntax:
%   dcsFcnConnectorPortCheck(xPort,cAttribute,hDbc,hCfgAdapt)
%
% Inputs:
%     xPort - structure with fields: 
%      .type            - string with connector type (DIVe predefied type)
%      .orientation     - string with connector orientation  
%      .moduleSetup     - string with moduleSetup of connector
%      .functionalChain - string name of functional chain
%   cAttribute - cell with strings of attributes to check
%           hDbc - handle of DIVe Basic Configurator GUI
%      hCfgAdapt - handle of Adapt Configurations GUI
%
% Outputs:
%        bState - boolean for check success:
%                   0: Any check failed
%                   1: All attributes are correct
%
% Example: 
%   dcsFcnConnectorPortCheck(xPort,cAttribute)

% initialze output
bState = true;

% loop over attributes
for nIdxAttribute = 1:numel(cAttribute)
    [cOccurence,nU2A,nAll2Unique] = unique({xPort.(cAttribute{nIdxAttribute})}); %#ok<ASGLU>
    if numel(cOccurence) > 1
        % determine majority value
        nRef = mode(nAll2Unique);
        
        for nIdxPort = 1:numel(xPort) % for all ports
            % if port does not match majority
            if ~strcmp(xPort(nIdxPort).(cAttribute{nIdxAttribute}),xPort(nRef(1)).(cAttribute{nIdxAttribute}))
                % update state
                bState = false;

                % display inconsistency message
                sMsg = sprintf(['The port "%s" of module "%s" does not ' ...
                    'match the connector attribute "%s" (this: %s, other: %s)' ...
                    'of other ports in the connector "%s"'],...
                    xPort(nIdxPort).name,xPort(nIdxPort).moduleSetup,...
                    cAttribute{nIdxAttribute},...
                    xPort(nIdxPort).(cAttribute{nIdxAttribute}),...
                    xPort(nRef(1)).(cAttribute{nIdxAttribute}),...
                    xPort(nRef(1)).connectorName);
                
                if isempty(hCfgAdapt) && ~isempty(hDbc)
                    umsMsg('Configurator',4,sMsg);
                else
                    fprintf(1,sMsg);
                end
            end % if deviation port
        end % for all ports
        
    end % if deviation
end % for attribute
return
