function cChange = hlxChangesParse(sMsg)
% HLXCHANGESPARSE parse the information of a p4 changes listing with '-l'
% option (long description listing)
%
% Syntax:
%   cChange = hlxChangesParse(sMsg)
%
% Inputs:
%   sMsg - string with p4 changes output
%
% Outputs:
%   cChange - cell (mx6) with changelist information
%             (:x1) integer (1x1) with changelist number
%             (:x2) string with date (and time in case of -t option)
%             (:x3) string with submitter of change
%             (:x4) string with workspace of change
%             (:x5) string with description of change
%             (:x6) string with collection tag of change
%             (:x7) cell of strings with DIVe ID tags
%
% Example: 
%   cChange = hlxChangesParse(p4('changes -l -t @3920,@3940'))
%
% See also: verLessThanMATLAB
%
% Author: Rainer Frey, TP/EAC, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2019-01-25

% divide into lines and remove empty lines
if verLessThanMATLAB('8.4.0')
    ccLine = textscan(sMsg,'%s','BufSize',16777216,'Delimiter','\n','MultipleDelimsAsOne',true); %#ok<BUFSIZE>
else
    ccLine = textscan(sMsg,'%s','Delimiter','\n','MultipleDelimsAsOne',true);
end

% parse changelist entries
nChange = find(cellfun(@(x)strncmp('Change ',x,7),ccLine{1}));
cChange = cell(numel(nChange),7);
for nIdxChange = 1:numel(nChange)
    % determine changelist number
    cChange{nIdxChange,1} = sscanf(ccLine{1}{nChange(nIdxChange)},'Change %i');
    
    % get date and timestamp
    cChange{nIdxChange,2} = regexp(ccLine{1}{nChange(nIdxChange)},'(?<=on ).+(?= by)','match','once');

    % get submitter
    cChange{nIdxChange,3} = regexp(ccLine{1}{nChange(nIdxChange)},'(?<=by )\w+','match','once');

    % determine client/workspace of submit
    cChange{nIdxChange,4} = regexp(ccLine{1}{nChange(nIdxChange)},'(?<=@)\w+','match','once');
    
    % combine all lines of changelist description
    if numel(nChange) < nIdxChange+1
        nDescEnd = numel(ccLine{1});
    else
        nDescEnd = nChange(nIdxChange+1)-1;
    end
    sDescription = strGlue(ccLine{1}(nChange(nIdxChange)+1:nDescEnd),char(10)); %#ok<CHARTEN>
    
    % split tags in brackets [*] and description
    [cBracket,nEnd] = regexp(sDescription,'[^\[\]]+','match','end');
    if numel(cBracket) > 1
        % store classification
        bCol = cellfun(@(x)strcmp('COL:',x(1:min(numel(x),4))),cBracket);
        nCol = find(bCol);
        if ~isempty(nCol)
            cChange{nIdxChange,6} = cBracket{nCol(1)}(5:end);
        end
        
        % store DIVe ID tags
        cChange{nIdxChange,7} = cBracket(~bCol);
        
        % store rest of changelist description
        if numel(ccLine{1}{nIdxChange*2}) > nEnd(end)+1
            cChange{nIdxChange,5} = ccLine{1}{nIdxChange*2}(nEnd(end)+1:end);
        else
            cChange{nIdxChange,5} = '';
        end
    else
        cChange{nIdxChange,5} = sDescription;
%         xChange = hlxDescribeParse(nChange(nIdxChange));
%         if ~isempty(xChange.cFile)
%             bSame = true(1,numel(xChange.cFile{1}));
%             for nIdxFile = 2:numel(xChange.xFile)
%                 nMin = min(numel(bSame),numel(xChange.cFile{nIdxFile}));
%                 bSame = xChange.cFile{nIdxFile-1}(1:nMin) == xChange.cFile{nIdxFile}(1:nMin);
%             end
            %         cChange{nIdxChange,6} =
            %         regexp(xChange.cFile{1}(1:sum(bSame)),'(?=//\w+/\w+/\w+).+','match','once')
%             cChange{nIdxChange,6} = Change.cFile{1}(1:sum(bSame));
%         end
    end
    
    % remove changelist reference tags {*} from description
    cChange{nIdxChange,5} = regexprep(cChange{nIdxChange,5},'\{.+\}','');
end
return
