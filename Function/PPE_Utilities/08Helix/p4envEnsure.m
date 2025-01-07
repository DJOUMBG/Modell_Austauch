function [nStatus,sMsg,xBase] = p4envEnsure
% P4ENVENSURE ensure basic registry settings of p4 (P4PORT, P4USER and ssl
% certificate trust) or reports basic issues. Returns also basic
% information gathered in the process.
% function [nStatus,sMsg,xBase] = p4envEnsure
% P4ENVENSURE ensure basic registry settings of p4 (P4PORT, P4USER and ssl
% certificate trust) or reports basic issues. Returns also basic
% information gathered in the process.
% 
% Syntax:
%   xBase = p4envEnsure
%
% Inputs:
%
% Outputs:
%  nStatus - integer with status, 0: success, 1: fail
%     sMsg - string with error messages
%    xBase - structure with fields returning the "p4 set" values (these
%            values are stored as Windows registry entries in 
%             (set) Computer\HKEY_CURRENT_USER\Software\Perforce\Environment
%             (set -s) Computer\HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Perforce\Environment
%      .P4PORT
%      .P4USER
%      .P4CLIENT
%
% Example: 
%   xBase = p4envEnsure
%
% See also: p4
%
% Author: Rainer Frey, TP/EAC, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2020-02-06

% initialize Output
nStatus = 0;
xBase = structInit({'P4PORT','P4USER','P4CLIENT'});

% try a system call on p4
[nStatusP4Set,sMsg] = system('p4 set');

% cover exceptions (assume possible: empty = no settings, no p4 installation)
[bStatus,sIdent,sCure] = p4Exception(sMsg,0);

% report exception (no p4 installation)
if nStatusP4Set && bStatus
    fprintf(2,'%s\n',sCure);
    nStatus = 1;
    return
end

% cover leftover cases
sUser = getenvOwn('username');
if strcmp(sIdent,'Empty') % p4 installed, but no settings for user
    xBase(1).P4PORT = p4ServerPreSelect;
    xBase(1).P4USER = lower(sUser);
    xBase(1).P4CLIENT = '';
    setAll(xBase);    
    nStatus = 0;

else % at least some settings available -> preserve and check settings
    % parse set info to prevent multicall
    cOut = hlxOutParse(sMsg,{'=','('},inf,true);
    
    % fallback
    if isempty(cOut)
        fprintf(1,'Empty parsing from "p4 set" created an error with message:\n%s\nBasics are set.\n',sMsg);
        xBase(1).P4PORT = p4ServerPreSelect;
        xBase(1).P4USER = lower(sUser);
        xBase(1).P4CLIENT = '';
        setAll(xBase);
        nStatus = 0;
        return
    end
    
    % check and assign server
    bServer = strcmp('P4PORT',cOut(:,1));
    if any(bServer)
        xBase(1).P4PORT = strtrim(cOut{bServer,2});
    else
        xBase(1).P4PORT = p4ServerPreSelect;
        p4(sprintf('set P4PORT="%s"',xBase(1).P4PORT));
    end
    
    % check and assign user
    bUser = strcmp('P4USER',cOut(:,1));
    if any(bUser)
        xBase(1).P4USER = strtrim(cOut{bUser,2});
    else
        xBase(1).P4USER = lower(sUser);
        p4(sprintf('set P4USER="%s"',lower(sUser)));
    end
    
    % get current workspace user
    bClient = strcmp('P4CLIENT',cOut(:,1));
    if any(bClient)
        xBase(1).P4CLIENT = strtrim(cOut{bClient,2});
        % check client
        if ~strncmp(xBase(1).P4CLIENT,lower(sUser),numel(sUser)) %#ok<STNCI>
            xBase(1).P4CLIENT = '';
            p4(sprintf('set -s P4CLIENT="%s"',xBase(1).P4CLIENT)); % reset client/workspace
        end
    else
        xBase(1).P4CLIENT = '';
        p4(sprintf('set -s P4CLIENT="%s"',xBase(1).P4CLIENT)); % reset client/workspace
    end
end
return

% =========================================================================

function setAll(xBase)
% SETALL set all p4 environment variables
%
% Syntax:
%   setAll(xBase)
%
% Inputs:
%   xBase - structure with fields: 
%     .P4PORT - string with
%     .P4USER - string with
%     .P4CLIENT - string with
%
% Outputs:
%
% Example: 
%   setAll(xBase)

p4(sprintf('set P4PORT="%s"',xBase.P4PORT));
p4(sprintf('set P4USER="%s"',xBase.P4USER));
p4(sprintf('set -s P4CLIENT="%s"',xBase.P4CLIENT));
return

% =========================================================================

function sServer = p4ServerPreSelect
% P4SERVERPRESELECT set default server according DNS suffix or domain
%
% Syntax:
%   sServer = p4ServerPreSelect
%
% Inputs:
%
% Outputs:
%   sServer - string with server setting for P4PORT
%
% Example: 
%   sServer = p4ServerPreSelect

%% get preselection
sServer = '';
% along DNS-suffix
[nStatus,sMsg] = system('ipconfig /all');
if ~nStatus
    cOut = hlxOutParse(sMsg,{': '},2,true);
    bSuffix = ~cellfun(@isempty,strfind(cOut(:,1),'Suffix')); %#ok<STRCLFH>
    bPrimary = ~cellfun(@isempty,strfind(cOut(:,1),'Prim')); %#ok<STRCLFH>
    nSuffixPrimary = find(bSuffix & bPrimary); 
    if ~isempty(nSuffixPrimary) 
        if isempty(cOut{nSuffixPrimary(1),2}) % Win11 does not state Primary DNS Suffix anymore
            nSuffix = find(bSuffix);
            nNonEmpty = find(~cellfun(@isempty,cOut(bSuffix,2)));
            if isempty(nNonEmpty) % no hit
                cSuffix = {'destr'};
            else
                sSuffix = cOut{bSuffix(nSuffix(nNonEmpty(1)))};
                cSuffix = strsplitOwn(sSuffix,'.');
            end
        else
            cSuffix = strsplitOwn(cOut{nSuffixPrimary(1),2},'.');
        end
        switch  cSuffix{1}
            case 'destr'
                sServer = 'ssl:cae-divedb-de.emea.tru.corpintra.net:1666'; % main broker
            case {'us164','us590'}
                sServer = 'ssl:stnaacvdl261.us164.corpintra.net:1666'; % proxy server Portland
            case {'in623','inedc'}
                sServer = 'ssl:sara1m000203.inedc.corpintra.net:1666'; % edge server Bangalore
            % otherwise
                % sServer = 'ssl:cae-divedb-de.emea.tru.corpintra.net:1666'; % main broker
        end
    end
end

% along domain - dangerous if APAC machine is in other network 
% (e.g. laptop on travel)
if isempty(sServer)
    [nStatus,sMsg] = system('ECHO %userdomain%');
    if ~nStatus
        sDomain = strtrim(sMsg);
        switch sDomain
            case 'EMEA'
                sServer = 'ssl:cae-divedb-de.emea.tru.corpintra.net:1666'; % main broker
            case 'APAC'
                sServer = 'ssl:sara1m000203.inedc.corpintra.net:1666'; % edge server
            case 'AMERICAS'
                sServer = 'ssl:stnaacvdl261.us164.corpintra.net:1666'; % proxy server Portland
            otherwise
                sServer = 'ssl:cae-divedb-de.emea.tru.corpintra.net:1666'; % main broker
        end
    end
end

%% set server
p4(sprintf('set P4PORT=%s',sServer));
return
