function sMsg = p4logtail(nLine)
% P4LOGTAIL wrapper of p4 logtail with easy user definition of end lines to
% be displayed (rough estimate).
%
% Syntax:
%   sMsg = p4logtail(nLine)
%
% Inputs:
%   nLine - integer (1x1) lines to be displayed
%
% Outputs:
%   sMsg - string with tail of log
%
% Example: 
%   sMsg = p4logtail(20)
%
% See also: p4
%
% Author: Rainer Frey, TP/EAC, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2020-08-14

% check input
if nargin < 1
    nLine = 1000;
end

% determine logtail basics
sMsg = p4('logtail');
sOffset = regexp(sMsg(end-25:end),'(?<=offset )\d+','match','once');
nByteLine = ceil(numel(sMsg)/(sum(sMsg==char(10))-6)); %#ok<CHARTEN>
if isempty(sOffset)
    fprintf(2,'Could not determine offset from end of p4 logtail output. Stopped p4logtail.')
    return
else
    nOffset = str2double(sOffset);
end

% get full message scope
sMsg = p4(sprintf('logtail -s %i',nOffset-nLine*nByteLine));
return