function sMsg = p4fileBatch(sCommand,cFile,nBatchSize,bEmpty)
% P4FILEBATCH execute a specified command, which takes a file list as last
% input in batch sizes, not to exceed the maxlimit of command line
% interface (cmd.exe has limits).
%
% Syntax:
%   sMsg = p4fileBatch(sCommand,cFile)
%   sMsg = p4fileBatch(sCommand,cFile,nBatchSize)
%   sMsg = p4fileBatch(sCommand,cFile,nBatchSize,bEmpty)
%
% Inputs:
%     sCommand - string with command passed to p4 
%        cFile - cell (1xn) with string of files in Helix depot notation
%   nBatchSize - integer (1x1) with size of a single batch
%       bEmpty - boolean (1x1) if empty output is expected (default:false)
%
% Outputs:
%   sMsg - string combined output strings
%
% Example: 
%   sMsg = p4fileBatch('changes -m 1 %s',{'//DIVe/d_main/com/...','//DIVe/d_main/test/...'},15)
%
% See also: p4, strGlue, hlxOutParse
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2018-10-29

% check input
if nargin < 3
    nBatchSize = 12;
end
if nargin < 4
    bEmpty = false;
end

%% file based single call execution mode (only windows and when multiple files used)
% check OS version due to Win11 policy change
[nStatus,sMsg] = system('wmic os get Caption /value');
if ~nStatus
    sVer = regexp(sMsg,'(?<=Windows )\d{2,2}','match','once');
    bWin11 = strcmp(sVer,'11');
else
    bWin11 = false;
end

nStatus = 1;
sCall = ['p4 ' sCommand '"',strGlue(cFile,'" "'),'"'];
if ispc && numel(cFile) > 2*nBatchSize && ...
        numel(sCall) < 33247 && ... % sign limit on powershell command
        ~bWin11 % first Win11 implementation prevents powershell execution
    try
        % create test vector
        % assignin('base','sCommand',sCommand)
        % assignin('base','cFile',cFile)
        % assignin('base','nBatchSize',nBatchSize)

        % write file for Powershell one line approach
        sCommandShort = regexp(sCommand,'[a-z]{3,}','once','match');
        nPID = getPIDMatlab;
        sFileTemp = fullfile(tempdir,sprintf('p4Files4Batch_%s_%i_%04i%02i%02i_%02i%02i%02.0f.ps1',sCommandShort,nPID,datevec(now)));
        nFid = fopen(sFileTemp,'w');
        fprintf(nFid,['p4 ' sCommand],'');
        fprintf(nFid,'%s',['"',strGlue(cFile,'" "'),'"']);
        fprintf(nFid,'\n');
        fclose(nFid);

        % system call with file
        % WORK REMARK - powershell approach works (test on 33246 chars in call; fails with 33247 signs; number of items not relevant)
        [nStatus,sMsg] = system(sprintf('powershell;"%s";exit;exit;',sFileTemp));
        if any(strncmpi(sMsg,{'Error','Fehle'},5))
            fprintf(2,['send to Rainer: p4fileBatch fail with powershell ' ...
                'call with %i items and %i signs (attach p4fileBatchExample.zzz)\n'],...
                numel(cFile),numel(sCall))
            assignin('base','sCommand',sCommand)
            assignin('base','cFile',cFile)
            assignin('base','nBatchSize',nBatchSize)
            save('p4fileBatchExample.zzz','sCommand','cFile','nBatchSize','-mat');
            nStatus = 1;
        end
        
        % cleanup temporary file
        delete(sFileTemp);

    catch ME
        fprintf(1,'Execution error on p4fileBatch via powershell file call mode:\n  %s\n',ME.message);
        nStatus = 1;
    end
end

%% Matlab loop execution with p4 CLI Matlab wrapper
if nStatus % file based skipped or failed
    % execute command in batch sizes (not to exceed max length of CLI inputs)
    sMsg = '';
    for nIdxBatch = 1:ceil(numel(cFile)/nBatchSize)
        % try huge call to p4
        sCall = sprintf(sCommand,[' "',strGlue(cFile(1:min(numel(cFile),nBatchSize)),'" "'),'"']);
        sMsgAdd = p4(sCall);
        
        % check number of output message lines (at least one line per file
        % specifier expected)
        cCheck = strsplitOwn(sMsgAdd,char(10)); %#ok<CHARTEN>
        if strncmp('No file(s) to reconcile.',sMsgAdd,24)
            % proceed without checking
        elseif strncmpi('-z tag',sCommand,6)
            % proceed without checking - line numbers will not match filespecs
        elseif numel(cCheck) < min(numel(cFile),nBatchSize) && ~bEmpty
            fprintf(1,'p4fileBatch:CaptureIssue - switching to single mode... (Call: "p4(%s)"\n',sCall);
            sMsgLine = '';
            nFail = [];
            for nIdxLine = 1:min(numel(cFile),nBatchSize)
                % call again with single file specification
                sMsgLineAdd = p4(sprintf(sCommand,cFile{nIdxLine}));
                if isempty(sMsgLineAdd)
                    nFail = [nFail, nIdxLine]; %#ok<AGROW>
                else
                    sMsgLine = [sMsgLine sMsgLineAdd]; %#ok<AGROW>
                end
            end
            sMsgAdd = sMsgLine;
            
            if ~isempty(nFail)
                % report failures
                fprintf(2,['p4fileBatch:emptyP4Return - the following files produced '...
                    'empty output from the call p4(%s,<file>):\n'],sprintf(sCommand,'<file(s)>'));
                fprintf(2,'%s\n',cFile{nFail})
            end
        end
        
        % add messages and iterate file list
        sMsg = [sMsg, sMsgAdd]; %#ok<AGROW>
        cFile = cFile(nBatchSize+1:end);
    end
end
return
