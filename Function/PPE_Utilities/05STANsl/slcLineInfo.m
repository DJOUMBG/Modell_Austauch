function xLine = slcLineInfo(hLine)
% SLCLINEINFO generates a structure with important line properties.
% Part of Simulink custom package slc.
%
% Syntax:
%   xLine = slcLineInfo(hLine)
%
% Inputs:
%   hLine - handle (1xn) of Simulink lines
%
% Outputs:
%   xLine - struct (1xn) with fields
%   .Name               - string 
%   .Handle             - double/handle
%   .Parent             - string with full path of parent
%   .Points             - vector (nx2) with position of line nodes
%   .SegmentType        - 'trunk' or 'branch'
%   .LineParent         - handle of "upstream" line if branched,  
%                         no parent: -1 
%   .LineChildren       - handles of branched lines from this line,  
%                         no children: [] empty 
%   .SrcPortHandle      - handle of outport of source block
%   .SrcBlockHandle     - handle of source block
%   .DstPortHandle      - handle of inport of destination block
%   .DstBlockHandle     - handle of destination block
%
% Example: 
%   xLine = slcLineInfo(gcl)
%
% See also: slcBlockInfo, gcl
%
% Author: Rainer Frey, TP/EAC, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2012-01-17

% check input
if nargin < 1
    hLine = gcl;
end

% reduce to line handles only
type = get_param(hLine,'Type');
tf = ismember(type,{'line'});
hLine = hLine(tf);

% initialize output structure
xLine = struct('Name',[],'Handle',[],'Parent',[],'Points',[],... 
            'SegmentType',[],'LineParent',[],'LineChildren',[],...
            'SrcPortHandle',[],'SrcBlockHandle',[],'DstPortHandle',[],...
            'DstBlockHandle',[]);
        
% get line information
for k = 1:numel(hLine)
        xLine(k).Name = get_param(hLine(k),'Name');
        xLine(k).Handle = get_param(hLine(k),'Handle');
        xLine(k).Parent = get_param(hLine(k),'Parent');
        xLine(k).Points = get_param(hLine(k),'Points');
        xLine(k).SegmentType = get_param(hLine(k),'SegmentType');
        xLine(k).LineParent = get_param(hLine(k),'LineParent');
        xLine(k).LineChildren = get_param(hLine(k),'LineChildren');
        xLine(k).SrcPortHandle = get_param(hLine(k),'SrcPortHandle');
        xLine(k).SrcBlockHandle = get_param(hLine(k),'SrcBlockHandle');
        xLine(k).DstPortHandle = get_param(hLine(k),'DstPortHandle');
        xLine(k).DstBlockHandle = get_param(hLine(k),'DstBlockHandle');
end
return