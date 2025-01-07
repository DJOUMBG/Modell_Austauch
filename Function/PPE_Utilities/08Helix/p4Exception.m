function [bStatus,sIdent,sCure] = p4Exception(sMsg,nVerbose)
% P4EXCEPTION identify issues with p4 calls according the feedback message.
% Generate healing suggestion.
%  
% Covered with cures:
%   - p4 not installed
%   - user not logged in
%   - TCP connection failure
%   - missing trust (with automated trust)
% 
% Without cure - just identifier:
%   - empty feedback (e.g. p4 set without existing
%     settings)
%
% Syntax:
%   [bStatus,sIdent,sCure] = p4Exception(sMsg,nVerbose)
%
% Inputs:
%       sMsg - string string with output message of p4 system call
%   nVerbose - integer (1x1) with verbosity level
%
% Outputs:
%   bStatus - boolean (1x1) with output state
%              0: state not covered
%              1: state recognized (and break of function imminent)
%    sIdent - string with case identifier
%     sCure - string with cure suggestion to user
%
% Example: 
%   [bStatus,sIdent,sCure] = p4Exception(sMsg,nVerbose)
%
% See also: p4, p4envEnsure, p4switch 
%
% Author: Rainer Frey, TP/EAC, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2020-02-17

%  open: verbose state?

% initialize output
bStatus = false;
sIdent = 'Healthy';
sCure = '';

% check input
if nargin < 2
    nVerbose = 0;
end

%% failure mode detection
if isempty(sMsg) % no results/output on query
    bStatus = false;
    sIdent = 'Empty';
    sCure = '';
    
elseif strcmp(sMsg(1:min(numel(sMsg),10)),'Der Befehl') || ...
        any(strfind(sMsg,'not found')) || ...
        any(strfind(sMsg,'not recognized')) % no p4 installation
    bStatus = true;
    sIdent = 'NoP4';
    sCure = sprintf(['No Perforce Helix P4 installation on this computer available. \n' ...
        'Please install P4V Perforce Helix Client. (e.g. IT-Shop PERFORCE HELIX CORE APPS P4V 2019.1)']);
    
elseif strcmp(sMsg(1:min(numel(sMsg),24)),'Your session has expired') || ...
        strcmp(sMsg(1:min(numel(sMsg),17)),'Perforce password') % login needed
    bStatus = true;
    sIdent = 'NoLogin';
    sCure = 'Please log into the Perforce Helix Server before using the script.';
    
elseif strcmp(sMsg(1:min(numel(sMsg),4)),'User') && ...
        strcmp(sMsg(end-4:end),'exist') % User xxx doesn't exist
    bStatus = true;
    sIdent = 'NoAccount';
    sCure = 'Please contact your Perforce Helix Administrator to get an account.';
        
elseif ~isempty(strfind(sMsg,'TCP receive failed')) %#ok<STREMP> % just a TCP connection issue
    bStatus = true;
    sIdent = 'TCPfail';
    sCure = 'TCP connection failure during p4 call - check network connection.';

elseif ~isempty(strfind(sMsg,'Connect to server failed')) %#ok<STREMP> % a general connection issue
    bStatus = true;
    sIdent = 'ServerFail';
    if exist('p4port','file')
        sCure = ['TCP connect to server failure during p4 call - use ' ...
                 '"p4port" in Matlab to get correct P4PORT settings.'];
    else
        sCure = 'TCP connect to server failure during p4 call - check P4PORT environment variable.';
    end

elseif strcmp(sMsg(1:min(numel(sMsg),16)),'The authenticity') % p4 trust missing
    % precondition: p4 installed, P4PORT setting leads to an ssl encrpted server connection
    bStatus = true;
    sIdent = 'TrustRequest';
    sCure = ['You need to establish a SSL trust for encrypted connections - ' ...
        'please first open P4V with this server or use "p4 trust" to check ' ...
        'the correct SSL fingerprint of this server.'];

elseif strcmp(sMsg(1:min(numel(sMsg),15)),'Access for user') || ... % user has no account in server
        strcmp(sMsg(end-14:end-1),'doesn''t exist.') 
    bStatus = true;
    sIdent = 'NoAccount';
    [nStatusEnv,sMsgEnv,xBase] = p4envEnsure; %#ok<ASGLU>
    if nStatusEnv % failure in p4envEnsure
        sCure = 'Your user is not known. Please contacct your Perforce Helix Administrator';
    else
        sCure = sprintf(['Your user "%s" is not known to the server "%s", ' ...
            'please contact your Perforce Helix Administrator.\n' ...
            '(Hint 1: Perforce Helix uses only lower case users.\n' ...
            ' Hint 2: check "p4 set" for a correct P4USER entry and retry.)\n'],getenvOwn('username'),xBase.P4PORT);
    end
    

% elseif isempty(strfind(sMsg,'P4USER')) && isempty(strfind(sMsg,'P4PORT')) %#ok<STREMP>
%     bStatus = false;
%     sIdent = 'Empty';
%     sCure = '';
end

%% direct cures to failure modes
switch sIdent
    case 'TrustRequest'
        % extract server IP
        sIp = regexp(sMsg,'(?<=The authenticity of '')[\w\.]+:\d+','match','once');
        % check for known trust fingerprints
        bStatusTrust = p4trust(sIp);
        if bStatusTrust % show standard message, if no known trusts
            fprintf(2,'%s\n',sMsg);
        end
end

%% report failure cure
if bStatus && nVerbose > 0 && ~isempty(sCure)
    fprintf(1,'%s\n',sCure);
end
return

% =========================================================================

function bStatus = p4trust(sServer)
% P4TRUST automatically set ssl encryption trusts on known server
% fingerprints.
%
% Syntax:
%   bStatus = p4trust(sServer)
%
% Inputs:
%   sServer - string with server info (IP:Port or P4PORT string)
%
% Outputs:
%   bStatus - boolean (1x1) for success of autmatic trust settings
%               0: success
%               1: fail
%
% Example: 
%   bStatus = p4trust(sServer)

% known ssl fingerprints of servers
cFingerprint = {'ssl:cae-divedb-de.emea.tru.corpintra.net:1666','53.133.249.38:1666','75:66:81:EF:04:E7:89:DB:98:F4:A4:F9:EF:BE:81:90:3C:6A:E2:11'
                'ssl:cae-divedb-de-test.emea.tru.corpintra.net:1666','53.133.249.36:1666','CE:22:98:0B:9A:33:4D:BB:9D:A5:38:7F:3D:22:5B:35:B1:6A:65:23'
                'ssl:cae-divedb-de-commit.emea.tru.corpintra.net:1666','53.133.249.22:1666','91:48:6B:59:B2:38:80:C0:8A:6C:18:63:37:C8:41:4E:8B:C3:12:D7'
                'ssl:cae-divedb-de-commit-test.emea.tru.corpintra.net:1666','53.133.249.34:1666','B3:D2:28:BA:9C:8B:68:4F:FD:52:25:25:F5:87:84:B5:9B:B7:AF:76'
                'ssl:cae-divedb-de-replica.emea.tru.corpintra.net:1666','53.133.249.37:1666','69:DD:04:4E:05:56:E6:34:91:72:3A:E4:62:C6:08:F9:87:11:0C:DD'
                'ssl:cae-divedb-de-replica-test.emea.tru.corpintra.net:1666','53.133.249.35:1666','93:24:57:F4:3F:03:F8:F8:E6:F4:A1:8E:2E:40:01:06:08:8D:05:E2'
                'ssl:sara1m000203.inedc.corpintra.net:1666','53.197.27.93:1666','9E:63:62:63:6B:0C:23:2E:F8:A2:4B:3E:A8:99:C6:F3:D5:31:A2:64'
                'ssl:stnaacvdl261.us164.corpintra.net:1666','53.242.117.183:1666','B5:E3:29:E6:CB:CC:F9:AF:9C:A4:9B:24:29:9A:57:78:28:3D:EF:98'};

% check for servers
bServer = strcmpi(sServer,cFingerprint(:,2));
if ~any(bServer)
    bServer = strcmpi(sServer,cFingerprint(:,1));
end
if any(bServer)
    [sMsg,nStatus] = p4(sprintf('trust -i %s',cFingerprint{bServer,3}));
    if nStatus
        % p4 trust went wrong
        bStatus = true;
        fprintf(1,'Error on p4Exception:p4trust - error on p4 trust call with message:\n%s\n',sMsg);
    else
        % successful setting
        bStatus = false;
    end
else
    % no matching server found
    bStatus = true;
end
return
