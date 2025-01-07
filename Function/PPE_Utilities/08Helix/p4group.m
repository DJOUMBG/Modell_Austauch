function p4group(sGroup,cUser,cOwner,cSubgroup)
% P4GROUP change or update a Helix user group on current server according
% the specified settings.
%
% Syntax:
%   p4group(sGroup,cUser,cOwner,cSubgroup)
%
% Inputs:
%      sGroup - string with name of group
%       cUser - cell (1xn) with strings of user IDs of this group
%      cOwner - cell (1xn) with strings of user IDs which are group owners
%   cSubgroup - cell (1xn) with strings of subgroups or this group
%
% Outputs:
%
% Example: 
%   p4group('test_group2',{'rafrey5','pethama','nramach'},{'rafrey5','pethama'},{'test_group'})
%
% See also: strGlue, p4, p4FieldExpand, p4form
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2018-06-15

% check input
if nargin < 2
    cUser = {};
end
if nargin < 3
    cOwner = {};
end
if nargin < 4
    cSubgroup = {};
end

try
[nStatus,sMsg] = p4form('group',sGroup,'Subgroups',cSubgroup,'Owners',cOwner,'Users',cUser);
catch
end
if nStatus
    % failure of p4 command
    fprintf(2,'p4group failure with message:\n%s\n',sMsg);
end
return
