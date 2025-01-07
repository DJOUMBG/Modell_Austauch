function nByte = dirsize(sPath)
% DIRSIZE returns the size of a directory with all subsequent directories
% and files in bytes.
%
% Syntax:
%   nByte = dirsize(sPath)
%
% Inputs:
%   sPath - string with full path of directory 
%
% Outputs:
%   nByte - integer (1x1) with size of all files below directory in bytes
%
% Example: 
%   nByte = dirsize(pwd)
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-8485-3325
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2007-06-01

% check input
if ~exist(sPath,'dir')
    fprintf(2,'dirsize: The specified directory does not exist "%s"!',sPath);
    return
end

% determine size of path content
xDir = dir(sPath);

% split to files and folders
bDir = [xDir.isdir];
cFolder = {xDir(bDir).name};
cFolder = cFolder(~ismember(cFolder,{'.','..'}));

% sum bytes
nByteFolder = cellfun(@(x)dirsize(fullfile(sPath,x)),cFolder); % reccursion
nByte = sum(nByteFolder) + sum([xDir(~bDir).bytes]);
return
