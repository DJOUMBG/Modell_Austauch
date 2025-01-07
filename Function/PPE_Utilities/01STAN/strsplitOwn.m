function cString = strsplitOwn(str,split,bMultipleDelimsAsOne)
% STRSPLITOWN splits a string into segements divided by another specfied
% string or character.
% The function uses a boolean copy of the vector, so is not suitable for
% splitting very long strings.
%
% Syntax:
%   cString = strsplitOwn(str,split)
%   cString = strsplitOwn(str,split,bMultipleDelimsAsOne)
% 
% Inputs:
%   str     - string to be split
%   split   - string or cell with strings 
% bMultipleDelimsAsOne - boolean for treating multiple split delimiters as one
% 
% Outputs:
%   cString - cell with strings containing the non-empty split parts of the
%             passed string
% 
% Example:
% cellstr = strsplitOwn('this is bump a string','bump')
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2009-05-23

% return on empty string
if isempty(str)
    cString = {};
    return
end

% path input parameters
if nargin<3
    bMultipleDelimsAsOne = true;
end

% ensure cell type of split
if ~iscell(split)
    split = {split};
end
    
% create splitting information
tf = true(size(str));
for k = 1:length(split)
    pos = strfind(str,split{k});
    for m = 1:length(pos)
        tf(pos(m):pos(m)+length(split{k})-1) = false;
    end
end

% split string
str(~tf) = char(10); %#ok<CHARTEN>
if verLessThanMATLAB('8.4.0')
    ccString = textscan(str, '%s', ...
                        'Delimiter',char(10),...
                        'MultipleDelimsAsOne', bMultipleDelimsAsOne,...
                        'BufSize',262144); %#ok<CHARTEN,BUFSIZE>
else
    ccString = textscan(str, '%s', ...
                        'Delimiter',char(10),...
                        'MultipleDelimsAsOne', bMultipleDelimsAsOne); %#ok<CHARTEN>
end
cString = ccString{1};
return
