function xStruct = dcsFcnStructVersionId(xStruct,bPathP4)
% DCSFCNSTRUCTVERSIONID searches a struct for "versionId" fields. If a file
% path is the value, the matching P4 changelist number is retrieved from P4
% as new version ID.
% Requires files to be part of a Perforce Helix Workspace/Client and the
% user of this workspace is logged in.
%
% Syntax:
%   xStruct = dcsFcnStructVersionId(xStruct)
%
% Inputs:
%   xStruct - structure with fields of a DIVeMB confgiration including
%             versionId fields on various levels
%   bPathP4 - boolean if basepath is Helix workspace
%
% Outputs:
%   xStruct - structure with fields of a DIVeMB confgiration and updated
%             values of "versionId" fields
%
% Example: 
%   xStruct = dcsFcnStructVersionId(xStruct)
%
% See also: dcsFcnStructVersionId, setfieldRecursive, structFind, umsMsg,
% p4changeFolderHave
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2019-09-14

% determine version ID locations and element pathes
cVersion = structFind(xStruct,'fieldvar','versionId');
if isempty(cVersion)
    return
end    

% rate version ID values
nVersion = str2double(cVersion(:,2));

% loop over all character array entries
bPath = false(size(nVersion));
nIdChar = find(isnan(nVersion));
for nIdxIssue = 1:numel(nIdChar)
    % shortcut
    sValue = cVersion{nIdChar(nIdxIssue),2};
    
    % check for path (or file)
    if ~isempty(sValue) && ...
            ~strcmp(sValue,'NaN') && ...
            (exist(sValue,'dir') || exist(sValue,'file'))
        % is folder (of DIVe element hopefully)
        bPath(nIdChar(nIdxIssue)) = true;
    else % rogue entry -> delete
        fprintf(1,['Version ID determination - missing folder for item: %s\n' ...
                   '                                              path: %s\n'], ...
                   cVersion{nIdChar(nIdxIssue),1},cVersion{nIdChar(nIdxIssue),2});
        cVersion{nIdChar(nIdxIssue),2} = '';
    end
end

% get Perforce Helix Version IDs / changelist numbers of pathes
if any(bPath)
    if bPathP4 
        cChange = p4changeFolderHave(cVersion(bPath,2));
    else
        cChange = repmat({''},size(cVersion(bPath,2)));
    end
    % check feedback
    if numel(cChange)~=sum(bPath)
        umsMsg('Configurator',3,['Warning: Perforce Helix bundled changelist/version ' ...
            'request showed inconsistency - please do not save this configuration!\n']);
    end
    
    % assign version IDs in structure
    nIdVersion = find(bPath);
    for nIdxChange = 1:numel(cChange)
        xStruct = setfieldRecursive(xStruct,cVersion{nIdVersion(nIdxChange),1},cChange{nIdxChange});
    end
end

% fix NaN string entries in versionId -> empty, as they cannot be traced anymore
nNaN = find(cellfun(@(x)strcmp('NaN',x),cVersion(:,2)));
for nIdxNan = nNaN'
    xStruct = setfieldRecursive(xStruct,cVersion{nIdxNan,1},'');
end
return

