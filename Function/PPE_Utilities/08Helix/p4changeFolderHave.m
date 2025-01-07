function cChange = p4changeFolderHave(cFolder)
% P4CHANGEFOLDERHAVE determine most recent synced changelist of the
% specified folders. If a file is specified, the function operates still on
% the whole containing folder!
% Caution: If the user has manually synced only folder parts, the output
% might be not consistent. 
%
% Syntax:
%   cChange = p4changeFolderHave(cFolder)
%
% Inputs:
%   cFolder - cell (1xn) with strings of Perforce depot pathes or file
%             system pathes within a workspace
%             or string with path
%
% Outputs:
%   cChange - string or cell array (nx1) of strings with matching 
%             have/synced changelists of specified folders
%
% Example: 
%   cChange = p4changeFolderHave({'//DIVe/d_main/com/DIVe/Function/DPS','//DIVe/d_main/com/DIVe/Function/CHK'})
%   cChange = p4changeFolderHave({'//DIVe/d_main/com/DIVe/Content/phys/test/simple/dummy/Module/std/std.xml' ...
%               '//DIVe/d_main/com/DIVe/Content/phys/test/simple/dummy/Module/open/std.xml'})
%
% See also: p4, p4fileBatch
%
% Author: Rainer Frey, TP/EAC, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2019-07-24

% check input
bChar = false;
if ischar(cFolder)
    % ensure cell array
    cFolder = {cFolder};
    bChar = true;
end
if ~iscell(cFolder)
    error('p4changeFolderHave:unkownInput',['The p4changeFolderHave ' ...
        'expects a cell array as cFolder input.']);
end
% % check consistency of input TODO check if really necessary, improved robustness below should return empty version ID string 
% nNumel = cellfun(@numel,cFolder);
% bRogue = nNumel <5;
% if any(bRogue)
%     % report rogue version ID values
%     nRogue = find(bRogue);
%     fprintf(2,'p4changeFolderHave: following folders from request cannot be processed (empty version ID)...\n');
%     for nIdxRogue = 1:numel(nRogue)
%         fprintf(2,' %i: "%s"\n',nRogue(nIdxRogue),cFolder{nRogue(nIdxRogue)});
%     end
% end

% initialize Output
cChange = cell(size(cFolder));

% prepare folder requests
cFolder = strrep(cFolder,'...','');
cFolderPure = cell(size(cFolder));
for nIdxFolder = 1:numel(cFolder)
    [sPath,sFile,sExt] = fileparts(cFolder{nIdxFolder});
    if ~isempty(sPath)
        sSeparator = cFolder{nIdxFolder}(numel(sPath)+1);
        if isempty(sExt) % folder
            cFolderPure{nIdxFolder} = strGlue({sPath,sFile},sSeparator);
        else % file -> take containing folder
            cFolderPure{nIdxFolder} = strGlue({sPath},sSeparator);
        end
    end % if
end % for 
cFolderDot = cellfun(@(x)fullfileSL(x,'...'),cFolderPure,'UniformOutput',false);
cFolderHave = cellfun(@(x)[x '#have'],cFolderDot,'UniformOutput',false);

% ensure correct workspace
[nStatus,sWorkspace,sPrevious] = p4switch(cFolderPure{1},0); %#ok<ASGLU>

% check for reconcile states
xReconcile = hlxZtagParse(p4fileBatch('-z tag reconcile -aed -n %s',cFolderDot,15));
if isempty(xReconcile)
    % no reconciles - all files are actual in Perforce
    bNoReq = false(size(cFolderPure));
else
    % handle reconcile output according action
    cAction = {xReconcile.action};
    bAdd = strcmp('add',cAction);
    bEdit = strcmp('edit',cAction);
    
    % remove add and edit directories from request
    cFileRemove = {xReconcile(bAdd|bEdit).clientFile};
    cPathRemove = unique(cellfun(@fileparts,cFileRemove,'UniformOutput',false));
    
    % loop over folders for p4 changes determination
    bNoReq = false(size(cFolderPure));
    for nIdxPath = 1:numel(bNoReq)
        % compare if folder contains a reconcile operation -> exempt from
        % p4 have as version ID is unknown due to pendig submit
        bNoReq(nIdxPath) = any(strcmp(cFolderPure{nIdxPath},...
            cellfun(@(x)x(1:min(numel(x),numel(cFolderPure{nIdxPath}))),...
                    cPathRemove,'UniformOutput',false)));
    end
end

% exempt non existent folders
for nIdxFolder = 1:numel(cFolderPure)
    if ~isempty(cFolderPure{nIdxFolder}) && ...
            ~strcmp(cFolderPure{nIdxFolder}(1),'/') && ...
            ~exist(cFolderDot{nIdxFolder}(1:end-min(3,numel(cFolderDot{nIdxFolder})-1)),'dir')
        bNoReq(nIdxFolder) = true;
    end
end
    
% patch no search folders with empty changelist feedback
cChange(bNoReq) = deal({''});
if all(bNoReq)
    return
end

% request Perforce changelists
cChangeReq = hlxOutParse(p4fileBatch('changes -m 1 %s',cFolderHave(~bNoReq),15),' ',2,true);
if size(cChangeReq,1) == sum(~bNoReq)
    % assign cumulated changelists to output
    cChangeDeal = cChangeReq(:,2)';
    cChange(~bNoReq) = deal(cChangeDeal(:));
else
    % at least one changelist request failed - loop on single calls
    fprintf(2,['Cumulated version request to Helix failed - switching to ' ...
               'single mode...\nThis may take some time. To improve ' ...
               'performance, please handle folders below differently:\n']);
    nReq = find(~bNoReq);
    if size(nReq,1) > size(nReq,2)
        nReq = nReq';
    end
    for nIdxFolder = nReq
        sMsg = p4(sprintf('changes -m 1 %s',cFolderHave{nIdxFolder}));
        if isempty(sMsg)
            % can happen, when rights are missing or reconcile exemptions
            % are not correctly handled or copied/changed files which are
            % "imported" (stream does not allow upload)
            fprintf(1,['Empty feedback during call "p4 changes -m 1" with ' ...
                'folder: %s\nThese files are not known to Perforce Helix ' ...
                'or you do not have the access rights for them or your ' ...
                'folders are set to import.\n'],cFolderHave{nIdxFolder});
            cChange(nIdxFolder) = {''};
        else
            % parse message
            cChangeSingle = hlxOutParse(sMsg,' ',2,true);
            if strcmp(cChangeSingle{1,1},'Change') && ~isnan(str2double(cChangeSingle{1,2}))
                cChange(nIdxFolder) = cChangeSingle(1,2);
            else
                fprintf(2,['Unknown feedback during call "p4 changes -m 1" with ' ...
                    'folder: %s\nPlease report this message together with folder details.\%s\n'],...
                    cFolderHave{nIdxFolder},sMsg);
                cChange(nIdxFolder) = {''};
            end 
        end % if
    end %for
end % if
% switch back to original workspace
if ~strcmp(sWorkspace,sPrevious)
    p4switch(sPrevious,0);
end

% shape output
if numel(cChange) == 1 && bChar
    % single call output string
    cChange = cChange{1};
else
    % multi-call output cell
end
return
