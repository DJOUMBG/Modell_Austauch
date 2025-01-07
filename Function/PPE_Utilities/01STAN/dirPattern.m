function [cElem,xElem] = dirPattern(sPath,cPattern,sType,bRegExp)
% DIRPATTERN extends system 'dir' command for multiple patterns and type
% (file/folder) specification.
%
% Syntax:
%   cElem = dirPattern
%   cElem = dirPattern(sPath)
%   cElem = dirPattern(sPath,cPattern)
%   cElem = dirPattern(sPath,cPattern,sType)
%   cElem = dirPattern(sPath,cPattern,sType,bRegExp)
%   [cElem,xElem] = dirPattern(sPath,cPattern,sType,bRegExp)
%
% Inputs:
%      sPath - string with file system path
%   cPattern - cell (1xn) with strings of search patterns
%      sType - string with search type:
%                 'file': only files
%               'folder': only folders without system folders
%                  'all': all except system folders
%    bRegExp - boolean to enable regular expression for search pattern
%
% Outputs:
%   cElem - cell (mx1) with strings of found elements (file|folders)
%   xElem - structure (mx1) with output of dir command for filtered element
%
% Example: 
%   cElem = dirPattern(pwd,'*','folder')
%   cElem = dirPattern(pwd,{'*.txt','*.m'},'file')
%   cElem = dirPattern(pwd,'[^p]','file',true)
%   [cElem,xElem] = dirPattern(pwd,'*','folder')
%
% See also: dir, ismember
%
% Author: Rainer Frey, TT/XCI-6, Daimler Truck AG
%  Phone: +49-711-8485-3325
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2014-07-15

% init output
cElem = {};
xElem = struct('name',{},'folder',{},'date',{},'bytes',{},'isdir',{},'datenum',{});

% input check
if nargin < 1
    sPath = pwd;
end
if nargin < 2
    cPattern = {'*'};
end
if nargin < 3
    sType = 'all';
end
if nargin < 4
    bRegExp = false;
end
if ~iscell(cPattern)
    cPattern = {cPattern};
end
if ~ischar(sPath)
    if nargout < 1
        fprintf(1,'The specified path is no string!');
    end
    cElem = {};
    return
end
if exist(sPath,'dir') == 0
    if nargout < 1
        fprintf(1,'The specified path was not found: %s',sPath);
    end
    return
end

% get specified element types of specified path
xDir = dir(sPath);
switch lower(sType)
    case 'file'
        % remove folders
        xDir = xDir(~[xDir.isdir]);
    case {'folder','dir'}
        % remove files
        xDir = xDir([xDir.isdir]);
        
        % remove system folders
        cElem = {xDir.name};
        bSystem = strcmp('.',cElem) | strcmp('..',cElem);
        xDir = xDir(~bSystem);
    case 'all'
        % remove system folders
        cElem = {xDir.name};
        bSystem = ismember(cElem,{'.','..'});
        xDir = xDir(~bSystem);
    otherwise
        warning('dstDir:TypeUnknown','Unknown type - only ''file'' or ''folder'' allowed');
        return
end
if isempty(xDir)
    return
end

% reduce to pattern matches
bKeep = false(1,numel(xDir));
for nIdxPattern = 1:numel(cPattern)
    % convert pattern
    if ~bRegExp
        sPattern = searchstring2regexp(cPattern{nIdxPattern}); 
    else
        sPattern = cPattern{nIdxPattern};
    end
    % test hits against patterns
    cIndex = regexpi({xDir.name},sPattern,'once');
    bKeep = bKeep | ~cellfun(@isempty,cIndex);
end

% reduce list
xElem = xDir(bKeep);
cElem = {xElem.name};

% ensure folder output
if nargout > 1 && verLessThanMATLAB('9.8') && ...
        (~isfield(xElem,'folder') || (~isempty(xElem) && isempty(xElem(1).folder)))
    for nIdxElem = 1:numel(xElem)
        xElem(nIdxElem).folder = sPath;
    end
end
return
