function p4reconcileSubmitPath(cPath)
% P4RECONCILESUBMITPATH reconcile and submit all changes, adds and deletes
% of the specified pathes and all their subdirectories.
%
% Syntax:
%   p4reconcileSubmitPath(cPath)
%
% Inputs:
%   cPath - cell (1xn) with strings of pathes within Perforce workspace
%           checkouts, which shall be directly reconciled and submitted.
%
% Outputs:
%
% Example: 
%   p4reconcileSubmitPath({'c:\myPath1','c:\myPath2'})
%
% See also: p4, p4change, p4switch
%
% Author: Rainer Frey, TP/EAC, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2019-08-28

% check input
if ischar(cPath) % ensure cell
    cPath = {cPath};
end

% loop over pathes
for nIdxPath = 1:numel(cPath)
    % check path existence
    if ~exist(cPath{nIdxPath},'dir')
        fprintf(2,'p4reconcileSubmitPath - this path does not exist on this computer: %s',cPath{nIdxPath});
        continue
    end
    
    % switch to correct workspace
    nStatus = p4switch(cPath{nIdxPath});
    if ~nStatus
        fprintf(2,'p4reconcileSubmitPath - could not determine the Workspace of this path: %s',cPath{nIdxPath});
        continue
    end
    
    % create changelist
    nChange = p4change(sprintf('Reconcile on path "%s"',cPath{nIdxPath}));
    if isempty(nChange)
        error('p4reconcileSubmitPath:noChangelistGenerated',...
             ['Changelist could not be generated - please check for correct ' ...
              'login, server and workspace with "p4 info"']);
        
    end
    
    % prepare path for Perforce
    [sPath,sFile,sExt] = fileparts(cPath{nIdxPath});
    if isempty(sExt) && ~isempty(sPath)
        sSeparator = cPath{nIdxPath}(numel(sPath)+1);
        cPath{nIdxPath} = strGlue({sPath,sFile,'...'},sSeparator);
    end
    
    % reconcile on path
    p4(sprintf('reconcile -c %i -a -e -d -f %s',nChange,cPath{nIdxPath}));
    
    % submit changelist
    p4(sprintf('submit -c %i',nChange));
    fprintf(1,'Submitted path "%s".',cPath{nIdxPath});
end
return
