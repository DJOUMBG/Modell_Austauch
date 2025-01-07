function bValid = chkFileExists(sFilepath)
% CHKFILEEXISTS checks if a file exist and returns flag.
%
% Syntax:
%   bValid = chkFileExists(sFilepath)
%
% Inputs:
%   sFilepath - string: filepath of file
%
% Outputs:
%   bValid - bool (1x1): flag, if file exists (true) or not (false)
%
% Example: 
%   bValid = chkFileExists(sFilepath)
%
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2022-12-15

%% check if file exists
bValid = logical(exist(sFilepath,'file')) && ~logical(exist(sFilepath,'dir'));  % => Not working for case sensitiv names !!! 

return

