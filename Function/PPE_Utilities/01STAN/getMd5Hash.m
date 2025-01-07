function sMD5hash = getMd5Hash(sFile)
% GETMD5HASH gets an MD5 hash of a specified file by use of java.
% CAUTION: MD5 hashes from empty files cannot be created.
%
% Syntax:
%   sMD5hash = getMd5Hash(sFile)
%
% Inputs:
%      sFile - string with filepath whose md5 hash value is to be fetched
%
% Outputs:
%   sMD5hash - string of md5 hash values
%
% Example: 
%   sMD5hash = getMd5Hash(sFile)
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2016-05-18

% check input
bExist = exist(sFile,'file');
if bExist < 2 || bExist > 6
    error('getMd5Hash:fileNotFound',...
        'The specified file is not on the file system %s.',sFile);
end

% check file size
xDir = dir(sFile);
if xDir.bytes == 0
    % fprintf(2,'Empty files can not be handled by getMd5Hash: %s\n',sFile);
    sMD5hash = '0';
    return
end

% invoke java object
oMD5 = java.security.MessageDigest.getInstance('MD5');

try
    nFid = fopen(sFile); % open file in matlab
    % pass file content to java
    dMD5hash = typecast(oMD5.digest(fread(nFid,inf,'*uint8')),'uint8');
    fclose(nFid); % close file
    sMD5hash = reshape(dec2hex(dMD5hash),1,[]); % reshape output
catch ME
    fclose(nFid); % close file
    error('getMd5Hash:errorOnHash',['The MD5 hash for the specified file ' ...
        'could not be generated:\n %s\n %s'],sFile,ME.message);
end
return
