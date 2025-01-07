function xTree = dsxRead(sFile,bEntityCheckAll,nVerbose,bBlank)
% DSXREAD read a XML file into an special MATLAB structure.
% The structure can be with flattened Contents or Attributes into fields
% and element nodes are typical further structure branches.
%
% Syntax:
%   xTree = dsxRead(sFile)
%   xTree = dsxRead(sFile,bEntityCheckAll)
%   xTree = dsxRead(sFile,bEntityCheckAll,nVerbose)
%   xTree = dsxRead(sFile,bEntityCheckAll,nVerbose,bBlank)
%
% Inputs:
%             sFile - string with xml filename
%   bEntityCheckAll - [optional] boolean (1x1) for character entity conversion
%                       0: {default} check only defined list of Attributes
%                       1: check all attributes for char entities
%          nVerbose - integer with verbosity level (0: no warnings, 1:warnings)
%            bBlank - boolean (1x1) for if blanks are allowed around "="
%                     for XML parsing (default:0 not allowed)
%
% Outputs:
%   xTree - structure with fields: 
%
% Example: 
%   xTree = dsxRead('C:\dirsync\06DIVe\03Platform\com\Content\phys\test\simple\dummy\Module\std\std.xml')
%   xTree = dsxRead('c:\temp\modelDescription.xml',bEntityCheckAll)
%   xTree = dsxRead(sFile,bEntityCheckAll,nVerbose)
%   xTree = dsxRead('c:\temp\modelDescription.xml',0,0,1)
%
% Subfunctions: dsxMarkupParse
% Other m-files required: parseArgs
%
% See also: parseArgs 
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2014-06-12

% check inputs
if exist(sFile,'file')~=2
    error('dsxRead:fileNotFound',['The specified file is not on the file ' ...
          'system: %s'],sFile);
end
if nargin < 2
    bEntityCheckAll = false;
end
if nargin < 3
    nVerbose = 1;
end
if nargin < 4
    bBlank = false;
end

% initialize output
xTree = struct; %#ok<NASGU>

%% determine encoding declaration
% MATLAB standard encondings
cMatlabEncoding = {'Big5','EUC-JP','GBK','ISO-8859-1','ISO-8859-2',...
    'ISO-8859-3','ISO-8859-4','ISO-8859-9','ISO-8859-13','ISO-8859-15',...
    'Shift_JIS','US-ASCII','UTF-8','windows-932','windows-936',...
    'windows-949','windows-950','windows-1250','windows-1251',...
    'windows-1252','windows-1253','windows-1254','windows-1257'};

% get first line
nFID = fopen(sFile);
if nFID < 0
    error('dsxRead:openFile',...
          ['dsxRead was not able to open the file with "fopen": ' sFile]);
else % file successful opened
    sLine = fgetl(nFID); % get first line
    fclose(nFID);
    if isempty(sLine)
        error('dsxRead:emptyFirstLine',['dsxRead encountered an empty first' ...
            'line in file - not according XML standards: "%s"'],sFile);
    end
end

% parse line for encoding information
[sTag,xAttribute] = dsxMarkupParse(strtrim(sLine),false,false); %#ok<ASGLU>
if isfield(xAttribute,'encoding')
    sEncoding = xAttribute.encoding;
    if ~ismember(sEncoding,cMatlabEncoding)
        sEncoding = 'UTF-8';
    end
else
    sEncoding = 'UTF-8';
end

% read file
nFID = fopen(sFile,'r','n',sEncoding);
if verLessThanMATLAB('8.4.0')
    ccLine = textscan(nFID,'%s','delimiter','\n','whitespace','','bufsize',65536); %#ok<BUFSIZE>
else
    ccLine = textscan(nFID,'%s','delimiter','\n','whitespace','');
end
cLine = ccLine{1};
fclose(nFID);
[cMarkup,cContent] = dsxMarkupSplit(cLine);

% parse file content
xTree = dsxTreeBuild(struct(),cMarkup,cContent,0,bEntityCheckAll,nVerbose,bBlank);
return

% =========================================================================

function [cMarkup,cContent] = dsxMarkupSplit(cLine)
% DSXMARKUPSPLIT split a cell with strings into single markups.
%
% Syntax:
%   [cMarkup,cContent] = dsxMarkupSplit(sLine)
%
% Inputs:
%   cLine - cell with strings of an XML file line each
%
% Outputs:
%    cMarkup - cell with strings of XML markups 
%   cContent - cell with strings of XML content between markups 
%
% Example: 
%   [cMarkup,cContent] = dsxMarkupSplit(sLine)

% get position of markups for complete cell cLine
cMupOpen = strfind(cLine,'<');
cMupClose = strfind(cLine,'>');
cCdataOpen = strfind(cLine,'<![CDATA[');
cCdataClose = strfind(cLine,']]>');

% initialize
cMarkup = cell(numel(cLine),1);
cContent = cell(numel(cLine),1);
nActual = 0;
sRest = '';
bMarkup = false;
bCdata = false;

% parse all lines
for nIdxLine = 1:numel(cLine)
    % check and enlarge pre-allocation of variables
    if nIdxLine > max(numel(cMarkup),numel(cContent))
        cMarkup{nIdxLine + 2000} = [];
        cContent{nIdxLine + 2000} = [];
    end
    
    % init line search for markup entities
    nCharLast = 0; % line marker for transferred characters
    nEntity = 0; % line marker for evaluated markup entities
    
    % loop until no markup or content in line is left
    while nCharLast < numel(cLine{nIdxLine})
        
        % get next entity position, action and state booleans
         [nEntity,nChar,sType,bMarkup,bCdata] = dsxEntityNext(nEntity,...
             cMupOpen{nIdxLine},cMupClose{nIdxLine},cCdataOpen{nIdxLine},...
             cCdataClose{nIdxLine},bMarkup,bCdata);
         if isempty(nEntity) % no entity found - use rest of line
             nEntity = numel(cLine{nIdxLine});
             nChar = numel(cLine{nIdxLine});
         end
        
        % derive/add string
        sNew = dsxCharClean(cLine{nIdxLine}(nCharLast+1:nChar));
        nCharLast = nChar;
        if isempty(sRest) % one line
            sRest = sNew;
        elseif ~isempty(sNew) % preserve carriage return
            sRest = [sRest ' ' char(10) sNew]; %#ok<CHARTEN,AGROW>
        end
        
        % create element if applicable
        switch sType
            case 'Content'
                if ~isempty(sRest)
                    if nActual > 0
                        cContent{nActual} = sRest;
                    end
                    sRest = '';
                end
            case 'Markup' % and CDATA
                nActual = nActual + 1;
                cMarkup{nActual} = sRest;
                sRest = '';
            case 'add'
                % just collect string
        end
    end % while line is not empty
end % for all lines

% reduce result cells to used range
cMarkup = cMarkup(1:nActual);
cContent = cContent(1:min(nActual,numel(cContent)));
return

% =========================================================================

function [nEntity,nChar,sType,bMarkup,bCdata] = dsxEntityNext(nEntity,nMupOpen,...
                            nMupClose,nCdataOpen,nCdataClose,bMarkup,bCdata)
% DSXLINEPOSNEXT determine next entity of special tag characters and the
% content type of the content up to the entity.
%
% Syntax:
%   [nEntity,nChar,sType,bMarkup,bCdata] = dsxEntityNext(nEntity,nMupOpen,...
%                           nMupClose,nCdataOpen,nCdataClose,bMarkup,bCdata)
%
% Inputs:
%        nEntity - integer (1x1) with the last evaluated entity position in line
%       nMupOpen - integer (1xn) with positions of markup open "<" in line
%       nMupClose - integer (1xn) with positions of markup close ">" in line
%      nCdataOpen - integer (1xn) with positions of CDATA open "<![CDATA[" in line
%     nCdataClose - integer (1xn) with positions of CDATA close "]]>" in line
%         bMarkup - boolean to indicate an open markup
%          bCdata - boolean to indicate an open CDATA markup
%
% Outputs:
%       nEntity - integer (1x1) with position of entity (first character for
%                 open, last character for close
%         nChar - integer (1x1) with position of string to read
%         sType - string with action type, what to create from string
%       bMarkup - boolean to indicate an open markup
%        bCdata - boolean to indicate an open CDATA markup
%
% Example: 
%   [nEntity,nChar,sType,bMarkup,bCdata] = dsxEntityNext(nEntity,nMupOpen,...
%       nMupClose,nCdataOpen,nCdataClose,bMarkup,bCdata)

% build sort vector
if bCdata % inside a CDATA tag 
    % other markups are just value content 
    nPos = [nCdataOpen,nCdataClose];
    nId = [ones(size(nCdataOpen)).*3,ones(size(nCdataClose)).*4];
else % search for all tags
    nPos = [nCdataOpen,nCdataClose,nMupOpen,nMupClose];
    nId = [ones(size(nCdataOpen)).*3 , ones(size(nCdataClose)).*4,...
           ones(size(nMupOpen))  .*1 , ones(size(nMupClose))  .*2];
end
    
% resort entity positions
[nPos,nSort] = sort(nPos);
nId = nId(nSort);

% reduce to entities in unused line part
bUnused = nPos > nEntity;
nPos = nPos(bUnused);
nId = nId(bUnused);

% determine action type
if isempty(nPos) % no entity in rest of line - add rest to existing rest 
    sType = 'add';
    nEntity = [];
    nChar = [];
    
else % entity found in line 
    
    % error cases
    if bMarkup && nId(1) == 1
        error('dsxRead:dsxEntityNext:openInsideMarkup',...
            'Encountered markup open sign "<" inside a markup')
    end
    if bCdata && nId(1) == 1
        error('dsxRead:dsxEntityNext:openInsideMarkup',...
            'Encountered CDATA open sign "<![CDATA[" inside a markup')
    end
    if bCdata && nId(1) == 3
        error('dsxRead:dsxEntityNext:openInsideCdata',...
            'Encountered CDATA open sign "<![CDATA[" inside a CDATA block')
    end
    
    % determine action type for entity
    switch nId(1)
        case 1 % MarkupOpen
            sType = 'Content';
            nEntity = nPos(1);
            nChar = nPos(1) - 1;
            bMarkup = true;
        case 2 % MarkupClose
            sType = 'Markup';
            nEntity = nPos(1);
            nChar = nPos(1);
            bMarkup = false;
        case 3 % CdataOpen
            sType = 'Content';
            nEntity = nPos(1);
            nChar = nPos(1) - 1;
            bCdata = true;
        case 4 % CdataClose
            sType = 'Markup';
            nEntity = nPos(1) + 2;
            nChar = nPos(1) + 2;
            bCdata = false;
    end
end
return

% =========================================================================

function [xTree,nActual] = dsxTreeBuild(xTree,cMarkup,cContent,nActual,bEntityCheckAll,nVerbose,bBlank)
% DSXTREEBUILD recursive function to build a MATLAB structure from an XML
% file.
%
% Syntax:
%   [xTree,nActual] = dsxTreeBuild(xTree,cMarkup,cContent,nActual,bEntityCheckAll)
%   [xTree,nActual] = dsxTreeBuild(xTree,cMarkup,cContent,nActual,bEntityCheckAll,nVerbose)
%   [xTree,nActual] = dsxTreeBuild(xTree,cMarkup,cContent,nActual,bEntityCheckAll,nVerbose,bBlank)
%
% Inputs:
%      xTree - structure to add the tree contained in 
%    cMarkup - cell (1xn) with all markups
%   cContent - cell (1xn) with content in a markup
%    nActual - integer (1x1) with depth level
%   bEntityCheckAll - boolean (1x1) for character entity conversion
%                       0: check only defined list of Attributes
%                       1: check all attributes for char entities
%   nVerbose - integer with verbosity level (0: no warnings, 1:warnings)
%     bBlank - boolean (1x1) for if blanks are allowed around "=" for XML parsing
%
% Outputs:
%     xTree - structure with fields: 
%   nActual - integer (1x1) 
%
% Example: 
%   [xTree,nActual] = dsxTreeBuild(xTree,cMarkup,cContent,nActual,bEntityCheckAll)

% check input
if nargin < 6
    nVerbose = 1;
end

% loop over markups
nSize = numel(cMarkup);
while nActual < nSize
    % evaluate next markup
    nActual = nActual+1;
    [sTag,xAttribute,sType] = dsxMarkupParse(cMarkup{nActual},bEntityCheckAll,bBlank);
    if ~isvarname(sTag)
        sTag = genvarname(sTag); % ensure allowed field name for MATLAB
    end
    
    switch sType
        case 'TagStart'
            % add attributes to level
            xTreeAdd.(sTag) = xAttribute;
            
            % add content
            if nActual<=numel(cContent) && ~isempty(cContent{nActual})
                xTreeAdd.(sTag).cONTENT = cContent{nActual};
            end
            
            % add subtree
            [xTreeAdd.(sTag),nActual] = dsxTreeBuild(xTreeAdd.(sTag),...
                                cMarkup,cContent,nActual,bEntityCheckAll,nVerbose,bBlank);
            xTree = structAdd(xTree,xTreeAdd,nVerbose);
            xTreeAdd = struct();
        case 'TagEnd'
            break
        case 'TagEmpty'
            % add attributes to level
            xTreeAdd.(sTag) = xAttribute;
            xTree = structAdd(xTree,xTreeAdd,nVerbose);
            xTreeAdd = struct();
        case 'ProcessingInstruction'
            % no implementation
        case 'Comment'
            % no implementation
        case 'CDATA'
            % create CDATA attribute
            xTree.CDATA = xAttribute.CDATA;
        otherwise
            % no implementation
    end
end
return

% =========================================================================

function [sTag,xAttribute,sType] = dsxMarkupParse(sMarkup,bEntityCheckAll,bBlank)
% DSXMARKUPPARSE parse the tag and attributes of a single markup <...> into
% a structure with XML attributes represented as structure fields.
%
% Syntax:
%   [sTag,xAttribute] = dsxMarkupParse(sMarkup)
%   [sTag,xAttribute] = dsxMarkupParse(sMarkup,bEntityCheckAll,bBlank)
%
% Inputs:
%           sMarkup - string with a complete markup <...>
%   bEntityCheckAll - boolean (1x1) for character entity conversion
%                       0: check only defined list of Attributes
%                       1: check all attributes for char entities
%            bBlank - boolean (1x1) for if blanks are allowed around "="
%                     for XML parsing
%
% Outputs:
%         sTag - string with tag name of the markup
%   xAttribute - structure with fields <attributeName> containing the
%                <attributeValue> of the markup
%
% Example: 
%   [sTag,xAttribute] = dsxMarkupParse(sMarkup)

% determine type
if strcmp('/>',sMarkup(end-1:end))
    sType = 'TagEmpty'; % CAUTION: also used single tag+attribute statements
elseif strcmp('</',sMarkup(1:2)) 
    sType = 'TagEnd';
elseif strcmp('<?',sMarkup(1:2)) && strcmp('?>',sMarkup(end-1:end))
    sType = 'ProcessingInstruction'; % processing instruction (alike definition header)
elseif strcmp('<!--',sMarkup(1:4)) && strcmp('-->',sMarkup(end-2:end))
    sType = 'Comment';
elseif numel(sMarkup)>9 && strcmp('<![CDATA[',sMarkup(1:9)) && strcmp(']]>',sMarkup(end-2:end))
    sType = 'CDATA';
else
    sType = 'TagStart';
end    

switch sType
    case 'CDATA'
        sTag = 'CDATA';
        xAttribute.CDATA = sMarkup(10:end-3);
    case 'TagEnd'
        sTag = sMarkup(3:end-1);
        xAttribute = struct();
    otherwise
        % standard markup
        % determine Tag of Markup
        sTag = regexp(sMarkup,'(?<=\<[/\?\!\-]*)(\w|:)+','match','once');
        
        % determine Attributes of Markup
        if ~bBlank
            % reduced DIVe parsing
            cAttributeName = regexp(sMarkup,'[\w:]+(?=\=")','match');
        else
            % allow blanks and formatting around "=" equal sign
            cAttributeName = regexp(sMarkup,'[\w:]+(?=\s*\=\s*")','match'); %neu
        end
        % old expression - can not capture empty attributes!
        % cAttributeValue = regexp(sMarkup,'(?<=\=")[^\<\>&''"]*(?=")','match'); 
        cAttributeValue = regexp(sMarkup,'"[^\<\>"]*"','match');
        
        % create Attribute structure
        xAttribute = struct;
        for nIdxAttribute = 1:numel(cAttributeName)
            % ensure valid attribute name
            if isvarname(cAttributeName{nIdxAttribute})
                sVarname = cAttributeName{nIdxAttribute};
            else
                sVarname = genvarname(cAttributeName{nIdxAttribute});
            end
            
            % transformation of character entities
            if bEntityCheckAll || any(strcmp(sVarname,{'description','unit',...
                    'signalLabel','manualDescription','autoDescription','Description'})) 
                sAttr = dsxEntityConvert(cAttributeValue{nIdxAttribute}(2:end-1));
            else
                sAttr = cAttributeValue{nIdxAttribute}(2:end-1);
            end
            
            % create attribute field
            xAttribute.(sVarname) = sAttr;
            % Comment: RF - implementation with direct struct call is no
            % big improvement
        end
end
return

% =========================================================================

function sChar = dsxEntityConvert(sChar)
% DSXENTITYCONVERT convert character entities of input string into their
% matching character.
%
% Syntax:
%   sChar = dsxEntityConvert(sChar)
%
% Inputs:
%   sChar - char (1xn) with entity and character references (e.g. &amp;, &#196;, &#xA;)
%
% Outputs:
%   sChar - char (1xn) with special characters for XML (e.g. &, Ä)
%
% Example: 
%   sChar = dsxEntityConvert('Das ist &#228;hnlich zu a &gt; 3 &#x26; b &#60; 2');

% search for entities
nAmp = find(sChar == '&'); % implementation is ~16% faster than strfind

bKeep = true(size(sChar));
for nIdxAmp = 1:numel(nAmp)
    % get entity content
    sEntity = strtok(sChar(nAmp(1,nIdxAmp)+1:end),';'); 
    nAmp(2,nIdxAmp) = nAmp(1,nIdxAmp)+numel(sEntity)+1; % store end of entity
    
    % convert entity reference
    if strcmp(sEntity(1),'#')
        % numeric entity reference
        if strcmp(sEntity(2),'x')
            % hexadecimal entity reference
            sChar(nAmp(1,nIdxAmp)) = char(hex2dec(sEntity(3:end)));
        else
            % assume decimal entity reference
            sChar(nAmp(1,nIdxAmp)) = char(str2double(sEntity(2:end)));
        end
    else
        % character entity reference
        switch lower(sEntity)
            case 'quot'
                sChar(nAmp(1,nIdxAmp)) = '"';
            case 'amp'
                sChar(nAmp(1,nIdxAmp)) = '&';
            case 'lt'
                sChar(nAmp(1,nIdxAmp)) = '<';
            case 'gt'
                sChar(nAmp(1,nIdxAmp)) = '>';
            case 'apos'
                sChar(nAmp(1,nIdxAmp)) = '''';
            otherwise
                error('dsxRead:parse:entityConvert',...
                    'dsxRead encountered an unknown character entity reference: "%s"',sEntity)
        end
    end
    
    % mark entity for delete
    [bKeep(nAmp(1,nIdxAmp)+1:nAmp(2,nIdxAmp))] = deal(false);
end

% cut string to remove rest of entities
sChar = sChar(bKeep);
return

% =========================================================================

function sChar = dsxCharClean(sChar)
% DSXCHARCLEAN remove special blank, tab and carriage return character from
% front and end of line. (Could be done with deblankx, but here with
% improved performance.)
%
% Syntax:
%   sChar = dsxCharClean(sChar)
%
% Inputs:
%   sChar - string with certain newline characters
%
% Outputs:
%   sChar - string without certain newline characters
%
% Example: 
%   sChar = [char([9 10 11]),'abc',char([32 65279])];
%   numel(sChar)
%   sChar = dsxCharClean([char([9 10 11]),'abc',char([32 65279])])
%   numel(sChar)

% character ID to remove
% nCharRemove = [9 10 11 32 65279]; % original set to remove - chars 9, 10, and 11 can be removed by strtrim 
nCharRemove = 65279; % chars 9, 10, 11 and 32 can be removed by strtrim 
sCharRemove = char(nCharRemove);

sChar = strtrim(sChar);
if isempty(sChar)
    return
else
    for nIdxRemove = 1:numel(sCharRemove)
        sChar = strrep(sChar,sCharRemove(nIdxRemove),'');
    end
    if isempty(sChar)
        return
    else
        sChar = strtrim(sChar);
    end
end
return
