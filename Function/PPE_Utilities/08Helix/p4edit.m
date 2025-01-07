function [sMsg] = p4edit(sFile,nChange)
% P4EDIT open a file in perforce for edit 
%
% Syntax:
%   sMsg = p4edit(sFile)
%   sMsg = p4edit(sFile,nChange)
%
% Inputs:
%     sFile - string with file name or full file path
%   nChange - [optional] integer (1x1) with changelist number
%               or string with description of a new changelist
%
% Outputs:
%   sMsg - string with messages of p4 operation
%
% Example: 
%   p4edit p4edit
%   sMsg = p4edit('p4edit')
%   sMsg = p4edit('p4edit',3001)
%   sMsg = p4edit('p4edit','improve p4edit for robustness')
%
% See also: p4edit
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2018-03-23

% check input
sFileExtend = which(sFile);
if ~isempty(sFileExtend)
    sFile = sFileExtend;
end
if ~exist(sFile,'file')
    fprintf('(p4edit) The specified file "%s" is unknown.\n',sFile);
    return
end
sDescription = '';
if nargin > 1
    % check/ensure number 
    if ischar(nChange) 
        if isnan(str2double(nChange))
            % assume description for a new changelist instead of number
            sDescription = nChange;
        else
            % number was passed as string - just convert to number
            nChange = str2double(nChange);
        end
    end
    
    if isempty(sDescription)
        % check plausibility of changelist number
        cChange = hlxOutParse(p4('changes -s pending --me'),{' '},2,true);
        nChangePending = cellfun(@str2double,cChange(:,2));
        if ~ismember(nChange,nChangePending)
            error('p4edit:unknownChangelist',['The specified changelist "%i" ' ...
                'is not known or of the current user.'],nChange);
        end
    end
end

% ensure correct workspace
[nStatus,sWorkspace,sPrevious] = p4switch(sFile,0); %#ok<ASGLU>
if nStatus
    % combine input arguments
    if nargin < 2
        sMsg = p4('edit',sFile);
    else
        if ~isempty(sDescription)
            % create changelist
            nChange = p4change(sDescription,{},'public');
        end
        % open file for edit in changelist
        sMsg = p4(sprintf('edit -c %i "%s"',nChange,sFile));
    end
    
    % switch back to original workspace
    p4switch(sPrevious,0);
else
    fprintf(2,'Could not switch to correct workspace. Open for edit in Perforce failed...');
end

% open file in MATLAB editor or bring to front
[sPath,sName,sExt] = fileparts(sFile); %#ok<ASGLU>
if any(strcmpi(sExt,{'.m','.xml','.txt','.asc','.trn'}))
    edit(sFile);
else
    % omit opening in editor
end
return

