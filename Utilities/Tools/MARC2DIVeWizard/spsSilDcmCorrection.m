function spsSilDcmCorrection(sFile)
% SPSSILDCMCORRECTION correction file for MARC DCM export files, which have
% an illegal ST/Y tag within "STUETZSTELLENVERTEILUNG" sections. This needs
% to be replaced by ST/X in these sections.
%
% Syntax:
%   spsSilDcmCorrection(sFile)
%
% Inputs:
%   sFile - string with filepath of DCM file
% Outputs:
%
% Example: 
%   spsSilDcmCorrection(sFile)
%
% Subfunctions: getVectorElementGreater
%
% See also: verLessThanMATLAB
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2017-06-14

% input check
if nargin < 1
        [sFile,sPath] = uigetfile( ...
        {'*.dcm','DCM files (*.dcm)'; ...
        '*.*',  'All Files (*.*)'}, ...
        'Open DCM File',...
        'MultiSelect','off');
    if isequal(sFile,0) % user chosed cancel in file selection popup
        return
    else
        sFile = fullfile(sPath,sFile);
    end
end

% read DCM as ASCII file
nFid = fopen(sFile,'r');
if verLessThanMATLAB('8.4.0')
    ccLine = textscan(nFid,'%s','delimiter','\n','Whitespace','','bufsize',65536); 
else
    ccLine = textscan(nFid,'%s','delimiter','\n','Whitespace','');
end
fclose(nFid);
cLine = ccLine{1};

% determine start and end of section STUETZSTELLENVERTEILUNG
nStart = find(~cellfun(@isempty,regexp(cLine,'^STUETZSTELLENVERTEILUNG','once')));
nEndAll = find(~cellfun(@isempty,regexp(cLine,'^END','once')));
nIdxEnd = arrayfun(@(x)find(x<nEndAll,1,'first'),nStart);
nEnd = nEndAll(nIdxEnd);

% replace ST/Y entry by ST/X entry within section STUETZSTELLENVERTEILUNG
for nIdxSection = 1:numel(nStart)
    cLine(nStart(nIdxSection):nEnd(nIdxSection)) = regexprep(...
        cLine(nStart(nIdxSection):nEnd(nIdxSection)),...
        'ST/Y','ST/X');
end

% secure old file
[sPath,sName] = fileparts(sFile);
bStatus = 0;
nRetry = 0;
while ~bStatus && nRetry < 10
    [bStatus,sMsg] = movefile(sFile,fullfile(sPath,[sName,'.org']));
    pause(0.1);
    nRetry = nRetry + 1;
end
if nRetry > 9
    fprintf(2,'movefile failed and reached the retry limit: \n%s\n',sMsg);
end

% write DCM file
nFid = fopen(sFile,'w');
for nIdxLine = 1:numel(cLine)
    fprintf(nFid,'%s\n',cLine{nIdxLine});
end
fclose(nFid);
return
