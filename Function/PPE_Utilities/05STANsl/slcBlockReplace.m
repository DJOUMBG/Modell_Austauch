function slcBlockReplace(sSource,sTarget)
% SLCBLOCKREPLACE replace a block by another block while maintaining size
% and signal connections.
% Part of Simulink custom package slc.
%
% Syntax:
%   slcBlockReplace(sSource,sTarget)
%
% Inputs:
%   sSource - string with Simulink block path
%   sTarget - string with Simulink block path 
%
% Outputs:
%
% Example: 
%   slcBlockReplace(sSource,sTarget)
%
% See also: pathpartsSL, slcBlockReplace, slcLoadEnsure
%
% Author: Rainer Frey, TP/EAC, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2013-02-14

% ensure availability of source block
cSource = pathpartsSL(sSource);
slcLoadEnsure(cSource{1});
if isempty(find_system(sSource,'SearchDepth',0))
    error('slcBlockReplace:blockNotInSource',['The specified block is not in the source model: ' sSource]);
end

% replace block
if ismdl(sTarget)
    % store info of target block
    nPosition = get_param(sTarget,'Position');
    % remove original block
    delete_block(sTarget);
else
    nPosition = get_param(sSource,'Position');
end
add_block(sSource,sTarget,'Position',nPosition);

% move block for secure connection
set_param(sTarget,'Position',nPosition + [0 1 0 1]);
set_param(sTarget,'Position',nPosition);
return
