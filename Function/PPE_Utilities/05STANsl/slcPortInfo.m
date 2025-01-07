function xPortInfo = slcPortInfo(hPort,nPort)
% SLCPORTINFO get all relevant port information of an external subsystem
% port and its corresponding internal block in a structure.
%
% Syntax:
%   xPortInfo = slcPortInfo(hPort)
%
% Inputs:
%   hPort - handle or vector of handles of a subsystem port (external) 
%           or handle/vector of handles/string/cell of strings with path of
%           an internal subsystem port block.
%           [optional] In case of the nPort usage the subsystem can be
%           specified instead of the port.
%   nPort - [optional] integer (1xn) with number of ports to get from
%           specified subsystem
%
% Outputs:
%   xPortInfo - structure with fields: 
%       .ext.Handle      - handle of external port
%       .ext.nPortNumber - integer with port number (1 based index)
%       .ext.sPortNumber - string with port number (1 based index)
%       .ext.PortType    - string with port type (e. g. 'Inport' 
%                          CAUTION: the original lower first case is
%                          converted for matching with the port block
%                          properties)
%       .ext.Position    - vector (1x2) of port connection position in
%                          parent system
%       .ext.Parent      - string with path of port's subsystem
%       .ext.hBlockCon   - handle (1xn) of blocks connected to port
%       .ext.nBlockCon   - vector (1xn) with port index (1 based) of
%                          connected block (converted from 0 based!)
%       .ext.hLine       - handle of line connected to port
%       .ext.sLineName   - string with name of line connected to port
%       .int.Handle      - handle of port block in subsystem
%       .int.Path        - string with blockpath of port block in subsystem
%       .int.Port        - string with port number (1 based index)
%       .int.BlockType   - string with block type of port (e. g. 'Inport')
%       .int.hBlockCon   - handle (1xn) of blocks connected to port
%       .int.nBlockCon   - vector (1xn) with port index (0 based) of
%                          connected block
%       .int.hLine       - handle of line connected to port
%       .int.sLineName   - string with name of line connected to port
% 
% 
%
% Example: 
%   xBlockInfo = slcBlockInfo(gcb);
%   xPortInfo = slcPortInfo(xBlockInfo.PortHandles)
%
%
% Subfunctions:
% Private functions:
% Other m-files required:
% MAT-files required:
%
% See also: gcbs, slcBlockInfo, slcLineInfo
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2013-12-09

% % initialize output
% xExt = struct('Handle',{},'nPortNumber',{},'sPortNumber',{},'PortType',{},'Position',{},'Parent',{},'hBlockCon',{},'nBlockCon',{},'hLine',{});
% xInt = struct('Handle',{},'Path',{},'Port',{},'BlockType',{},'hBlockCon',{},'nBlockCon',{},'hLine',{});
% xPortInfo.ext = xExt;
% xPortInfo.int = xInt;

% input check
if ~(isnumeric(hPort) && all(ishandle(hPort)) || ...
        ischar(hPort) || ...
        iscell(hPort) && ~isempty(hPort) && ischar(hPort{1}))
    error('slcPortInfo:InputUnknown','The input argument is of an unknown type - only handles, vectors of handles, strings of cells of strings are allowed')
end
if exist('nPort','var') ~= 1
    nPort = [];
end

% generate handle vector (as common start point)
if ischar(hPort)
    hPort = get_param(hPort,'Handle');
elseif iscell(hPort)
    cPort = hPort;
    hPort = zeros(1,numel(cPort));
    for nIdxElement = 1:numel(cPort)
        hPort = get_param(cPort{nIdxElement},'Handle');
    end
end

% ensure handle vector in case of subsystem passing
if strcmpi('block',get_param(hPort(1),'Type')) && ... % if block is specified
        strcmpi('SubSystem',get_param(hPort(1),'BlockType')) % if block is subsystem
    
    % return if no ports are requested
    if isempty(nPort)
        return
    end
    
    % get block info
    xBlockInfo = slcBlockInfo(hPort(1));
    
    % generate handle vector
    if nPort(1) == -1
        % return all inports and outports
        hPort = [xBlockInfo.PortHandles.Inport xBlockInfo.PortHandles.Outport];
    else
        % divide requested ports into port types
        nInport     = nPort(nPort <= xBlockInfo.Ports(1));
        nOutport    = nPort(nPort <= xBlockInfo.Ports(2) & nPort > xBlockInfo.Ports(1)) - sum(xBlockInfo.Ports(1:1));
        nEnable     = nPort(nPort <= xBlockInfo.Ports(3) & nPort > xBlockInfo.Ports(2)) - sum(xBlockInfo.Ports(1:2));
        nTrigger    = nPort(nPort <= xBlockInfo.Ports(4) & nPort > xBlockInfo.Ports(3)) - sum(xBlockInfo.Ports(1:3));
        nState      = nPort(nPort <= xBlockInfo.Ports(5) & nPort > xBlockInfo.Ports(4)) - sum(xBlockInfo.Ports(1:4));
        nLConn      = nPort(nPort <= xBlockInfo.Ports(6) & nPort > xBlockInfo.Ports(5)) - sum(xBlockInfo.Ports(1:5));
        nRConn      = nPort(nPort <= xBlockInfo.Ports(7) & nPort > xBlockInfo.Ports(6)) - sum(xBlockInfo.Ports(1:6));
        nIfaction   = nPort(nPort <= xBlockInfo.Ports(8) & nPort > xBlockInfo.Ports(7)) - sum(xBlockInfo.Ports(1:7));
        
        % generate handle vector
        hPort = [xBlockInfo.PortHandles.Inport(nInport),...
                 xBlockInfo.PortHandles.Outport(nOutport),...
                 xBlockInfo.PortHandles.Enable(nEnable),...
                 xBlockInfo.PortHandles.Trigger(nTrigger),...
                 xBlockInfo.PortHandles.State(nState),...
                 xBlockInfo.PortHandles.LConn(nLConn),...
                 xBlockInfo.PortHandles.RConn(nRConn),...
                 xBlockInfo.PortHandles.Ifaction(nIfaction)];
    end
end
    
% get all port properties
for nIdxPort = 1:numel(hPort)
    
    % determine external port handle
    sType = get_param(hPort(nIdxPort),'Type');
    if strcmp(sType,'port')
        xPortInfo(nIdxPort).ext.Handle = hPort(nIdxPort); %#ok
    elseif strcmp(sType,'block')
        % determine external port handle from internal block
        sBlockType = get_param(hPort(nIdxPort),'BlockType');
        sParent = get_param(hPort(nIdxPort),'Parent');
        xPortHandles = get_param(sParent,'PortHandles');
        
        switch sBlockType
            case 'Inport'
                sPort = get_param(hPort(nIdxPort),'Port');
                xPortInfo(nIdxPort).ext.Handle = xPortHandles.Inport(str2double(sPort)); %#ok
            case 'Outport'
                sPort = get_param(hPort(nIdxPort),'Port');
                xPortInfo(nIdxPort).ext.Handle = xPortHandles.Outport(str2double(sPort)); %#ok
            case 'Enable'
                xPortInfo(nIdxPort).ext.Handle = xPortHandles.Enable(1); %#ok
            case 'TriggerPort'
                xPortInfo(nIdxPort).ext.Handle = xPortHandles.Trigger(1); %#ok
            case 'ActionPort'
                xPortInfo(nIdxPort).ext.Handle = xPortHandles.Ifaction(1); %#ok
            otherwise
                error('slcPortInfo:BlockTypeNotCovered',['The specified block of type ' sBlockType ' is not a covered port blocktype in the function.'])
        end
        
    else % neither block nor port 
        error('slcPortInfo:TypeNotCovered',['The specified element of type ' sType ' is not covered in the function.'])
    end
    
    % get all external port properties
    xPortInfo(nIdxPort).ext.nPortNumber = get_param(xPortInfo(nIdxPort).ext.Handle,'PortNumber'); %#ok
    xPortInfo(nIdxPort).ext.sPortNumber = num2str(xPortInfo(nIdxPort).ext.nPortNumber,'%3.0f'); %#ok
    xPortInfo(nIdxPort).ext.PortType    = get_param(xPortInfo(nIdxPort).ext.Handle,'PortType'); %#ok
    xPortInfo(nIdxPort).ext.PortType(1) = upper(xPortInfo(nIdxPort).ext.PortType(1)); %#ok
    xPortInfo(nIdxPort).ext.Position    = get_param(xPortInfo(nIdxPort).ext.Handle,'Position'); %#ok
    xPortInfo(nIdxPort).ext.Parent      = get_param(xPortInfo(nIdxPort).ext.Handle,'Parent'); %#ok
    xPortConnectivity = get_param(xPortInfo(nIdxPort).ext.Parent,'PortConnectivity');
    nPortConnectivity = xPortInfo(nIdxPort).ext.nPortNumber;
%     nPortConnectivity = slcPortPropertiesToPortConnectivityCount(xPortInfo(nIdxPort).ext.PortType,...
%                         xPortInfo(nIdxPort).ext.nPortNumber,get_param(xPortInfo(nIdxPort).ext.Parent,'Ports'),sMatlabInfo);
    xPortInfo(nIdxPort).ext.hBlockCon   = [xPortConnectivity(nPortConnectivity).SrcBlock xPortConnectivity(nPortConnectivity).DstBlock]; %#ok
    xPortInfo(nIdxPort).ext.nBlockCon   = [xPortConnectivity(nPortConnectivity).SrcPort xPortConnectivity(nPortConnectivity).DstPort] + 1; %#ok CAUTION: original 0 based indexing is changed to 1 based indexing for comfort
    xPortInfo(nIdxPort).ext.hLine       = get_param(xPortInfo(nIdxPort).ext.Handle,'Line'); %#ok
    if ishandle(xPortInfo(nIdxPort).ext.hLine)
        xPortInfo(nIdxPort).ext.sLineName = get_param(xPortInfo(nIdxPort).ext.hLine,'Name'); %#ok
    else
        xPortInfo(nIdxPort).ext.sLineName = ''; %#ok
    end
    % try to retrieve propagated signal names
    if isempty(xPortInfo(nIdxPort).ext.sLineName) && ...
            strcmp(xPortInfo(nIdxPort).ext.PortType,'Outport')
        sSignalPropagate = get(xPortInfo(nIdxPort).ext.Handle,'PropagatedSignals');
        if ~isempty(sSignalPropagate)
            xPortInfo(nIdxPort).ext.sLineName = sSignalPropagate; %#ok<AGROW>
        end
    end
        
        
    % translate port type to block type
    cPortAlias = {'Inport' 'Inport';
                  'Outport' 'Outport';
                  'Enable' 'EnablePort';
                  'Trigger' 'TriggerPort';
                  'State' 'unknownSimscape';
                  'LConn' 'unknownSimscape';
                  'RConn' 'unknownSimscape';
                  'Ifaction' 'ActionPort';
                  'Reset' 'ResetPort'};
    bPortType = strcmp(xPortInfo(nIdxPort).ext.PortType,cPortAlias(:,1));
    sBlockType = cPortAlias{bPortType,2};
    
              
    % get all internal port properties
    if any(strcmp(sBlockType,{'Inport','Outport'}))
        cPort = find_system(xPortInfo(nIdxPort).ext.Parent,'SearchDepth',1,'FollowLinks','on','LookUnderMasks','all',...
            'BlockType',sBlockType,...
            'Port',     xPortInfo(nIdxPort).ext.sPortNumber);
    else
        cPort = find_system(xPortInfo(nIdxPort).ext.Parent,'SearchDepth',1,'FollowLinks','on','LookUnderMasks','all',...
            'BlockType',sBlockType);
    end
    xPortInfo(nIdxPort).int.Handle      = get_param(cPort{1},'Handle'); %#ok
    xPortInfo(nIdxPort).int.Path        = cPort{1}; %#ok
	xPortInfo(nIdxPort).int.Name        = get_param(xPortInfo(nIdxPort).int.Handle,'Name'); %#ok
    if any(strcmp(sBlockType,{'Inport','Outport'}))
        xPortInfo(nIdxPort).int.Port        = get_param(xPortInfo(nIdxPort).int.Handle,'Port'); %#ok
    else
        xPortInfo(nIdxPort).int.Port        = []; %#ok
    end
    xPortInfo(nIdxPort).int.BlockType   = get_param(xPortInfo(nIdxPort).int.Handle,'BlockType'); %#ok
    xPortConnectivity = get_param(xPortInfo(nIdxPort).int.Handle,'PortConnectivity');
    xPortInfo(nIdxPort).int.hBlockCon   = [xPortConnectivity.SrcBlock xPortConnectivity.DstBlock]; %#ok concatenation ok, as a port block has only one port
    xPortInfo(nIdxPort).int.nBlockCon   = [xPortConnectivity.SrcPort xPortConnectivity.DstPort] + 1; %#ok CATION: original 0 based indexing is changed to 1 based indexing for comfort
    xLineHandles = get_param(xPortInfo(nIdxPort).int.Handle,'LineHandles');
    xPortInfo(nIdxPort).int.hLine       = [xLineHandles.Inport,xLineHandles.Outport,xLineHandles.Enable,xLineHandles.Trigger,xLineHandles.State,xLineHandles.LConn,xLineHandles.RConn,xLineHandles.Ifaction]; %#ok
    if ishandle(xPortInfo(nIdxPort).int.hLine)
        xPortInfo(nIdxPort).int.sLineName   = get_param(xPortInfo(nIdxPort).int.hLine,'Name'); %#ok
    else
        xPortInfo(nIdxPort).int.sLineName   = ''; %#ok
    end
    % try to retrieve propagated signal names
    if isempty(xPortInfo(nIdxPort).ext.sLineName) && ...
            strcmp(xPortInfo(nIdxPort).int.BlockType,'Inport')
        xPortHandles = get_param(xPortInfo(nIdxPort).int.Handle,'PortHandles');
        sSignalPropagate = get(xPortHandles.Outport,'PropagatedSignals');
        if ~isempty(sSignalPropagate)
            xPortInfo(nIdxPort).int.sLineName = sSignalPropagate; %#ok<AGROW>
        end
    end
end
return