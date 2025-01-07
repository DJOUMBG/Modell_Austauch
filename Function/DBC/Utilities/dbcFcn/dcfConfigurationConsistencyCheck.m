function [cFileConfigFail] = dcfConfigurationConsistencyCheck(sPathConfig,sPathContent)
% DCFCONFIGURATIONCONSISTENCYCHECK checks all DIVe configuration beneath a
% specified path, if the specified Modules and Datasets are available in
% the specified DIVe content path.
%
% Syntax:
%   cFileConfigFail = dcfConfigurationConsistencyCheck(sPathConfig,sPathContent)
%
% Inputs:
%    sPathConfig - string with path containing configuration files to check
%   sPathContent - string with path of DIVe content (Modules, datasets etc)
%
% Outputs:
%   cFileConfigFail - cell (1xn) with string of configuration files, which
%                     configuration content is not available in the
%                     specified DIVe content path 
%
% Example: 
%   cFileConfigFail = dcfConfigurationConsistencyCheck(sPathConfig,sPathContent)
%
% See also: dirPattern, dpsDataSetVariantCollect, dsxRead, strsplitOwn
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2016-07-14

% determine all configs in specified path
if exist(sPathConfig,'dir') == 7
    % get all folders below specified path
    cPathAll = strsplitOwn(genpath(sPathConfig),';');
    cFileConfig = {};
    for nIdxPath = 1:numel(cPathAll)
        % get XML files from all folders
        cFileConfig = [cFileConfig ...
            cellfun(@(x)fullfile(cPathAll{nIdxPath},x),...
                    dirPattern(cPathAll{nIdxPath},'*.xml','file'),...
                    'UniformOutput',false)]; %#ok<AGROW>
    end
elseif exist(sPathConfig,'file') == 2 && strcmp(sPathConfig(end-3:end),'.xml')
    cFileConfig = {sPathConfig};
else
    error('dcfConfigurationConsistencyCheck:noPathInputArgument',...
        'The specified input argument is no valid path')
end

% loop over configs
bConfigFail = false(size(cFileConfig));
for nIdxFile = 1:numel(cFileConfig)
    % load config
    xTree = dsxRead(cFileConfig{nIdxFile});
    xModuleSetup = xTree.Configuration.ModuleSetup;
    
    % loop over all ModuleSetups
    for nIdxSetup = 1:numel(xModuleSetup)
        % code shortcut
        xMod = xModuleSetup(nIdxSetup).Module;
        
        % check availability of Module and ModelSet
        sPathPart = fullfile(xMod.context,xMod.species,xMod.family,xMod.type,'Module',xMod.variant,xMod.modelSet);
        if exist(fullfile(sPathContent,sPathPart),'dir') ~= 7
            bConfigFail(nIdxFile) = true;
        end
        
        % check availability of Dataset variants
        cPathDataVariant = dpsDataSetVariantCollect(xModuleSetup(nIdxSetup),sPathContent);
        for nIdxData = 1:numel(cPathDataVariant)
            if exist(cPathDataVariant{nIdxData},'dir') ~= 7
                bConfigFail(nIdxFile) = true;
            end
        end
    end
end

% assign output
cFileConfigFail = cFileConfig(bConfigFail);
return
