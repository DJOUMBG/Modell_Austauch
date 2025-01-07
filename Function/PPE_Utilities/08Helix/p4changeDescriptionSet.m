function  nStatus = p4changeDescriptionSet(nChange,sDescription)
% P4CHANGEDESCRIPTIONSET set the description text of the specified
% changelist.
% CAUTION: requires superuser rights!
%
% Syntax:
%   nStatus = p4changeDescriptionSet(nChange,sDescription)
%
% Inputs:
%   nChange - integer (1x1) with changelist number
%   sDescription - char (1xn) with text of changelist description
%
% Outputs:
%   nStatus - integer (1x1) with system call feedback (0 = no error)
% 
% Example: 
%   nStatus = p4changeDescriptionSet(51,'blabla')
%
% See also: strGlue, p4
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2018-06-14

% combine input arguments
[nStatus,sMsg] = p4form('change',num2str(nChange,'%i'),'-f','Description',{sDescription});

% system call
if nStatus
    % failure of p4 command
    fprintf(2,'p4changeDescriptionSet failure with message:\n%s\n',sMsg);
end
return