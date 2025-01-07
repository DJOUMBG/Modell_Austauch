function cPart = pathparts(sPath)
% PATHPARTS cuts a path into its parts and returns it in a cell vector
%
% Syntax:
%   cPart = pathparts(sPath)
%
% Inputs:
%   sPath - string with full path to be separated 
%
% Outputs:
%   cPart - cell vector (1xn) with all parts of path 
%
% Example: 
%   cPart = pathparts('C:\folder1\folder2\folder3')
%
% See also: filelparts
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2008-02-07

% initialize output
cPart = {};

% check input
if isempty(sPath)
    return
end

% remove fileseparator from end of string to ensure correct exit strategy
bLinux = strncmp(computer,'GLNX',4);
if sPath(end) == filesep  && ( (bLinux && numel(sPath)>1) || ~bLinux ) 
    sPath = sPath(1:end-1);
end
    
% use fileparts for separation
[sPathRest,sPathPart] = fileparts(sPath);

% reccursion
if isempty(sPathRest) % end reccursion
    cPart = {sPathPart};
elseif isempty(sPathPart) % end reccursion
    cPart = {sPathRest};
else % proceed into reccursion and add results
    cPart = pathparts(sPathRest);
    cPart = [cPart {sPathPart}];
end
return
