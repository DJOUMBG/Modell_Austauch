function sRelPath = fleRelativePathGet(sTargetPath,sAbsPath)
% FLERELATIVEPATHGET creates the relative path to reach the given absolute
% path from the given target path.
%
% Syntax:
%   sRelPath = fleRelativePathGet(sTargetPath,sAbsPath)
%
% Inputs:
%   sTargetPath - string: target path, from which the abosulte path should be described relative 
%      sAbsPath - string: absolute path, which should be described from target path relative 
%
% Outputs:
%   sRelPath - string: relative path of given absolute path
%
% Example: 
%   fleRelativePathGet('C:\a\b\c\d','C:\a\b\f\g\i')
%   fleRelativePathGet('C:\a','C:\a\b\f\g\i')
%
% Subfunctions: createBackPathString
%
%
% See also: fleIsAbsPath, fleAbsolutePathGet
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2023-03-27

%% check given paths

% format with os specifiy filesep
sTargetPath = fullfile(sTargetPath);
sAbsPath = fullfile(sAbsPath);

% check for absolute paths
if ~fleIsAbsPath(sTargetPath)
    error('Given path "%s" must be a absolute path.',sTargetPath);
end
if ~fleIsAbsPath(sAbsPath)
    error('Given path "%s" must be a absolute path.',sAbsPath);
end


%% get cut position

% split paths
cTargetParts = strsplit(sTargetPath,filesep);
cAbsParts = strsplit(sAbsPath,filesep);

% search for equal parts
nNumTargetParts = length(cTargetParts);
nCutPos = 0;

% get position of first difference in target path
for nPart=1:length(cAbsParts)
    % if target path parts differs first time from abs part
    if (nPart > nNumTargetParts) || ~strcmp(cAbsParts{nPart},cTargetParts{nPart})
        nCutPos = nPart;
        break;
    end
end

% check finding
if ~nCutPos
    error('Could not create relative path for "%s"\nfrom target path "%s".',...
        sAbsPath,sTargetPath);
end


%% create relative path

% append path
sAppendPath = fullfile(strjoin(cAbsParts(nCutPos:end),filesep));

% create relative path
if nCutPos > nNumTargetParts
    % append path parts on target path
    sRelPath = sAppendPath;
else
    % number of going back parts
    nBackNumber = length(cTargetParts(nCutPos:end));
    sRelPath = fullfile(createBackPathString(nBackNumber),sAppendPath);
end

return

% =========================================================================

function sPathStr = createBackPathString(nBackNumber)

sPathStr = '';
for nNum=1:nBackNumber
    sPathStr = fullfile(sPathStr,'..\');
end
    
return