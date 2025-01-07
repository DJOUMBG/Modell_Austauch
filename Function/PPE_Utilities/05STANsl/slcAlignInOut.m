function slcAlignInOut(hSubsystem)
% SLCALIGNINOUT allign all block chains connected to the inports and
% outports of the specified subsystem with the block ports, as long as they
% are either a single output source block, single input sink block or a
% block with one in-/outport each. Also adapted for enable/fcall/action
% ports.
%
% Syntax:
%   slcAlignInOut(hSubsystem)
%
% Inputs:
%   hSubsystem - handle or string with block path of specified block
%
% Outputs:
%
% Example: 
%   slcAlignInOut(hSubsystem)
%
% See also: slcBlockInfo
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2013-04-11

if nargin == 0
    xBlockInfo = slcBlockInfo(gcb);
else
    xBlockInfo = slcBlockInfo(hSubsystem);
end

% All block connected to inports
for nIdxInport = 1:xBlockInfo.Ports(1)
    if ishandle(xBlockInfo.PortCon(nIdxInport).SrcBlock)
        alignSource(xBlockInfo.PortCon(nIdxInport).SrcBlock,...
                    xBlockInfo.PortCon(nIdxInport).Position(2));
        straightLine(xBlockInfo.LineHandles.Inport(nIdxInport));
    end
end

% All block connected to outports
for nIdxOutport = 1:xBlockInfo.Ports(2)
    nIdxCon = sum(xBlockInfo.Ports([1,3,4]))+nIdxOutport;
    if ishandle(xBlockInfo.PortCon(nIdxCon).DstBlock)
        alignDestination(xBlockInfo.PortCon(nIdxCon).DstBlock,...
                         xBlockInfo.PortCon(nIdxCon).Position(2));
        straightLine(xBlockInfo.LineHandles.Outport(nIdxOutport));
    end
end

% enable ports
for nIdxOutport = 1:xBlockInfo.Ports(3)
    nIdxCon = sum(xBlockInfo.Ports(1))+1;
    if ishandle(xBlockInfo.PortCon(nIdxCon).SrcBlock)
        alignSource(xBlockInfo.PortCon(nIdxCon).SrcBlock,...
                         xBlockInfo.PortCon(nIdxCon).Position(2)-45);
    end
end

% fcncall ports
for nIdxOutport = 1:xBlockInfo.Ports(4)
    nIdxCon = sum(xBlockInfo.Ports([1,3]))+1;
    if ishandle(xBlockInfo.PortCon(nIdxCon).SrcBlock)
        alignSource(xBlockInfo.PortCon(nIdxCon).SrcBlock,...
                         xBlockInfo.PortCon(nIdxCon).Position(2)-45);
    end
end
return

% =========================================================================

function straightLine(hLine)
% STRAIGHTLINE correct line to minimal amount of nodes, if necessary.
% Prevents sawtooth style signal lines after copy and port change actions
% of Simulink blocks.
%
% Syntax:
%   straightLine(hLine)
%
% Inputs:
%   hLine - handle 
%
% Example: 
%   straightLine(hLine)

% get line information
xLI = slcLineInfo(hLine);

% if line has in minimum start and end point
if size(xLI.Points,1) > 2
    % if line has intermediate points with different vertical position than start and end point 
    if numel(unique(xLI.Points(:,2)')) > numel(unique([xLI.Points(1,2),xLI.Points(end,2)]))
        % delete line
        delete_line(xLI.Handle);
        
        % create line
        slcLinePortHandleCreate(xLI.SrcPortHandle,xLI.DstPortHandle,xLI.Name);
    end
end
return

% =========================================================================

function hLine = slcLinePortHandleCreate(hPortSource,hPortDest,sName)
% SLCLINEPORTHANDLECREATE create a line based on the adjacent porthandles
% with 'autorouting' switched on.
%
% Syntax:
%   slcLinePortHandleCreate(hPortSource,hPortDest)
%
% Inputs:
%   hPortSource - handle of source port (property 'SrcPortHandle' of line)
%     hPortDest - handle of destination port (property 'DstPortHandle' of line)
%         sName - string with name of signal (default: '')
%
% Outputs:
%
% Example: 
%   slcLinePortHandleCreate(hPortSource,hPortDest)

% check input arguments
if nargin < 3 
    sName = '';
end
if ~ishandle(hPortSource) && strcmp(get_param(hPortSource,'Type'),'port')
    error('slcLinePortHandleCreate:wrongArgument','The passed hPortSource is not a valid port handle.');
end
if ~ishandle(hPortDest) && strcmp(get_param(hPortDest,'Type'),'port')
    error('slcLinePortHandleCreate:wrongArgument','The passed hPortDest is not a valid port handle.');
end

% create outport information
nPortNumber = get_param(hPortSource,'PortNumber');
sParent = get_param(hPortSource,'Parent');
cParent = pathpartsSL(sParent);
sOutport = fullfileSL(cParent{end},num2str(nPortNumber));

% create inport information
nPortNumber = get_param(hPortDest,'PortNumber');
sParent = get_param(hPortDest,'Parent');
cParent = pathpartsSL(sParent);
sInport = fullfileSL(cParent{end},num2str(nPortNumber));

% create line
sSystem = fullfile(cParent{1:end-1});
hLine = add_line(sSystem,sOutport,sInport, 'autorouting','on');
set_param(hLine,'Name',sName);
return

% =========================================================================

function alignSource(hBlock,nPosition)
% ALIGNSOURCE align the specified block's outport to the vertical position,
% if the block is a single output source block or a block with one
% in-/outport each.
%
% Syntax:
%   alignSource(hBlock,vPosition)
%
% Inputs:
%      hBlock - handle of block
%   nPosition - integer with vertical position description in Simulink
%               notation
%
% Outputs:
%
% Example: 
%   alignSource(hBlock,vPosition)

% get block info
xBlockInfo = slcBlockInfo(hBlock);

% align block
if xBlockInfo.Ports(1) <= 1 &&... % one inport maximum
        xBlockInfo.Ports(2) <= 1 % one outport maximum
    vBlockHeight = xBlockInfo.Position(4)-xBlockInfo.Position(2);
    vBlockCorner = nPosition - floor(0.5*vBlockHeight);
    vPositionNew = [xBlockInfo.Position(1)...
                    vBlockCorner...
                    xBlockInfo.Position(3)...
                    vBlockCorner+vBlockHeight];
    set_param(hBlock,'Position',vPositionNew);
end

% align further source blocks
if xBlockInfo.Ports(1) == 1 && ishandle(xBlockInfo.PortCon(1).SrcBlock)
    alignSource(xBlockInfo.PortCon(1).SrcBlock,nPosition);
end
return

% =========================================================================

function alignDestination(hBlock,nPosition)
% ALIGNDESTINATION align the specified block's inport to the vertical position,
% if the block is a single input sink block or a block with one in-/outport
% each.
%
% Syntax:
%   alignDestination(hBlock,vPosition)
%
% Inputs:
%      hBlock - handle of block
%   nPosition - integer with vertical position description in Simulink
%               notation
%
% Outputs:
%
% Example: 
%   alignDestination(hBlock,vPosition)

% get block info
xBlockInfo = slcBlockInfo(hBlock);

% align block
if xBlockInfo.Ports(1) <= 1 &&... % one inport maximum
        xBlockInfo.Ports(2) <= 1 % one outport maximum
    vBlockHeight = xBlockInfo.Position(4)-xBlockInfo.Position(2);
    vBlockCorner = nPosition - floor(0.5*vBlockHeight);
    vPositionNew = [xBlockInfo.Position(1)...
                    vBlockCorner...
                    xBlockInfo.Position(3)...
                    vBlockCorner+vBlockHeight];
    set_param(hBlock,'Position',vPositionNew);
end

% align further destination blocks
if xBlockInfo.Ports(2) == 1 && ishandle(xBlockInfo.PortCon(sum(xBlockInfo.Ports(1:2))).DstBlock)
    alignDestination(xBlockInfo.PortCon(2).DstBlock,nPosition);
end
return
