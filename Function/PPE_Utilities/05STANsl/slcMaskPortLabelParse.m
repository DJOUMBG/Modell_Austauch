function [nStatus,cInport,cOutport] = slcMaskPortLabelParse(hBlock)
% SLCMASKPORTLABELPARSE parses port names from port_label statements in the
% display string of a block mask. Used sometimes for special blocks like
% s-functions, FMU or other.
%
% Syntax:
%   [nStatus,cInport,cOutport] = slcMaskPortLabelParse(hBlock)
%
% Inputs:
%   hBlock - handle (1x1) of a masked block
%
% Outputs:
%    nStatus - integer (1x1) if parsed port names match block's inports and
%              outports, 0: port numbers match, 1: mismatch in port numbers
%    cInport - cell (mx1) with strings of inport names 
%   cOutport - cell (mx1) with strings of outport names 
%
% Example: 
%   [nStatus,cInport,cOutport] = slcMaskPortLabelParse(gcb)
%
% See also: strsplitOwn
%
% Author: Rainer Frey, TP/EAF, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2021-02-18

% check input
if nargin < 0
    hBlock = gcb;
end

% initialize output
nStatus = 0;

% get Mask display content
sDisp = get_param(hBlock,'MaskDisplay');
cLine = strsplitOwn(sDisp,{char(10),';'},true); %#ok<CHARTEN>

% parse portnames from display label
cInport = cell(numel(cLine),1);
cOutport = cell(numel(cLine),1);
for nIdxLine = 1:numel(cLine)
    % split line
    cOut = strsplitOwn(cLine{nIdxLine},{'''','(',',',')'},true);
    if numel(cOut)==4 && strcmp(cOut{1},'port_label')
        if strcmp(cOut{2},'input')
            cInport{str2double(cOut{3})} = cOut{4};
        elseif strcmp(cOut{2},'output')
            cOutport{str2double(cOut{3})} = cOut{4};
        end
    end % if port_label
end % for line

% compress port cells
cInport = cInport(~cellfun(@isempty,cInport));
cOutport = cOutport(~cellfun(@isempty,cOutport));

% validate parsed ports against block ports
nPort = get_param(hBlock,'Ports');
if numel(cInport)~=nPort(1)
    fprintf(2,['slcMaskPortLabelParse:InportWrongNumber - inport name ' ...
        'parsing from mask display returned wrong number of ports ' ...
        '(parse %i vs. Block %i)!\n'],numel(cInport),nPort(1))
    nStatus = 1;
end
if numel(cOutport)~=nPort(2)
    fprintf(2,['slcMaskPortLabelParse:OutportWrongNumber - Outport name ' ...
        'parsing from mask display returned wrong number of ports ' ...
        '(parse %i vs. Block %i)!\n'],numel(cOutport),nPort(2))
    nStatus = 1;
end
return