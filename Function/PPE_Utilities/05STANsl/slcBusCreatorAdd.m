function [hBlock,nPosIn,nPosOut] = slcBusCreatorAdd(hParent,sName,nInport,nPosition)
% SLCBUSCREATORADD adds a Simulink BusCreator block in the specified position.
% Further the block name is hidden and the connector ports positions are
% returned in addition to the block handle.
%
% Syntax:
%   [hBlock,nPosIn,nPosOut] = slcBusCreatorAdd(hParent,sName,nInport,nPosition)
%
% Inputs:
%     hParent - handle or string with blockpath of parent system
%       sName - string with block name
%     nInport - integer (1x1) with number of inports in BusCreator
%   nPosition - integer (1x4) with block position
%
% Outputs:
%    hBlock - handle of added block
%    nPosIn - integer (nx2) poisions of inports
%   nPosOut - integer (1x2) position of outport
%
% Example: 
%   [hBlock,nPosIn,nPosOut] = slcBusCreatorAdd(hParent,sName,nInport,nPosition)
%
% See also: slcSubSystemAdd,slcInportAdd, slcOutportAdd 
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2015-10-22

% check input 
if ~ismdl(hParent)
    error('slcSubsystemAdd:invalidParentSystem',...
          'The specified parent system "%s" is not available', hParent)
end
if ishandle(hParent)
    hParent = getfullname(hParent);
end
if isempty(sName)
    sName = 'BusCreator';
end

% add bus creator
hBlock = add_block('built-in/BusCreator',fullfileSL(hParent,sName));
set_param(hBlock,'Position',nPosition,'Inputs',num2str(nInport),'ShowName','off');

% get port positions
xPortCon = get_param(hBlock,'PortConnectivity');
nPos = reshape([xPortCon.Position],2,nInport+1)';
nPosIn = nPos(1:end-1,:);
nPosOut = nPos(end,:);
return
