function sOut = head(varargin) 
% HEAD simple head implementation (pure MATLAB based) to get first lines of
% a file. Single, static call - no "follow" option.
%
% Syntax:
%   sOut = head(sLine,sFile)
%
% Inputs:
%   sLine - character array with line specifier to be read e.g. '-5' 
%   sFile - character array with filepath to be tailed
%
% Outputs:
%   sOut - character array containing first lines including newline char(10) 
%
% Example: 
%   sOut = head('-5','Textfile.txt')
%   head -5 Textfile.txt 
%
% See also: tailShell, tail
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2017-10-17

% check input
sFile = varargin{end};
if ~exist(sFile,'file')
    error('head:fileNotFound','The specified file cannot be found: "%s"\n',sFile);
end
nLine = str2double(varargin{1}(2:end));
if isnan(nLine)
    error('head:unknownLineSpecified',...
        'The specified tailing lines are illegal: "%s"\n',varargin{1});
end

% read from file
cLine = cell(1,nLine);
nFid = fopen(sFile,'r');
for nIdxLine = 1:nLine
    cLine{nIdxLine} = fgets(nFid);
    if cLine{nIdxLine} == -1
        cLine = cLine(1:end-1);
        break
    end
end
fclose(nFid);

% concatenate to output character array
sOut = [cLine{:}];

% remove carriage return char (\r), char(13) - otherwise double 
sOut = sOut(sOut~=char(13));
return 
