function structDisp(xElement,nMaxLevel)
% structDisp - gives a visualisation of the structure from the parsestruct
% function at the command promt window
% 
% Input variables:
% xElement   - structure from parsestruct function
% nMaxLevel  - maximum displayed depth level 
% 
% Example calls:
% structDisp(structParse(structure))
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2012-11-21

if nargin == 1
    nMaxLevel = inf;
end
if isstruct(xElement) && ~all(ismember({'sType' 'vSize' 'nLevel' 'sName' 'nContent' 'cValue'},fieldnames(xElement)))
    xElement = structParse(xElement);
end

for k = 1:length(xElement)
    if xElement(k).nLevel<=nMaxLevel
        sLine = [blanks(4*(xElement(k).nLevel-1)) xElement(k).sName '(' xElement(k).sType ')(' num2str(xElement(k).vSize) ')'];
        if strcmpi(xElement(k).sType,'cell') && ~isempty(xElement(k).cValue)
            if ischar(xElement(k).cValue{1})
                sLine = [sLine ': [' xElement(k).cValue{1} ',' xElement(k).cValue{end} '] pure char cell']; %#ok<AGROW>
            else
                sLine = [sLine ': [' num2str(xElement(k).cValue{1}) ',' num2str(xElement(k).cValue{2}) '] pure numeric/boolean MinMax']; %#ok<AGROW>
            end
        elseif strcmpi(xElement(k).sType,'numeric') || strcmpi(xElement(k).sType,'boolean')
            sLine = [sLine ': [' num2str(xElement(k).cValue{1}) ',' num2str(xElement(k).cValue{2}) '] MinMax']; %#ok<AGROW>
        elseif strcmpi(xElement(k).sType,'char')
            if length(xElement(k).cValue{1})<30 && size(xElement(k).cValue{1},1)<2
                sLine = [sLine ': [' xElement(k).cValue{1} ']']; %#ok<AGROW>
            else
                sLine = [sLine ': [' xElement(k).cValue{1}(1:30) '... ' ']']; %#ok<AGROW>
            end
        end
        disp(sLine);
    end
end
return
