function sString = strGlue(cString,sGlue)
% STRGLUE create string from all non-empty parts of a cell with strings
% separated by the specified "glue" string.
%
% Syntax:
%   sString = strGlue(cString,sGlue)
%
% Inputs:
%   cString - cell (1xn) with strings
%     sGlue - string which shall separate the specified strings
%
% Outputs:
%   sString - string conatenated from cell parst and glue string
%
% Example: 
%   sString = strGlue({'a','b','','d'},'.') % returns 'a.b.d'

% prepare string cell, remove empty parts
bKeep = ~cellfun(@isempty,cString);
cString = cString(bKeep);
if isempty(cString)
    sString = '';
    return
end

% build string from non-empty parts
sString = cString{1};
for nIdxString = 2:numel(cString)
    sString = [sString sGlue cString{nIdxString}]; %#ok<AGROW>
end
return
