function bValid = chkFolderExists(sFolderpath)
% CHKFOLDEREXISTS checks if a folder exist and returns flag.
%
% Syntax:
%   bValid = chkFolderExists(sFolderpath)
%
% Inputs:
%   sFolderpath - string: folderpath of folder
%
% Outputs:
%   bValid - bool (1x1): flag, if folder exists (true) or not (false)
%
% Example: 
%   bValid = chkFolderExists(sFolderpath)
%
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2022-12-15

%% check if folder exists

bValid = logical(exist(sFolderpath,'dir'));  % => Not working for case sensitiv names !!!

return

