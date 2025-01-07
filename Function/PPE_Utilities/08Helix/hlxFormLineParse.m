function [cParse,cComment] = hlxFormLineParse(cLine,cSplit,nCellMax,bMerge)
% HLXFORMLINEPARSE parse lines of a Perforce Helix line content file.
%
% Syntax:
%   [cParse,cComment] = hlxFormLineParse(cLine,cSplit,nCellMax)
%
% Inputs:
%      cLine - cell (mx1) with lines of file
%     cSplit - cell (nx1) with characters used for value splits 
%   nCellMax - integer (1x1) with maximum results of split values
%     bMerge - boolean (1x1) if split cell should be merged
%
% Outputs:
%     cParse - cell (mx2) with 
%               {:,1} - string with name of form field
%               {:,2} - cell array with values of field
%   cComment - cell (nx1) with comment lines
%
% Example: 
%   [cParse,cComment] = hlxFormLineParse(cLine,cSplit)
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2018-08-30

% check input
if nargin < 2
    cSplit = {''};
end
if nargin < 2
    nCellMax = inf;
end
if nargin < 3
    bMerge = true;
end

% remove comment lines
if ~any(~cellfun(@isempty,regexp(cSplit,'\#','once'))) % omit if # is in a split definition
    bKeep = cellfun(@isempty,regexp(cLine,'(?<!\#)\#(?!\#)','once'));
    cComment = cLine(~bKeep);
    cLine = cLine(bKeep);
end

% parse fields and values
cParse = cell(0,2);
nIdxLine = 0;
nIdxParse = 0;
nLine = numel(cLine);
while nIdxLine < nLine
    nIdxLine = nIdxLine + 1;
    
    % try to get a field from the line
    sField = regexp(cLine{nIdxLine},'^\w+','match','once');
    if ~isempty(sField)
        % store field in parsing cell
        nIdxParse = nIdxParse + 1;
        cParse{nIdxParse,1} = sField;
        
        % get values of field
        if nIdxLine < nLine && isempty(cLine{nIdxLine+1})
            % single line field value - get value after field identifier
            cParse{nIdxParse,2} = strsplitOwn(strtrim(cLine{nIdxLine}(numel(sField)+2:end)),cSplit);
        else
            % multi line field value
            cValue = cell(0,1);
            nIdxLine = nIdxLine + 1;
            while nIdxLine <= nLine && ~isempty(strtrim(cLine{nIdxLine}))
                % split line according specified limits
                cParts = strsplitOwn(strtrim(cLine{nIdxLine}),cSplit);
                % limit result to maximum requested results
                cValue{end+1,1} = cParts(1:min(numel(cParts),nCellMax)); %#ok<AGROW>
                
                nIdxLine = nIdxLine + 1;
            end
            
            if bMerge
                % merge the cell of cells into a one-layer cell
                nMax = max(cellfun(@numel,cValue)); % get max parts over all lines
                cOut = cell(numel(cValue),nMax);
                for nIdxItem = 1:numel(cValue)
                    cOut(nIdxItem,1:numel(cValue{nIdxItem})) =  cValue{nIdxItem}';
                end
                cParse{nIdxParse,2} = cOut;
            else % leave as is
                cParse{nIdxParse,2} = cValue;
            end
        end
    end % if found a new field
end % while lines are left
return