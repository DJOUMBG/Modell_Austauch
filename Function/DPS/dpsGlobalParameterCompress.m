function [cSetup,cGlobal,xGlobalParDef] = dpsGlobalParameterCompress(sPathContent,xModuleSetup)
% DPSGLOBALPARAMETERCOMPRESS compress the information of all global
% parameters, which are defined in the specified ModuleSetups for
% initOrder determination and checking. 
%
% Syntax:
%   [cSetup,cGlobal,xGlobalParDef] = dpsGlobalParameterCompress(sPathContent,xModuleSetup)
%
% Inputs:
%   sPathContent - string with path of Content folder with DIVe logical
%                  hierarchy folder tree
%   xModuleSetup - structure (1x1) with fields of one ModuleSetup
%                  (structure from DIVe Configuration XML)
%
% Outputs:
%    cSetup - cell (mx4) for each ModuleSetup with content
%               (:,1): string with ModuleSetup name
%               (:,2): string with species name
%               (:,3): cell with string with source ModuleSetup names for global
%                      parameters of module (can be for debug output comma separated)
%               (:,4): cell with string with destination moduleSetup names for global
%                      parameters of module (can be for debug output comma separated)
%    cGlobal - cell (nx5) for each GlobalParameter
%               (:,1): string with global parameter name
%               (:,2): string with source species
%               (:,3): string with source ModuleSetup name
%               (:,4): cell with string with source ModuleSetup names for global
%                      parameters of module (can be for debug output comma separated)
%               (:,5): cell with string with destination moduleSetup names for global
%                      parameters of module (can be for debug output comma separated)
%    xGlobalParDef - struct with source and destination information
%               .src - cell (nx3) source information of each global parameter dependency
%                       (:,1): string with global parameter name
%                       (:,2): string with source parameter
%                       (:,3): string with source moduleSetup name
%               .dest - cell (nx3) destination information of each global parameter dependency
%                       (:,1): string with global parameter name
%                       (:,2): string with destination parameter
%                       (:,3): string with destination moduleSetup name
%
% Example:
%   [cSetup,cGlobal,xGlobalParDef] = dpsGlobalParameterCompress(sPathContent,xModuleSetup)
%
% See also: dpsGlobalParameterXmlRead
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2017-05-04

% init output
cGlobal = cell(0,5);
cSetup = cell(numel(xModuleSetup),4);
GlobalParamDep = {};
LocalParamDep = {};

%% collect global parameter informaton from all modules
for nIdxSetup = 1:numel(xModuleSetup)
    [xGlobal,xDependent] = dpsGlobalParameterXmlRead(sPathContent,xModuleSetup(nIdxSetup));
    
    %% compress global parameters structure to one overall cell for all global paramaters
    % global parameter
    if ~isempty(xGlobal)
        % create base cell
        cGlobalAdd = [{xGlobal.name}',...
            repmat({xModuleSetup(nIdxSetup).Module.species},[numel(xGlobal),1]),...
            repmat({xModuleSetup(nIdxSetup).name},[numel(xGlobal),1]),...
            repmat({{}},[numel(xGlobal),1]),...
            repmat({{}},[numel(xGlobal),1])];
        cGlobal = dpsGpcMerge(cGlobal,cGlobalAdd);
        tmpGlobal = {};
        tmpGlobal(:,1) = {xGlobal.name}';
        tmpGlobal(:,2) = {xGlobal.parameter}';
        tmpGlobal(:,3) = {xModuleSetup(nIdxSetup).name};
        GlobalParamDep = [GlobalParamDep; tmpGlobal];
    end
    
    % local parameter
    if ~isempty(xDependent)
        % create base cell
        cGlobalAdd = [{xDependent.globalName}',...
            repmat({{}},[numel(xDependent),1]),...
            repmat({{}},[numel(xDependent),1]),...
            repmat({{xModuleSetup(nIdxSetup).Module.species}},[numel(xDependent),1]),...
            repmat({{xModuleSetup(nIdxSetup).name}},[numel(xDependent),1])];
        cGlobal = dpsGpcMerge(cGlobal,cGlobalAdd);
        tmpLocal = {};
        tmpLocal(:,1) = {xDependent.globalName}';
        tmpLocal(:,2) = {xDependent.name}';
        tmpLocal(:,3) = {xModuleSetup(nIdxSetup).name};
        LocalParamDep = [LocalParamDep; tmpLocal];
    end
end

% check for missing source parameters
nIdxNoSource = find(cellfun(@isempty,cGlobal(:,2)) & cellfun(@isempty,cGlobal(:,3)));
% reduce cGlobal where no source parameter available:
cGlobal(nIdxNoSource,:) = [];

xGlobalParDef.src = GlobalParamDep;
xGlobalParDef.dest = LocalParamDep;

%% create setup cell with source/destination
for nIdxSetup = 1:numel(xModuleSetup)
    % store own names
    cSetup{nIdxSetup,1} = xModuleSetup(nIdxSetup).name;
    cSetup{nIdxSetup,2} = xModuleSetup(nIdxSetup).Module.species;
    
    % determine sources for local dependent parameters of this ModuleSetup
    bSourceOfThis = cellfun(@(x)any(strcmp(cSetup{nIdxSetup,1},x)),cGlobal(:,5));
    cSetup{nIdxSetup,3} = unique(cGlobal(bSourceOfThis,3)');
    
    % determine targets for global parameters created by this ModuleSetup
    bTargetOfThis = strcmp(cSetup{nIdxSetup,1},cGlobal(:,3));
    if ~any(bTargetOfThis)
        cSetup{nIdxSetup,4} = {};
    else
        cSetup{nIdxSetup,4} = unique([cGlobal{bTargetOfThis,5}]);
    end
end
return

% =========================================================================

function cGlobal = dpsGpcMerge(cGlobal,cGlobalAdd)
% DPSGPCMERGE merge the source/destination information of added cell into
% the according cell columns of already existing global parameter entries.
%
% Syntax:
%   cGlobal = dpsGpcMerge(cGlobal,cGlobalAdd)
%
% Inputs:
%    cGlobal - cell (mx5) for each GlobalParameter
%               (:,1): string with global parameter name
%               (:,2): string with source species
%               (:,3): string with source ModuleSetup name
%               (:,4): string with destination species (comma separated)
%               (:,5): string with destination ModuleSetup names (comma separated)
%    cGlobalAdd - cell (nx5) for each GlobalParameter to be added
%               (:,1): string with global parameter name
%               (:,2): string with source species
%               (:,3): string with source ModuleSetup name
%               (:,4): string with destination species (comma separated)
%               (:,5): string with destination ModuleSetup names (comma separated)
%
% Outputs:
%    cGlobal - cell (ox5) for each GlobalParameter
%               (:,1): string with global parameter name
%               (:,2): string with source species
%               (:,3): string with source ModuleSetup name
%               (:,4): string with destination species (comma separated)
%               (:,5): string with destination ModuleSetup names (comma separated)
%
% Example:
%   cGlobal = dpsGpcMerge(cGlobal,cGlobalAdd)

% determine available global parameters
[bExist,nGlobal] = ismember(cGlobalAdd(:,1)',cGlobal(:,1)');

% add new global parameters
cGlobal = [cGlobal; cGlobalAdd(~bExist,:)];

% add source/destination species/ModuleSetup for existing global parameters
for nIdxPar = find(bExist)
    % merge source
    if ~isempty(cGlobalAdd{nIdxPar,2})
        cGlobal(nGlobal(nIdxPar),2) = cGlobalAdd(nIdxPar,2);
        cGlobal(nGlobal(nIdxPar),3) = cGlobalAdd(nIdxPar,3);
    end
    
    % merge destination
    if ~isempty(cGlobalAdd{nIdxPar,4})
        % combine values
        cGlobal{nGlobal(nIdxPar),4} = unique([cGlobal{nGlobal(nIdxPar),4} cGlobalAdd{nIdxPar,4}]);
        cGlobal{nGlobal(nIdxPar),5} = unique([cGlobal{nGlobal(nIdxPar),5} cGlobalAdd{nIdxPar,5}]);
    end
end
return
