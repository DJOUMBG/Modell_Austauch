function p4mergeChangeKeep(sHlxSource,sHlxTarget,bSelect,bSubmitDirect)
% P4MERGECHANGEKEEP merge/copy the changes form a source stream to its
% parent or the spedified target stream, while keeping the changelist
% assignments as far as possible.
%
% Syntax:
%   p4mergeChangeKeep(sHlxSource)
%   p4mergeChangeKeep(sHlxSource,sHlxTarget)
%   p4mergeChangeKeep(sHlxSource,sHlxTarget,bSelect)
%   p4mergeChangeKeep(sHlxSource,sHlxTarget,bSelect,bSubmitDirect)
%
% Inputs:
%     sHlxSource - string with source stream in Helix depot notation
%     sHlxTarget - string with source stream in Helix depot notation
%        bSelect - boolean (1x1) if selection dialogue is shown (default: 1)
%  bSubmitDirect - boolean (1x1) if changes shall be submitted directly 
%                  (default: 1)
%
% Outputs:
%
% Example: 
%   p4mergeChangeKeep('//DIVe/dam_0042') % -> merge to parent stream
%   p4mergeChangeKeep('//DIVe/d_main','//DIVe/dam_0044') % -> copy from mainline needs 2nd argument 
%   p4mergeChangeKeep('//DIVe/ddm_dev_eats') % -> copy changes to release stream
%   p4mergeChangeKeep('//DIVe/ddm_dev_eats','//DIVe/dam_0044',true,false) % -> copy with selection of changes and do not submit 
%
% p4mergeChangeKeep('//DIVe/ddm_dev_mcmacm','//DIVe/drm_0047',1,0)
% p4mergeChangeKeep('//DIVe/dam_0048','//DIVe/dam_0047',1,0)
% p4mergeChangeKeep('//DIVe/drm_0048','//DIVe/drm_0047',1,0)
% p4mergeChangeKeep('//DIVe/dam_0047','//DIVe/dam_0048',1,0)
% p4mergeChangeKeep('//DIVe/drm_0047','//DIVe/drm_0048',1,0)
% p4mergeChangeKeep('//DIVe/drm_0048','//DIVe/d_main',1,0)
% p4mergeChangeKeep('//DIVe/d_main','//DIVe/drm_0048',1,0)
% p4mergeChangeKeep('//DIVe/dbm_platform','//DIVe/d_main',1,0)
% p4mergeChangeKeep('//DIVe/d_main','//DIVe/dbm_platform',1,0)
% p4mergeChangeKeep('//DIVe/ddc_dev_DIVe3D','//DIVe/d_main',1,0)
% p4mergeChangeKeep('//DIVe/d_main','//DIVe/ddc_dev_DIVe3D',1,0)
% p4mergeChangeKeep('//DIVe/drl_dev_eVeh','//DIVe/drl_dev_Concepts',1,0)
% p4mergeChangeKeep('//DIVe/drl_dev_Concepts','//DIVe/drl_dev_eVeh',1,0)
% 
% See also: hlxOutParse, p4, p4change, p4mergeChangeKeep, p4switch
%
% Author: Rainer Frey, TP/EAC, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2019-02-25

% input check
if nargin < 1 % no source specified - ask user
    % determine newest DIVe MB release stream dam_*, e.g. dam_0042
    cStream = hlxOutParse(p4('streams -F "Type=release Name=dam_*"'),' ',2,true);
    nSelection = listdlg('Name','Stream to merge',...
        'ListString',cStream(:,2),...
        'PromptString','Select stream to be merged to parent',...
        'SelectionMode','single',...
        'ListSize',[200 250]);
    if isempty(nSelection) % user pressed cancel
        return
    else
        sHlxSource = cStream{nSelection,2};
    end
end

[cParent,cType] = hlxFormParse(p4(sprintf('stream -o %s',sHlxSource)),{'Parent','Type'},' ',2,true);
if nargin < 2 || isempty(sHlxTarget) % no target specified
    % determine Parent Stream as merge target and source stream type
    sHlxTarget = cParent{1};
    sSourceType = cType{1};
else
    % determine source stream type
    sSourceType = cType{1};
end

if nargin < 3 % selection mode not specified
    bSelect = true;
end

if nargin < 4 % direct submit not specified
    bSubmitDirect = true;
end

% switch to correct client/workspace
[sUser,sHost] = getenvOwn({'username','computername'});
cClient = hlxOutParse(p4(sprintf('clients -u "%s" -E "%s" -S "%s" ',...
    lower(sUser),['*',sHost,'*'],sHlxTarget)),' ',5,true);
if isempty(cClient)
    fprintf(2,'No p4 client of target stream "%s" of this user on this computer known!\n',sHlxTarget);
    return
end
p4switch(cClient{1,2});
sRoot = cClient{1,5}; % root folder of this client
cd(sRoot);
p4('sync'); % sync workspace to be up to date in files

% determine operation details
[sRcmSource,sRcmParent,sAction,sReverse] = integrateAction(sHlxSource,sHlxTarget);


% generate changelist
nChange = p4change(sprintf('Merge Container for %s from %s to %s',sAction,sHlxSource,sHlxTarget));
% start integration
if strcmp(sAction,'merge')
    if isempty(sReverse) % merge changes from source (child) to target (parent) stream
        p4(sprintf('%s -c %i -S %s',sAction,nChange,sHlxSource)); % merge changes from source to target stream
    else % merge changes from parent to child/dev stream
        p4(sprintf('%s -c %i -P %s -S %s %s',sAction,nChange,sRcmParent,sRcmSource,sReverse)); 
    end
    sMsg = p4('resolve -am'); % resolve content (automatic resolve option, all files of client view)
    fprintf(1,'Resolve results:\n')
    if strncmpi(sMsg,'No file',7)
        [sMsg,nStatus] = p4(sprintf('change -d %i',nChange));
        if nStatus
            fprintf(2,['No files in merge changelist, but removal of ' ...
                'changelist failed - please remove changelist %i manually.\nsMsg\n'],nChange,sMsg);
        else
            fprintf(1,'No files in merge changelist - removed changelist.\n')
        end
        return
    else
        disp(sMsg);
    end
elseif strcmp(sAction,'copy')
    % DEBUG: failed for  p4mergeChangeKeep('//DIVe/d_main','//DIVe/drm_0048',1,0) | p4 copy -c 11401 -P //DIVe/d_main -S //DIVe/drm_0048 -r
%     p4(sprintf('copy -c %i -P %s -S %s %s',nChange,sRcmParent,sRcmSource,sReverse)); % copy changes from source to target stream
    p4(sprintf('copy -c %i -S %s %s',nChange,sRcmSource,sReverse)); % copy changes from source to target stream
    xChange = hlxDescribeParse(nChange);
    if isempty(xChange.cFile)
        [sMsg,nStatus] = p4(sprintf('change -d %i',nChange));
        if nStatus
            fprintf(2,['No files in copy changelist, but removal of ' ...
                'changelist failed - please remove changelist %i manually.\nsMsg\n'],nChange,sMsg);
        else
            fprintf(1,'No files in copy changelist - removed changelist.\n')
        end
        return
    end
end



    
% split up the merge changelist and resolve
p4mergeChangeSplitUp(nChange,sHlxSource,sHlxTarget,bSelect,bSubmitDirect);
return

% =========================================================================

function [sRcmSource,sRcmParent,sAction,sReverse] = integrateAction(sHlxSource,sHlxTarget)
% INTEGRATEACTION determine the integration type and arguments from the
% next relevant non-virtual stream.
%
% Syntax:
%   [sRcmSource,sRcmParent,sAction,sReverse] = integrateAction(sHlxSource,sHlxTarget)
%
% Inputs:
%   sHlxSource - string with "source" stream for integration
%   sHlxTarget - string with "target" stream for integration
%
% Outputs:
%   sRcmSource - string with source/child stream of p4 command (option -S)
%   sRcmParent - string with parent stream in depot (p4 comman option -P)
%      sAction - string with action of legal stream relation
%     sReverse - string with reverse flag if necessary (else: empty)
%
% Example: 
%   [sRcmSource,sRcmParent,sAction,sReverse] = integrateAction('//DIVe/ddm_dev_mcmacm','//DIVe/drm_0047')
%   [sRcmSource,sRcmParent,sAction,sReverse] = integrateAction('//DIVe/dam_0048','//DIVe/dam_0047')
%   [sRcmSource,sRcmParent,sAction,sReverse] = integrateAction('//DIVe/drm_0048','//DIVe/drm_0047')
%   [sRcmSource,sRcmParent,sAction,sReverse] = integrateAction('//DIVe/dam_0047','//DIVe/dam_0048')
%   [sRcmSource,sRcmParent,sAction,sReverse] = integrateAction('//DIVe/drm_0047','//DIVe/drm_0048')
%   [sRcmSource,sRcmParent,sAction,sReverse] = integrateAction('//DIVe/drm_0048','//DIVe/d_main')
%   [sRcmSource,sRcmParent,sAction,sReverse] = integrateAction('//DIVe/d_main','//DIVe/drm_0048')
%   [sRcmSource,sRcmParent,sAction,sReverse] = integrateAction('//DIVe/dbm_platform','//DIVe/d_main')
%   [sRcmSource,sRcmParent,sAction,sReverse] = integrateAction('//DIVe/d_main','//DIVe/dbm_platform')
%   [sRcmSource,sRcmParent,sAction,sReverse] = integrateAction('//DIVe/ddc_dev_DIVe3D','//DIVe/d_main')
%   [sRcmSource,sRcmParent,sAction,sReverse] = integrateAction('//DIVe/d_main','//DIVe/ddc_dev_DIVe3D')
%   [sRcmSource,sRcmParent,sAction,sReverse] = integrateAction('//DIVe/drl_dev_eVeh','//DIVe/drl_dev_Concepts')
%   [sRcmSource,sRcmParent,sAction,sReverse] = integrateAction('//DIVe/drl_dev_Concepts','//DIVe/drl_dev_eVeh')
%
% See also: hlxZtagParse, integrateAction, p4

% get istat details
xSource = getStreamStat(sHlxSource);
xTarget = getStreamStat(sHlxTarget);

% get direction
cAction = {'merge','copy'};
if strcmp(sHlxTarget,xSource.parent) || ...
        strcmp(xTarget.stream,xSource.parent) || ...
        (isfield(xSource,'parentBase') && (...
         strcmp(sHlxTarget,xSource.parentBase) || ...
         strcmp(xTarget.stream,xSource.parentBase)))
    % target is related to parent of source
    sReverse = '';
    sRcmSource = sHlxSource;
    sRcmParent = sHlxTarget;
    sAction = xSource.integToParentHow;
    
elseif strcmp(sHlxSource,xTarget.parent) || ...
        strcmp(xSource.stream,xTarget.parent) || ...
        (isfield(xTarget,'parentBase') && (...
         strcmp(sHlxSource,xTarget.parentBase) || ...
         strcmp(xSource.stream,xTarget.parentBase)))
    % source is related to parent of target - reverse direction for copy
    sRcmSource = sHlxTarget;
    sRcmParent = sHlxSource;
    sAction = cAction{~strcmp(xTarget.integToParentHow,cAction)};
%     if strcmp(sAction,'copy')
        sReverse = '-r'; % reverse flag only with copy on release streams
%     else
%         sReverse = '';
%     end
else
    error('p4mergeChangeKeep:integrateAction','Integration case not covered');
end

if strcmp(sAction,'none')
    error('p4mergeChangeKeep:integrateAction','Integration case not covered - perhaps prohibited.');
end

% debugging outputonly
% if isempty(sReverse)
%     disp([sHlxSource,' -> ',sHlxTarget,'  ||| Child: ',sRcmSource,'  ->  Parent: ',sRcmParent,'  ||| Action: ',sAction,'  ',sReverse])
% else
%     disp([sHlxSource,' -> ',sHlxTarget,'  ||| Child: ',sRcmSource,'  ->  Parent: ',sRcmParent,'  ||| Action: ',sAction,'  ',sReverse])
% end
return

% =========================================================================

function xStream = getStreamStat(sStream)
% GETSTREAMSTAT get p4 istat infos of stream or next non-virtual parent
% stream.
%
% Syntax:
%   xStream = getStreamStat(sStream)
%
% Inputs:
%   sStream - string with stream path e.g. //DIVe/drm_0048
%
% Outputs:
%   xStream - structure with fields: 
%                    stream: string with stream '//DIVe/ddm_dev_mcmacm'
%                           (first non virtual related stream)
%                 streamOrg: string with stream '//DIVe/ddm_dev_mcmacm'
%                            (can be virtual)
%                    parent: string with parent of stream '//DIVe/drm_0047'
%                parentBase: [optional] string with next non-virtual stream '//DIVe/dam_0047' 
%                      type: string with stream type 'release'
%                parentType: string with 'release'
%          firmerThanParent: string with boolean value 'true'
%       changeFlowsToParent: string with boolean value 'true'
%     changeFlowsFromParent: string with boolean value 'false'
%             integToParent: string with boolean value 'true'
%          integToParentHow: action for integration into parent 'merge'/'copy' 
%
% Example: 
%   xStream = getStreamStat('//DIVe/d_main')

% ensure non-virtual stream
sStreamNV = getNonVirtual(sStream);

% get integration info of stream
xStream = hlxZtagParse(p4(sprintf('istat %s',sStreamNV)));
xStream.streamOrg = sStream;
return

% =========================================================================

function sStream = getNonVirtual(sStream)
% GETNONVIRTUAL get the next non-virtual Stream starting with the
% specified one and proceeding towards the parent in a reccursive function.
%
% Syntax:
%   sStream = getNonVirtual(sStream)
%
% Inputs:
%   sStream - string with stream path e.g. //DIVe/drm_0048
%
% Outputs:
%   sStream - string with non-virtual stream path e.g. //DIVe/dam_0048
%
% Example: 
%   sStream = getParentNonVirtual('/DIVe/drm_0048')

% get basic stream info
cOut = strsplitOwn(p4(sprintf('streams -F "Stream=%s"',sStream)),' ');
if strcmp(cOut{3},'virtual') % check stream type
    sStream = getNonVirtual(cOut{4}); % reccursion with parent stream
end
return

