function [sBlockPath,hLine] = slcInportAdd(hSystem,sName,nPosition,nOffset)
% SLCINPORTADD adds an inport block to with an offset to a block port
% position.
%
% Syntax:
%   [sBlockPath,hLine] = slcInportAdd(hSystem,sName,nPosition,nOffset)
%
% Inputs:
%     hSystem - handle of parent system to place inport in 
%       sName - string with name of inport
%   nPosition - integer (1x2) with position of block port with target
%               connection
%     nOffset - integer (1x2) with offset vector of inport's open port
%
% Outputs:
%   sBlockPath - string with block path of added port block
%        hLine - handle of connection line between port block and specified
%                position
%
% Example: 
%   xPortCon = get_param(gcb,'PortConnectivity')
%   [sBlockPath,hLine] = slcInportAdd(hSystem,'TestPort',xPortCon(1).Position,[-250 0])
%
% See also: fullfileSL, slcSetBlockPosition
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2014-08-01

% create target block path string
sBlockPath = fullfileSL(get_param(hSystem,'Parent'),get_param(hSystem,'Name'),sName);

% add block
hBlock = add_block('built-in/Inport',sBlockPath,...
                   'MakeNameUnique', 'on');
               
% align block with connecting position
slcSetBlockPosition(hBlock,[nPosition+nOffset+[-30 -7] 30 14]);

% add line
hLine = add_line(hSystem,[nPosition+nOffset; nPosition]);
set_param(hLine,'Name',sName);
return