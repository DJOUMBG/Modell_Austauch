function hlxReview(nChange)
% HLXREVIEW review function for admins with superuser rights to waiver
% changelists from users against the trigger chkContent function.
%
% Syntax:
%   hlxReview(nChange)
%
% Inputs:
%   nChange - integer (1x1) with the number of the changelist to waiver
%
% Outputs:
%
% Example: 
%   hlxReview(3333)
%
% See also: hlxDescribeParse, hlxFormParse, hlxOutParse, hlxReview, p4,
% p4change, p4form, p4info, p4switch, strGlue, getenvOwn 
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2020-01-17

% check function availability
nStatus = hlxFunctionAvailability({'chkContent','dsxRead','dstXmlGetAll'},...
    {'drd_DIVeScripts'},...
    {'CHK','DPS','ModuleDev\Simulink'});
if nStatus
    return
end

% determine current user
sUser = p4info('User name');
sHost = upper(getenvOwn('computername'));

% determine workspace and stream of change
xChange = hlxDescribeParse(nChange,'-S');
sStream = regexp(xChange.cFileShelve{1},'(?<=//\w+/)\w+','match','once');

% check available workspaces and switch to stream 
cClient = hlxOutParse(p4('clients','--me'),' ',5,true); % get clients of this user
cStream = regexp(cClient(:,2),'(?<=_C[^_]+_)\w+','match','once');
bStream = ~cellfun(@isempty,regexp(cStream,['^' sStream],'once'));
if any(bStream)
    cClient = cClient(bStream,:);
else
    fprintf(2,['You have no clients of stream "%s". ' ...
        'You need to create a new workspace first. \n'],sStream);
    return
end
cHost = regexp(cClient(:,2),'(?<=_)C[^_]+','match','once');
bHost = ~cellfun(@isempty,regexp(cHost,['^' sHost],'once'));
if ~any(bHost)
    fprintf(2,['You have no clients of stream "%s" on this computer. ' ...
        'You need to create a new workspace first. \n'],sStream);
    fprintf(2,'You have clients of stream "%s" on computer(s): \n',sStream); ...
    disp(cHost(~bHost));
    return
else
    % TODO implement client creation
end
nHost = find(bHost);
sClient = cClient{nHost(1),2};
[nStatus,sWorkspace,sPrevious] = p4switch(sClient,0,'',cClient); %#ok<ASGLU>

% determine disk folder
[cStream,cRoot] = hlxFormParse(p4('client -o'),{'Stream','Root'},' ',1); %#ok<ASGLU>

%% check prerquisites for shelfed changelist operations
% check if all files are shelved
cAll = union(xChange.cFile,xChange.cFileShelve);
if numel(cAll) ~= numel(xChange.cFileShelve)
    fprintf(2,'Not all files are shelved! Aborting...\n')
    return
end

% revert files if not yet done
if ~isempty(xChange.cFile)
        p4(sprintf('revert -c %i -C %s //...',nChange,xChange.sWorkspace));
end

%% determine uppermost common disk path of file in changelist
ccPath = cellfun(@pathparts,xChange.cFileShelve,'UniformOutput',false);
sPathDepotStream = [ ccPath{1}{1} '/' ccPath{1}{2}];
nMin = min(cellfun(@numel,ccPath));
ccPath = cellfun(@(x)x(3:min(numel(x),nMin)),ccPath,'UniformOutput',false); % remove //depot/stream and limit to common base
cPath = vertcat(ccPath{:});
nBase = nMin-2;
while numel(unique(cPath(:,nBase))) > 1 && nBase > 1
    nBase = nBase - 1;
end
cPathClient = pathparts(cRoot{1});
sPathBase = fullfile(cPathClient{:},cPath{1,1:nBase});

%% sync workspace part
[sMsg,nStatus] = p4(sprintf('sync %s',strGlue([{sPathDepotStream},cPath(1,1:nBase),{'...'}],'/')));

%% unshelve files and remove them from chelve
if false 
    % unshelve to new changelist
    % create new changelist with matching description
    nNew = p4change(xChange.sDescription,[],'public');
    
    % unshelve and delete shelve
    [nStatus] = unshelve(nChange,nNew);
else
    % overtake changelist
    [nStatus,sMsg] = p4form('change',num2str(nChange),'-f','User',{sUser},'Client',{sClient});
    if nStatus
        fprintf(2,'Failure in overtaking the changelist "%i" with message:\n%s\nhlxReview stopped.}n',nChange,sMsg);
        return
    end
    
    % unshelve and delete shelve
    [nStatus] = unshelve(nChange,nChange);
end

%% issue DIVe checks
xElement = dstXmlGetAll(sPathBase);
bStatusAll = true;
for nIdxElem = 1:numel(xElement)
    [bStatus,cMsg] = chkContent(xElement(nIdxElem).sPath);
    if ~bStatus
        % report error and create link for retesting
        fprintf(2,'Check failed on "%s" with message:/n%s',...
                  xElement(nIdxElem).sPath,cMsg{end,1});
        fprintf(2,['<a href="matlab:chkContent(%s)">Re-issue ' ...
            'chkContent on failed element</a>\n'],xElement(nIdxElem).sPath);
    end
    bStatusAll = bStatusAll && bStatus;
end

if bStatusAll
    % create submit link
    fprintf(1,['All elements passed DIVe chkContent ' ... 
        '<a href="matlab:p4(''submit -c %i'')">Submit waiver change %i</a>\n'],nChange,nChange);
else
    % create re-issue DIVe check link
        fprintf(2,'Check failed on "%s" with message:/n%s',...
                  xElement(nIdxElem).sPath,cMsg{end,1});
        fprintf(2,['<a href="matlab:xElement=dstXmlGetAll(''%s'');' ...
            'for nIdxElem = 1:numel(xElement), ' ...
            '[bStatus,cMsg] = chkContent(xElement(nIdxElem).sPath); ' ...
            'end">At least one fail - re-issue ' ...
            'chkContent on submit</a>\n'],sPathBase);
        fprintf(2,['Some elements failed DIVe chkContent ' ... 
        '<a href="matlab:p4(''submit -c %i'')">Submit waiver change %i</a>\n'],nChange,nChange);
end
    
%% return to old workspace
if ~isempty(sPrevious)
    p4switch(sPrevious);
end
return

% =========================================================================

function [nStatus] = unshelve(nChangeSource,nChangeTarget)
% UNSHELVE unshelve files into changelist and remove them from shelf.
%
% Syntax:
%   nStatus = unshelve(nChangeSource,nChangeTarget)
%
% Inputs:
%   nChangeSource - integer (1x1) with changelist of shelved files
%   nChangeTarget - integer (1x1)  with changelist the files should be
%                   unshelved to
%
% Outputs:
%   nStatus - integer (1x1) with cummulated status (n=0 means success)
%
% Example: 
%   nStatus = unshelve(nChangeSource,nChangeTarget)

% unshelve into changelist
[sMsg,nStatus] = p4(sprintf('unshelve -s %i -c %i',nChangeSource,nChangeTarget));
if nStatus
    fprintf(2,['hlxReview:unshelveFail - the unshelve from changelist ' ...
        '"%i" to "%i" failed - stopped operation.\n%s\n'],nChangeSource,nChangeTarget,sMsg);
    return
end

% delete shelved files
[sMsg,nStatus] = p4(sprintf('shelve -f -d -c %i -Af',nChangeTarget));
if nStatus
    fprintf(2,['hlxReview:shelveDeleteFail - the delete of shelved files ' ...
        'from changelist "%i" to "%i" failed - stopped operation.\n%s\n'],...
        nChangeSource,nChangeTarget,sMsg);
    return
end
return