function [sMsg,nStatus] = p4print(cDepot,cFile)
% P4PRINT direct interface to use p4 print to get files from Perforce.
%
% Syntax:
%   p4print(cDepot,cFile)
%
% Inputs:
%   cDepot - cell (1xn) with strings of depot filespecs
%    cFile - cell (1xn) with strings of matching filesystem locations
%
% Outputs:
%
% Example: 
%   p4print({'//depot/myStream/myFolder/myFile1.txt'},{'c:\temp\myFolder\myFile1.txt})
%   p4print({'//depot/myStream/myFolder/myFile1.txt@12345'},{'c:\temp\myFolder\myFile1.txt})
%   p4print({'//depot/myStream/myFolder/...'},{'c:\temp\myFolder\...}) % get alle files + subfolders 
%
% See also: p4
%
% Author: Rainer Frey, TP/EAF, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2021-03-25

for nIdxFile = 1:numel(cDepot)
    sCall = sprintf('print -q -o %s %s',cFile{nIdxFile},cDepot{nIdxFile});
    [sMsg,nStatus] = p4(sCall); 
end
return
