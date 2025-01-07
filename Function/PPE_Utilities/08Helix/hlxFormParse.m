function [varargout] = hlxFormParse(sOut,cField,cSplit,nCellMax,bMerge)
% HLXFORMPARSE parse a Perforce HelixCore Form specified field and return
% as single cell arrays. 
%
% Syntax:
%   varargout = hlxFormParse(sOut)
%   varargout = hlxFormParse(sOut,cField)
%   varargout = hlxFormParse(sOut,cField,cSplit)
%   varargout = hlxFormParse(sOut,cField,cSplit,nCellMax)
%   varargout = hlxFormParse(sOut,cField,cSplit,nCellMax,bMerge)
%
% Inputs:
%       sOut - string 
%     cField - cell (1xn) with string with fields in form to parse and return 
%     cSplit - string or cell with strings with split characters for line
%   nCellMax - integer (1x1) to limit split results from single lines
%     bMerge - boolean (1x1) if cell result shall be merged/compressed from
%              cell of cell to a cell array and transpose the cell
%
% Outputs:
%   varargout - cell(1xn) with field values as specified in cField
%
% Example: 
%   cAll = hlxFormParse(p4('client -o'))
%   cView = hlxFormParse(p4('client -o'),'View')
%   [cClient,cView] = hlxFormParse(p4('client -o'),{'Client','View'})
%   cView = hlxFormParse(p4('client -o'),'View',' ')
%   cView = hlxFormParse(p4('client -o'),'View',' ',1)
%   ccView = hlxFormParse(p4('client -o'),'View',' ',inf,false)
%
% See also: strsplitOwn, p4, hlxOutParse
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2018-08-30

% input check
if nargin < 2
    cField = {};
end
if nargin < 3 || isempty(cSplit)
    cSplit = {''};
end
if nargin < 4 || isempty(nCellMax) || nCellMax < 1
    nCellMax = inf;
end
if nargin < 5
    bMerge = true;
end

% ensure cell types
if ~iscell(cField)
    cField = {cField};
end
if ~iscell(cSplit)
    cSplit = {cSplit};
end

% split into lines
cLine = strsplitOwn(sOut,char(10),false);

% parse fields and values
cParse = hlxFormLineParse(cLine,cSplit,nCellMax,bMerge);

% assign output
if isempty(cField)
    % if no cField argument is procided, output all
    if nargout < 2
        varargout{1} = cParse(:,2)';
    else
        varargout = cParse(:,2)';
    end
else
    % assign requested output fields of form, if contained in form
    varargout = cell(numel(cField),1);
    for nIdxOut = 1:numel(cField)
        bField = strcmp(cField{nIdxOut},cParse(:,1));
        if any(bField)
            varargout(nIdxOut) = cParse(bField,2);
        else
            varargout{nIdxOut} = {};
        end
    end
end
return
