function cStr = rmcellstr(cStr,sRemove,bRegExp,bCaseIgnore)
% RMCELLSTR removes the specified strings from a cell of strings
%
% Syntax:
%   cStr = rmcellstr(cStr,sRemove,bRegExp,bCaseIgnore)
%
% Inputs:
%          cStr - cell (mxn) with strings
%       sRemove - string which shall be removed from
%       bRegExp - boolean, if remove shall be treated as regular expression
%   bCaseIgnore - boolean, if remove string should ignore upper/lower case
%
% Outputs:
%   cStr - cell (mxn) with strings
%
% Example: 
%   cStr = rmcellstr({'ab','cd','ef','fg'},'cd')
%   cStr = rmcellstr({'ab','cd','ef','fg'},'cd',false,false)
%   cStr = rmcellstr({'ab','cd','ef','fg'},'cD',false,true)
%   cStr = rmcellstr({'ab','cd','ef','fg'},'f',true,true)
%
% See also: regexp, regexpi, strcmp, strcmpi
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2016-07-15

% check input
if nargin < 3
    bRegExp = false;
end
if nargin < 4
    bCaseIgnore = false;
end

% check for regular expression
if bRegExp
    if bCaseIgnore
        bKeep = cellfun(@isempty,regexpi(cStr,sRemove,'match','once'));
    else
        bKeep = cellfun(@isempty,regexp(cStr,sRemove,'match','once'));
    end
else % direct string comparison
    if bCaseIgnore
        bKeep = ~strcmpi(sRemove,cStr);
    else
        bKeep = ~strcmp(sRemove,cStr);
    end
end

% remove identified string from cell string
cStr = cStr(bKeep);
return
