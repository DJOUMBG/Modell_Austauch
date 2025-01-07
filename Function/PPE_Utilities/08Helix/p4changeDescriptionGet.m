function sDescription = p4changeDescriptionGet(nChange)
% P4CHANGEDESCRIPTIONGET get the description text of the specified
% changelist.
%
% Syntax:
%   sDescription = p4changeDescriptionGet(nChange)
%
% Inputs:
%   nChange - integer (1x1) with changelist number
%
% Outputs:
%   sDescription - char (1xn) with text of changelist description
%
% Example: 
%   sDescription = p4changeDescriptionGet(nChange)
%
% See also: strGlue, p4
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2018-06-14

% p4 call
[sMsg,nStatus] = p4(sprintf('change -o %i',nChange));
if nStatus
    % failure of p4 command
    sDescription = [];
else
    % determine description of changelist
    cDescription = hlxFormParse(sMsg,{'Description'},inf,true);
    sDescription = strGlue(cDescription,char(10)); %#ok<CHARTEN>
end
return