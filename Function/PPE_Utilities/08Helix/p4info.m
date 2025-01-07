function varargout = p4info(varargin)
% P4INFO reduced information set of p4 with basic client information
%
% Syntax:
%   p4info
%
% Inputs:
%
% Outputs:
%
% Example: 
%   p4info
%
% See also: p4, p4('info') 
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2018-11-30

cInfo = hlxOutParse(p4('info'),{': '},2,true);
cPrint = {'Broker address'
          'Server address'
          'Server uptime'
          'User name'
          'Client stream'
          'Client root'
          'Client name'};
[bPrint,nPrint] = ismember(cPrint,cInfo(:,1));
nPrint = nPrint(bPrint);

% print info output on command window
nFront = cellfun(@numel,cPrint);
nMax = max(nFront);
for nIdxHit = 1:numel(nPrint)
    fprintf(1,'%s%s: %s\n',repmat(' ',1,nMax+1-nFront(nIdxHit)),...
            cInfo{nPrint(nIdxHit),1},cInfo{nPrint(nIdxHit),2});
end

% create output
if nargout > 0
    if nargin > 0
        % specific field requested
        bRequest = strcmp(varargin{1},cInfo(:,1));
        if any(bRequest)
            varargout = cInfo(bRequest,2);
        else
            varargout = cInfo{''};
        end
    else
        % return complete cell
        varargout = {cInfo(nPrint,:)};
    end
end
return
