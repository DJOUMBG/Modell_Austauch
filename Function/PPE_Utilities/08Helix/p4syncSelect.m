function p4syncSelect(cClientIn)
% P4SYNCSELECT sync Perforce Helix workspaces of this user from this
% computer according list or user interaction input.
%
% Syntax:
%   p4syncSelect(cClientIn)
%
% Inputs:
%   cClientIn - cell (1xn) with strings of workspaces to be sync
%                OR
%               cell (mx5) with (:,2) denoting the workspace name (= output
%               of hlxOutParse(p4('clients','-u',lower(sUser)),' ',5,true))
%
% Outputs:
%
% Example: 
%   p4syncSelect(cClientIn)
%
% See also: hlxOutParse, p4, getenvOwn
%
% Author: Rainer Frey, TP/EAF, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2021-06-17

% get list of clients of this user
[sUser,sHost] = getenvOwn({'username','computername'});
cClient = hlxOutParse(p4('clients','-u',lower(sUser)),' ',5,true);

% limit to clients of this computer
bThis = ~cellfun(@isempty,regexpi(cClient(:,2),sHost,'once'));
cClient = cClient(bThis,:);

if nargin < 1
    [nSelect,bUserAction] = listdlg('ListString',cClient(:,2), ...
            'PromptString','Select Clients to be synced:',...
            'ListSize',[300 300],...
            'OkString','Sync',...
            'CancelString','None');
    if bUserAction
        cClient = cClient(nSelect,:);
    else
        return
    end
else
    if min(size(cClientIn)) == 1
        % single workspace list
        bKeep = ismember(cClientIn,cClient(:,2));
        cClient = cClient(bKeep,:);
    else
        % full cell
        cClient = cClientIn;
    end
end
    
for nIdxClient = 1:size(cClient,1)
    % sync particular client
    p4('-c',cClient{nIdxClient,2},'sync');
end
return
