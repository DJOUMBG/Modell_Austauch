function [nStatus,sMsg] = p4port(sUser,sServer,sClient,nVerbose)
% P4PORT change the server of the Matlab instance by setting new values for
% Perforce HelixCore registry entries. If arguments are omitted the current
% system user is used. Server can be choosen from a list interactively.
% Client workspace can be choosen interactively.
%
% Syntax:
%   p4port
%   p4port(sUser,sServer,sClient)
%   p4port(sUser,sServer,sClient,nVerbose)
%
% Inputs:
%     sUser - [optional] string with user for login/switching the client
%   sServer - [optional] string with server (protocol:server:port)
%   sClient - [optional] string with client/workspace of user on server
%   nVerbose - [optional] integer with flag for verbosity 
%              0: no output on command window
%
% Outputs:
%    nStatus - integer with feedback of P4PORT set
%       sMsg - string with message
%
% Example: 
%   p4port
%   p4port('rafrey5','s019ac0141.destr.corpintra.net::1666','')
%
% See also: p4, p4port
%
% Author: Rainer Frey, TP/EAC, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2019-02-26

% check input
sUserSys = lower(getenvOwn('username'));
if nargin < 1
    sUser = sUserSys;
end
if nargin < 4
    nVerbose = 1;
end

% define default servers
if any(strcmpi(sUser,{'rafrey5','frmoelle','rohrere','sdronka'}))
    cPort = {'ssl:cae-divedb-de.emea.tru.corpintra.net:1666'
             'ssl:cae-divedb-de-test.emea.tru.corpintra.net:1666'
             'ssl:sara1m000203.inedc.corpintra.net:1666'
             'ssl:cae-divedb-de-commit.emea.tru.corpintra.net:1666'
             'ssl:s019ac0197.emea.tru.corpintra.net:1666'
             'ssl:cae-divedb-de-replica.emea.tru.corpintra.net:1666'
             'ssl:s019ac0281.emea.tru.corpintra.net:1666'
             'ssl:cae-divedb-de-commit-test.emea.tru.corpintra.net:1666'
             'ssl:s019ac0274.emea.tru.corpintra.net:1666'
             'ssl:cae-divedb-de-replica-test.emea.tru.corpintra.net:1666'
             'ssl:s019ac0279.emea.tru.corpintra.net:1666'
             'ssl:stnaacvdl261.us164.corpintra.net:1666'
            };
else
    cPort = {'ssl:cae-divedb-de.emea.tru.corpintra.net:1666'
             'ssl:cae-divedb-de-test.emea.tru.corpintra.net:1666'};
end

% add MBRDI edge server where necessary
sDomain = getenvOwn('userdomain');
if strcmpi(sDomain,'apac')
    cPort = [{'ssl:sara1m000203.inedc.corpintra.net:1666'
              'ssl:cae-divedb-de.emea.tru.corpintra.net:1666'
              'ssl:cae-divedb-de-test.emea.tru.corpintra.net:1666'};cPort];
elseif strcmpi(sDomain,'americas')
    cPort = [{'ssl:stnaacvdl261.us164.corpintra.net:1666'
              'ssl:cae-divedb-de.emea.tru.corpintra.net:1666'
              'ssl:cae-divedb-de-test.emea.tru.corpintra.net:1666'};cPort];
end

if nargin < 2
    if numel(cPort) > 1
        % user selection of server
        nSelection = listdlg('Name','Select server',...
            'ListString',cPort,...
            'PromptString','Select server for connection:',...
            'SelectionMode','single',...
            'ListSize',[200 250]);
        if isempty(nSelection) % user pressed cancel
            return
        end
        sServer = cPort{nSelection};
    else
        sServer = cPort{1};
    end
end

% check for different user to current Windows user
if ~strcmp(sUser,sUserSys)
    p4(sprintf('set P4USER=%s',lower(sUser)));
    if nVerbose
        fprintf(1,['Caution: Set Helix user "%s" different to Windows user "%s" in registry. \n' ...
            '      restore with: p4 set P4USER=%s\n'],sUser,sUserSys,sUserSys);
    end
end

% set new server
[nStatus,sMsg] = p4(sprintf('set P4PORT=%s',sServer));
if nVerbose
    fprintf(1,'Set environment for server "%s".\n',sServer);
end

% query clients
if nargin < 3
    cClient = hlxOutParse(p4(sprintf('-p %s clients -u %s',sServer,sUser)),' ',2,true);
    if numel(cClient) == 2 && ...
            ((strcmp(cClient{1},'Perforce') && ...
              strcmp(cClient{2},'password')) || ...
             (strcmp(cClient{1},'Your') && ...
              strcmp(cClient{2},'session')))
        if exist('p4login','file')
            p4login;
        else
            if nVerbose
                fprintf(2,'Login to server "%s" needed.\n',sServer);
            end
            return
        end
    end
    
    if ~isempty(cClient)
        % check for correct hostname of client (this computer)
        bHost = ~cellfun(@isempty,regexpi(cClient(:,2),getenvOwn('computername'),'once'));
        cClient = cClient(bHost,:);
    end
    
    % catch no clients on this server
    if isempty(cClient)
        if nVerbose
            disp('No valid clients of this computer and user found on the server.')
            disp('Switched server (P4PORT) but not the client.')
        end
        return
    end
    
    % ask user which one to take
    nSelection = listdlg('Name','Select client/workspace',...
        'ListString',cClient(:,2),...
        'PromptString','Select client/workspace on server:',...
        'SelectionMode','single',...
        'ListSize',[200 250]);
    if isempty(nSelection) % user pressed cancel
        return
    end
    sClient = cClient{nSelection,2};
end
% set new client
if ~isempty(sClient)
    p4(sprintf('set -s P4CLIENT=%s',sClient));
    if nVerbose
        fprintf(1,'Set environment for client "%s".\n',sClient);
    end
end
return
