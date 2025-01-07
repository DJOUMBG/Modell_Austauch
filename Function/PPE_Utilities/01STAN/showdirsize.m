function showdirsize(sPath)
% SHOWDIRSIZE shows all folders within a directory with their storage sizes.
%
% Syntax:
%   showdirsize(sPath)
%
% Inputs:
%   sPath - string with full path of directory
%
% Outputs:
%
% Example: 
%   showdirsize(pwd)
%
% See also: dirsize
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-8485-3325
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2019-06-24

% check input
if nargin < 1
    sPath = pwd;
end
if ~exist(sPath,'dir')
    error('showdirsize:fileNotFound','The specified file does not exist "%s"',sPath);
end

% get info
xDir = dir(sPath);
xDir(1).dirbytes = [];
nDir = [];
for nIdxDir = 1:length(xDir)
    if xDir(nIdxDir).isdir && ~strcmpi(xDir(nIdxDir).name,'.') && ~strcmpi(xDir(nIdxDir).name,'..')
        xDir(nIdxDir).dirbytes = dirsize(fullfile(sPath,xDir(nIdxDir).name));
        xDir(nIdxDir).string = [xDir(nIdxDir).name '  ' num2str(xDir(nIdxDir).dirbytes/1024^2,'%1.1f') ' MB'];
        nDir(end+1) = nIdxDir; %#ok<AGROW>
    end
end

% user interaction
xList = xDir(nDir);
xList = {xList.string};
[nSelection] = listdlg('ListSize',[400 600],...
                      'ListString',xList,...
                      'SelectionMode','single',...
                      'Name',[sPath ' ' num2str(sum([xList.dirbytes])/1024^2,'%2.0f') ' MB' ]);
if ~isempty(nSelection) && nSelection(1) > 0
    showdirsize(fullfile(sPath,xList(nSelection(1)).name));
end
return
