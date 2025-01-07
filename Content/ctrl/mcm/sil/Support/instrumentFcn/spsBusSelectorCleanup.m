function spsBusSelectorCleanup(hBlock,sMP)
% SPSBUSSELECTORCLEANUP check the output signals of a BusSelector against
% the available signals in the current DIVe MB model.
% To be used as "CopyFcn" of a block.
%
% Syntax:
%   spsBusSelectorCleanup(hBlock,sMP)
%
% Inputs:
%   hBlock - handle of BusSelector block within DIVe MB Model
%      sMP - structure of DIVe ModelBased
%
% Example: 
%   spsBusSelectorCleanup(gcb,sMP)
%
% See also: strGlue, strsplitOwn
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2016-03-16

% check input
if ~isfield(sMP,'link') || ~isfield(sMP.link,'bus')
    fprintf(2,['spsBusSelectorCleanup - Cleanup of BusSelector failed as ' ...
               'no full sMP of DIVe MB is available: \n%s\n'],...
               getfullname(hBlock));
end

% get signals of BusSelector
sOutputSignals = get_param(fullfileSL(getfullname(hBlock),'BusSelectorMain'),'OutputSignals');
cOutputSignal = strsplitOwn(sOutputSignals,',');

% check signals for existence in model
for nIdxSignal = 1:numel(cOutputSignal)
    % split bus signal into single elements
%     cBus = strsplitOwn(cOutputSignal{nIdxSignal},'.');
    ccBus = textscan(cOutputSignal{nIdxSignal}, '%s', 'Delimiter','.');
    
    sBus = regexp(ccBus{1}{1},'^\w+','match','once');
    sSignal = ccBus{1}{2};
    
    % reset signal to ground terminator if not in present in model
    if ~ (isfield(sMP.link.bus,sBus) && isfield(sMP.link.bus.(sBus),'port') && ...
            any(strcmp(sSignal,{sMP.link.bus.(sBus).port.name})))
        cOutputSignal{nIdxSignal} = 'term [Bus].term';
    end
end

% set signals of BusSelector
set_param(fullfileSL(getfullname(hBlock),'BusSelectorMain'),'OutputSignals',strGlue(cOutputSignal,','));
return
