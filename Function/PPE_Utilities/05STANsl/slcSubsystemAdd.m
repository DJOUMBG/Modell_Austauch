function [hBlock,xInport,xOutport] = slcSubsystemAdd(hParent,sName,cInport,cOutport,nPosition,sBackgroundColor)
% SLCSUBSYSTEMADD add subsystem with specified name, ports, position and color.
% Part of Simulink custom package slc.
%
% Syntax:
%   [hBlock,xInport,xOutport] = slcSubsystemAdd(hParent,sName,cInport,cOutport,nPosition,sBackgroundColor)
%
% Inputs:
%            hParent - handle or string with block path of parent system
%              sName - string with subsystem name
%            cInport - cell (1xm) with strings of inport names
%           cOutport - cell (1xn) with strings of outport names
%          nPosition - integer (1x4) with position of Simulink Block
%   sBackgroundColor - string with vector (1x3) of RGB colors e.g. '[0.6 0.7 0.84]' 
%
% Outputs:
%            hBlock - handle of new subsystem
%           xInport - structure with fields:
%              .handle  - handle of port block
%              .nPosInt - integer (1x2) with internal port position
%              .nPosExt - integer (1x2) with external port position
%          xOutport - structure with fields:
%              .handle  - handle of port block
%              .nPosInt - integer (1x2) with internal port position
%              .nPosExt - integer (1x2) with external port position
%
% Example: 
%   [hBlock,xInport,xOutport] = slcSubsystemAdd('test','Sub1',{'bIn1','bIn2'},{'bOut1','bOut2'},[50 50 350 150],[0.9 0.9 0.93])
%
% See also: fullfileSL, ismdl
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2015-10-15

% check input 
if ~ismdl(hParent)
    error('slcSubsystemAdd:invalidParentSystem',...
          'The specified parent system "%s" is not available', hParent)
end
% ensure parent as string of simulink block path
if ishandle(hParent)
    hParent = getfullname(hParent);
end
if nargin < 6
    sBackgroundColor = '[1 1 1]';
end 
if isnumeric(sBackgroundColor) && numel(sBackgroundColor) == 3
    sBackgroundColor = sprintf('[%6.4f %6.4f %6.4f]',sBackgroundColor(1),...
                                sBackgroundColor(2),sBackgroundColor(3));
end

% add subsystem
hBlock = add_block('built-in/SubSystem',fullfileSL(hParent,sName));
set_param(hBlock,'Position',nPosition,'BackgroundColor',sBackgroundColor)

% add inports
xInport = struct('handle',{},'nPosInt',{},'nPosExt',{});
for nIdxPort = 1:numel(cInport)
    xInport(nIdxPort).handle = add_block('built-in/Inport',...
                                  fullfileSL(hParent,sName,cInport{nIdxPort}));
    set_param(xInport(nIdxPort).handle,'Position',[50 nIdxPort*50 80 nIdxPort*50+14]);
    xPortCon = get_param(xInport(nIdxPort).handle,'PortConnectivity');
    xInport(nIdxPort).nPosInt = xPortCon(1).Position;
end

% add outports
xOutport = struct('handle',{},'nPosInt',{},'nPosExt',{});
for nIdxPort = 1:numel(cOutport)
    xOutport(nIdxPort).handle = add_block('built-in/Outport',...
                                  fullfileSL(hParent,sName,cOutport{nIdxPort})); 
    set_param(xOutport(nIdxPort).handle,'Position',[970 nIdxPort*50 1000 nIdxPort*50+14]);
    xPortCon = get_param(xOutport(nIdxPort).handle,'PortConnectivity');
    xOutport(nIdxPort).nPosInt = xPortCon(1).Position;
end

% get external port positions
xPortCon = get_param(hBlock,'PortConnectivity');
for nIdxPort = 1:numel(cInport)
    xInport(nIdxPort).nPosExt = xPortCon(nIdxPort).Position;
end
for nIdxPort = 1:numel(cOutport)
    xOutport(nIdxPort).nPosExt = xPortCon(numel(cInport)+nIdxPort).Position;
end
return
