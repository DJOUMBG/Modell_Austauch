function cOption = changeOption(cOption,sParameter,sValue)
% CHANGEOPTION change or add a parameter value in a cell array of
% parameters.
%
% Syntax:
%   cOption = changeOption(cOption,sParameter,sValue)
%
% Inputs:
%      cOption - cell (1xm) with parameter and value combinations
%   sParameter - string with parameter name
%       sValue - string or numeric with value of parameter
%
% Outputs:
%   cOption - cell (1xn) with parameter and value combinations
%
% Example: 
% cOption = {'SearchDepth',6,'Regexp','on'}
% cOption = changeOption(cOption,'Regexp','off')
% cOption = changeOption(cOption,'CaseSensitive','off')
%
% Author: Rainer Frey, TP/EAC, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2007-06-01

nIdString = find(~cellfun(@isnumeric,cOption)); % remove numeric values for ismember call
[bTrash, nLoc] = ismember(sParameter,cOption(nIdString));  %#ok<ASGLU>
if nLoc == 0 % parameter pair not in options cell
    cOption = [cOption {sParameter,sValue}];
else % replace parameter value
    nLoc = nIdString(nLoc); % re-transform parameter location to full options with numeric values
    cOption{nLoc+1} = sValue;
end
return