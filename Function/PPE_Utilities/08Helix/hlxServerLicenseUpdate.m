function hlxServerLicenseUpdate(sPath,cServer)
% HLXSERVERLICENSEUPDATE update the licenses of servers from a folder with
% license files from Perforce.
%
% Syntax:
%   hlxServerLicenseUpdate
%   hlxServerLicenseUpdate(sPath)
%   hlxServerLicenseUpdate(sPath,cServer)
%
% Inputs:
%     sPath - string with folder path containing only license files
%   cServer - cell (1xn) with strings listing servers
%
% Outputs:
%
% Example: 
%   hlxServerLicenseUpdate
%   hlxServerLicenseUpdate(sPath,cServer)
%
%
% See also: p4, dirPattern, pathparts, textscan
%
% Author: Rainer Frey, TP/EAC, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2020-09-15

% check input
if nargin < 1
    sPath = pwd;
end
if nargin < 2
    cFile = dirPattern(sPath,'*','file');
    nSelection = listdlg('Name','Servers',...
        'ListString',cFile,...
        'PromptString','Select Servers for license update:',...
        'ListSize',[300 200]);
    if isempty(nSelection)
        fprintf(1,'User abort - no license updated.\n');
        return
    end
    cFile = cFile(nSelection);
    
elseif ischar(cServer) && strcmp(cServer,'all')
    cFile = dirPattern(sPath,'*','file');
    
else

    % TODO match ip with DNS name?!?
end

% loop over servers
for nIdxServer = 1:numel(cFile)
    % get license details
    xServer = getLicenseFile(fullfile(sPath,cFile{nIdxServer}));
    
    % get current license details
    xServerOld = getLicenseServer(xServer.IPaddress);
    if isempty(xServerOld)
        continue
    end
    
    % check user count
    if str2double(xServerOld.Users) > str2double(xServer.Users)
        sGo = questdlg(sprintf(['New license for server %s has less users ' ...
            '(%s) than old license (%s). \n Do you want to proceed?'],...
            xServer.IPaddress,xServer.Users,xServerOld.Users), ...
            'License Update', ...
            'Yes','No','No');
        if strcmp(sGo,'No')
            fprintf(2,'Skipped update on server "%s" due to user decision.',xServer.IPaddress);
            continue
        end
    end
    
    % update license file in server
    ensureFileLinebreak(fullfile(sPath,cFile{nIdxServer}));
    setLicenseServer(fullfile(sPath,cFile{nIdxServer}),xServer);
end
return

% =========================================================================

function setLicenseServer(sFile,xServer)
% SETLICENSESERVER set a specified license file of a server
%
% Syntax:
%   setLicenseServer(sFile,xServer)
%
% Inputs:
%     sFile - string with filepath of license file
%   xServer - structure with fields of license file entries: 
%       .IPaddress - string with ip address and port of server e.g. '53.53.11.80:1666' 
%       .Users - string with number of users in license
%
% Example: 
%   setLicenseServer('SomeServer.license',xServer)

% store old Server
% cOut = hlxOutParse(p4('set'),{'=',' '},1,true);
% sPortOld = cOut{strcmp('P4PORT',cOut(:,1)),2};
% sUser = cOut{strcmp('P4USER',cOut(:,1)),2};

% add ssl encryption and switch to server
sPortEnc = ['ssl:' xServer.IPaddress];
% p4port(sUser,sPortEnc,[],0); % includes login if needed

% update license
[sMsg,nStatus] = p4(sprintf('-p %s license -i < "%s"',sPortEnc,sFile));
if nStatus
    fprintf(2,'license update for server "%s" failed with message:\n%s\n',...
        xServer.IPaddress,sMsg);
end

% return to old server
% p4port(sUser,sPortOld,[],0); 
return

% =========================================================================

function xServer = getLicenseServer(sPort)
% GETLICENSESERVER get license details from a server (only encrypted servers)
%
% Syntax:
%   xServer = getLicenseServer(sPort)
%
% Inputs:
%   sPort - string with <ip address>:<port>
%
% Outputs:
%   xServer - structure with fields of license file entries: 
%       .IPaddress - string with ip address and port of server e.g. '53.53.11.80:1666' 
%       .Users - string with number of users in license
%
% Example: 
%   xServer = getLicenseServer('53.53.11.93:1666')

% init output
xServer = structInit('IPaddress','Users');

% check server reachability
cPort = strsplitOwn(sPort,':');
[bSuccess,sIp,sName] = reachServer(cPort{1});
if ~bSuccess
    fprintf(2,'Server "%s" not reachable (test by nslookup).\n',sPort)
    return
end

% % store old Server
% cOut = hlxOutParse(p4('set'),{'=',' '},2,true);
% sPortOld = cOut{strcmp('P4PORT',cOut(:,1)),2};
% sUser = cOut{strcmp('P4USER',cOut(:,1)),2};

% add ssl encryption and switch to server
sPortEnc = ['ssl:' sPort];
% p4port(sUser,sPortEnc,[],0); % includes login if needed

% get current license content
sMsg = p4(sprintf('-p %s license -o',sPortEnc));

% TODO p4 -p ssl:s019ac0139.destr.corpintra.net:1666 license -o

% return to original server
% p4port(sUser,sPortOld,[],0); 

% parse content
cLine = strsplitOwn(sMsg,char(10)); %#ok<CHARTEN>
xServer = parseLicense(cLine);
return

% =========================================================================

function xServer = getLicenseFile(sFileLicense)
% GETLICENSEFILE read and parse Helix license file
%
% Syntax:
%   xServer = getLicenseFile(sFileLicense)
%
% Inputs:
%   sFileLicense - string with filepath of license file
%
% Outputs:
%   xServer - structure with fields of license file entries: 
%       .IPaddress - string with ip address and port of server e.g. '53.53.11.80:1666' 
%       .Users - string with number of users in license
%
% Example: 
%   xServer = getLicenseFile(sFileLicense)

% read file
nFid = fopen(sFileLicense,'r');
ccLine = textscan(nFid,'%s','Delimiter',char(10)); %#ok<CHARTEN>
fclose(nFid);

% parse content
xServer = parseLicense(ccLine{1});
return

% =========================================================================

function ensureFileLinebreak(sFileLicense)
% ENSUREFILELINEBREAK ensure newline linebreak (linux style) for compliance
% with Perforce requirements. (sometimes license files come with carriage
% return linebreak of Mac).
%
% Syntax:
%   ensureFileLinebreak(sFileLicense)
%
% Inputs:
%   sFileLicense - string with filepath of license file
%
% Outputs:
%
% Example: 
%   ensureFileLinebreak('c:\temp\my.license')

% read file
sContent = fileread(sFileLicense);

% check for correction need
if sum(sContent==char(10)) == 0 %#ok<CHARTEN>
    % replace \r by \n
    sContent = strrep(sContent,char(13),char(10)); %#ok<CHARTEN> 
    
    % write corrected filed
    nFid = fopen(sFileLicense,'w');
    fprintf(nFid,'%s',sContent);
    fclose(nFid);
end
return

% =========================================================================

function xServer = parseLicense(cLine)
% PARSELICENSE parse text of a Helix license file into a structure
%
% Syntax:
%   xServer = parseLicense(cLine)
%
% Inputs:
%   cLine - cell with lines of license file
%
% Outputs:
%   xServer - structure with fields of license file entries: 
%       .IPaddress - string with ip address and port of server e.g. '53.53.11.80:1666' 
%       .Users - string with number of users in license
%
% Example: 
%   xServer = parseLicense(cLine)

% remove empty and comment lines
bEmpty = cellfun(@isempty,cLine);
cLine = cLine(~bEmpty); % remove empty
bKeep = cellfun(@(x)~strcmp(x(1),'#') , cLine);
cLine = cLine(bKeep); % only relevant non-comment lines left

% parse file 
cFront = genvarname(regexp(cLine,'^[^:]+','match','once'));
cRear = regexp(cLine,'\S+$','match','once');
for nIdxLine = 1:numel(cLine)
    % create fields
    xServer.(cFront{nIdxLine}) = cRear{nIdxLine};
end

if isfield(xServer,'PerforceClientError')
    fprintf(2,'Error on server command:\n%s\n',strGlue(cLine,char(10)));
    xServer = structInit('IPaddress','Users');
end
return

% =========================================================================

function [bSuccess,sIp,sName] = reachServer(sQuery)
% REACHSERVER check server reachability by nslookup call
%
% Syntax:
%   [bSuccess,sIp,sName] = reachServer(sQuery)
%
% Inputs:
%   sQuery - string with IP address or DNS name
%
% Outputs:
%   bSuccess - boolean (1x1) for DNS reachability of specified machine
%        sIp - string with IP address of machine
%      sName - string with DNS name of machine
%
% Example: 
%   [bSuccess,sIp,sName] = reachServer(sQuery)

% check reachability via nslookup
[nStatus,sMsg] = system(sprintf('nslookup %s',sQuery));
cOut = hlxOutParse(sMsg,{':',' '},2,true);

% determine results
nName = find(strcmp('Name',cOut(:,1)));
if isempty(nName) || nStatus
    bSuccess = false;
    sIp = '';
    sName = '';
else
    bSuccess = true;
    sIp = cOut{nName+1,2};
    sName = cOut{nName,2};
end
return

