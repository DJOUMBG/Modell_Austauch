function sPathBlockRef = slcDisableLink(hBlock)
% SLCDISABLELINK disable the library link of a Simulink block any parent subsystem. Needed to
% change the model content or properties of the the block or any system
% below.
% Part of Simulink custom package slc.
%
% Syntax:
%   sPathBlockRef = slcDisableLink(hBlock)
%
% Inputs:
%   hBlock - handle (1x1) or string with blockpath of a Simulink block 
%
% Outputs:
%   sPathBlockRef - string with path of the block "hBlock" in the library
%                   e.g. full path of the input "hBlock" is 
%                   system/subsys1/subsys2/blockName and subsys1 is a link 
%                   to the library "lib1" then sPathBlockRef becomes 
%                   "lib1/subsys1/subsys2/blockName".
%
% Example: 
%   sPathBlockRef = slcDisableLink(gcb)
%
% See also: pathpartsSL, slcLoadEnsure
%
% Author: Rainer Frey, TP/EAC, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2013-03-26

% initialize output
sPathBlockRef = '';

% generate full block path
sBlockName = get_param(hBlock,'Name');
sBlockParent = get_param(hBlock,'Parent');
if isempty(sBlockParent)
    sBlockPath = sBlockName;
else
    sBlockPath = [sBlockParent '/' strrep(sBlockName,'/','//')];
end

% generate cell with blockpath elements (do not use strfind with '/' onto
% the full block path as slash can also be in the block name)
cBlockPath = pathpartsSL(sBlockPath);

% The for-loop is until the parent index is 2 since if nIdxParent = 1 
% then it is the top level model which doesn't have the property "LinkStatus"
for nIdxParent = length(cBlockPath):-1:2
   sParentCurrent = fullfileSL(cBlockPath(1:nIdxParent));
   linkStatus = get_param(sParentCurrent,'LinkStatus');
   if strcmp(linkStatus,'resolved')
       set_param(sParentCurrent,'LinkStatus','inactive');
       if nIdxParent == length(cBlockPath)
           sPathBlockRef = get_param(sParentCurrent,'AncestorBlock');
       else
           sPathBlockRef = fullfileSL([{get_param(sParentCurrent,'AncestorBlock')} cBlockPath(nIdxParent:end)]);
       end
       return
   end
end
return

