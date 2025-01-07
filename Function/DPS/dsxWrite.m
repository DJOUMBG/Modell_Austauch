function dsxWrite(sFile,xTree,bEntityCheckAll)
% DSXWRITE write a XML file into a special MATLAB structure.
% The structure is with flattened Attributes into fields and element nodes
% are typical further structure field branches.
%
% Syntax:
%   dsxWrite(sFile,xTree,)
%   dsxWrite(sFile,xTree,bEntityCheckAll)
%
% Inputs:
%   sFile - string with xml filename
%   xTree - structure where
%           1. sub-structures with structure in a field is a XML
%              node/element
%           2. fields with standard variable types as content are
%              attributes
%           3. element content is taken from the field "cONTENT"
%           4. Processing instructions like the declaration are preset.
%   bEntityCheckAll - [optional] boolean (1x1) for character entity conversion
%                       0: {default} check only defined list of Attributes
%                       1: check all attributes for char entities
% 
%
% Outputs:
%
% Example: 
%    dsxWrite('test.xml',xTree)
%
%
% Subfunctions: dsxCarriageReturn, dsxChar, dsxTreeExpand
% Other m-files required: 
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2014-06-12

% check inputs
if nargin < 3
    bEntityCheckAll = false;
end

% initialization
sEncoding = 'UTF-8';

% create XML lines
cField = fieldnames(xTree);
cLine = {};
for nIdxField = 1:numel(cField)
    for nIdxVector = 1:numel(xTree.(cField{nIdxField}))
        cLine = [cLine dsxTreeExpand(xTree.(cField{nIdxField})(nIdxVector),...
                       {},cField{nIdxField},0,bEntityCheckAll)]; %#ok<AGROW>
    end
end

% check lines
bCell = cellfun(@iscell,cLine);
if any(bCell)
    % some attribute value was a cell (instead of char) - cannot be written
    fprintf(2,['error: dsxWrite - value of an XML attribute contained a cell. ' ...
               'Cannot write file "%s".\n'],sFile);
    return
end

% open file and write declaration
nFID = fopen(sFile,'w','n',sEncoding);
fprintf(nFID,'<?xml version="1.0" encoding="%s"?>\r\n',sEncoding);

% write content
for nIdxLine = 1:numel(cLine)
    fprintf(nFID,'%s\r\n',cLine{nIdxLine});
end

% close file
fclose(nFID);
return

% =========================================================================

function cLine = dsxTreeExpand(xTree,cLine,sName,nLevel,bEntityCheckAll)
% DSXTREEEXPAND derive XML element lines from a MATLAB structure
%
% Syntax:
%   cLine = dsxTreeExpand(xTree,cLine,sName,nLevel,bEntityCheckAll)
%
% Inputs:
%    xTree - structure with fields: 
%    cLine - cell (mx1) 
%    sName - string with current module name
%   nLevel - integer with depth level of XML element for format indent 
%   bEntityCheckAll - boolean (1x1) for character entity conversion
%                       0: {default} check only defined list of Attributes
%                       1: check all attributes for char entities
%
% Outputs:
%   cLine - cell (mxn) 
%
% Example: 
%   cLine = dsxTreeExpand(xTree,cLine,sName,nLevel,bEntityCheckAll)

% initialize indent
sIndent = char(32.*ones(1,4*nLevel));

% determine field types
cField = fieldnames(xTree);
bAttribute = false(1,numel(cField));
for nIdxField = 1:numel(cField)
    if ~isstruct(xTree.(cField{nIdxField}))
        bAttribute(nIdxField) = true;
    end
end

% exempt CDATA and cONTENT fields from attribute creation
bContent = strcmp('cONTENT',cField)';
bCDATA = strcmp('CDATA',cField)';
bAttribute = bAttribute & ~bContent & ~bCDATA;

% create tag with attributes
sLine = [sIndent '<' sName];
for nIdxAttribute = find(bAttribute)
    % omit empty inherited fields, but write empty char values
    if isempty(xTree.(cField{nIdxAttribute})) && ~ischar(xTree.(cField{nIdxAttribute}))
        continue
    end
    
    % correction on attribute names
    cTagXmlns = {'xmlns0x3Axsi','xsi0x3AschemaLocation','xmlns0x3Axs','xs0x3AschemaLocation'};
    if any(strcmp(cField{nIdxAttribute},cTagXmlns))
        sAttributeName = strrep(cField{nIdxAttribute},'0x3A',':');
    else
        sAttributeName = cField{nIdxAttribute};
    end
    
    % correction on attribute values
    if bEntityCheckAll || any(strcmp(cField{nIdxAttribute},{'description','unit',...
            'signalLabel','manualDescription','autoDescription','Description'}))
        xTree.(cField{nIdxAttribute}) = dsxChar(xTree.(cField{nIdxAttribute}));
    end % if attribute with special characters
    
    % generate line entry
    sLine = [sLine ' ' sAttributeName '="' ...
        dsxCarriageReturn(xTree.(cField{nIdxAttribute}),sIndent) '"']; %#ok<AGROW>
end
if any(~bAttribute)
    sLine = [sLine '>'];
    sLineClose = [sIndent '</' sName '>'];
else
    sLine = [sLine '/>'];
    sLineClose = '';
end
cLine{end+1} = sLine;

% create subsequent tags 
nLevel = nLevel + 1;
for nIdxField = find(~bAttribute & ~bCDATA & ~bContent)
    for nIdxArray = 1:numel(xTree.(cField{nIdxField}))
        cLine = dsxTreeExpand(xTree.(cField{nIdxField})(nIdxArray),...
                              cLine,cField{nIdxField},nLevel,bEntityCheckAll);
    end
end

% enlarge indent
sIndent = [sIndent char(32.*ones(1,4))];

% create CDATA section
if any(bCDATA)
   cLine{end+1} = [sIndent '<![CDATA[' ...
       dsxCarriageReturn(xTree.CDATA,[sIndent char(32.*ones(1,9))]) ']]>']; 
end

% create tag content
if any(bContent)
   cLine{end+1} = [sIndent dsxCarriageReturn(xTree.cONTENT,sIndent)]; 
end
    
% add close tag
if ~isempty(sLineClose)
    cLine{end+1} = sLineClose;
end
return

% =========================================================================

function sChar = dsxCarriageReturn(sChar,sIndent)
% DSXCARRIAGERETURN correct format for carriage return
%
% Syntax:
%   sChar = dsxCarriageReturn(sChar,sIndent)
%
% Inputs:
%     sChar - string with string containing char(10) for carraige return
%   sIndent - string current standard indent (will enlarged by 4 blanks)
%
% Outputs:
%   sChar - string with corrected carriage return
%
% Example: 
%   sChar = dsxCarriageReturn(['bla' char(10) 'blub'],'   ')

% add indent and windows style carriage return
if ~isempty(sChar)
    sChar = strrep(sChar,char(10),[char(13) char(10) sIndent]); %#ok<CHARTEN>
end
return

% =========================================================================

function sAttr = dsxChar(sAttrIn)
% DSXCHAR special and non UTF-8 character replacement by decimal character
% entity. (Implementation 2 - simple implementation with growing character
% array is ~ 15% slower).
%
% Syntax:
%   sAttr = dsxChar(sAttrIn)
%
% Inputs:
%   sAttrIn - char (1xn) with special characters for XML (e.g. &, Ä)
%
% Outputs:
%   sAttr - char (1xn) with entity and character references (e.g. &amp;, &#196;)
%
% Example: 
%   sAttr = dsxChar(sAttrIn)

% init output
sAttr = sAttrIn;

% convert to integer vector
nAttr = double(sAttrIn);

% define special characters to be replaced by entities
bSpecial = (nAttr==34) | ...
    (nAttr==38) | ...
    (nAttr==39) | ...
    (nAttr==60) | ...
    (nAttr==62) | ...
    (nAttr > 127);

if any(bSpecial)
    nAttrSpecial = nAttr(bSpecial);
    % determine string extension
    nAdd = (4-1)* sum(bSpecial)+...        % &#1;
        sum(nAttrSpecial>9) + ...    % &#10;
        sum(nAttrSpecial>99) + ...   % &#100;
        sum(nAttrSpecial>999) + ...  % &#1000;
        sum(nAttrSpecial>9999); % &#10000;
    sAttr = [sAttrIn repmat(' ',1,nAdd)];
    nLAttr = numel(sAttr);
    
    % insert character entity
    nSpecial = find(bSpecial);
    nSpecialShift = nSpecial;
    for nIdxSpecial = 1:numel(nSpecial)
        % generate entity
        sEntity = sprintf('&#%i;',nAttr(nSpecial(nIdxSpecial)));
        nShift = numel(sEntity)-1;
        nIdSpecial = nSpecialShift(nIdxSpecial);
        
        % shift rest of string to right
        sAttr(nIdSpecial+nShift:nLAttr) = sAttr(nIdSpecial:nLAttr-nShift);
        
        % insert entity
        sAttr(nIdSpecial:nIdSpecial+nShift) = sEntity;
        
        % shift entity reference
        nSpecialShift = nSpecialShift + nShift;
    end
end % if special character contained
return
