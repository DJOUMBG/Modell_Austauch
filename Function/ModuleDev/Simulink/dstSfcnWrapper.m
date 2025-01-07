function dstSfcnWrapper(hBlock,sName) 
% DSTSFCNWRAPPER create a subsystem around an s-function with the same
% portnames as specified in the s-function mask display.
% Part of DIVe Simulink Transfer Package dst
%
% Syntax:
%   dstSfcnWrapper(hBlock)
%
% Inputs:
%   hBlock - handle of s-function block
%    sName - string with name of block
%
% Outputs:
%
% Example: 
%   dstSfcnWrapper(gcb)
%
% See also: fullfileSL, slcBlockInfo, slcInportAdd, slcOutportAdd, 
%           slcSetBlockPosition
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2014-08-01

% input check
if nargin < 1
    hBlock = gcb;
end
if nargin < 2
    sName = 'spe_fam_typ_mdl';
end

% add subsystem
hSystem = add_block('built-in/SubSystem',fullfileSL(get_param(hBlock,'Parent'),sName),'MakeNameUnique', 'on');
sBlockPathSystem = fullfileSL(get_param(hSystem,'Parent'),get_param(hSystem,'Name'));
slcSetBlockPosition(hSystem,[40 40 160 60]);
set_param(hSystem,'Backgroundcolor','darkGreen');
Simulink.SubSystem.deleteContents(hSystem); % delete default subssystem content

% move sfcn model into subsystem
hBlockOld = hBlock;
hBlock = add_block(hBlockOld,fullfileSL(sBlockPathSystem,get_param(hBlockOld,'Name')),'MakeNameUnique', 'on');
delete_block(hBlockOld);

% get mask display of sfcn block
sMaskDisplay = get_param(hBlock,'MaskDisplay');
cInportName = regexp(sMaskDisplay,'(?<=port_label\(''input'',\W*\d+\W*,\W*'')[a-zA-Z0-9\._]+','match'); % get inport names
cOutportName = regexp(sMaskDisplay,'(?<=port_label\(''output'',\W*\d+\W*,\W*'')[a-zA-Z0-9\._]+','match'); % get outport names

% resize sfcn according port numbers
slcSetBlockPosition(hBlock,[400 50 400 40*max(numel(cInportName),numel(cOutportName))]);
xBI = slcBlockInfo(hBlock); % get general block info

% add inports
for nIdxInport = 1:xBI.Ports(1)
    slcInportAdd(sBlockPathSystem,cInportName{nIdxInport},xBI.PortCon(nIdxInport).Position,[-250 0]);
end

% add outports
for nIdxOutport = 1:xBI.Ports(2)
    slcOutportAdd(sBlockPathSystem,cOutportName{nIdxOutport},xBI.PortCon(xBI.Ports(1)+nIdxOutport).Position,[+250 0]);
end

% resize subsystem according port numbers
slcSetBlockPosition(sBlockPathSystem,[-1 -1 400 40*max(numel(cInportName),numel(cOutportName))]);

% enable mask
set_param(hSystem,'Mask','on');

% transfer subsystem mask 
if strcmp(get_param(hBlock,'Mask'),'on')
    set_param(hSystem,...
        'MaskVariables',get_param(hBlock,'MaskVariables'),...
        'MaskStyles',get_param(hBlock,'MaskStyles'),...
        'MaskPrompts',get_param(hBlock,'MaskPrompts'),...
        'MaskValues',get_param(hBlock,'MaskValues'),...
        'MaskTunableValues',get_param(hBlock,'MaskTunableValues'),...
        'MaskEnables',get_param(hBlock,'MaskEnables'));
end

%% correction of masknames according s-function
% get parameters of s-function
sSfcnParameters = get_param(hBlock,'Parameters'); % get s-function parameters
cSfcnParameter = strsplitOwn(sSfcnParameters,{',',' '}); 
cSfcnParameter = strtrim(cSfcnParameter); % remove leading and trailing blanks

% get the low level mask info
sMaskVariable = get_param(hBlock,'MaskVariables'); % get variables of low level mask (s-function)
cMaskVariable = strsplitOwn(sMaskVariable,';'); 
cMaskVariable = regexp(cMaskVariable,'^[^\=]+','match','once');
cMaskVariable = strtrim(cMaskVariable);
cMaskValue = get_param(hBlock,'MaskValues');

% bridge the low level mask
bInMask = ismember(cMaskVariable,cSfcnParameter);
for nIdxParameter = find(bInMask)'
    cMaskValue{nIdxParameter} = cMaskVariable{nIdxParameter};
end
set_param(hBlock,'MaskValues',cMaskValue);
% as the high level mask is a complete copy of the low level mask, the
% variable names in the high level mask should equal now the values in the
% low level mask, which has the same name again as variable name. The
% variable name matches the s-function dialogue entries.

%% open subsystem view
open_system(get_param(hSystem,'Parent'))
return
