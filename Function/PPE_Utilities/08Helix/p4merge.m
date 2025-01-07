function nChange = p4merge(sHlxSource,sHlxTarget,nVerbose,cPath,cWorkspace,bExemptMFile)
% P4MERGE merge/copy the changes form a source stream to its
% parent or the specified target stream with option to limit the merge on
% specified pathes of a stream. Only generatates a changelist with resolved
% files - no submit.
%
% Syntax:
%   nChange = p4merge(sHlxSource)
%   nChange = p4merge(sHlxSource,sHlxTarget)
%   nChange = p4merge(sHlxSource,sHlxTarget,nVerbose)
%   nChange = p4merge(sHlxSource,sHlxTarget,nVerbose,cPath)
%   nChange = p4merge(sHlxSource,sHlxTarget,nVerbose,cPath,cWorkspace)
%   nChange = p4merge(sHlxSource,sHlxTarget,nVerbose,cPath,cWorkspace,bExemptMFile)
%
% Inputs:
%     sHlxSource - string with source stream in Helix depot notation
%     sHlxTarget - string with target stream in Helix depot notation
%       nVerbose - integer (1x1) with verbosity level (default: 0 = quiet)
%          cPath - cell (1xm) of strings with subpathes of depot to be
%                  integrated (merge/copy) in depot notation (slash
%                  separated: /folder1/folder2)
%     cWorkspace - cell (1xn) of strings with workspaces valid for 
%                  integration changelist
%
% Outputs:
%    nChange - integer (1x1) with number of pending changelist with
%              integrated files
% 
% 
% Example: 
%   p4merge('//DIVe/dam_0042') % -> merge to parent stream
%   p4merge('//DIVe/d_main','//DIVe/dam_0044') % -> copy from mainline needs 2nd argument 
%   p4merge('//DIVe/ddm_dev_eats') % -> copy changes to release stream
%   p4merge('//DIVe/ddm_dev_eats','//DIVe/dam_0044',true,false) % -> copy with selection of changes and do not submit 
%
% p4merge('//DIVe/ddm_dev_mcmacm','//DIVe/drm_0047',1,{})
% p4merge('//DIVe/dam_0048','//DIVe/dam_0047',1,{})
% p4merge('//DIVe/drm_0048','//DIVe/drm_0047',1,{})
% p4merge('//DIVe/dam_0047','//DIVe/dam_0048',1,{})
% p4merge('//DIVe/drm_0047','//DIVe/drm_0048',1,{})
% p4merge('//DIVe/drm_0048','//DIVe/d_main',1,{})
% p4merge('//DIVe/d_main','//DIVe/drm_0048',1,{})
% p4merge('//DIVe/dbm_platform','//DIVe/d_main',1,{})
% p4merge('//DIVe/d_main','//DIVe/dbm_platform',1,{})
% p4merge('//DIVe/ddc_dev_DIVe3D','//DIVe/d_main',1,{})
% p4merge('//DIVe/d_main','//DIVe/ddc_dev_DIVe3D',1,{})
% p4merge('//DIVe/drl_dev_eVeh','//DIVe/drl_dev_Concepts',1,{})
% p4merge('//DIVe/drl_dev_Concepts','//DIVe/drl_dev_eVeh',1,{})
% 
% See also: hlxOutParse, p4, p4change, p4merge, p4switch
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

[cParent,cType] = hlxFormParse(p4(sprintf('stream -o %s',sHlxSource)),{'Parent','Type'},' ',2,true); %#ok<ASGLU>
if nargin < 2 || isempty(sHlxTarget) % no target specified
    % determine Parent Stream as merge target and source stream type
    sHlxTarget = cParent{1};
end

if nargin < 3
    nVerbose = 0;
end
if nargin < 4
    cPath = {};
end
if nargin < 5
    cWorkspace = {};
end
if nargin < 6
    bExemptMFile = 1;
end

% switch to correct client/workspace
[sUser,sHost] = getenvOwn({'username','computername'});
cClient = hlxOutParse(p4(sprintf('clients -u "%s" -E "%s" -S "%s" ',...
    lower(sUser),['*',sHost,'*'],sHlxTarget)),' ',5,true);
if isempty(cClient)
    if nVerbose > 0
        fprintf(2,['No p4 client of target stream "%s" of this user on ' ...
                   'this computer known!\n'],sHlxTarget);
    end
    return
end
if ~isempty(cWorkspace)
    bKeep = ismember(cClient(:,2),cWorkspace);
    if ~any(bKeep)
        if nVerbose > 0
            fprintf(2,['The specified workspace "%s" is not valid or for the ' ...
                'target stream - stopped.\n'],cWorkspace{1});
        end
        return
    end
    cClient = cClient(bKeep,:);
end
p4switch(cClient{1,2});
sRoot = cClient{1,5}; % root folder of this client
cd(sRoot); % switch to root folder

% sync workspace to be up to date in files
if isempty(cPath)
    p4('sync'); 
else
    % path specific sync of files
    cFile = cellfun(@(x)strGlue( [{sHlxTarget}; strsplitOwn(x,'/'); {'...'}] ,'/'),...
                    cPath,'UniformOutput',false);
    p4fileBatch('sync %s',cFile,5);
end

% determine operation details
[sRcmSource,sRcmParent,sAction,sReverse] = integrateAction(sHlxSource,sHlxTarget);
if strcmp(sAction,'none')
    fprintf(1,'Stream %s cannot be integrated to %s - stopped p4merge.\n',sRcmSource,sRcmParent);
    nChange = [];
    return
end

% generate changelist
nChange = p4change(sprintf('Merge Container for %s from %s to %s',sAction,sHlxSource,sHlxTarget));
% start integration
if strcmp(sAction,'merge')
    
    
% p4 merge -c 22283 -S //DIVe/dam_platform -r -s //DIVe/dam_platform/com/DIVe/Function/DBC/...
% p4 merge -c 22318 -S //DIVe/dam_platform -r -s //DIVe/dam_platform/com/DIVe/Function/...


    if isempty(sReverse) % merge changes from source (child) to target (parent) stream
        if isempty(cPath)
            p4(sprintf('%s -c %i -S %s',sAction,nChange,sHlxSource)); 
        else % with path limitation
            for nIdxPath = 1:numel(cPath)
                p4(sprintf('%s -c %i -S %s -s %s',sAction,nChange,sHlxSource,...
                    strGlue({sHlxSource,cPath{nIdxPath},'...'},'/'))); 
            end
        end
    else % merge changes from parent to child/dev stream
        if isempty(cPath)
            p4(sprintf('%s -c %i -P %s -S %s %s',sAction,nChange,sRcmParent,sRcmSource,sReverse));
        else % merge with path limitation
            for nIdxPath = 1:numel(cPath)
                p4(sprintf('%s -c %i -P %s -S %s %s -s %s',sAction,nChange,sRcmParent,sRcmSource,sReverse,...
                    strGlue({sHlxSource,cPath{nIdxPath},'...'},'/')));
            end
        end
    end
    
    % resolve and cleanup
    sMsg = p4('resolve -am'); % resolve content (automatic resolve option, all files of client view)
    fprintf(1,'Resolve results:\n')
    if strncmpi(sMsg,'No file',7)
        [sMsg,nStatus] = p4(sprintf('change -d %i',nChange));
        nChange = [];
        if nStatus
            if nVerbose > 0
                fprintf(2,['No files in merge changelist, but removal of ' ...
                    'changelist failed - please remove changelist %i manually.\nsMsg\n'],nChange,sMsg);
            end
        else
            if nVerbose > 0
                fprintf(1,'No files in merge changelist - removed changelist.\n')
            end
        end
        return
    else
        disp(sMsg);
    end
    
elseif strcmp(sAction,'copy')
    if isempty(cPath) % plain copy
        % p4 copy -F -c 22290 -S //DIVe/dam_platform -s //DIVe/dam_platform/com/DIVe/Utilities/...
        % p4 copy -F -c 22290 -S //DIVe/dam_platform -s //DIVe/dam_platform/int/DIVe/Utilities/...
        % DEBUG: failed for  p4merge('//DIVe/d_main','//DIVe/drm_0048',1,0) | p4 copy -c 11401 -P //DIVe/d_main -S //DIVe/drm_0048 -r
        % p4(sprintf('copy -c %i -P %s -S %s %s',nChange,sRcmParent,sRcmSource,sReverse)); % copy changes from source to target stream
        p4(sprintf('copy -c %i -S %s %s',nChange,sRcmSource,sReverse)); % copy changes from source to target stream
    else % copy with path limitation
        for nIdxPath = 1:numel(cPath)
            p4(sprintf('copy -F -c %i -S %s %s -s %s',nChange,sRcmSource,sReverse,...
                strGlue({sHlxSource,cPath{nIdxPath},'...'},'/'))); % copy changes from source to target stream
        end
    end
    
    % check result of copy command and 
    xChange = hlxDescribeParse(nChange);
    
    % remove m-files from changelist TODO - special code for configuration  merge
    if ~isempty(xChange) && ~isempty(xChange.cFile) && bExemptMFile
        bKeep = true(size(xChange.cFile));
        for nIdxFile = 1:numel(xChange.cFile)
            if strcmp(xChange.cFile{nIdxFile}(end-1:end),'.m')
                bKeep(nIdxFile) = false;
            end
        end
        p4fileBatch(sprintf('revert -c %i %%s',nChange),xChange.cFile(~bKeep),8);
        xChange.cFile = xChange.cFile(bKeep);
        xChange.cFileAction = xChange.cFileAction(bKeep);
    end
    
    % remove changelist, if empty
    if isempty(xChange) || isempty(xChange.cFile)
        [sMsg,nStatus] = p4(sprintf('change -d %i',nChange));
        nChange = [];
        if nStatus
            if nVerbose > 0
                fprintf(2,['No files in copy changelist, but removal of ' ...
                    'changelist failed - please remove changelist %i manually.\nsMsg\n'],nChange,sMsg);
            end
        else
            if nVerbose > 0
                fprintf(1,'No files in copy changelist - removed changelist.\n')
            end
        end
        return
    end
end
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
    error('p4merge:integrateAction','Integration case not covered');
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

