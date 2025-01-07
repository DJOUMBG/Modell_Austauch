function sAbsPath = fleAbsolutePathGet(sTargetPath,sRelPath)
% FLEABSOLUTEPATHGET creates the absolute path to reach the given relative
% path from the given target path.
%
% Syntax:
%   sAbsPath = fleAbsolutePathGet(sTargetPath,sRelPath)
%
% Inputs:
%   sTargetPath - string: target path, from which the relative path is described  
%      sRelPath - string 
%
% Outputs:
%   sAbsPath - string: absolute path, which should be described from target path relative  
%
% Example: 
%   fleAbsolutePathGet('C:\a\b\c\d','..\..\f\g\i')
%   fleAbsolutePathGet('C:\a','b\f\g\i')
%   fleAbsolutePathGet('C:\a\b\c\d','..\..\f\g\..\..\i\..')
%
%
% Subfunctions:
% Private functions:
% Other m-files required:
% MAT-files required:
%
% See also: fleIsAbsPath, fleRelativePathGet
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2023-03-27

%% check given paths

% format with os specifiy filesep
sTargetPath = fullfile(sTargetPath);
sRelPath = fullfile(sRelPath);

% check for absolute paths
if ~fleIsAbsPath(sTargetPath)
    error('Given target path "%s" must be a absolute path.',sTargetPath);
end


%% get cut position

% split paths
cTargetParts = strsplit(sTargetPath,filesep);
cRelParts = strsplit(sRelPath,filesep);

% init absolute paths
cAbsParts = cTargetParts;

% delete back going parts and append real path parts
for nPart=1:length(cRelParts)
    
    if strcmp(cRelParts{nPart},'..')
        if length(cAbsParts) > 1
            cAbsParts = cAbsParts(1:end-1);
        else
            error('Could not create abolute path for "%s"\nfrom target path "%s".',...
                cRelParts,sTargetPath);
        end
    else
        cAbsParts = [cAbsParts,cRelParts(nPart)]; %#ok<AGROW>
    end
    
end

sAbsPath = fullfile(strjoin(cAbsParts,filesep));

return
