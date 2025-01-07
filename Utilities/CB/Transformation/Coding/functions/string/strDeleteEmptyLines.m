function sTxt = strDeleteEmptyLines(sTxt)

% convert string to line list
cLines = strStringToLines(sTxt);

% init new line list
cCleanLines = {};

% search for empty lines
for nLine=1:numel(cLines)
    
    % only append to new list if no white characters in line
    if ~isempty(strtrim(cLines{nLine}))
        cCleanLines = [cCleanLines;cLines(nLine)]; %#ok<AGROW>
    end
    
end

% create updated text from cleaned list
sTxt = strLinesToString(cCleanLines);

return