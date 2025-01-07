function hlxLogReduce(sFile,nLevel,sSearch,bDoubleRemove)
% HLXLOGREDUCE reduce a p4 log output to relevant command lines without db
% or command execution details. Results are written to a *_red.txt-file.
%
% Syntax:
%   hlxLogReduce(sFile,nLevel,sSearch)
%
% Inputs:
%     sFile - string with file to be reduced
%    nLevel - integer (1x1) with reduction levels
%              0: keep everything
%              1: reduce to Perforce server info lines (issued commands)
%              2: remove rmt-journal entries of replica and edge servers
%              3: remove rogue line (incomplete) {default value}
%              4: remove trgContentRead entries
%              5: remove automation_LDYN entries
%              6: remove diveonesys entries
%   sSearch - [optional] string with string contained in lines of interest
%
% Outputs:
%
% Example: 
%   hlxLogReduce('log.txt',5)
%   hlxLogReduce('log.txt',5,'automation_LDYN')
%
% See also: p4 logtail
%
% Author: Rainer Frey, TP/EAC, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2020-11-19

% check nargin
if nargin < 1
    sFile = uigetfile('*.txt','Select log.txt file');
    if isempty(sFile) || isnumeric(sFile)
        return
    end
end
if nargin < 2
    nLevel = 3;
end
if nargin < 3
    sSearch = '';
end
if nargin < 4
    bDoubleRemove = false;
end

% read file 
nFid = fopen(sFile,'r');
ccLine = textscan(nFid,'%s','Delimiter',char(10)); %#ok<CHARTEN>
fclose(nFid);
nLineOrg = numel(ccLine{1});

% compress to relevant lines
if nLevel > 0
    bServerInfo = strncmp(ccLine{1},'Perforce server info:',21);
    nServerInfo = find(bServerInfo)+1;
    cLine = ccLine{1}(nServerInfo);
    fprintf(1,'Removed detail lines (%i/%i)\n',nLineOrg-numel(cLine),nLineOrg);
    clear ccLine
end

% remove server journal copy
if nLevel > 1
    bKeep = ~cellfun(@(x)strcmp(x(max(1,numel(x)-12):end),'''rmt-Journal'''),cLine);
    fprintf(1,'Removed Journal copy lines (%i/%i)\n',sum(~bKeep),numel(cLine));
    cLine = cLine(bKeep);
end

% remove rogue lines
if nLevel > 2
    bKeep = cellfun(@(x)numel(x)>29,cLine);
    fprintf(1,'Removed rogue lines (length < 30) (%i/%i)\n',sum(~bKeep),numel(cLine));
    cLine = cLine(bKeep);
    bKeep = ~cellfun(@(x)contains(x,'compute'),cLine);
    fprintf(1,'Removed lines of compute statement (%i/%i)\n',sum(~bKeep),numel(cLine));
    cLine = cLine(bKeep);
    bKeep = ~cellfun(@(x)contains(x,'completed'),cLine);
    fprintf(1,'Removed lines of completed statement (%i/%i)\n',sum(~bKeep),numel(cLine));
    cLine = cLine(bKeep);
    bKeep = ~cellfun(@(x)contains(x,'svcedge'),cLine);
    fprintf(1,'Removed lines of svcedge (%i/%i)\n',sum(~bKeep),numel(cLine));
    cLine = cLine(bKeep);
    bKeep = ~cellfun(@(x)contains(x,'svccommit'),cLine);
    fprintf(1,'Removed lines of svccommit (%i/%i)\n',sum(~bKeep),numel(cLine));
    cLine = cLine(bKeep);
end

if isempty(sSearch)
    % remove trigger lines
    if nLevel > 3
        bKeep = ~cellfun(@(x)contains(x,'trgContentRead'),cLine);
        fprintf(1,'Removed lines of Trigger User (%i/%i)\n',sum(~bKeep),numel(cLine));
        cLine = cLine(bKeep);
    end
    
    % remove automation_LDYN lines
    if nLevel > 4
        bKeep = ~cellfun(@(x)contains(x,'automation_LDYN'),cLine);
        fprintf(1,'Removed lines of automation_LDYN User (%i/%i)\n',sum(~bKeep),numel(cLine));
        cLine = cLine(bKeep);
    end
    
    % remove diveonesys lines
    if nLevel > 5
        bKeep = ~cellfun(@(x)contains(x,'diveonesys'),cLine);
        fprintf(1,'Removed lines of diveonesys User (%i/%i)\n',sum(~bKeep),numel(cLine));
        cLine = cLine(bKeep);
    end
else
    bKeep = cellfun(@(x)contains(x,sSearch),cLine);
    fprintf(1,'Extracted lines containing "%s" (%i/%i)\n',sSearch,sum(bKeep),numel(cLine));
    cLine = cLine(bKeep);
end

if bDoubleRemove
    nLineLength = cellfun(@numel,cLine);
    nDiffLength = diff(nLineLength);
    bKeep = true(size(cLine));
    for nIdxLine = (find(nDiffLength == 0))'
        if strcmp(cLine{nIdxLine},cLine{nIdxLine+1})
            bKeep(nIdxLine+1) = false;
        end
    end
    fprintf(1,'Removed double lines (%i/%i)\n',sum(~bKeep),numel(cLine));
    cLine = cLine(bKeep);
end

% write reduced file
[sPath,sName,sExt] = fileparts(sFile);
sFileNew = fullfile(sPath,[sName '_red' sExt]);
nFid = fopen(sFileNew,'w');
for nIdxLine = 1:numel(cLine)
    fprintf(nFid,'%s\n',cLine{nIdxLine});
end
fclose(nFid);
return


