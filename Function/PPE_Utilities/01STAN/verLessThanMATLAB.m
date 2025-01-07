function bLessThan = verLessThanMATLAB(sVersion)
% VERLESSTHANMATLAB determines if the specified MATLAB version and major patch level
% is older than the current MATLAB version.
%
% Syntax:
%   bLessThan = verLessThanMATLAB(sVersion)
%
% Inputs:
%   sVersion - string with version (e.g. '7.11' or '7.11.1')
%
% Outputs:
%   bLessThan - boolean if specified version less than actual used
%
% Example: 
%   bLessThan = verLessThanMATLAB('7.11')
%   bLessThan = verLessThanMATLAB('9.99')
%
% Subfunctions: verString2Number
%
% See also: sscanf, version
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2016-03-16

% init output
bLessThan = [];

% check input
if isempty(sVersion)
    return
end

% convert specified version to number
vVersion = verString2Number(sVersion);

% convert current MATLAB version to number
vVersionInstall = verString2Number(version);

% evaluate boolean return value
bLessThan = vVersion > vVersionInstall;
return

% =========================================================================

function vVersion = verString2Number(sVersion)
% VERSTRING2NUMBER convert a multidigit block version string (e.g.
% '7.11.1') into a float number. Limit is to 3 digit blocks, so MATLABs
% minor path levels (like 7.11.1.866) are not considered
%
% Syntax:
%   vVersion = verString2Number(sVersion)
%
% Inputs:
%   sVersion - string with multidigit block version string
%
% Outputs:
%   vVersion - value (1x1) with version
%
% Example: 
%   vVersion = verString2Number(sVersion)

nVersion = sscanf(sVersion,'%d.'); % parse string into numbers
nVersion = nVersion(1:min(3,numel(nVersion))); % limit to 3 number blocks
vMultiplier = 10.^(0:-3:-3*(numel(nVersion)-1));
vVersion = vMultiplier * nVersion;
return
