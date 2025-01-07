function [nStatus,sMsg] = hlxStreamCreate(sName,sDepot,sParent,sType,sUser,sDescription,sOptions,cPaths,cRemapped,cIngored)
% HLXSTREAMCREATE create a stream with special settings and populate it
% with files.
%
% Syntax:
%   [nStatus,sMsg] = hlxStreamCreate(sName,sDepot,sParent,sType,sUser,sDescription,sOptions,cPaths,cRemapped,cIngored)
%
% Inputs:
%          sName - string with name of new stream e.g. dam_0046
%         sDepot - string with name of depot of streams e.g. DIVe
%        sParent - string with name of parent stream e.g. d_main
%          sType - string with stream type
%                   {'release','development','virtual','task'}
%          sUser - string with user ID of owner
%   sDescription - string with description of stream
%       sOptions - string [] with options in quotes ("")
%                    allsubmit|ownersubmit
%                    locked|unlocked
%                    toparent|notoparent
%                    fromparent|nofromparent
%                    mergedown|mergeany
%         cPaths - cell (mx1) with strings of path definitions
%      cRemapped - cell (mx1) with strings of re-mappings
%       cIngored - cell (mx1) with strings of ignores
%
% Outputs:
%   nStatus - integer (1x1) 
%      sMsg - string 
%
% Example: 
%   [nStatus,sMsg] = hlxStreamCreate('dam_0046','DIVe','d_main','release',...
%           'rafrey5','DIVeMB Build0046')
%
% See also: p4, p4form
%
% Author: Rainer Frey, TP/EAC, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2019-07-11

if nargin < 4
    fprintf(2,'hlxStreamCreate with less arguments - stopped.\n');
    return
end 
if ~ismember(sType,{'mainline','release','development','virtual','task'})
    error('hlxStreamCreate:unknownType','The stream type "%s" is unknown!',sType);
end
if nargin < 5
    sUser = lower(getenv('username'));
end 
if nargin < 6
    sDescription = 'Some stream of a lazy creator';
end 
if nargin < 7
    if strcmp(sType,'virtual')
        sOptions = '"allsubmit unlocked notoparent nofromparent mergedown"';
    else
        sOptions = '"allsubmit unlocked toparent fromparent mergedown"';
    end
end 

% create stream names in depot notation
sStream = sprintf('//%s/%s',sDepot,sName);
sStreamParent = sprintf('//%s/%s',sDepot,sParent);

% create stream initially
try
%     p4(sprintf('stream -t release -P %s %s',sStreamParent,sStream));
    p4(sprintf('stream -t %s -P %s -o %s | p4 stream -i',sType,sStreamParent,sStream));
catch ME
    fprintf(2,'error in stream creation: %s\n',ME.message);
end
% adapt stream to correct settings
cForm = {'stream',sStream,...
        'Stream',{sStream},...
        'Owner',{sUser},... % DIveMB developer group
        'Name',{sName},...
        'Parent',{sStreamParent},... % always branch from mainline
        'Type',{sType},...
        'Description',{sDescription},...
        'Options',{sOptions}};
[nStatus,sMsg] = p4form(cForm{:});
if exist('cPaths','var') && ~isempty(cPaths)
    cForm = {'stream',sStream,'Paths',cPaths};
    [nStatus,sMsg] = p4form(cForm{:});
end
if exist('cRemapped','var') && ~isempty(cRemapped)
    cForm = {'stream',sStream,'Remapped',cRemapped};
    [nStatus,sMsg] = p4form(cForm{:});
end
if exist('cIngored','var') && ~isempty(cIngored)
    cForm = {'stream',sStream,'Ingored',cIngored};
    [nStatus,sMsg] = p4form(cForm{:});
end

if nStatus
    % failure of p4 command
    fprintf(2,'p4 stream creation failure with message:\n%s\n',sMsg);
    fprintf(2,'Abort from creation and poputlation of stream "%s"\n',sStream);
    return
end

% populate stream for release and development streams
if ismember(sType,{'release','development'})
    sDescription = sprintf('Initial branch of files from %s (%s) to %s (%s)',...
                    sParent,sStreamParent,sName,sStream);
    p4(sprintf('populate -d "%s" -r -S %s',sDescription,sStream));
end
return