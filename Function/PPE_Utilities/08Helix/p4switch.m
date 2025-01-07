function [nStatus,sWorkspace,sPrevious,cClient] = p4switch(sWorkspace,nVerbose,sPrevious,cClient)
% P4SWITCH switch to a specific workspace of Perforce HelixCore without
% initializing a sync. If no argument is passed, user can select new
% workspace from list of workspaces on executing host.
%
% Syntax:
%   [nStatus,sWorkspace,sPrevious] = p4switch(sWorkspace)
%   [nStatus,sWorkspace,sPrevious] = p4switch(sWorkspace,nVerbose)
%   [nStatus,sWorkspace,sPrevious] = p4switch(sWorkspace,nVerbose,sPrevious)
%   [nStatus,sWorkspace,sPrevious] = p4switch(sWorkspace,nVerbose,sPrevious,cClient)
%
% Inputs:
%   sWorkspace - [optional] string with
%                   * Perforce Helix workspace 
%                   * file of a Perforce Helix workspace 
%                   * folder of a Perforce Helix workspace 
%     nVerbose - [optional] integer (1x1) with verbosity level
%                 0: no messages in normal operation
%                 1: report switching success to command window {default}
%    sPrevious - [optional] string with previous workspace (skips current
%                workspace detection)
%      cClient - [optional] cell (nx5) with the client info of the current
%                 user (skips client detection)
%
% Outputs:
%      nStatus - integer (1x1) of success (1: success, 0: break or fail)
%   sWorkspace - string with new workspace name
%    sPrevious - string with previous workspace name
%      cClient - cell (nx5) with the client info of the current user
%
% Example:
%   cClient = hlxOutParse(p4('clients','--me'),' ',5,true);
%   [nStatus,sWorkspace,sPrevious] = p4switch(which('p4switch'))
%   p4switch(which('p4switch'),false);
%   p4switch(which('p4switch'),false,'rafrey5_C019L061023_Matlab_00Tools');
%   p4switch(which('p4switch'),false,'rafrey5_C019L061023_Matlab_00Tools',cClient);
%
% See also: hlxOutParse, p4, hlxWorkspaceOfFile
%
% Author: Rainer Frey, TP/EAC, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2018-11-21

% init output
nStatus = 0; % fail

% check input
if nargin < 2
    nVerbose = 1;
end

if (nargin < 3 && nargout > 2) || ...
        nargin < 1 || ...
        (nargin > 2 && isempty(sPrevious))
    % store current workspace
    cInfo = hlxOutParse(p4('info'),{': '},2,true);
    if isempty(cInfo)
        sPrevious = '';
    else
        sPrevious = cInfo{2,2}; % current workspace in MATLAB environment
    end
end

% fast path with high workspace plausibility skip checks and transformations
[sUser,sHost] = getenvOwn({'username','computername'});
sWorkspaceStart = strGlue({lower(sUser),upper(sHost)},'_');
if exist('sWorkspace','var') && ...
        strncmp(sWorkspace,sWorkspaceStart,numel(sWorkspaceStart)) && ...
        nargout < 4
    % switch client/workspace of p4 (set Windows registry entry)
    nStatus = p4setClient(sWorkspace,nVerbose);
    return
end

% get clients of this user
if ~exist('cClient','var')
    cClient = hlxOutParse(p4('clients','--me'),' ',5,true);
    % cClient = hlxOutParse(p4(sprintf('clients -u %s',lower(getenvOwn('username')))),' ',5,true);
    if isempty(cClient) || ~strcmp(cClient{1,1},'Client')
        % no user account or clients... - proper error message should be already passed by p4Exception 
        cClient = cell(0,5);
        return
    end
end
if isempty(cClient)
    sWorkspace = '';
    if ~exist('sPrevious','var')
        sPrevious = '';
    end
    return
end

% check for correct hostname of client (this computer)
bHost = ~cellfun(@isempty,regexpi(cClient(:,2),sHost,'once'));
cClient = cClient(bHost,:);
if isempty(cClient) % no perforce client/workspace of this user for this computer
    fprintf(2,['Perforce Helix has no registered client for this ' ...
        'computer (%s)\nCreate a client with P4V before using this script.\n' ...
        '(no switch due to missing target)\n'],...
        sHost);
    return
end

% user interactive mode
if nargin < 1 && ~isempty(sPrevious)
    % determine default value for listbox
    nPrevious = find(strcmp(sPrevious,cClient(:,2)));
    if isempty(nPrevious)
        nPrevious = 1;
    end
    
    % ask user for workspace
    nSelection = listdlg('Name','Select p4 client/workspace',...
        'ListString',cClient(:,2),...
        'PromptString','Select p4 workspace to work in:',...
        'SelectionMode','single',...
        'InitialValue',nPrevious,...
        'ListSize',[300 250]);
    if isempty(nSelection)
        nStatus = 0;
        fprintf(2,'User selected cancel in Workspace selection.\n');
        return;
    end
    sWorkspace = cClient{nSelection,2};
end

% determine workspace in case of passed path or file
if exist(sWorkspace,'dir') || exist(sWorkspace,'file')
    % fix missing path of files in current MATLAB path
    if isempty(fileparts(sWorkspace))
        sWorkspace = which(sWorkspace);
    end
    
    % determine workspace of file or folder
    cRoot = cellfun(@(x)['^' regexptranslate('escape',[x,filesep])],cClient(:,5),'UniformOutput',false);
    bClient = ~cellfun(@isempty,regexpi([sWorkspace,filesep],cRoot,'once','start'));

    if sum(bClient) > 1
        % error on multiple matches
        fprintf(2,['The specified file/folder '...
              '"%s" is part of multiple p4 clients: \n' ...
              repmat('%s\n',1,sum(bClient))],sWorkspace,cClient{bClient,2});
        return
    elseif sum(bClient) == 1
        % exact one workspace matches
        sWorkspace = cClient{bClient,2};
    else
        % file/folder is not in workspace
        fprintf(2,['The specified file/folder "%s" is not in a p4 '...
                   'workspace of this client.\n'],sWorkspace);
        return
    end
    
elseif strcmp(sWorkspace(1:2),'//') % passed Perforce Helix depot notation
    
    % try to determine correct client for switching
    sStream = regexp(sWorkspace,'(?<=//\w+/)\w+','match','once');
    cnClientHit = regexp(cClient(:,2),...
        sprintf('(?<=\\w+_%s_)%s',upper(sHost),sStream),'once');
    nHit = find(~cellfun(@isempty,cnClientHit));
    if isempty(nHit)
        fprintf(2,'Please create a P4 workspace/client before on this computer for this stream: %s\n',sStream);
        return
    else
        sWorkspace = cClient{nHit(1),2};
    end
    
end % if is file/folder

% match input with possible workspaces/clients
bClient = strcmpi(sWorkspace,cClient(:,2));
if ~any(bClient)
    fprintf(2,'p4switch was called with an unknown workspace: %s\n',sWorkspace);
    return
end
    
% switch client/workspace of p4 (set Windows registry entry)
nStatus = p4setClient(sWorkspace,nVerbose);
return

% ==================================================================================================

function nStatus = p4setClient(sWorkspace,nVerbose)
% p4setClient set registry value for P4CLIENT including error handling
%
% Syntax:
%   nStatus = p4setClient(sWorkspace,nVerbose)
%
% Inputs:
%   sWorkspace - string with Perforce Helix workspace name
%     nVerbose - integer (1x1) with verbosity level of messages
%
% Outputs:
%   nStatus - integer (1x1) for success (1: success, 0: failure)
%
% Example: 
%   nStatus = p4setClient('rafrey5_C019L061023_Matlab_00Tools',0)

[sMsg,nStatusP4] = p4('set','-s',sprintf('P4CLIENT=%s',sWorkspace));
if nStatusP4
    fprintf(2,'Error on "p4 set -s" command with message:\n%s\n',sMsg);
    if ~isempty(strfind(sMsg,['registry: create key: The system could not ' ...
            'find the environment option that was entered.'])) %#ok<STREMP>
        [sMsg,nStatusP4] = p4('set',sprintf('P4CLIENT=%s',sWorkspace));
        if nStatusP4
            fprintf(2,'Error on "p4 set" command with message:\n%s\n',sMsg);
        end
    end
    if nVerbose
        fprintf(1,['Switched to p4 workspace "%s" with "p4 set" (no sync, no merge).' ...
            'Error with "p4 set -s" - Windows registry HKLM not available.\n'],sWorkspace);
    end
else
    nStatus = 1;
    if nVerbose
        fprintf(1,'Switched to p4 workspace "%s" with "p4 set -s" (no sync, no merge)\n',sWorkspace);
    end
end
return
