function sHlxPath = hlxPathFromFsPath(sPath)
% HLXPATHFROMFSPATH translates a file system path into a Perforce HelixCore
% depot path.
%
% Syntax:
%   sHlxPath = hlxPathFromFsPath(sPath)
%
% Inputs:
%   sPath - string with file system path within the current client/
%           workspace
%
% Outputs:
%   sHlxPath - string with Helix depot path and (e.g. //DIVe/d_main/f1/f2/...)
%
% Example: 
%   sHlxPath = hlxPathFromFsPath(sPath)
%
% See also: hlxFormParse, p4, pathparts, strGlue
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2018-10-26

% get information of current workspace
[cClient,cStream,cRoot] = hlxFormParse(p4('client -o'),{'Client','Stream','Root'},' ',1);

% check relation to currect path
if ~strcmpi(cRoot{1},sPath(1:min(numel(sPath),numel(cRoot{1}))))
    fprintf(1,['The specified path "%s" is not under the current workspace ' ...
        '"%s" with root "" and depot path ""'],sPath,cClient{1},cStream{1},cRoot{1});
    sHlxPath = '';
    return
end

% split up pathes
cPath = pathparts(sPath);
cPathRoot = pathparts(cRoot{1});
nPathRoot = numel(cPathRoot);

% create depot path
sHlxPath = strGlue([cStream cPath(nPathRoot+1:end) {'...'}],'/');
return
