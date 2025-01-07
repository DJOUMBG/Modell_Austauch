function bSuccess = touch(cFile)
% TOUCH updates lastModified timestamp of a file by Java.
%
% Syntax:
%   bSuccess = touch(cFile) 
%   bSuccess = touch(cFile,nMode)
%
% Inputs:
%   cFile - string or cell of strings with filepath
%
% Outputs:
%   bSuccess - string or cell of strings with filepath
%
% Example: 
%   touch('test.m')
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2017-02-23

% check input
if isempty(cFile)
    return
end
if ~iscell(cFile) && ischar(cFile)
    if exist(cFile,'file')
        cFile = {cFile};
    elseif exist(cFile,'dir')
        cFile = getFilesAll(cFile);
    else
        error('touch:unknownArgumentType',...
            'The argument to "touch" is neither cell nor string (file/path).')
    end
end

% loop over files
bSuccess = false(size(cFile));
for nIdxFile = 1:numel(cFile)
    % check existence of file
    if ~exist(cFile{nIdxFile},'file')
        fprintf(2,'Error: touch:FileNotFound - The specified file is not on the file system: %s\n',...
            cFile{nIdxFile});
        continue
    end
    
    % change the lastModified timestamp
    bSuccess(nIdxFile) = java.io.File(cFile{nIdxFile}).setLastModified(java.lang.System.currentTimeMillis);
end
return
