function [nStatus,sMsg] = p4form(sCommand,varargin)
% P4FORM creates Perforce HelixCore p4 commands which fill a p4 form in a
% single call (e.g. creation of groups, streams, users, clients ...) with
% reduced comfort syntax.
%
% Syntax:
%   [nStatus,sMsg] = p4form(sCommand,varargin)
%
% Inputs:
%    sCommand - string with p4 command to execute with form -o/-i and
%               additional field syntax
%   sArgument - [optional] string with argument to command
%      sForce - [optional] string "-f" as force option at input call
%  repeating:
%     sArg<n> - string with form field name
%   cValue<n> - cell with values to be set for form field
%
% Outputs:
%   nStatus - integer (1x1) with status of system call
%      sMsg - string with feedback from system call
%
% Example: 
%   [nStatus,sMsg] = p4form('change','Type',{'restricted'},'Description',{'blabla'})
%   [nStatus,sMsg] = p4form('group','test_group','Owners',{'rafrey5'},'Users',{'rafrey5','pethama'})
%   [nStatus,sMsg] = p4form('change',num2str(51,'%i'),'-f','Description',{'test bla bla'})
%   [nStatus,sMsg] = p4form('stream','//DIVe/drm_main','-f','Options',{'"allsubmit unlocked notoparent nofromparent mergedown"'})
%
% See also: p4FieldExpand, strGlue, p4
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2018-06-15

%% check input
% check for force flag
bForce = strcmp('-f',varargin(1:min(2,numel(varargin))));
if any(bForce)
    % remove force flag from varargin
    varargin(bForce) = [];
    cForce = {'-f'};
else
    cForce = {};
end

% check for additional argument for command
if mod(numel(varargin),2) == 0
    cArgument = {};
else
    cArgument = varargin(1);
    varargin = varargin(2:end);
end

%% handle field value listings
% parse input arguments assuming argument value pairs at end
cPV = reshape(varargin,2,numel(varargin)/2)';

% ensure correct data types
bChar = cellfun(@ischar,cPV(:,1));
if ~all(bChar)
    error('p4form:invalidInputPairChar',....
        ['p4form input is not a char vector argument on argument/value ' ...
         'pair no. %i - always argument(char)/value(cell) pairs are needed'],...
        find(bChar));
end
bCell = cellfun(@iscell,cPV(:,2));
if ~all(bCell)
    error('p4form:invalidInputPairChar',....
        ['p4form input is not a cell vector argument on argument/value ' ...
         'pair no. %i - always argument(char)/value(cell) pairs are needed'],...
        find(bCell));
end

% expand lists
ccField = cell(1,size(cPV,1));
for nIdxPair = 1:size(cPV,1)
    ccField{nIdxPair} = p4FieldExpand(cPV{nIdxPair,1:2});
end

%% issue direct p4 CLI call
% combine input arguments
sCall = strGlue([ccField{:},{sCommand},{'-o'},cArgument,...
                 {'| p4'},{sCommand},{'-i'},cForce],' '); 
             
% p4 call
[sMsg,nStatus] = p4(sCall);
if nStatus
    % failure of p4 command
    fprintf(1,'p4form failure - retrying with file based approach...\n\n');
    [sMsg,nStatus] = p4formFileBased(sCommand,cArgument,cPV);
end
return

% =========================================================================

function [sMsg,nStatus] = p4formFileBased(sCommand,cArgument,cPV)
% P4FORMFILEBASED change Perforce Helix forms with direct file input to
% overcome CLI command length limiation via cmd.exe/system calls. Form file
% is exported to temporary directory (potential Linux issue), read, content
% changed, written to new form file, new form file is passed to p4 CLI.
%
% Syntax:
%   [sMsg,nStatus] = p4formFileBased(sCommand,cArgument,cPV)
%
% Inputs:
%    sCommand - string with p4 command used
%   cArgument - cell (1xn) with command arguments
%         cPV - cell (mx2) with 
%               {:,1} - string with form field name
%               {:,2} - cell (1xm) of strings with field value(s)
%
% Outputs:
%
% Example: 
%   [sMsg,nStatus] = p4formFileBased(sCommand,cArgument,cPV)

%% file based recovery
% export and read form file
% Caution: tempdir might have issues in Linux
fprintf(1,'Try file based form change...\n');
vDate = datevec(now);
sSecond = sprintf('%i',round(vDate(end)*1e4)); % file identifier
cCommand = strsplit(sCommand,' ');
nPID = feature('getpid');
sName = sprintf('p4_%i_%s_%s',nPID,cCommand{end},sSecond); % filename for high frequency use
sFile = fullfile(tempdir,[sName '.form']);
sCall = strGlue([{sCommand},{'-o'},cArgument,{' > '},{sFile}],' ');
[sMsg,nStatus] = p4(sCall);
if nStatus
    % failure of p4 command
    fprintf(2,'Form file export failed with message:\n%s\n\nStopped in p4form.\n',sMsg);
    return
end    
nFid = fopen(sFile,'r');
ccLine = textscan(nFid,'%s','Delimiter',char(10)); %#ok<CHARTEN>
fclose(nFid);

% adapt form file
[cParse,cComment] = hlxFormLineParse(ccLine{1});

% replace field content
[bField,nField] = ismember(cPV(:,1),cParse(:,1));
nFieldPV = find(bField);
nFieldParse = nField(bField);
for nIdxField = 1:numel(nFieldPV)
    cParse(nFieldParse(nIdxField),2) = cPV(nFieldPV(nIdxField),2);
end

% write new form file
sFileNew = fullfile(tempdir,[sName '.formnew']);
nFid = fopen(sFileNew,'w');
% write comment
for nIdxComment = 1:numel(cComment)
    fprintf(nFid,'%s\n',cComment{nIdxComment});
end
fprintf(nFid,'\n');
% write form fields
for nIdxField = 1:size(cParse,1)
    if numel(cParse{nIdxField,2}) > 1 % multivalue fields
        fprintf(nFid,'%s:\n',cParse{nIdxField,1});
        for nIdxValue = 1:numel(cParse{nIdxField,2})
            fprintf(nFid,'\t%s\n',cParse{nIdxField,2}{nIdxValue});
        end
    elseif isempty(cParse{nIdxField,2}) % empty fields
        fprintf(nFid,'%s:\n',cParse{nIdxField,1});
    else % single value field
        fprintf(nFid,'%s:\t%s\n',cParse{nIdxField,1},cParse{nIdxField,2}{1});
    end
    fprintf(nFid,'\n');
end
fclose(nFid);

% pass form file to p4
sCall = strGlue([{sCommand},{'-i'},{' < '},{sFileNew}],' ');
[sMsg,nStatus] = p4(sCall);
if nStatus
    % failure of p4 command
    fprintf(2,'File based form change failed. No changes in Perforce Helix for call:\n%s\n',sMsg);
else
    fprintf(1,'File based form change successful.\n\n');
end    

% cleanup formfiles
pause(0.01)
delete(sFile);
delete(sFileNew)
return
