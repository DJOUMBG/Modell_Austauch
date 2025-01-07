function [hBlock,nPosIn,nPosOut] = slcBusSelectorAdd(hParent,sName,cSignal,nPosition)
% SLCBUSSELECTORADD adds a Simulink BusSelector block in the specified
% position. Further the block name is hidden, specified signal names are
% extracted from the bus and the connector ports positions are returned in
% addition to the block handle.
%
% Syntax:
%   [hBlock,nPosIn,nPosOut] = slcBusSelectorAdd(hParent,sName,cSignal,nPosition)
%
% Inputs:
%     hParent - handle or string with blockpath of parent system
%       sName - string with block name
%     cSignal - cell (1xn) of strings with signal entries to be extracted
%               from the bus as BusSelector Outports
%   nPosition - integer (1x4) with block position
%
% Outputs:
%    hBlock - handle of added block
%    nPosIn - integer (1x2) poisions of inport
%   nPosOut - integer (nx2) position of outports
%
% Example: 
%   [hBlock,nPosIn,nPosOut] = slcBusSelectorAdd(hParent,sName,cSignal,nPosition)
%
% See also: slcSubSystemAdd,slcInportAdd, slcOutportAdd, fullfileSL
%
% Author: Rainer Frey, TP/EAF, Daimler AG
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
    sName = 'BusSelector';
end

% add bus creator
hBlock = add_block('built-in/BusSelector',fullfileSL(hParent,sName));
set_param(hBlock,'Position',nPosition,'OutputSignals',strGlue(cSignal,','),'ShowName','off');

% get port positions
xPortCon = get_param(hBlock,'PortConnectivity');
nPos = reshape([xPortCon.Position],2,numel(cSignal)+1)';
nPosIn = nPos(1,:);
nPosOut = nPos(2:end,:);
return
