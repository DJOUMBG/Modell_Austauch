function str = deblankx(str,x)
% DEBLANKX clean output string from leading and trailing defined character
%
% Syntax:
%   str = deblankx(str,x)
%
% Inputs:
%   str - string to remove leading and trailing specified character
%     x - single character which is removed from start and end of string
%
% Outputs:
%   str - string without leading and trailing specified character
%
% Example: 
%   str = deblankx(str,x)
%
%
% See also: deblank, strcmp 
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2012-09-03

% return if string is empty
if isempty(str)
    return
end

% store length
LE = length(str);

% remove leading character
if any(strcmp(str(1),x))
    str = str(2:end);
end

% remove trailing character
if ~isempty(str) && any(strcmp(str(end),x))
    str = str(1:end-1);
end

% recursive call if something changed (multiple chars)
if LE > length(str)
    str = deblankx(str,x);
end
return
