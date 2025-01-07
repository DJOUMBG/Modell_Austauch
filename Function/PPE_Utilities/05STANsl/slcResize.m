function slcResize(hBlock,nSpace)
% SLCRESIZE resize block according signal/port count.
% Part of Simulink custom package slc.
%
% Syntax:
%   slcResize(hBlock)
%   slcResize(hBlock,nSpace)
%
% Inputs:
%   hBlock - handle of Simulink block
%   nSpace - integer with Simulink position spacing per port.
%
% Outputs:
%
% Example: 
%   slcResize(gcb)
%   slcResize(gcb,50)
%
% See also: slcBlockInfo
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2014-06-23

% input check
if nargin < 1
    hBlock = gcb;
end
if nargin < 2
    nSpace = 40;
end

% get current block values
nPortMax = max(get_param(hBlock,'Ports'));
nPosition = get_param(hBlock,'Position');

% set new vertical block spacing
nPosition(4) = nPosition(2)+nSpace*nPortMax;
set_param(hBlock,'Position',nPosition);
return