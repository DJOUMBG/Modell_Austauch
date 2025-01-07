function xTree = dsxReadCfgHeader(sFile,nVerbose)
% DSXREADCFGHEADER read the second line of a XML file into an special structure.
%
% Syntax:
%   xTree = dsxReadCfgHeader(sFile)
%   xTree = dsxReadCfgHeader(sFile,nVerbose)
%
% Inputs:
%      sFile - string with xml filename
%   nVerbose - integer with verbosity level (0: no warnings, 1:warnings)
%
% Outputs:
%   xTree - structure with fields of XML attributes in 2nd line
%
% Example: 
%   xTree = dsxReadCfgHeader('C:\dirsync\06DIVe\03Platform\com\Configuration\Vehicle_Other\DIVeDevelopment\CosimCheckTime.xml')
%
% Subfunctions: dsxMarkupParse
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49 711 8485 3325
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2015-09-24

% check inputs
if ~exist(sFile,'file')
    error('dsxReadCfgHeader:fileNotFound',...
        'dsxReadCfgHeader: The specified file is not on the file system: %s',sFile);
end
if nargin < 2
    nVerbose = 1;
end

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
    
else
    sLine = fgetl(nFID); % get first line
    fclose(nFID);
end

% parse line for encoding information
[sTag,xAttribute] = dsxMarkupParse(strtrim(sLine)); %#ok<ASGLU>
if isfield(xAttribute,'encoding')
    sEncoding = xAttribute.encoding;
    if ~any(strcmp(sEncoding,cMatlabEncoding))
        sEncoding = 'UTF-8';
    end
else
    sEncoding = 'UTF-8';
end

% read file
nFID = fopen(sFile,'r','n',sEncoding);
sLine1 = fgetl(nFID); %#ok<NASGU> % get first line
sLine2 = fgetl(nFID); % get second line
if ~strcmp(sLine2(end),'>')
    bClose = false;
    while ~bClose && ~feof(nFID)
        sNext = fgetl(nFID);
        nMark = strfind(sNext,'>');
        if isempty(nMark)
            sLine2 = [sLine2 char(10) sNext]; %#ok<AGROW>
        else
            sLine2 = [sLine2 char(10) sNext(1:nMark(1))]; %#ok<AGROW>
            bClose = true;
        end
    end
end
fclose(nFID);
sLine2 = strtrim(sLine2);
% patch open comment
if ~strcmp(sLine2(end),'>')
    % get value marker
    sMark = regexp(sLine2(14:min(numel(sLine2),35)),'(?<=\=)["'']','match','once');
    % close XML tag
    sLine2 = [sLine2 ' ...' sMark '>'];
end
[cMarkup,cContent] = dsxMarkupSplit({strtrim(sLine2)});

% parse file content
xTree = dsxTreeBuild(struct(),cMarkup,cContent,0,nVerbose);
return

% =========================================================================

function [cMarkup,cContent] = dsxMarkupSplit(cLine)
% DSXMARKUPSPLIT split a cell with strings into single markups.
%
% Syntax:
%   cMarkup = dsxMarkupSplit(sLine)
%
% Inputs:
%   cLine - cell with strings of an XML file line each
%
% Outputs:
%   xMarkup - structure with fields: 
%
% Example: 
%   xMarkup = dsxMarkupSplit(sLine)

% initialize
cMarkup = cell(1000,1);
cContent = cell(1000,1);
nActual = 0;
sRest = '';
bClose = true;

% get position of markups for complete cell cLine
cPosStart = strfind(cLine,'<');
cPosEnd = strfind(cLine,'>');

for nIdxLine = 1:numel(cLine)
    while ~( isempty(cPosStart{nIdxLine}) &&...
             isempty(cPosEnd{nIdxLine}) &&...
             isempty(cLine{nIdxLine}))
         
         if ~isempty(cPosStart{nIdxLine}) && cPosStart{nIdxLine}(1) ~= 1 % content before first markup
             sContent = cLine{nIdxLine}(1:cPosStart{nIdxLine}(1)-1);
             if nActual>0 &&... % previous markup exists
                     ( ( ~isempty(sRest) && bClose) || ... % line content is not empty
                        ~isempty(dsxCharClean(sContent))) % rest string and markup closed
                        % ~isempty(deblankx(sContent,cellfun(@char,{9 10 11 32 65279},'UniformOutput',false)))) % line content is not empty %RF: performance improvement 
                 if bClose % rest string was external of markup tag
                     % sContent = deblankx([sRest sContent],cellfun(@char,{9 10 11 32 65279},'UniformOutput',false)); % add rest to content %RF: performance improvement 
                     sContent = dsxCharClean([sRest sContent]); % % add rest to content
                     sRest = ''; % reset rest string
                 end
                 if ~isempty(sContent)
                     % store content with previous markup
                     cContent{nActual} = sContent; % add content to previous markup
                     sContent = '';
                 end
             end
             
             % cleanup
             cLine{nIdxLine} = cLine{nIdxLine}(cPosStart{nIdxLine}(1):end); % remove used content from line
             cPosEnd{nIdxLine} = cPosEnd{nIdxLine}-cPosStart{nIdxLine}(1)+1; % adjust position information
             cPosStart{nIdxLine} = cPosStart{nIdxLine}-cPosStart{nIdxLine}(1)+1; % adjust position information
             
         elseif ~isempty(cPosStart{nIdxLine}) && ~isempty(cPosEnd{nIdxLine}) 
             if cPosStart{nIdxLine}(1) < cPosEnd{nIdxLine}(1) % complete markup in line
                 % disp(['line' num2str(nIdxLine,'%03.0f') ' 2.1']) % debug output 
                 
                 % store new markup
                 nActual = nActual + 1;
                 cMarkup{nActual} = cLine{nIdxLine}(cPosStart{nIdxLine}(1):cPosEnd{nIdxLine}(1));
                 
                 % cleanup
                 cLine{nIdxLine} = cLine{nIdxLine}(cPosEnd{nIdxLine}(1)+1:end); % remove used content from line
                 cPosStart{nIdxLine} = cPosStart{nIdxLine}-cPosEnd{nIdxLine}(1); % adjust position information
                 cPosEnd{nIdxLine} = cPosEnd{nIdxLine}-cPosEnd{nIdxLine}(1); % adjust position information
                 cPosStart{nIdxLine} = cPosStart{nIdxLine}(2:end);
                 cPosEnd{nIdxLine} = cPosEnd{nIdxLine}(2:end);
                 
             elseif cPosStart{nIdxLine}(1) > cPosEnd{nIdxLine}(1) % rest markup of previous line
                 % disp(['line' num2str(nIdxLine,'%03.0f') ' 2.2']) % debug output 
                 if ~bClose % open markup tag is in rest string
                     % store new markup
                     nActual = nActual + 1;
                     cMarkup{nActual} = [sRest cLine{nIdxLine}(1:cPosEnd{nIdxLine}(1))];
                     cLine{nIdxLine} = cLine{nIdxLine}(cPosEnd{nIdxLine}(1)+1:end);
                     
                     sRest = ''; % reset rest string
                     bClose = true; % markup is closed now
                 else
                     error(['Syntax Error in markups - closing markup ">" without matching open in line ' num2str(nIdxLine)])
                 end
             else
                error('inconsistent position information'); 
             end
         elseif ~isempty(cPosStart{nIdxLine}) &&  isempty(cPosEnd{nIdxLine}) % open markup in line
             % disp(['line' num2str(nIdxLine,'%03.0f') ' 3.1']) % debug output 
             if numel(cPosStart{nIdxLine}) > 1
                 error(['Syntax Error in markups - multiple opening markups "<" in line ' num2str(nIdxLine)])
             end
             % cleanup existing rest to content
             if ~isempty(sRest)
             disp(['line' num2str(nIdxLine,'%03.0f') ' 3.2'])
                 cContent{nActual} = dsxCharClean(sRest);
                 sRest = '';
             end
             
             % move line to rest and tag open markup
             sRest = dsxCharClean([ sRest cLine{nIdxLine} ]); 
             bClose = false;
             
             % cleanup
             cPosStart{nIdxLine} = [];
             cLine{nIdxLine} = '';
         elseif  isempty(cPosStart{nIdxLine}) && ~isempty(cPosEnd{nIdxLine}) % markup close in line
             % disp(['line' num2str(nIdxLine,'%03.0f') ' 4.1'])
             if numel(cPosEnd{nIdxLine}) > 1
                 error(['Syntax Error in markups - multiple closing markups ">" in line ' num2str(nIdxLine)])
             end
             
             % store new markup
             nActual = nActual + 1;
             cMarkup{nActual} = [sRest cLine{nIdxLine}(1:cPosEnd{nIdxLine}(1))];
             
             % cleanup
             cLine{nIdxLine} = cLine{nIdxLine}(cPosEnd{nIdxLine}(1)+1:end);
             cPosEnd{nIdxLine} = [];
         elseif isempty(cPosStart{nIdxLine}) && isempty(cPosEnd{nIdxLine}) % no markup characters in line
              % disp(['line' num2str(nIdxLine,'%03.0f') ' 5.1'])
              sRest = dsxCharClean([ sRest cLine{nIdxLine} ]); 
              cLine{nIdxLine} = '';
         end 
    end
end

% reduce result cells to used range
cMarkup = cMarkup(1:nActual);
cContent = cContent(1:nActual);
return

% =========================================================================

function [xTree,nActual] = dsxTreeBuild(xTree,cMarkup,cContent,nActual,nVerbose)
% DSXTREEBUILD recursive function to build a MATLAB structure from an XML
% file.
%
% Syntax:
%   [xTree,nActual] = dsxTreeBuild(xTree,cMarkup,cContent,nActual)
%
% Inputs:
%      xTree - structure to add the tree contained in 
%    cMarkup - cell (1xn) 
%   cContent - cell (1xn) 
%    nActual - integer (1x1) with depth level
%   nVerbose - integer with verbosity level (0: no warnings, 1:warnings)
%
% Outputs:
%     xTree - structure with fields: 
%   nActual - integer (1x1) 
%
% Example: 
%   [xTree,nActual] = dsxTreeBuild(xTree,cMarkup,cContent,nActual)

nSize = numel(cMarkup);

while nActual < nSize
    % evaluate next markup
    nActual = nActual+1;
    [sTag,xAttribute,sType] = dsxMarkupParse(cMarkup{nActual});
    if ~isvarname(sTag)
        sTag = genvarname(sTag); % ensure allowed field name for MATLAB
    end
    
    switch sType
        case 'TagStart'
            % add attributes to level
            xTreeAdd.(sTag) = xAttribute;
            
            % add subtree
            [xTreeAdd.(sTag),nActual] = dsxTreeBuild(xTreeAdd.(sTag),cMarkup,cContent,nActual,nVerbose);
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
            % no implementation
        otherwise
            % no implementation
    end
end
return

% =========================================================================

function [sTag,xAttribute,sType] = dsxMarkupParse(sMarkup)
% DSXMARKUPPARSE parse the tag and attributes of a single markup <...> into
% a structure with XML attributes represented as structure fields.
%
% Syntax:
%   [sTag,xAttribute] = dsxMarkupParse(sMarkup)
%
% Inputs:
%   sMarkup - string with a complete markup <...>
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
    sType = 'TagEmpty';
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

% determine Tag of Markup
sTag = regexp(sMarkup,'(?<=\<[/\?\!\-]*)(\w|:)+','match','once');

% determine Attributes of Markup
cAttributeName = regexp(sMarkup,'\w+(?=\=")','match');
% cAttributeValue = regexp(sMarkup,'(?<=\=")[^\<\>&''"]*(?=")','match'); % old expression - can not capture empty attributes! 
cAttributeValue = regexp(sMarkup,'"[^\<\>"]*"','match');
% cAttributeValue = cellfun(@(x)x(2:end-1),cAttributeValue,'UniformOutput',false); % RF: improve performance

% create Attribute structure
xAttribute = struct;
for nIdxAttribute = 1:numel(cAttributeName)
    if isvarname(cAttributeName{nIdxAttribute})
        sVarname = cAttributeName{nIdxAttribute};
    else
        sVarname = genvarname(cAttributeName{nIdxAttribute});
    end
    % xAttribute.(sVarname) = cAttributeValue{nIdxAttribute}; % RF: improve performance
    xAttribute.(sVarname) = cAttributeValue{nIdxAttribute}(2:end-1);
end

% % create Attribute structure % RF: alternative implementation, but no big improvement
% for nIdxAttribute = 1:numel(cAttributeName)
%     if isvarname(cAttributeName{nIdxAttribute})
%         cAttributeName{nIdxAttribute} = cAttributeName{nIdxAttribute};
%     else
%         cAttributeName{nIdxAttribute} = genvarname(cAttributeName{nIdxAttribute});
%     end
%     cAttributeValue{nIdxAttribute} = cAttributeValue{nIdxAttribute}(2:end-1);
% end
% cStruct = reshape([cAttributeName;cAttributeValue],1,2*numel(cAttributeValue));
% xAttribute = struct(cStruct{:});
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
%   sChar - string 
%
% Outputs:
%   sChar - string 
%
% Example: 
%   sChar = [char([9 10 11]),'abc',char([32 65279])];
%   numel(sChar)
%   sChar = dsxCharClean([char([9 10 11]),'abc',char([32 65279])])
%   numel(sChar)


% character ID to remove
% nCharRemove = [9 10 11 32 65279]; % original set to remove - chars 9, 10, and 11 can be removed by strtrim 
nCharRemove = [32 65279]; % original set to remove - chars 9, 10, and 11 can be removed by strtrim 
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
