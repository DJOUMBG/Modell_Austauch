function hlxClientsObliterate(sUser)
% HLXCLIENTSOBLITERATE obliterate deleted Perforce HelixCore clients of the specified user.
%
% CAUTION: This is a dangerous script - only use, when you understand what it does!
% 
% Syntax:
%   hlxClientsObliterate(sUser)
%
% Inputs:
%   sUser - string with user ID to cleanup clients
%
% Outputs:
%
% Example: 
%   hlxClientsObliterate('diveonesys')
%
% See also: p4, regexp, contains
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-8485-3325
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2023-04-05

% check input
if nargin < 1
    fprintf(2,'User for workspace obliteration must be provided!')
    return
end

% drop clients to file (faster than backloop to Matlab
sFile = sprintf('Client_%s.txt',sUser);
p4(sprintf('files //spec/client/%s... > %s',sUser,sFile));

% read and parse client file
nFid = fopen(sFile,'r');
ccLine = textscan(nFid,'%s','delimiter',char(10)); %#ok<CHARTEN>
fclose(nFid);
delete(sFile);
cLine = ccLine{1};

% determine client name and delete state
cClient = regexp(cLine,'[\w-]+\.p4s','match','once');
fprintf(1,'Found %i clients\n',numel(cClient));
bDelete = contains(cLine,'delete default change');
fprintf(1,' %i clients still in use\n',sum(~bDelete));
cClientKeep = cClient(~bDelete);
cClient = cClient(bDelete);

% determine user_machine blocks 
cClientShort = regexp(cClient,'^[a-zA-Z0-9]+_[a-zA-Z0-9\-]+_','match','once');
cClientUnique = unique(cClientShort);
cClientShortKeep = regexp(cClientKeep,'^[a-zA-Z0-9]+_[a-zA-Z0-9\-]+_','match','once');
cClientUniqueKeep = unique(cClientShortKeep);
bKeep = ismember(cClientUnique,cClientUniqueKeep);
cClientUnique = cClientUnique(~bKeep);
bEmpty = cellfun(@isempty,cClientUnique);
cClientUnique = cClientUnique(~bEmpty);

% obliterate deleted client definitions
fprintf(1,'Start obliterating clients from %i machines...\n',numel(cClientUnique));
for nIdxClient = 1:numel(cClientUnique)
    p4('obliterate -y  //spec/client/%s... > outputDump.txt',cClientUnique{nIdxClient});
    fprintf(1,'obliterated %s\n',cClientUnique{nIdxClient});
end
return


