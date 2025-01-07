function sNew = dpsModelSetAuto(cSets,sOld,sPreference,xVersion)
% DPSMODELSETAUTO determine the most matching ModelSet according preference
% or currently used Matlab instance.
%
% Syntax:
%   sNew = dpsModelSetAuto(cSets,sOld,sPreference)
%   sNew = dpsModelSetAuto(cSets,sOld,sPreference,xVersion)
%
% Inputs:
%         cSets - cell (1xn) with strings of avaliable ModelSets 
%          sOld - string with original ModelSet
%   sPreference - string with preference ModelSet
%   xVersion    - structure [optional] of Toolbox 'MATLAB' with fields
%     .Name     - string with Toolbox Name
%     .Version  - string with release version (e.g. '9.9')
%     .Release  - string with release name (e.g. '(R2020b)')
%
% Outputs:
%   sNew - string with new suggested ModelSet
%
% Example: 
%   sNew = dpsModelSetAuto({'sfcn_w32_R2010bSP1','sfcn_w32_R2014a','sfcn_w64_R2014a'},'sfcn_w32_R2010bSP1')
%   sNew = dpsModelSetAuto({'open','sfcn_w32_R2010bSP1','sfcn_w32_R2014a','sfcn_w64_R2014a','sfcn_w64_R2016a'},'sfcn_w32_R2010bSP1','open')
%
% Author: Rainer Frey, TP/EAC, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2020-02-03

% check input
if nargin < 4
    xVersion = ver('MATLAB');
end

% preference handling
if nargin > 2 && ~isempty(sPreference)
    % determine preferences (for switching s-functions against open modelset)
    nPref = find(~cellfun(@isempty,regexp(cSets,sPreference,'once')));
    if ~isempty(nPref)
        sNew = cSets{nPref(1)};
        return
    end
else % no preferences specified
    % prevent switching of non-sfunction modelSets when not needed
    if numel(sOld)>3 && ~strcmp(sOld(1:4),'sfcn')
        sNew = sOld;
        return
    end
end

% get version of current Matlab
sMatlabBitType = regexprep(computer('arch'),'^win','w'); % returns 'w32' or 'w64'
sMatlabRelease = xVersion.Release(2:end-1);
sSetSfcnCurrent = regexp(sMatlabRelease,'(?<=^R)\d\d\d\d\w','match','once');
nSetCurrent = feval(@(x)str2double(x(1:end-1))+double(x(end))*1e-3,sSetSfcnCurrent);

% filter ModelSets for sfcn bit type
bKeep = ~cellfun(@isempty,regexp(cSets,sprintf('^sfcn_%s',sMatlabBitType),'once'));
cSetBit = cSets(bKeep);

% remove newer s-functions than current and determine next matching one
cSetSfcn = regexp(cSetBit,'(?<=sfcn_w\d\d_R)\d\d\d\d\w','match','once');
nSetVersion = cellfun(@(x)str2double(x(1:end-1))+double(x(end))*1e-3,cSetSfcn);
bValid = nSetVersion <= nSetCurrent;
nSetValid = max(nSetVersion(bValid));
sVersion = num2str(floor(nSetValid));
sSubversion = char(round(mod(nSetValid,1)*1000));
bSetNew = strcmp([sVersion sSubversion],cSetSfcn);
if any(bSetNew)
    % assign next feasible sfcn ModelSet
    sNew = cSetBit{bSetNew};
else
    % use open ModelSet as backup
    bOpen = strcmp('open',cSets);
    if any(bOpen)
        sNew = cSets{bOpen};
    else
        sNew = sOld;
    end
end
return
