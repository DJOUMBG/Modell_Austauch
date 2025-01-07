function xChange = hlxDescribeParse(nChange,sOption)
% HLXDESCRIBEPARSE get the details (p4 describe -s) of the specified
% changelists parsed into a specific structure format.
%
% Syntax:
%   xChange = hlxDescribeParse(nChange)
%   xChange = hlxDescribeParse(nChange,sOption)
%
% Inputs:
%   nChange - integer (1xn) with changelist numbers to extract details
%   sOption - [optional] string with options to be entered between command
%             and changelist number
%
% Outputs:
%   xChange - structure (1xm) for each requested changelist with fields: 
%    .cFile        - cell (nx1) with strings of files in Helix depot
%                    notation e.g. //dep/strm/subfolder1/file.ext
%    .sDescription - char (1xn) with changelist description (may contain char(10)) 
%    .nChange      - integer (1x1) with change list number
%    .sUser        - char (1xn) with user ID sumitting the changelist
%    .sWorkspace   - char (1xn) with workspace from which the changelist
%                    was submitted
%    .vDateVec     - integer (1x6) with Matlab date vector
%
% Example: 
%   xChange = hlxDescribeParse(4048)
%   xChange = hlxDescribeParse([4048 4049 4052])
%
% See also: p4, strGlue, strsplitOwn, structInit
%
% Author: Rainer Frey, TP/EAC, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2019-02-25

% check input
if nargin < 2
    sOption = '';
else
    sOption = [sOption ' '];
end

% get changelist description outputs
% sMsg = p4(['describe -s' sOption sprintf(' %i',nChange)]);
sMsg = p4(['describe -s' sprintf([' %s%i' repmat(' %i',1,numel(nChange)-1)],sOption,nChange)]);

% split into lines
cLineAll = strsplitOwn(sMsg,char(10),false); %#ok<CHARTEN>

% detect start of single changes in answer
nChangeStart = find(cellfun(@(x)strncmp('Change ',x,7),cLineAll));
nChangeStart = [nChangeStart;numel(cLineAll)+1];

% try to repair "Change " as start of changelist description
if any(nChangeStart < 8) % minimum length of a change line output is 8
    % keep only starts, when block before has more than 8 lines
    nIdStartReasonable = [1; find(diff(nChangeStart)>7)+1]; 
    nChangeStart = nChangeStart(nIdStartReasonable);
end

% split changes
xChange = structInit('cFile','sDescription','nChange','sUser','sWorkspace','vDateVec');
for nIdxChange = 1:numel(nChangeStart)-1 % loop over changes
    % get lines of this change
    cLine = cLineAll(nChangeStart(nIdxChange):nChangeStart(nIdxChange+1)-1);

    % parse header line
    cHead = strsplitOwn(cLine{1},' ',true);
    if strcmp(cHead{end},'*pending*') % remove pending for date parsing
        cHead = cHead(1:end-1);
    end
    xChange(nIdxChange).nChange = str2double(cHead{2});
    cSubmitInfo = strsplitOwn(cHead{4},'@');
    xChange(nIdxChange).sUser = cSubmitInfo{1};
    xChange(nIdxChange).sWorkspace = cSubmitInfo{2};
    xChange(nIdxChange).vDateVec = datevec(strGlue(cHead(end-1:end),' '));
    
    % parse content blocks
    nLineEmpty = find(cellfun(@isempty,cLine));
    xChange(nIdxChange).sDescription = strGlue(cLine(nLineEmpty(1):nLineEmpty(2)-1),char(10)); %#ok<CHARTEN>
    nLineFile = find(strcmp('Affected files ...',cLine));
    if ~isempty(nLineFile)
        nLineEmpty = nLineEmpty(nLineEmpty > nLineFile);
        xChange(nIdxChange).cFile = cellfun(@(x)regexp(x,'//.+(?=\#\d+)','match','once'),...
                                    cLine(nLineEmpty(1)+1:nLineEmpty(2)-1),'UniformOutput',false);
        xChange(nIdxChange).cFileAction = cellfun(@(x)regexp(strtrim(x),'\S+$','match','once'),...
                                    cLine(nLineEmpty(1)+1:nLineEmpty(2)-1),'UniformOutput',false);
    end
    nLineFile = find(strcmp('Shelved files ...',cLine));
    if ~isempty(nLineFile)
        nLineEmpty = nLineEmpty(nLineEmpty > nLineFile);
        xChange(nIdxChange).cFileShelve = cellfun(@(x)regexp(x,'//.+(?=\#\d+)','match','once'),...
                                    cLine(nLineEmpty(1)+1:nLineEmpty(2)-1),'UniformOutput',false);
        xChange(nIdxChange).cFileShelveAction = cellfun(@(x)regexp(strtrim(x),'\S+$','match','once'),...
                                    cLine(nLineEmpty(1)+1:nLineEmpty(2)-1),'UniformOutput',false);
    end
end
return
