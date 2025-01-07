function [xCfg,nVersionPass] = dcsConfigLoad(sPathFile,sPathContent,sMsgTag,bDescriptionLoad,bVersionCheck)
% DCSCONFIGLOAD load configuration and related meta-data.
% Loads the DIVe configuration XML and the specified module XML meta-data
% into a configuration structure.
% Part of DIVe Configuration Standard for reuse in platform/configurator.
%
% Syntax:
%   xCfg = dcsConfigLoad(sPathFile,sPathContent)
%   xCfg = dcsConfigLoad(sPathFile,sPathContent,sMsgTag)
%   xCfg = dcsConfigLoad(sPathFile,sPathContent,sMsgTag,bDescriptionLoad)
%   xCfg = dcsConfigLoad(sPathFile,sPathContent,sMsgTag,bDescriptionLoad,bVersionCheck)
%
% Inputs:
%       sPathFile - string with path of configuration file
%    sPathContent - string with content path of modules and data (DIVe
%                   logical hierarchy of data and modules)
%         sMsgTag - string with pleading part of messages
%    bDescriptionLoad - boolean (1x1) if descriptions are needed
%       bVersionCheck - boolean (1x1) if version of Configuration vs
%                       Perforce Helix checkout in current Content folder
%                       is needed
%
% Outputs:
%   xCfg - structure with fields: 
%     .Configuration - structure with complete DIVe configuration content
%     .xml           - structure with fields
%       .Module      - structure vector of module XML meta-data according
%                      the order of appearance in
%                      .Configuration.ModuleSetup
%   nVersionPass - integer (1x1) with state of version check against
%                  Perforce
%                  0: no check executed (offline mode, no p4 install, ...)
%                  1: check executed and all DIVe elements in workspace
%                     match the versionIds, which are specified in the
%                     Configuration
%                  2: check executed and at least one DIVe element does not
%                     match the versionId specified in the Configuration
%
% Example: 
%   xCfg = dcsConfigLoad(sPathFile,sPathContent)
%   [xCfg,nVersionPass] = dcsConfigLoad('C:\bla\Configuration\Vehicle\Other\test.xml','C:\bla\Content','some: ',0,1)
%
% See also: dsxRead, structConcat, structInit, dcsFcnSupportSetGet
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2015-11-02

% check input
if nargin < 2
    sPathContent = [regexp(sPathFile,['.+(?=Configuration)'],'match','once') 'Content'];
end
if nargin < 3
    sMsgTag = '';
end
if nargin < 4
    bDescriptionLoad = true;
end
if nargin < 5
    bVersionCheck = false;
end

%% Perforce Helix connectivity
if bVersionCheck
    % check for online/offline state of DIVe Basic Configurator
    hDbc = findobj('Tag','DIVeBasicConfigurator');
    if isempty(hDbc)
        bDbc = false;
        bConnection = false;
    else
        bDbc = true;
        data = guidata(hDbc);
        bConnection = data.const.setup.bConnection; % capture online/offline state
    end
    
    % check p4 availability on this system
    % try a system call on p4
    [nStatusP4Set,sMsg] = system('p4 set');
    % cover exceptions (assume possible: empty = no settings, no p4 installation)
    [bStatus,sIdent,sCure] = p4Exception(sMsg,0); %#ok<ASGLU>
    
    % report exception (no p4 installation)
    if nStatusP4Set || bStatus || (~bConnection && bDbc) || ~bVersionCheck
        % missing p4 installation
        bPathP4 = false;
    else
        % detect P4 state of base path
        bPathP4 = p4switch(sPathContent,0);
        
        if bPathP4 && (bConnection || bVersionCheck)
            bPathP4 = true;
        else % if DBC is in offline mode
            bPathP4 = false;
        end
    end
else
    bPathP4 = false;
end

%% read configuration
xCfg.filepath = sPathFile;
xCfg.build = structInit({'username','computername','path','start','end'});
xCfg.run = structInit({'username','computername','path','init','start','end'});
xRead = dsxRead(xCfg.filepath,0,0); % load XML
xCfg.Configuration = dcsConfigFieldSort(xRead.Configuration);
xCfg.nameshort = xCfg.Configuration.name;

% resort configuration module setups according initialization order
nInit = str2double({xCfg.Configuration.ModuleSetup.initOrder}); 
[nTrash,nInitOrder] = sort(nInit); %#ok<ASGLU>
xCfg.Configuration.ModuleSetup = xCfg.Configuration.ModuleSetup(nInitOrder);

%% get module XMLs
% initialize structure
xXml.Module = struct('xmlns',{},'name',{},'type',{},'family',{},...
    'species',{},'context',{},'specificationVersion',{},'moduleVersion',{},...
    'maxCosimStepsize',{},'solverType',{},'description',{},...
    'Implementation',{},'Interface',{});

% read module XMLs, fix and update configuration entries
xVersion = ver('MATLAB');
for nIdxModule = 1:numel(xCfg.Configuration.ModuleSetup)
    % code shortcuts
    xModule = xCfg.Configuration.ModuleSetup(nIdxModule).Module;
    
    % read Module xml
    sPathXml = fullfile(sPathContent,xModule.context,...
                        xModule.species,xModule.family,xModule.type,'Module',...
                        xModule.variant,[xModule.variant '.xml']);
    xXmlModule = dsxRead(sPathXml,0,0);
    if bPathP4
        % add version ID field for determination with Perforce
        xXmlModule.Module.versionId = sPathXml;
    end
            
    % ensure solverType field
    if ~isfield(xModule,'solverType') || isempty(xModule.solverType)
        xModule.solverType = 'FixedStep01';
    end

    % add Module xml to structure
    xXml.Module = structConcat(xXml.Module,xXmlModule.Module);
    
    % transfer description to configuration structure
    if bDescriptionLoad
        xCfg.Configuration.ModuleSetup(nIdxModule).Module.description = xXmlModule.Module.description;
    end

    % ensure minimum solverType and maxCosimStepsize values
    if (~isfield(xCfg.Configuration.ModuleSetup(nIdxModule).Module,'maxCosimStepsize') || ...
             isempty(xCfg.Configuration.ModuleSetup(nIdxModule).Module.maxCosimStepsize))
        if isfield(xXmlModule.Module,'maxCosimStepsize') 
             xCfg.Configuration.ModuleSetup(nIdxModule).Module.maxCosimStepsize = xXmlModule.Module.maxCosimStepsize;
        else
            xCfg.Configuration.ModuleSetup(nIdxModule).Module.maxCosimStepsize = 0.01;
        end
    end
    if (~isfield(xCfg.Configuration.ModuleSetup(nIdxModule).Module,'solverType') || ...
             isempty(xCfg.Configuration.ModuleSetup(nIdxModule).Module.solverType))
        if isfield(xXmlModule.Module,'solverType') && ~isempty(xXmlModule.Module.solverType)
            xCfg.Configuration.ModuleSetup(nIdxModule).Module.solverType = xXmlModule.Module.solverType;
        else
            xCfg.Configuration.ModuleSetup(nIdxModule).Module.solverType = 'FixedStep01';
        end
    end
    
    % get Configuration Module support sets
    if isfield(xCfg.Configuration.ModuleSetup(nIdxModule),'SupportSet') && ...
            isfield(xCfg.Configuration.ModuleSetup(nIdxModule).SupportSet,'name')
        cSupportCfg = arrayfun(@(x)[x.name '_' x.level],...
            xCfg.Configuration.ModuleSetup(nIdxModule).SupportSet,'UniformOutput',false);
    else
        cSupportCfg = {};
    end
    
    % adapt Configuration to match current Module XML Support Sets
    xSupportMod = dcsFcnSupportSetGet(sPathContent, xXmlModule.Module,bVersionCheck,bPathP4);
    cSupportMod = arrayfun(@(x)[x.name '_' x.level],xSupportMod,'UniformOutput',false);
    
    % report changes, updates and new support sets + add description
    for nIdxSet = 1:numel(xSupportMod)
        % find SupportSet in structute of configuration
        bSetInCfg = strcmp(cSupportMod{nIdxSet},cSupportCfg);
        
        % get description of SupportSet
        if bDescriptionLoad
            xSet = xSupportMod(nIdxSet); % shortcut
            if ~isempty(bSetInCfg) && any(bSetInCfg) % supportset exists in Configuration
                sPathSupportSet = fullfile(dpsPathLevel(fileparts(sPathXml),xSet.level),'Support',xSet.name);
                sPathXmlSup = fullfile(sPathSupportSet,[xSet.name '.xml']);
                xSupport = dsxReadCfgHeader(sPathXmlSup); % read XML header
                if isfield(xSupport,'SupportSet') && isfield(xSupport.SupportSet,'description')
                    xSupportMod(nIdxSet).description = ...
                        xSupport.SupportSet.description;
                else
                    xSupportMod(nIdxSet).description = '';
                end
                xXml.Module(end).Implementation.SupportSet(nIdxSet).versionId = sPathXmlSup;
            end
        end
        
        % check existence of SupportSet in configuration
        if any(bSetInCfg)
            % transfer of versionIDs from Configuration to SupportSet structure 
            if ~bVersionCheck
                xSupportMod(nIdxSet).versionId = xCfg.Configuration.ModuleSetup(nIdxModule).SupportSet(bSetInCfg).versionId;
            end
        else % new support set to add -> report
            fprintf(1,'%sModule "%s" added new SupportSet "%s" during Configuration update\n',...
                sMsgTag,xModule.species,xSupportMod(nIdxSet).name);
            continue
        end
        
        % changed level
        if ~strcmp(xSupportMod(nIdxSet).level,...
                xCfg.Configuration.ModuleSetup(nIdxModule).SupportSet(bSetInCfg).level)
            fprintf(1,['%sModule "%s" update SupportSet "%s" regarding logical' ...
                      'hierarchy level from "%s" to "%s".\n'],...
                sMsgTag,xModule.species,xSupportMod(nIdxSet).name,...
                xCfg.Configuration.ModuleSetup(nIdxModule).SupportSet(bSetInCfg).level,...
                xSupportMod(nIdxSet).level);
        end
        % changed versionId
        if ~strcmp(xSupportMod(nIdxSet).versionId,...
                xCfg.Configuration.ModuleSetup(nIdxModule).SupportSet(bSetInCfg).versionId)
            fprintf(1,['%sModule "%s" update verion ID of SupportSet "%s" ' ...
                      'from "%s" to "%s".\n'],...
                sMsgTag,xModule.species,xSupportMod(nIdxSet).name,...
                xCfg.Configuration.ModuleSetup(nIdxModule).SupportSet(bSetInCfg).versionId,...
                xSupportMod(nIdxSet).versionId);
        end

    end % for all SupportSets
    xCfg.Configuration.ModuleSetup(nIdxModule).SupportSet = xSupportMod;
    
    % loop over all datasets
    xDataSet = xCfg.Configuration.ModuleSetup(nIdxModule).DataSet;
    for nIdxSet = 1:numel(xDataSet)
        % get description of DataSet
        xSet = xDataSet(nIdxSet);
        sPathDataSet = fullfile(dpsPathLevel(fileparts(sPathXml),xSet.level),...
                                'Data',xSet.classType,xSet.variant);
        sPathXmlDat = fullfile(sPathDataSet,[xSet.variant '.xml']);
        xData = dsxReadCfgHeader(sPathXmlDat);
        
        % transfer description to configuration structure
        if bDescriptionLoad
            xCfg.Configuration.ModuleSetup(nIdxModule).DataSet(nIdxSet).description = ...
                xData.DataSet.description;
        end
        
        % store version ID for dataset
        if strcmp(xSet.classType,'initIO') && isfield(xXml.Module(end).Interface,'DataSetInitIO')
            xXml.Module(end).Interface.DataSetInitIO.versionId = sPathXmlDat;
        else
            bDataSet = strcmp(xSet.className,{xXml.Module(end).Interface.DataSet.className});
            if any(bDataSet) && sum(bDataSet)==1
                xXml.Module(end).Interface.DataSet(bDataSet).versionId = sPathXmlDat;
            else
                fprintf(2,['The DataSet className "%s" of the Configuration''s ModuleSetup "%s" is ' ...
                    'not known to the Module XML: %s\n'],xSet.className,...
                    xCfg.Configuration.ModuleSetup(nIdxModule).name,sPathXml);
                error('Encountered missmatch of Module definition in Configuration and Module XML')
            end
        end
    end
end % for all Modules

%% check and report versionIDs
nVersionPass = 0;
if bPathP4
    nVersionPass = 1;
    cLevel = {'species','family','type'};
    % get Module versionIds and compare to configuration
    xXml = dcsFcnStructVersionId(xXml,bPathP4);
    for nIdxModule = 1:numel(xCfg.Configuration.ModuleSetup)
        % check Module
        xMod = xCfg.Configuration.ModuleSetup(nIdxModule).Module; % shortcut
        cLogHier = {xMod.context,xMod.species,xMod.family,xMod.type};
        sWsVersion = pmsStrEmptyPatch(xXml.Module(nIdxModule).versionId);
        sCfgVersion = pmsStrEmptyPatch(xMod.versionId);
        if ~strcmp(sCfgVersion,sWsVersion)
            fprintf(1,'%sModule versionID differs for "%s" (Configuration: %s, Module: %s)\n',...
                sMsgTag,strGlue([cLogHier {'Module',xMod.variant}],'.'),sCfgVersion,sWsVersion);
            nVersionPass = 2;
        end
        
        % check DataSet versionIDs
        for nIdxData = 1:numel(xCfg.Configuration.ModuleSetup(nIdxModule).DataSet)
            xSet = xCfg.Configuration.ModuleSetup(nIdxModule).DataSet(nIdxData); % shortcut
            if strcmp(xSet.classType,'initIO') && isfield(xXml.Module(nIdxModule).Interface,'DataSetInitIO')
                sWsVersion = xXml.Module(nIdxModule).Interface.DataSetInitIO.versionId;
            else
                bDataSet = strcmp(xSet.className,{xXml.Module(nIdxModule).Interface.DataSet.className});
                sWsVersion = xXml.Module(nIdxModule).Interface.DataSet(bDataSet).versionId;
            end
            sWsVersion = pmsStrEmptyPatch(sWsVersion);
            sCfgVersion = pmsStrEmptyPatch(xSet.versionId);
            if ~strcmp(sCfgVersion,sWsVersion)
                nLevel = find(strcmp(xSet.level,cLevel));
                fprintf(1,'%sDataSet versionID differs for "%s" (Configuration: %s, Workspace: %s)\n',...
                    sMsgTag,strGlue([cLogHier(1:1+nLevel) {'Data',xSet.className,xSet.variant}],'.'),...
                    sCfgVersion,sWsVersion);
                nVersionPass = 2;
            end
        end
        
        % check SupportSets versionIDs
        if isfield(xCfg.Configuration.ModuleSetup,'SupportSet')
            for nIdxSupport = 1:numel(xCfg.Configuration.ModuleSetup(nIdxModule).SupportSet)
                xSet = xCfg.Configuration.ModuleSetup(nIdxModule).SupportSet(nIdxSupport); % shortcut
                cSetWs = arrayfun(@(x)[x.name '_' x.level],xXml.Module(nIdxModule).Implementation.SupportSet,'UniformOutput',false);
                bSupportSet = strcmp([xSet.name '_' xSet.level],cSetWs);
                sWsVersion = pmsStrEmptyPatch(xXml.Module(nIdxModule).Implementation.SupportSet(bSupportSet).versionId);
                sCfgVersion = pmsStrEmptyPatch(xSet.versionId);
                if ~strcmp(sCfgVersion,sWsVersion)
                    nLevel = find(strcmp(xSet.level,cLevel));
                    fprintf(1,'%sSupportSet versionID differs for "%s" (Configuration: %s, Workspace: %s)\n',...
                        sMsgTag,strGlue([cLogHier(1:1+nLevel) {'Support',xSet.name}],'.'),...
                        sCfgVersion,sWsVersion);
                    nVersionPass = 2;
                end
            end % for SupportSets
        end % if SupportSet on Module
    end % for ModuleSetups
end % if p4

% assign read Module XMLs to structure
xCfg.xml = xXml;

%% evaluate automatic initialization order determination
if ~isfield(xCfg.Configuration,'useAutoInitOrder')
    % ensure availability of flag
    if any(arrayfun(@(x)isempty(x.initOrder),xCfg.Configuration.ModuleSetup))
        xCfg.Configuration.useAutoInitOrder = '1'; % force autoInit with empty order
    else
        xCfg.Configuration.useAutoInitOrder = '0'; % be conservative
    end
end
if str2double(xCfg.Configuration.useAutoInitOrder)
    % update the initialization order
    xCfg.Configuration.ModuleSetup = dpsModuleInitOrderAuto(sPathContent,...
        xCfg.Configuration.ModuleSetup);
end

%% clearing of configuration link
xCfg.Configuration = dcsFcnLinkCreate(xCfg.Configuration,xCfg.xml.Module);

%% expand pltm.log.common
xCfg.Configuration = dcsPltmLogCommon(xCfg,sPathContent);
return

% =========================================================================

function str = pmsStrEmptyPatch(str)
% PMSSTREMPTYPATCH patch empty strings by string "<empty>"
%
% Syntax:
%   str = pmsStrEmptyPatch(str)
%
% Inputs:
%   str - 
%
% Outputs:
%   str - 
%
% Example: 
%   str = pmsStrEmptyPatch('')

if isempty(str)
    str = '<empty>';
end
return

% =========================================================================

function xConfig = dcsConfigFieldSort(xConfig)
% DCSCONFIGFIELDSORT resort structure fields of a DIVe Configuration so MasterSolver is in front of
% ModuleSetup.
%
% Syntax:
%   xConfig = dcsConfigFieldSort(xConfig)
%
% Inputs:
%   xConfig - structure with fields of a DIVe Configuration 
%
% Outputs:
%   xConfig - structure with fields of a DIVe Configuration 
%
% Example: 
%   xConfig = dcsConfigFieldSort(xConfig)

cOrderTarget = {'MasterSolver','ModuleSetup','Interface','OptionalContent'}';
cField = fieldnames(xConfig);
bContain = ismember(cOrderTarget,cField);
cOrder = cField(~ismember(cField,cOrderTarget));
cOrder = [cOrder; cOrderTarget(bContain)];
xConfig = orderfields(xConfig,cOrder);
return
