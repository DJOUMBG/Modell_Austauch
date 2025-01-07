function nChange = hlxChangeSplitDIVe(nChange,sLevel)
% HLXCHANGESPLITDIVE reopen the files of a changelist in the depot DIVe
% into own changelists for scripting, configurations and each module
% species. Can help to identify problematic content in large changelists.
%
% Syntax:
%   nChange = hlxChangeSplitDIVe(nChange)
%   nChange = hlxChangeSplitDIVe(nChange,sLevel)
%
% Inputs:
%   nChange - integer (1x1) with changelist number to be splitted
%    sLevel - string with level of Content splits
%               'species': one changelist per species
%               'family':  one changelist per family
%               'type':    one changelist per type
%               'element': one changelist per DIVe element: Module variant,
%                          DataSet variant, SupportSet
%
% Outputs:
%   nChange - integer (1xn) with changelist numbers of created changelists
%
% Example: 
%   nChange = hlxChangeSplitDIVe(666)
%   nChange = hlxChangeSplitDIVe(666,'species')
%
% See also: hlxDescribeParse, p4fileBatch
%
% Author: Rainer Frey, TP/EAC, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2020-01-17

if nargin < 2
    sLevel = 'species';
end  

% get changelist description and files
xChange = hlxDescribeParse(nChange);
[nStatus,sWorkspace,sPrevious] = p4switch(xChange.sWorkspace); %#ok<ASGLU>

%% split files into new changelists
%% split platform and scripting part
bFileScript = ~cellfun(@isempty,regexp(xChange.cFile,['^//DIVe/\w+/com/DIVe/Function|'...
    '^//DIVe/\w+/com/DIVe/Utilities|^//DIVe/\w+/int|^//DIVe/\w+/test'],'start','once'));

% create a changelist
nChangeNew = p4change(sprintf('%s - Scripting',xChange.sDescription),{},'public');
if isempty(nChangeNew)
    error('hlxChangeSplitDIVe:noChangelistGenerated','Changelist generation for Scripting has failed.')
end

% reopen files in new changelist
sMsg = p4fileBatch(sprintf('reopen -c %i %s',nChangeNew,'%s'),xChange.cFile(bFileScript),10); %#ok<NASGU>

%% split Content into level
switch sLevel
    case 'species'
        sExp = '(?<=^//DIVe/\w+/com/DIVe/Content/)\w+/\w+';
    case 'family'
        sExp = '(?<=^//DIVe/\w+/com/DIVe/Content/)\w+/\w+/\w+';
        % known limit - will capture shared datasets and support sets as family
    case 'type'
        sExp = '(?<=^//DIVe/\w+/com/DIVe/Content/)\w+/\w+/\w+/\w+';
        % known limit - will capture shared datasets and support sets as type 
    case 'element'
        sExp = ['(?<=^//DIVe/\w+/com/DIVe/Content/)\S+/Data/\w+/\w+|' ...
                '(?<=^//DIVe/\w+/com/DIVe/Content/)\S+/Module/\w+|' ...
                '(?<=^//DIVe/\w+/com/DIVe/Content/)\S+/Support/\w+'];
end

% determine split entities
cSplit  = regexp(xChange.cFile,sExp,'match','once');
cUnique = unique(cSplit);
cUnique = cUnique(~cellfun(@isempty,cUnique));
for nIdxUnique = 1:numel(cUnique)
    % get files of this entity
    bThis = strcmp(cUnique{nIdxUnique},cSplit);
    
    % create a changelist
    nChangeNew = p4change(sprintf('%s - Content: %s',xChange.sDescription,cUnique{nIdxUnique}),{},'public');
    if isempty(nChangeNew)
        error('hlxChangeSplitDIVe:noChangelistGenerated',...
            'Changelist generation for Content "%s" has failed.',cUnique{nIdxUnique});
    end
    
    % reopen files in new changelist
    sMsg = p4fileBatch(sprintf('reopen -c %i %s',nChangeNew,'%s'),xChange.cFile(bThis),10); %#ok<NASGU>
end

%% split Configurations
% determine configuration files
bFileConfiguration = ~cellfun(@isempty,regexp(xChange.cFile,'^//DIVe/\w+/com/DIVe/Configuration','start','once'));

% create a changelist
nChangeNew = p4change(sprintf('%s - Configurations',xChange.sDescription),{},'public');
if isempty(nChangeNew)
    error('hlxChangeSplitDIVe:noChangelistGenerated','Changelist generation for configuratiosn has failed.')
end

% reopen files in new changelist
sMsg = p4fileBatch(sprintf('reopen -c %i %s',nChangeNew,'%s'),xChange.cFile(bFileConfiguration),10); %#ok<NASGU>

% switch back to original workspace
p4switch(sPrevious);
return
