function cLine = hlxOutParse(sOut,cSplit,nCellMax,bMerge)
% HLXOUTPARSE split a string with newline characters into a line cell and
% split the single cell line into cells according the specified split
% characters.
%
% Syntax:
%   cLine = hlxOutParse(sOut)
%   cLine = hlxOutParse(sOut,cSplit)
%   cLine = hlxOutParse(sOut,cSplit,nCellMax)
%   cLine = hlxOutParse(sOut,cSplit,nCellMax,bMerge)
%
% Inputs:
%       sOut - string 
%     cSplit - string or cell with strings with split characters for line
%   nCellMax - integer (1x1) to limit split results from single lines
%     bMerge - boolean (1x1) if cell result shall be merged/compressed from
%              cell of cell to a cell array and transpose the cell
% Outputs:
%   cLine - cell (mxn) 
%
% Example: 
%   ccLine = hlxOutParse(p4('streams'))
%   ccLine = hlxOutParse(p4('set'),{'=',' '})
%   ccLine = hlxOutParse(p4('set'),{'=',' '},2)
%   cLine = hlxOutParse(p4('set'),{'=',' '},2,true)
%   cLine = hlxOutParse(p4('set'),{'=',' '},inf,true)
%
% See also: strsplitOwn, p4
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2018-08-16

% input check
if nargin < 2 || isempty(cSplit)
    cSplit = ' ';
end
if nargin < 3 || isempty(nCellMax) || nCellMax < 1
    nCellMax = inf;
end
if nargin < 4
    bMerge = false;
end

% ensure cell type of split
if ~iscell(cSplit)
    cSplit = {cSplit};
end

% split into lines
cLine = strsplitOwn(sOut,char(10));

% split lines according specification
for nIdxLine = 1:numel(cLine)
    cParts = strsplitOwn(cLine{nIdxLine},cSplit);
    % limit result to maximum requested results
    cLine{nIdxLine} = cParts(1:min(numel(cParts),nCellMax));
end 

% merge cell of cell into transposed cell array
if bMerge
    nPart = max(cellfun(@numel,cLine)); % get max parts over all lines
    cOut = cell(numel(cLine),nPart);
    for nIdxLine = 1:numel(cLine)
        cOut(nIdxLine,1:numel(cLine{nIdxLine})) =  cLine{nIdxLine}';
    end
    cLine = cOut;
end
return