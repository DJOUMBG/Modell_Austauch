function sUrl = urlEscape(sUrl,bRevert)
% URLESCAPE escape or revert escapes for URL commands (e.g. blank replaced
% by %20 ...).
%
% Syntax:
%   sUrl = urlEscape(sUrl,bRevert)
%
% Inputs:
%      sUrl - string 
%   bRevert - boolean (1x1)
%
% Outputs:
%   sUrl - string 
%
% Example: 
%   sUrl = urlEscape(sUrl,bRevert)
%
% Subfunctions: getEscape
%
% See also: regexptranslate, regexprep 
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-8485-3325
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2019-02-01

% check input
if nargin < 2
    bRevert = false;
end

% get esacpe sequences
cEscape = getEscape;

if bRevert
    % remove escape sequences from URL string
    cSearch = cEscape(:,2);
    cReplace = cEscape(:,1);
else
    % replace special characters by escape sequences
    % prepare search of special signs for regexp use
    cSearch = regexptranslate('escape',cEscape(:,1));
    cReplace = cEscape(:,2);
end

sUrl = regexprep(sUrl,cSearch,cReplace);
return

% =========================================================================

function cEscape = getEscape
% GETESCAPE defines URL escape sequences for special charactes not allowed
% in URL
%
% Syntax:
%   cEscape = getEscape
%
% Inputs:
%
% Outputs:
%   cEscape - cell (mx2) with 
%               (:,1) string with not allowed character
%               (:,1) string with escape sequence e.g. '%20' instead of
%                     blank
%
% Example: 
%   cEscape = getEscape

% escape definiton cell
cEscape = {...
           ' ','20'
           '!','21'
           '"','22'
           '#','23'
           '$','24'
           '%','25'
           '&','26'
           '''','27'
           '(','28'
           ')','29'
           '*','2A'
           '+','2B'
           ',','2C'
           '-','2D'
           '.','2E'
           '/','2F'
           ':','3A'
           ';','3B'
           '<','3C'
           '=','3D'
           '>','3E'
           '?','3F'
           '@','40'
           '[','5B'
           '\','5C'
           ']','5D'
           '{','7B'
           '|','7C'
           '}','7D'
           };
       
% add percent sign to escape sequence
cEscape(:,2) = cellfun(@(x)horzcat('%',x),cEscape(:,2),'UniformOutput',false);
return

