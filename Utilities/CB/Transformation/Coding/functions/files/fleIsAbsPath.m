function bIsAbs = fleIsAbsPath(sPath)
% FLEISABSPATH checks if given path is in absolute format (with drive as
% its root).
%
% Syntax:
%   bIsAbs = fleIsAbsPath(sPath)
%
% Inputs:
%   sPath - string: path of folder or file 
%
% Outputs:
%   bIsAbs - boolean (1x1): flag to indicate if path is absolute (true) or relative (false) 
%
% Example: 
%   bIsAbs = fleIsAbsPath(sPath)
%
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2023-03-24

%% check for absolute path

% init output
bIsAbs = false;

% format path
sPath = fullfile(sPath);

% split path by file seperator
cPathParts = strsplit(sPath,filesep);

% get root of path
sRoot = strtrim(cPathParts{1});

% check for character ':' in root to indicate drive
if ~isempty(sRoot)
    if strcmp(sRoot(end),':')
        bIsAbs = true;
    end
end

return