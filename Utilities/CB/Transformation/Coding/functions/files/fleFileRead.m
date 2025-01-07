function sTxt = fleFileRead(sFilepath)
% FLEFILEREAD reads the content of file to string with utf-8
%
% Syntax:
%   sTxt = fleFileRead(sFilepath)
%
% Inputs:
%   sFilepath - string: filepath of file to be read 
%
% Outputs:
%   sTxt - string: content of file as string 
%
% Example: 
%   sTxt = fleFileRead(sFilepath)
%
%
% See also: fleOpenFile
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2023-01-19


%% read file to string

% check if file exists
if ~chkFileExists(sFilepath)
    error('File "%s" does not exist.');
end

% open file
nFileId = fleOpenFile(sFilepath,'r');

% read file content as char
sTxt = fread(nFileId,'*char')';

% close file
fclose(nFileId);

return