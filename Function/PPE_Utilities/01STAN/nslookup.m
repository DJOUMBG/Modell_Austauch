function xClient = nslookup(cQuery)
% NSLOOKUP nslookup wrapper to for domain namespace lookups and translation
% of network client names to/from IP addresses. 
%
% Syntax:
%   xClient = nslookup(cQuery)
%
% Inputs:
%   cQuery - cell (1xn) with strings of IP or DNS queries, 
%            [or string with single IP or DNS query]
%
% Outputs:
%   xClient - structure (1xn) with fields:
%      .IP  - string with IP address of machine
%      .DNS - string with DNS name of machine
%
% Example: 
%   xClient = nslookup('53.53.12.146')
% 
% See also: hlxServerLicenseUpdate
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-8485-3325
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2020-09-16

% check input
if ischar(cQuery)
    cQuery = {cQuery};
end

for nIdxQuery = 1:numel(cQuery)
    % check reachability via nslookup
    [nStatus,sMsg] = system(sprintf('nslookup %s',cQuery{nIdxQuery}));
    cOut = hlxOutParse(sMsg,{':',' '},2,true);
    
    % determine results
    nName = find(strcmp('Name',cOut(:,1)));
    if isempty(nName) || nStatus
        xClient(nIdxQuery).IP = ''; %#ok<AGROW>
        xClient(nIdxQuery).DNS = ''; %#ok<AGROW>
    else
        xClient(nIdxQuery).IP = cOut{nName+1,2}; %#ok<AGROW>
        xClient(nIdxQuery).DNS = cOut{nName,2}; %#ok<AGROW>
    end
end
return