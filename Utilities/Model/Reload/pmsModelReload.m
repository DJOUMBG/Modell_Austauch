function sMP = pmsModelReload(sFilePath,sMP)
% PMSMODELRELOAD prepare sMP variable, platform and MATLAB for a model
% reload.
%
% Syntax:
%   sMP = pmsModelReload(sFilePath,sMP)
%
% Inputs:
%   sFilePath - string with filepath of loaded model
%         sMP - structure with standard DIVe ModelBased fields:
%           .platform  - structure with platform information
%           ...
%
% Outputs:
%   sMP - structure with standard DIVe ModelBased fields:
%    .platform  - structure with platform information
%    .cfg       - structure with configuration information
%    .link      - structure with configuration information
%    .bdry      - structure with parameters of context boundary
%    .ctrl      - structure with parameters of context control
%    .human     - structure with parameters of context human
%    .phys      - structure with parameters of context physics
%
% Example: 
%   sMP = pmsModelReload(sFilePath,sMP)

% determine last original workspace
sPath = fileparts(sFilePath);
cFile = dirPattern(sPath,'WS*.mat','file');

if ~isempty(cFile)
    % load last workspace
    xLoad = load(fullfile(sPath,cFile{end}));
    
    % transfer sMP configuration related content
    if isfield(xLoad,'sMP')
        cField = fieldnames(xLoad.sMP);
        cField = cField(~strcmp('platform',cField)); % remove platform field
        for nIdxField = 1:numel(cField)
            sMP.(cField{nIdxField}) = xLoad.sMP.(cField{nIdxField});
        end
    end
    
    % transfer non sMP variables to workspace - except sCR simulation results 
    cVar = fieldnames(xLoad);
    cVar = cVar(~strcmp('sMP',cVar));
    cVar = cVar(cellfun(@isempty,regexp(cVar,'^sCR','once')));
    for nIdxVar = 1:numel(cVar)
        assignin('base',cVar{nIdxVar},xLoad.(cVar{nIdxVar}));
    end
    
    % transfer original paths according new platform
    cPath = xLoad.sMP.platform.mpath.runtime;
    nPlatformOld = numel(xLoad.sMP.platform.path);
    bKeep = false(1,numel(cPath));
    for nIdxPath = 1:numel(cPath)
        cPath{nIdxPath} = [sMP.platform.path cPath{nIdxPath}(nPlatformOld+1:end)];
        
        % check path existence in current installation
        if exist(cPath{nIdxPath},'dir')
            bKeep(nIdxPath) = true;
        else
            fprintf(2,'Error:ModelReload - path not available: %s\n',cPath{nIdxPath});
        end
    end
    cPath = cPath(bKeep);
    
    % add original paths
    addpath(cPath{:});
    sMP.platform.mpath.runtime = cPath;
else
    fprintf(2,'ERROR - reload of original parameters and MATLAB paths failed!\n');
end
return
