function [sString,sStringWithKeys] = strStringBetweenKeys(sLine,sKeyLeft,sKeyRight)

% escape translate of keys
sKeyLeft = regexptranslate('escape',sKeyLeft);
sKeyRight = regexptranslate('escape',sKeyRight);

% get strings between keys and delete keys from result string
cMatch = regexp(sLine,sprintf('%s(.*?)%s',sKeyLeft,sKeyRight),'match');

% check number of findings
if numel(cMatch) > 0
    
    % assign first match
    sStringWithKeys = cMatch{1};
    
    % delete keys from matched string
    sString = sStringWithKeys;
    sString = regexprep(sString,sKeyLeft,'');
    sString = regexprep(sString,sKeyRight,'');
    
else
    sStringWithKeys = '';
    sString = '';
end

end