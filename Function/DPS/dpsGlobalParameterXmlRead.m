function [xGlobal,xDependent] = dpsGlobalParameterXmlRead(sPathContent,xModuleSetup)
% DPSGLOBALPARAMETERXMLREAD read the dependency.xml files of all
% dependentParameter dataset classes of a single specified ModuleSetup.
%
% Syntax:
%   [xGlobal,xDependent] = dpsGlobalParameterXmlRead(sPathContent,xModuleSetup)
%
% Inputs:
%   sPathContent - string with path of content structure
%   xModuleSetup - structure (1x1) with fields of one ModuleSetup
%                  (structure from DIVe Configuration XML)
%
% Outputs:
%      xGlobal - structure with fields of global parameters
%   xDependent - structure with fields of local dependent parameters
%
% Example: 
%   [xGlobal,xDependent] = dpsGlobalParameterXmlRead(sPathContent,xModuleSetup)
%
% See also: dpsDataSetVariantCollect, dsxRead, structConcat, structInit
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2017-05-04

% init output
xGlobal = structInit({'parameter','subspecies','name','description',...
    'dimension','minimum','maximum','unit'});
xDependent = structInit({'name','description','dimension','minimum',...
    'maximum','unit','subspecies','globalName'});

% get dependent parameter data classes
[cPathDataVariant,cDataClassName] = dpsDataSetVariantCollect(xModuleSetup,sPathContent);
nDependent = find(strcmp('dependentParameter',cDataClassName));
cDependentParameterFile = {};
if isempty(nDependent)
    return
else
    for nIdxSet = nDependent
        sFile = fullfile(cPathDataVariant{nIdxSet},'dependency.xml');
        cDependentParameterFile = [cDependentParameterFile {sFile}]; %#ok<AGROW>
    end
end

% get global/dependent parameter entries from ddependency.xml files
for nIdxFile = 1:numel(cDependentParameterFile)
    % read depdency XML
    xTree = dsxRead(cDependentParameterFile{nIdxFile});
    % add global parameters to struct
    if isfield(xTree,'Dependency') && ...
            isfield(xTree.Dependency,'GlobalParameter') && ...
            ~isempty(xTree.Dependency.GlobalParameter)
        xGlobal = structConcat(xGlobal,xTree.Dependency.GlobalParameter);
    end
    % add local dependent parameters
    if isfield(xTree,'Dependency') && ...
            isfield(xTree.Dependency,'LocalParameter') && ...
            ~isempty(xTree.Dependency.LocalParameter)
        xDependent = structConcat(xDependent,xTree.Dependency.LocalParameter);
    end
end
return
