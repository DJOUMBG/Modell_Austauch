function [cNames,cValues] = silConfigStringSplit(sConfigString)
% SILCONFIGSTRINGSPLIT returns name-value pair of given Silver config
% string, with syntax '-{name} {value}'.
%
% Syntax:
%   [cNames,cValues] = silConfigStringSplit(sConfigString)
%
% Inputs:
%   sConfigString - string: Silver config string, with Syntax '-{name} {value}'
%
% Outputs:
%    cNames - cell (1xm): names / options in config string
%   cValues - cell (1xm): value of name in config string
%
% Example: 
%   sConfigString = '-a  cpc_eep.par  -b  cpc_defaults.txt  -d  cpc_cds.hex  -f  cpc_out_def.txt  -g  cpc_out_val.txt  -h  cpc_debug.csv  -i  cpc_debug.txt  -j  1  -W  0  -X  0  -Y  0  -Z  5555 ';
%   cArgs = silConfigStringSplit(sConfigString)
%
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2023-03-24

%% split name value pair from config string

% add space on first and last position
cConfig = addWhiteSpaces({sConfigString});
sConfigString = cConfig{1};

% regex for splitting
sRegEx = ' \-[a-zA-Z] ';

% split config string
[cValues,cNames] = strsplit(sConfigString,sRegEx,'DelimiterType','RegularExpression');

% delete first empty value in cValues
if isempty(cNames)
    cValues = {};
else
    cValues = cValues(2:end);
end

% check number of elements is even
if ~isequal(numel(cValues),numel(cNames))
    cNames = {};
    cValues = {};
    fprintf(2,'User config string must be defined as name-value pair.');
    return;
end

% add whit spaces on first and las position
cNames = addWhiteSpaces(cNames);
cValues = addWhiteSpaces(cValues);

return

% =========================================================================

function cStrings = addWhiteSpaces(cStrings)

for nName=1:numel(cStrings)
    cStrings(nName) = {[' ',strtrim(cStrings{nName}),' ']};
end

return