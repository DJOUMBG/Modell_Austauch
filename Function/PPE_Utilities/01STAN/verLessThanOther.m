function bLess = verLessThanOther(sVer1,sVer2)
% VERLESSTHANOTHER compare version strings (dot separated) against each
% other.
%
% Syntax:
%   bLess = verLessThanOther(sVer1,sVer2)
%
% Inputs:
%   sVer1 - string with version notation e.g. '7.11'
%   sVer2 - string with version notation e.g. '7.11' 
%
% Outputs:
%   bLess - boolean (1x1) if first string is an older version than the
%           second string
%
% Example: 
%   bLess = verLessThanOther('7.3','7.11')
%   bLess = verLessThanOther('8.3','7.11')
%   bLess = verLessThanOther('8.3','8.3')
%
% See also: strsplitOwn
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2018-10-1

% init output
bLess = [];

% decompose strings
cVer1 = strsplitOwn(sVer1,'.');
cVer2 = strsplitOwn(sVer2,'.');

% compare elements
bEqual = true;
nCompare = 0;
nMaxEval = min(numel(cVer1),numel(cVer2));
while bEqual && nCompare<nMaxEval
    nCompare = nCompare+1; % inrecement for verson sublevel
    
    v1 = str2double(cVer1{nCompare});
    v2 = str2double(cVer2{nCompare});
    if v1 < v2
        bLess = true;
        bEqual = false;
    elseif v1 == v2
        bLess = false;
    elseif v1 > v2
        bLess = false;
        bEqual = false;
    end
end
return
