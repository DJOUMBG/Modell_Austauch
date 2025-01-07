function slcMaskCreate(hBlock,xMask)
% SLCMASKCREATE create a Simulink Subsystem block mask with default values for multiple properties.
%
% Syntax:
%   slcMaskCreate(hBlock,xMask)
%
% Inputs:
%   hBlock - handle (1x1) of subsystem to apply mask
%    xMask - structure (1x1) with fields or [optional] cell array of string with variables 
%            (omits all other options though): 
%     .MaskVariables - string with variables definition of mask e.g. 'par1=@1;par2=@2;myPar=@3'
%     .MaskPrompts - [optional] cell (nx1) of strings with the prompts of variable value in the block mask
%     .MaskValues - [optional] cell (nx1) of strings with the values of the variables in the block mask
%     .MaskType - [optional] string with mask type
%     .MaskDescription - [optional] string with block description
%     ...
%
% Outputs:
%
% Example: 
%   slcMaskCreate(gcb,struct('MaskVariables',{'par1=@1;par2=@2;myPar=@3'}))
%   slcMaskCreate(gcb,struct('MaskVariables',{'par1=@1;par2=@2;myPar=@3'},'MaskValues',{'sMP.phys.test.par1','sMP.phys.test.par2','sMP.phys.test.myPar'}))
%   slcMaskCreate(gcb,{'par1','par2','myPar'}))
%
% See also: strGlue
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-8485-3325
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2022-09-14

%% check & patch input
if nargin < 1
    hBlock = gcb;
end
if nargin < 2
    xMask = struct;
end
% base definition of parameters
if iscell(xMask)
    % create default mask with parameter name cell array
    cMaskName = xMask;
    xMask = struct;
    cMaskVariable = cellfun(@(x,y)[x '=@' num2str(y)],cMaskName,num2cell(1:numel(cMaskName)),'UniformOutput',false);
    xMask.MaskVariables = strGlue(cMaskVariable,';'); 
    nVariable = numel(cMaskVariable);
elseif isstruct(xMask) && ...
        isfield(xMask,'MaskVariables')
    cMaskVariable = strsplitOwn(xMask.MaskVariables,';');
    cMaskName = regexprep(cMaskVariable,'\=@\d$','');
    nVariable = numel(cMaskVariable);
else
    error('missing definition of mask variables in slcMaskCreate interface');
end
if ~isfield(xMask,'MaskType')
    xMask.MaskType = '';
end
if ~isfield(xMask,'MaskDescription')
    xMask.MaskDescription = '';
end
if ~isfield(xMask,'MaskHelp')
    xMask.MaskHelp = '';
end
if ~isfield(xMask,'MaskPrompts')
    xMask.MaskPrompts = cMaskName;
end
if ~isfield(xMask,'MaskValues')
    xMask.MaskValues = repmat({'0'},nVariable,1);
end
if ~isfield(xMask,'MaskCallbacks')
    xMask.MaskCallbacks = repmat({''},nVariable,1);
end
if ~isfield(xMask,'MaskEnables')
    xMask.MaskEnables = repmat({'on'},nVariable,1);
end
if ~isfield(xMask,'MaskStyles')
    xMask.MaskStyles = repmat({'edit'},nVariable,1);
end
if ~isfield(xMask,'MaskTunableValues')
    xMask.MaskTunableValues = repmat({'on'},nVariable,1);
end
if ~isfield(xMask,'MaskToolTipsDisplay')
    xMask.MaskToolTipsDisplay = repmat({'on'},nVariable,1);
end
if ~isfield(xMask,'MaskVisibilities')
    xMask.MaskVisibilities = repmat({'on'},nVariable,1);
end
if ~isfield(xMask,'MaskVarAliases')
    xMask.MaskVarAliases = repmat({''},nVariable,1);
end
if ~isfield(xMask,'MaskTabNames')
    xMask.MaskTabNames = repmat({''},nVariable,1);
end

%% set mask values
set_param(hBlock,...
    'Mask','on',...
    'MaskType',xMask.MaskType,... % string
    'MaskDescription',xMask.MaskDescription,... % string ''
    'MaskHelp',xMask.MaskHelp,... % string ''
    'MaskVariables',xMask.MaskVariables,... % {10x1 cell} ''
    'MaskValues',xMask.MaskValues,... % {10x1 cell} 'sMP.sdf...'
    'MaskPrompts',xMask.MaskPrompts,... % {10x1 cell} 'Description prompt'
    'MaskCallbacks',xMask.MaskCallbacks,... % {10x1 cell} ''
    'MaskEnables',xMask.MaskEnables,... % {10x1 cell} 'on'
    'MaskStyles',xMask.MaskStyles,... % {10x1 cell} 'edit'
    'MaskTunableValues',xMask.MaskTunableValues,... % {10x1 cell} 'on'
    'MaskToolTipsDisplay',xMask.MaskToolTipsDisplay,... % {10x1 cell} 'on'
    'MaskVisibilities',xMask.MaskVisibilities,... % {10x1 cell} 'on'
    'MaskVarAliases',xMask.MaskVarAliases,... % {10x1 cell} ''
    'MaskTabNames',xMask.MaskTabNames); % {10x1 cell} ''

return