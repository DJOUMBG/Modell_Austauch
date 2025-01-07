function xFile = dstFileTagCreate(sPath,cAttributeAsk,xPrevious,cExpression)
% DSTFILETAGCREATE create XML structure file entries with specified
% attributes.
% 
% Comfort detection of attribute 'isMain' with a single file or a single
% mdl/slx file in folder, which are directly tagged as 'isMain' without
% user selection.
% 
% If all files are attributed with 'isStandard' the attributes
% 'executeAtInit' and 'copyToRunDirectory' are assumed as false/'0'.
% 
% Part of "DIVe Simulink Transfer Package" (dst).
%
% Syntax:
%   xPart = dstFileTagCreate(sPath,cAttributeAsk)
%
% Inputs:
%           sPath - string with path of folder with files for tag
%   cAttributeAsk - cell (1xm) with strings of binary attributes and
%                   list dialogue for selection
%       xPrevious - structure with fields:
%         .name            - string with filename in specified directory
%         .<sAttributeAsk> - string {'0'/'1'} with selection for file
%     cExpression - cell (mx2) with
%                   (:,1): string with attribute name
%                   (:,2): string with regular expression to determine
%                          files with attribute value = true
%
% Outputs:
%   xFile - structure with fields describing an DIVe XML file entry: 
%    .name            - string with filename in specified directory
%    .<sAttributeAsk> - string {'0'/'1'} with selection for file
%
% Example: 
%   xTree.DataSet.DataFile = dstFileTagCreate(pwd,{'isStandard','executeAtInit','copyToRunDirectory'})
%
% See also: dirPattern, pathparts, searchstring2regexp
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2014-08-20

% check input
if nargin < 3
    xPrevious = struct();
end
if nargin < 4
    cExpression = {'',''}; 
end

% determine files of specified path
cSetFile = dirPattern(sPath,{'*'},'file');

% check UTF-8 conformity of filenames (rID0068)
bUtfViolation = cellfun(@(x)any(double(x)>127),cSetFile);
if any(bUtfViolation)
    fprintf(2,['Violation of allowed UTF-8 characters in filename of ' ...
               'file(s) in "%s":\n'],sPath);
    for nIdxFile = find(bUtfViolation)
        fprintf(2,'     %s\n',cSetFile{nIdxFile}); % list file
        sMark = repmat(' ',1,numel(cSetFile{nIdxFile}));
        [sMark(cSetFile{nIdxFile}>127)] = deal('^');
        fprintf(2,' Err:%s\n',sMark);
    end
    fprintf(2,'(XML creation stopped)\n');
    error('dstFileTagCreate:nonUTF8char',['non UTF-8 character in file name ' ...
          '(violation of rID0068)']);
end

% remove own XML description if present
cPath = pathparts(sPath);
bKeep = ~ismember(cSetFile,[cPath{end} '.xml']); % create boolean vector
cSetFile = cSetFile(bKeep); % remove own instance XML file

% get all file extensions
cFileExtension = cellfun(@(x)regexp(x,'(?<=\.)\w+$','match','once'),cSetFile,'UniformOutput',false); 

% remove DIVe unique ID file
bKeepDid = ~strcmp(cFileExtension,'did');
bKeepTumbsDB = cellfun(@isempty,regexpi(cSetFile,'thumbs\.db$','once'));
cSetFile = cSetFile(bKeepDid&bKeepTumbsDB); 

% get attribute info - loop is over attribute with sametime query over all files
bAllStandard = false; % dialogue blocker bit
for nIdxAttribute = 1:numel(cAttributeAsk)
    % init selection vector
    xAttribute.(cAttributeAsk{nIdxAttribute}) = false(1,numel(cSetFile)); 
    
    % attribute determination by regular expression
    [bRegStatus,bRegFile] = dstFileTagByExpression(cAttributeAsk{nIdxAttribute},cSetFile,cExpression);

    
    % user selection or special handlings  
    if bRegStatus
        % use attribute value from regular expression determination
        xAttribute.(cAttributeAsk{nIdxAttribute}) = bRegFile;
        
    elseif isfield(xPrevious,cAttributeAsk{nIdxAttribute}) && ...
            numel(cSetFile) == numel(xPrevious) && ...
            all(ismember(cSetFile,{xPrevious.name}))
        % determine attribute value from previous XML
        [bTF,nSort] = ismember({xPrevious.name},cSetFile); %#ok<ASGLU> % determine sort vector
        bPrevious = [xPrevious.(cAttributeAsk{nIdxAttribute})]; % get vector of previous attribute
        bPrevious = bPrevious(nSort); % resort attribute values according current file set
        xAttribute.(cAttributeAsk{nIdxAttribute}) = bPrevious;
        
    elseif bAllStandard && ismember(cAttributeAsk{nIdxAttribute},{'executeAtInit','copyToRunDirectory'})
        % no dialogue - only standard parameter files here, so
        % executeAtInit and copyToRunDirectory are no real option
        
    elseif strcmp(cAttributeAsk{nIdxAttribute},'isMain') && ... % if isMain option of Module's ModelSet
            numel(cSetFile)==1 % single file must be main file
        xAttribute.(cAttributeAsk{nIdxAttribute})(1) = true;
        
    elseif strcmp(cAttributeAsk{nIdxAttribute},'isMain') && ... % if isMain option of Module's ModelSet
            sum(strcmpi(cFileExtension,'mdl'))+sum(strcmpi(cFileExtension,'slx')) == 1 % single simulink file must be main file
        xAttribute.(cAttributeAsk{nIdxAttribute}) = strcmpi(cFileExtension,'mdl') | strcmpi(cFileExtension,'slx');
        
    elseif strcmp(cAttributeAsk{nIdxAttribute},'isMain') && ... % if isMain option of Module's ModelSet
            numel(cFileExtension) == 2 && ...
            sum(strcmpi(cFileExtension,'mdl')) == 1 && ...
            sum(strcmpi(cFileExtension,'slx')) == 1 % if only one mdl and one slx, mdl is main file
        xAttribute.(cAttributeAsk{nIdxAttribute}) = strcmpi(cFileExtension,'mdl');
        
    elseif strcmp(cAttributeAsk{nIdxAttribute},'isMain') && ... % if isMain option of Module's ModelSet
            sum(strcmpi(cFileExtension,'dll')) == 1 % single dll file must be main file (request of DIVeCB)
        xAttribute.(cAttributeAsk{nIdxAttribute}) = strcmpi(cFileExtension,'dll');
        
    elseif strcmp(cAttributeAsk{nIdxAttribute},'copyToRunDirectory') && ... % if only mdl and slx files,  no copyToRunDirectory
            numel(cFileExtension) == sum(strcmpi(cFileExtension,'mdl'))+sum(strcmpi(cFileExtension,'slx')) 
        % keep false init for attribute copyToRunDirectory
        
    elseif strcmp(cAttributeAsk{nIdxAttribute},'copyToRunDirectory') && ...
            numel(cFileExtension) == 2 && ...
            sum(strcmpi(cFileExtension,'mdl'))+sum(strcmpi(cFileExtension,'slx')) == 1 && ...
            sum(strcmpi(cFileExtension,'mexw32'))+sum(strcmpi(cFileExtension,'mexw64')) == 1 % if only one mdl/slx and one mex, no copyToRunDirectory
        xAttribute.(cAttributeAsk{nIdxAttribute}) = false(1,2);
        
    else % user selection of attribute value
        nSelection = listdlg('ListString',cSetFile,...
            'Name',['Select files which need ' cAttributeAsk{nIdxAttribute}],...
            'ListSize',[300,300]); % dialogue window
        xAttribute.(cAttributeAsk{nIdxAttribute})(nSelection) = true; % assign selection vector
    end
    
    % set bit to block dialogues for executeAtInit and copyToRunDirectory
    % when all files are standard parameter files
    if strcmp(cAttributeAsk{nIdxAttribute},'isStandard') && ...
            all(xAttribute.(cAttributeAsk{nIdxAttribute}))
        bAllStandard = true;
    end
end

% loop over files to create structure entries
xFile = struct;
for nIdxFile = 1:numel(cSetFile)
    xFile(nIdxFile).name = cSetFile{nIdxFile}; % add filename
    % add binary attributes
    for nIdxAttribute = 1:numel(cAttributeAsk)
        xFile(nIdxFile).(cAttributeAsk{nIdxAttribute}) = num2str(xAttribute.(cAttributeAsk{nIdxAttribute})(nIdxFile));
    end
end
return

% =========================================================================

function [bRegStatus,bRegFile] = dstFileTagByExpression(sAttribute,cSetFile,cExpression)
% DSTFILETAGBYEXPRESSION determine attribute values for specified files
% according attribute/regular expression pairs.
%
% Syntax:
%   [bRegStatus,bRegFile] = dstFileTagByExpression(sAttribute,cSetFile,cExpression)
%
% Inputs:
%    sAttribute - string with attibute name
%      cSetFile - cell (1xn) with strings filename
%   cExpression - cell (mx2) with
%                   (:,1): string with attribute name
%                   (:,2): string with regular expression to determine
%                          files with attribute value = true
%
% Outputs:
%   bRegStatus - boolean for successful regular expression determination
%     bRegFile - boolean (1xn) with attribute option for each file
%
% Example: 
%   [bRegStatus,bRegFile] = dstFileTagByExpression(sAttribute,cSetFile,cExpression)

% init output
bRegStatus = false;
bRegFile = false(1,numel(cSetFile));

% determine regular expression
bRegUse = strcmp(sAttribute,cExpression(:,1));

if any(bRegUse)
    % check files for regular expression
    bRegFile = ~cellfun(@isempty,regexp(cSetFile,cExpression{bRegUse,2},'once'));
    bRegStatus = true;
end
return
