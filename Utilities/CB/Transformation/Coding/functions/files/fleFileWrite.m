function fleFileWrite(sFilepath,sTxt,sPerm)
% FLEFILEWRITE writes the content of file as string text.
%
% Syntax:
%   fleFileWrite(sFilepath,sTxt,sPerm)
%   fleFileWrite(sFilepath,sTxt)
%
% Inputs:
%   sFilepath - string: filepath of file to be written 
%        sTxt - string: content of file as string
%       sPerm - string [optional]: writing permission
%
% Example: 
%   fleFileWrite(sFilepath,sTxt,sPerm)
%
%
% See also: fleOpenFile
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2023-03-02

%% input arguments

if nargin < 3
    sPerm = 'w';
end


%% read file to string

% open file
nFileId = fleOpenFile(sFilepath,sPerm);

% read file content as char
fwrite(nFileId,sTxt);

% close file
fclose(nFileId);

return