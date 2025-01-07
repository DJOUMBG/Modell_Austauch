function sPath = dpsPathLevel(sPathFull,sLevel)
% DPSPATHLEVEL determine file system path of a DIVe element level
% Part of the DIVe platform standard package (dps).
%
% Syntax:
%   sPath = dpsPathLevel(sPathFull,sLevel)
%
% Inputs:
%   sPathFull - string with path of the DIVe module location (= folder
%               with Module XML) or with any other level of DIVe logical
%               hierarchy
%        sLevel - string with DIVe hierarchy level (species, family, type)
%
% Outputs:
%   sPath - string with full path of folder reflecting the specified level
%
% Example: 
%   sPath = dpsPathLevel(sPathFull,sLevel)
%
% See also: pathparts
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2015-09-02

% check input
if ~exist(sPathFull,'dir')
    error('dpsPathLevel:invalidPath',['The specified module path was not '...
          'found on the file system: %s'], sPathFull);
end
cPath = pathparts(sPathFull);

% get level index
switch lower(sLevel)
    case 'species'
        nIdLevel = 1;
    case 'family'
        nIdLevel = 2;
    case 'type'
        nIdLevel = 3;
    otherwise
        error('dpsPathLevel:unknownLevel',['The specified level "' sLevel ...
              ' is no valid DIVe sharing level']);
end

% determine folder stacking
if strcmp(cPath{end-1},'Module')
    % determine path by Module
    sPath = fullfile(cPath{1:end-5+nIdLevel});
else
    % check for Context level
    nContext = find(ismember(cPath,{'bdry','ctrl','human','phys','pltm'}));
    % protect against shared level information
    nElement = find(ismember(cPath,{'Data','Module','Support'}));
    if isempty(nElement)
        nMax = numel(cPath);
    else
        nMax = nElement - 1;
    end
    if ~isempty(nContext)
        % check availability of level information
        if nMax < nContext+nIdLevel
            error('dpsPathLevel:invalidFolderTree',['The specified path ' ...
            '"%s" does not contain the requested level "%s".'],sPathFull,sLevel)
        end
        
        % determine path by Context
        sPath = fullfile(cPath{1:nContext+nIdLevel});
    else % failed detection
        error('dpsPathLevel:invalidFolderTree',['The specified path "%s" '...
            'is not a correct location of a DIVe logical hierarchy.'], ...
            sPathFull);
    end
end
return
