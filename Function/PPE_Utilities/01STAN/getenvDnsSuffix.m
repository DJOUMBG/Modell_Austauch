function sSuffix = getenvDnsSuffix
% GETENVDNSSUFFIX determine the (primary) DNS-Suffix of the current
% computer.
%
% Syntax:
%   sSuffix = getenvDnsSuffix
%
% Inputs:
%
% Outputs:
%   sSuffix - string with DNS-Suffix (most likely the primary, e.g. destr.corpintra.net) 
%
% Example: 
%   sSuffix = getenvDnsSuffix
%
% See also: strsplitOwn
%
% Author: Rainer Frey, TP/EAF, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2021-05-28

% init output
sSuffix = '';

% get ip adapter settings
[nStatus,sMsg] = system('ipconfig /all'); %#ok<ASGLU>
cLine = strsplitOwn(sMsg,char(10));

% search for suffix
nSuffix = find(~cellfun(@isempty,regexpi(cLine,'DNS[\s\-]Suffix.+\.net','once')));
if isempty(nSuffix)
    fprintf(2,'getenvDnsSuffix - DNS Suffix of machine was not found.\n')
    return
end
sSuffix = regexpi(strtrim(cLine{nSuffix(1)}),'[\w\.]+\.net$','match','once');
return