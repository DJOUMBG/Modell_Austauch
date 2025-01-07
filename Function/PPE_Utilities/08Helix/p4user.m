function nStatus = p4user(sLogin,sFullName,sEmail)
% P4USER create or update info of a Helix user.
% CAUTION: requires superuser rights!
%
% Syntax:
%   nStatus = p4user(sLogin,sFullName,sEmail)
%
% Inputs:
%      sLogin - string with AD user ID (lower case)
%   sFullName - string with full name of user
%      sEmail - string with email address of user
%
% Outputs:
%   nStatus - integer (1x1) with status of system call 
%
% Example: 
%   nStatus = p4user(sLogin,sFullName,sEmail)
%
% See also: p4form
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2018-06-15



[nStatus,sMsg] = p4form('User',sLogin,'-f',...
    'Email',{sEmail},...
    'FullName',{sFullName});
if nStatus
    % failure of p4 command
    fprintf(2,'p4user failure with message:\n%s\n',sMsg);
end
return
