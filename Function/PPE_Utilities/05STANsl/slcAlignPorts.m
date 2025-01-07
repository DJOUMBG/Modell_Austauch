function slcAlignPorts(hSubsystem)
% SLCALIGNPORTS aligns all ports in the current subsystem vertically with
% their connected blocks.
%
% Syntax:
%   slcAlignPorts(hSubsystem)
%
% Inputs:
%   hSubsystem - handle (1x1) or blockpath  of a Simulink system with 
%                inport or outport blocks
%
% Outputs:
%
% Example: 
%   slcAlignPorts(hSubsystem)
%
% See also: slcBlockInfo
%
% Author: Rainer Frey, TP/EAC, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2019-12-04

if nargin == 0
    xSys = slcBlockInfo(gcb);
else
    xSys = slcBlockInfo(hSubsystem);
end

% Inports
cInport = find_system(xSys.BlockPath,'SearchDepth',1,'BlockType','Inport');
for k = 1:length(cInport)
    xPort = slcBlockInfo(cInport{k});
    xDst = slcBlockInfo(xPort.PortCon(1).DstBlock);
    nPosDst = xDst.PortCon(xPort.PortCon(1).DstPort+1).Position;
    nPortHeight = xPort.Position(4) - xPort.Position(2);
    nPosNew = [xPort.Position(1) nPosDst(2)-round(nPortHeight*0.5) ...
               xPort.Position(3) nPosDst(2)+round(nPortHeight*0.5)];
    set_param(xPort.Handle,'Position',nPosNew);
end

% Outports
OutportList = find_system(xSys.BlockPath,'SearchDepth',1,'BlockType','Outport');
for k = 1:length(OutportList)
    xPort = slcBlockInfo(OutportList{k});
    xSrc = slcBlockInfo(xPort.PortCon(1).SrcBlock);
    nPosSrc = xSrc.PortCon(xPort.PortCon(1).SrcPort+1).Position;
    nPortHeight = xPort.Position(4) - xPort.Position(2);
    nPosNew = [xPort.Position(1) nPosSrc(2)-round(nPortHeight*0.5) ...
               xPort.Position(3) nPosSrc(2)+round(nPortHeight*0.5)];
    set_param(xPort.Handle,'Position',nPosNew);
end
return