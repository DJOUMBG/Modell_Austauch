function nFileId = fleOpenFile(sFilepath,sPerm)
% OPENFILE opens a file with specified permission and returns the file 
% handle ID.
%
%
% Syntax:
%   hFileId = openFile(sFilepath,sPerm)
%
% Inputs:
%   sFilepath - string of file path 
%       sPerm - string of read/write permission (see fopen)
%
% Outputs:
%   nFileId - integer (1x1) with file ID
%
% Example: 
%   hFileId = openFile(sFilepath,sPerm)
%
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2022-10-06

%% open file

% try to open file with permission
try
    %nFileId = fopen(sFilepath,sPerm,'n','UTF-8');
    nFileId = fopen(sFilepath,sPerm);
catch ME
    error('fleOpenFile:ErrorOpenFile',...
        'Could not open file "%s" with permission "%s", because of:\n%s',...
        sFilepath,sPerm,ME.message);
end

% check if file is opened
if nFileId < 0
    error('fleOpenFile:CouldNotOpenFile',...
        'Could not open file "%s" with permission "%s".',...
        sFilepath,sPerm);
end

return
