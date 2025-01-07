function bContains = strcontain(sStr,sPattern)
% STRCONTAIN checks if a strings contains a pattern.
%
% Syntax:
%   bContains = strcontain(sStr,sPattern)
%
% Inputs:
%       sStr - string: string 
%   sPattern - string: pattern within string 
%
% Outputs:
%   bContains - boolean (1x1): true, if contains pattern, false if it does not  
%
% Example: 
%   bContains = strcontain(sStr,sPattern)
%
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2023-01-31

%% contains string pattern

if ~isempty(strfind(sStr,sPattern))
    bContains = true;
else
    bContains = false;
end

return