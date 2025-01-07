function slcSetBlockPosition(hBlock,nPos)
% SLCSETBLOCKPOSITION sets a simulink block position with MATLAB GUI
% block size logic. The block size is specified here directly with width
% (pos(3)) and height (pos(4)) instead of specifying the absolute border
% values.
% Part of Simulink custom package slc.
%
% Syntax:
%   slcSetBlockPosition(hBlock,nPos)
%
% Inputs:
%   hBlock - handle (1xn) or string or cell with strings of Simulink block paths
%     nPos - vector (1x4) with position information of block to be set
%                 value of -1 means to keep original value of position
%                 vector
%                 1: distance of left block border to left system border
%                 2: distance of upper block border to upper system border
%                 3: distance of left block border to right block border
%                 4: distance of left block border to left block border
%
% Outputs:
%
% Example: 
%   slcSetBlockPosition(gcb,[-1 -1 400 200])
%
% Subfunctions: gui2sl, sl2gui
%
% See also: slcSetBlockPosition
%
% Author: Rainer Frey, TP/EAC, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2008-12-04

cl = slcBlockInfo(hBlock);

for k = 1:length(cl)
    % build position vector
    nPosNew = cl(k).Position;
    nPosNew = sl2gui(nPosNew); % convert position vector
    bPosReplace = (nPos ~= -1);
    nPosNew(bPosReplace) = nPos(bPosReplace);
    
    % set new position in block
    nPosNew = gui2sl(nPosNew); % convert position vector
    set_param(cl(k).Handle,'Position',nPosNew);
end
return

% =========================================================================

function nPos = sl2gui(nPos)
% SL2GUI convert Simulink position to GUI style position
%
% Syntax:
%   nPos = sl2gui(nPos)
%
% Inputs:
%   nPos - integer (1x4) with left, upper, right and lower border
%                  from left upper window edge
%
% Outputs:
%   nPos - integer (1x4) with left and upper border, width and height 
%                  from left upper window edge
%
% Example: 
%   nPos = sl2gui([100 100 250 175])

nPos(3) = nPos(3)-nPos(1);
nPos(4) = nPos(4)-nPos(2);
return

% =========================================================================

function nPos = gui2sl(nPos)
% GUI2SL convert GUI style position to Simulink position
%
% Syntax:
%   nPos = gui2sl(nPos)
%
% Inputs:
%   nPos - integer (1x4) with left and upper border from left upper 
%                  window edge and block width and height 
%
% Outputs:
%   nPos - integer (1x4) with left, upper, right and lower border
%                  from left upper window edge
%
% Example: 
%   nPos = gui2sl([100 100 150 75])

nPos(3) = nPos(3)+nPos(1);
nPos(4) = nPos(4)+nPos(2);
return