function p4syncAll
% P4SYNCALL sync all clients of this computer and current user.
%
% Syntax:
%   p4syncAll
%
% Example: 
%   p4syncAll
%
% See also: p4, p4syncAll
%
% Author: Rainer Frey, TP/EAC, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2019-01-22

% get list of clients of this user
[sUser,sHost] = getenvOwn({'username','computername'});
cClient = hlxOutParse(p4('clients','-u',lower(sUser)),' ',5,true);

% limit to clients of this computer
bThis = ~cellfun(@isempty,regexpi(cClient(:,2),sHost,'once'));
cClient = cClient(bThis,:);

for nIdxClient = 1:size(cClient,1)
    % sync particular client
    p4('-c',cClient{nIdxClient,2},'sync');
end
return