function cChange = hlxChangeExport(cStream,nChangeStart,nChangeEnd,sFile)
% HLXCHANGEEXPORT export the relevant changes of the specified streams
% between the specified changelist numbers into an Excel file.
% 
% Intended for change description collection for platform release.
% - Unique changes are stored in an Excel list. 
% - Tags [] and {} are removed. 
% - Species of change is determined. 
% - species.family.type is determined. (Determine affected datasets?)
% - Changes on configurations are ignored.
%
% Syntax:
%   cChange = hlxChangeExport
%   cChange = hlxChangeExport(cStream)
%   cChange = hlxChangeExport(cStream,nChangeStart)
%   cChange = hlxChangeExport(cStream,nChangeStart,nChangeEnd)
%   cChange = hlxChangeExport(cStream,nChangeStart,nChangeEnd,sFile)
%
% Inputs:
%        cStream - cell (mxn) with strings of Helix streams and subfolders
%                  e.g. 
%   nChangeStart - integer (1x1) with first changelist of export {1}
%     nChangeEnd - integer (1x1) with last changelist of export {'now'}
%          sFile - string with export filename
%
% Outputs:
%   cChange - cell (mx3) with
%             (:x1) string with affected species
%             (:x2) string with changelist description
%             (:x3) integer (1x1) with changelist numer
%
% Example: 
%   cChange = hlxChangeExport
%   cStream = {'//DIVe/dam_platform/int/DIVe/Utilities'
%              '//DIVe/dam_platform/int/DIVe/Function'
%              '//DIVe/dam_0046/com/DIVe/Content'};
%   cChange = hlxChangeExport(cStream,2708,4044)
%
% See also: hlxChangeExport, hlxChangesParse, hlxOutParse, p4, strGlue
%
% Author: Rainer Frey, TP/EAC, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2019-01-25

% check input
if nargin < 1 || isempty(cStream)
    % determine last DIVeMB release stream and platform stream with subfolders 
    cStreams = hlxOutParse(p4('streams //DIVe/dam_*'),' ',2,true);
    nRel = cellfun(@str2double,regexp(cStreams(:,2),'\d{4}$','match','once'));
    nIdStreamMax = nRel == max(nRel);
    cStream = {[cStreams{nIdStreamMax,2} '/com/DIVe/Content'] , ...
               [cStreams{isnan(nRel),2} '/int/DIVe/Utilities']};
    sStreamRel = cStreams{nIdStreamMax,2};
    
    % determine oldest changelist of release stream
    nChangeStart = sscanf(p4(sprintf('changes -r -m 1 %s/...',sStreamRel)),'Change %i');
elseif nargin < 2
    nChangeStart = 1;
end
if nargin < 3
    nChangeEnd = 'now';
end
if isnumeric(nChangeEnd)
    % convert to string for case of 'now' input
    nChangeEnd = sprintf('%i',nChangeEnd);
end
if nargin < 4
    sFile = fullfile(pwd,'ChangeExport.xlsx');
end
       
% determine search scope of changes
cSpecies = {};
for nIdxStream = 1:numel(cStream)
    % determine Species and add sorting scheme (species name or 'system')
    if any(strfind(cStream{nIdxStream},'Content'))
        cContext = hlxOutParse(p4(sprintf('dirs %s',...
                      strGlue({cStream{nIdxStream},'*'},'/'))),' ',1,true);
        % loop over context to get all relevant species
        for nIdxContext = 1:numel(cContext)
            cSpeciesAdd = hlxOutParse(p4(sprintf('dirs %s',...
                      strGlue({cContext{nIdxContext},'*'},'/'))),' ',1,true);
            cSpecies = [cSpecies; [cSpeciesAdd regexp(cSpeciesAdd,'(?<=/)[^/]+(?=/*)$','match','once')]]; %#ok<AGROW>
        end
        
    elseif any(strfind(cStream{nIdxStream},'Utilities')) % platform stuff
        cSpecies = [cSpecies; [cStream(nIdxStream) {'system'}]]; %#ok<AGROW>
    else % anything else
        cSpecies = [cSpecies; [cStream(nIdxStream) {'other'}]]; %#ok<AGROW>
    end
end

% search for changes
cChange = cell(0,3);
for nIdxSpecies = 1:size(cSpecies,1)
    % query changes
    sMsg = p4(sprintf('changes -l %s/...@%i,@%s',...
              cSpecies{nIdxSpecies},nChangeStart,nChangeEnd));
    % system call
    if isempty(sMsg)
        fprintf(2,'No changelists found for species "%s".\n',cSpecies{nIdxSpecies});
        continue
    end
    
    % process Helix output
    %   cChange - cell (mx6) with changelist information
    %             (:x1) integer (1x1) with changelist number
    %             (:x2) string with date (and time in case of -t option)
    %             (:x3) string with submitter of change
    %             (:x4) string with workspace of change
    %             (:x5) string with description of change
    %             (:x6) string with collection tag of change
    cChangeAdd = hlxChangesParse(sMsg);
    cChange = [cChange; [repmat(cSpecies(nIdxSpecies,2),size(cChangeAdd,1),1) ...
                         cChangeAdd(:,5) cChangeAdd(:,1)]]; %#ok<AGROW>
    
end

% filter changes
bKeep = cellfun(@isempty,regexp(cChange(:,2),...
            ['^Copying|^Copy|^Initial filling|^Initial branch|'...
             'Update from|^Wrong migration|^update lic|license'],'once'));
% bKeep = cellfun(@isempty,regexp(cChange(:,2),...
%             ['^Merging|^Copying|^Copy|^Initial filling|^Initial branch|'...
%              'Update from|^Wrong migration|^update lic|license'],'once'));
cChange = cChange(bKeep,:);

% remove empty changelist entries
bEmpty = cellfun(@isempty,cChange(:,3));
cChange = cChange(~bEmpty,:);

% sort according changelist number
[nTrash,nSort] = sort(cell2mat(cChange(:,3))); %#ok<ASGLU>
cChange = cChange(nSort,:);

% determine DIVe logical hierarchy of non-system changes
bSystem = ismember(cChange(:,1),{'system','other'});
nChangeContent = unique(cell2mat(cChange(~bSystem,3)));
xChange = hlxDescribeParse(nChangeContent); % get details of change
for nIdxChange = 1:size(cChange,1)
    % identify change in structure
    bThis = cChange{nIdxChange,3} == [xChange.nChange];
    if ~any(bThis)
        continue
    end
    cFileLogHier = regexp(xChange(bThis).cFile,['(?<=/Content/).+' ...
                          '(?=/Data|/Module|/Support)'],'match','once');
    cFileLogHier = unique(cFileLogHier); % reduce to relevant changes
    cFileLogHier = cFileLogHier(~cellfun(@isempty,cFileLogHier)); % remove empty/non-Content 
    cFileLogHier = regexprep(cFileLogHier,'/','.'); % replace / by .
    
    % reduce to logical hierarchies of species
    bSpeciesThis = ~cellfun(@isempty,regexp(cFileLogHier,...
        ['(?<=^(bdry|ctrl|human|phys|pltm)\.)' cChange{nIdxChange,1}],'once'));
    cFileLogHier = cFileLogHier(bSpeciesThis);
    
    % compress logical hierarchy for changes on many types/families
    if numel(cFileLogHier) > 2
        % check for type variance
       [cMatch,cVar] = regexp(cFileLogHier,'^\w+\.\w+\.?\w*','match','split','once');
       cVar = cellfun(@(x)x{2}(2:end),cVar,'UniformOutput',false);
       cLogHierReduce = unique(cMatch);
       
       % check for success
       if numel(cLogHierReduce) > 2
           [cMatch,cVar] = regexp(cFileLogHier,'^\w+\.\w+','match','split','once');
           cVar = cellfun(@(x)x{2}(2:end),cVar,'UniformOutput',false);
           cLogHierReduce = unique(cMatch);       
       end
       
       % compress output
       cFileLogHier = {[strGlue(cLogHierReduce,', ') ' (' strGlue(cVar,', ') ')']};
    end
    
    % remove Content./sMP. from description
    cChange{nIdxChange,2} = regexprep(cChange{nIdxChange,2},{'^Content\.','^sMP\.'},{'',''});
    
    % ensure logical hierarchy at description start
    if ~isempty(cFileLogHier)
        if ~strcmp(cFileLogHier{1},cChange{nIdxChange,2}...
                (1:min(numel(cFileLogHier{1}),numel(cChange{nIdxChange,2}))))
            cChange{nIdxChange,2} = [strGlue(cFileLogHier,', ') ' ' cChange{nIdxChange,2}];
        end
    end
end

% add columns of DIVeMB VersionHistory
if exist('sStreamRel','var')
    cChange = [repmat({max(nRel)},size(cChange,1),1) cChange(:,1:2)...
               repmat({sprintf('B%04ib00/c00',max(nRel))},size(cChange,1),1) ...
               cell(size(cChange,1),1) cChange(:,3)  cChange(:,4)];
    % add header      
    cChange = [{'Build' 'Item' 'Description' 'Validation' 'Package' 'Changelist'}; cChange];
end

% write output also to Excel file
xlswrite(sFile,cChange,1);
xlsSheetEmptyDelete(sFile);
return
 
% =========================================================================

function sNonVirtual = hlxStreamParentNonVirtualNext(sStream)
% HLXSTREAMPARENTNONVIRTUALNEXT get the next non-virtual stream in
% inheritance/dependency starting from a specified stream. Return value may
% also be the specified stream itself.
%
% Syntax:
%   sNonVirtual = hlxStreamParentNonVirtualNext(sStream)
%
% Inputs:
%   sStream - string with a Perforce Helix stream e.g. //DIVe/dbm_platform
%
% Outputs:
%   sNonVirtual - string with a Perforce Helix stream, which is non-virtual 
%
% Example: 
%   sNonVirtual = hlxStreamParentNonVirtualNext('//DIVe/dbm_platform')

cType = {'virtual'};
while strcmp(cType{1},'virtual')
    % get current stream properties
    [cType,cParent] = hlxFormParse(p4(sprintf('stream -o %s',sStream)),...
        {'Type','Parent'});
    if strcmp(cType{1},'virtual')
        sStream = cParent{1};
    else
        sNonVirtual = sStream;
    end
end
return
