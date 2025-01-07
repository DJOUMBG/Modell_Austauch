function dstSetMaskToSMP(hBlock,sSMPPath)
% DSTSETMASKTOSMP adds sMP structure path to a Simulink block mask, 
% holds only simple value assignments"
%
% Syntax:
%   dstSetMaskToSMP(hBlock,sSMPPath)
%
% Inputs:
%   hBlock - handle of simulink chart with mask, but only simple values 
%   sSMPPath - string of sMP path to be added to all parameter values
%
% Outputs:
%
% Example: 
%   dstSetMaskToSMP(gcb,'sMP.ctrl.tcm.')
%
% See also: 
%
% Author: Peter Hamann, TP/EAD Daimler AG
%  Phone: +49-711-17-24290
% MailTo: peter.hamann@daimler.com
%   Date: 2015-10-01

% check input
if nargin < 1
    hBlock = gcb;
    sSMPPath = 'sMP.context.species.'
end

% determine model and save location
sModel = bdroot(hBlock);
set_param(sModel,'Lock','off');

% get mask and parameter information
hParent = get_param(hBlock,'Parent');
sMaskVariables = get_param(hBlock,'MaskVariables');
cMaskValues = get_param(hBlock,'MaskValues');
cMaskPrompts = get_param(hBlock,'MaskPrompts');

for i1=1:length(cMaskValues)
   if regexp(cMaskValues{i1}(length(cMaskValues{i1})-2:end),'_0') > 0
        cMaskValues{i1}= [sSMPPath, 'out.', cMaskValues{i1}(1:end-2)];
   else 
        cMaskValues{i1}= [sSMPPath, cMaskValues{i1}];
   end
end

set_param(hBlock,...
    'Mask','on',...
    'MaskVariables',sMaskVariables,...
    'MaskPrompts',cMaskPrompts,...
    'MaskValues',cMaskValues);

% save model library
open_system(sModel);
save_system(sModel);
return