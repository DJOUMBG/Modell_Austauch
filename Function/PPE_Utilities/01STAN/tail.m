function sOut = tail(varargin) 
% TAIL simple tail implementation (pure MATLAB based) to get last lines of
% a file. Single, static call - no "follow" option.
%
% Syntax:
%   sOut = tail(sLine,sFile)
%
% Inputs:
%   sLine - character array with line specifier to be read e.g. '-5' 
%   sFile - character array with filepath to be tailed
%
% Outputs:
%   sOut - character array containing last lines including newline char(10) 
%
% Example: 
%   sOut = tail('-5','Textfile.txt')
%   tail -5 Textfile.txt 
%
% See also: tailShell, head
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2017-10-17

% check input
sFile = varargin{end};
if ~exist(sFile,'file')
    error('tail:fileNotFound','The specified file cannot be found: "%s"\n',sFile);
end
nLine = str2double(varargin{1}(2:end));
if isnan(nLine)
    error('tail:unknownLineSpecified',...
        'The specified tailing lines are illegal: "%s"\n',varargin{1});
end

% determine read limit
nByteMax = 1024*2^7;
xDir = dir(sFile);
nByteMax = min(xDir(1).bytes,nByteMax);

% init counters
nByte = 8;
nLineCurrent = 0;

% read from file
nFid = fopen(sFile,'r');
while nByte <= nByteMax && numel(nLineCurrent) < nLine+1
    try
        fseek(nFid,-nByte,'eof');
        sChar = fread(nFid,Inf,'*char')';
    catch ME
        fprintf(2,'getting last %i Bytes failed with message:\n %s\n',...
            nByte,ME.message);
    end
    nLineCurrent = find(sChar==sprintf('\n'),nLine+1,'last');
    nByte = nByte * 2;
    if nByte == nByteMax * 2
        nByte = nByteMax + 1;
    elseif nByte > nByteMax
        nByte = nByteMax;
    end
end
fclose(nFid);

% check stop condition
if nByte >= nByteMax
    fprintf(2,'Encountered file/byte limit (%i) without finding sufficient lines.\n',nByteMax);
end

% cut requested lines
sOut = sChar(nLineCurrent(1)+1:end);
% remove carriage return char (\r), char(13) - otherwise double 
sOut = sOut(sOut~=char(13));
return 
