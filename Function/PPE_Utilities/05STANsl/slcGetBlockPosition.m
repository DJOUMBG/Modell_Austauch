function nPos = slcGetBlockPosition(hBlock)
% SLCGETBLOCKPOSITION get position of passed or current block and store
% it with MATLAB main GUI.
% Part of Simulink custom package slc.
%
% Syntax:
%   nPos = slcGetBlockPosition(hBlock)
%
% Inputs:
%   hBlock - handle of Simulink block
%
% Outputs:
%   nPos - vector (1x4) with left and upper border, width and height from
%          left upper window edge
%
% Example: 
%   nPos = slcGetBlockPosition(gcb)
%
%
% Subfunctions: sl2gui
%
% See also: slcSetBlockPosition, gcb
%
% Author: Rainer Frey, TP/EAC, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2008-12-04

% get current block if not specified
if nargin == 0
    hBlock = gcb;
end

% get block position
xBlock = slcBlockInfo(hBlock);
nPos = xBlock.Position;

% translate position
nPos = sl2gui(nPos);

% set in clipboard
setappdata(0,'ClipBoardslcBlockPosition',nPos);
if nargout == 0
    disp(['Stored block position (GUI notation): ' num2str(nPos)]);
end
return

% =========================================================================

function nPos = sl2gui(nPos)
% SL2GUI convert Simulink position to GUI style position vector
%
% Syntax:
%   nPos = sl2gui(nPos)
%
% Inputs:
%   nPos - vector (1x4) with left, upper, right and lower border from left 
%          upper window edge
%
% Outputs:
%   nPos - vector (1x4) with left and upper border, width and height from
%          left upper window edge
%
% Example: 
%   pos = sl2gui(nPos)

nPos(3) = nPos(3)-nPos(1);
nPos(4) = nPos(4)-nPos(2);
return
