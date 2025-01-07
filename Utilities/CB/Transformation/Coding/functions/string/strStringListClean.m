function cCleanStrList = strStringListClean(cStrList)
% STRSTRINGLISTCLEAN delete empty strings and trim strings from a given
% cell array or matrix of strings and converts it to a column cell array of
% strings.
%
% Syntax:
%   cStrList = strStringListClean(cStrList)
%
% Inputs:
%   cStrList - cell (mxn): array or matrix of strings
%
% Outputs:
%   cStrList - cell (nx1): column cell array of strings 
%
% Example: 
%   cStrList = strStringListClean(cStrList)
%
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2022-12-14

%% delete white spaces and empty rows

% init output
cCleanStrList = {};

% clean up ech line
for i=1:numel(cStrList)
    % delete white spaces in line
    sStr = strtrim(cStrList{i});
    % only append if not an empty line
    if not(isempty(sStr))
        cCleanStrList = [cCleanStrList;{sStr}]; %#ok<AGROW>
    end
end

return