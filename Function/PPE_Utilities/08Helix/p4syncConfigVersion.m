function sMsg = p4syncConfigVersion(cFileConfig,sClient,nVerbose)
% P4SYNCCONFIGVERSION sync all DIVe elements used in a DIVe configuration
% to the specified versionID / changelist. Function assumes that the
% configuration is placed in the standard DIVe folder structure under
% "Configuration" and the DIVe elements are placed in the "Content" folder
% next to it.
%
% Syntax:
%   cSync = p4syncConfigVersion(cFileConfig)
%   cSync = p4syncConfigVersion(cFileConfig,sClient)
%
% Inputs:
%   cFileConfig - cell (1xn) of string or string with filepath of a DIVe Configuration
%       sClient - [optional] string with Perforce Client to be used for sync
%
% Outputs:
%   sMsg - string with output messages of sync command
%
% Example: 
%   cSync = p4syncConfigVersion('c:\DIVe\Configuration\Vehicle\Test\test.xml')
%
% Subfunctions: pfiCfgSetup2Path
%
% See also: dsxRead, p4switch, pathparts, strGlue
%
% Author: Rainer Frey, TP/EAC, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2020-06-16

% check input
if nargin < 1
    % get configurations from user dialogue
    [cFile,sPath] = uigetfile(fullfile(pwd,'*.xml'),'Select DIVe Configurations','MultiSelect','on');
    if isnumeric(cFile)
        return
    end
    if ischar(cFile)
        cFile = {cFile};
    end
    cFileConfig = cellfun(@(x)fullfile(sPath,x),cFile,'UniformOutput',false);
end
if ischar(cFileConfig)
    cFileConfig = {cFileConfig};
end
if nargin < 2
    cClient = hlxOutParse(p4('clients','--me'),' ',5,true);
    [nStatus,sClient,sPrevious] = p4switch(cFileConfig{1},0,'',cClient);
end
if nargin < 3
    nVerbose = 1;
end

bKeep = true(size(cFileConfig));
for nIdxFile = 1:numel(cFileConfig)
    if ~exist(cFileConfig{nIdxFile},'file')
        fprintf(2,'p4syncConfig:unknownFile - The specified file was not found: %s\n',cFileConfig{nIdxFile});
        bKeep(nIdxFile) = false;
        continue
    end
    [sPath,sFile,sExt] = fileparts(cFileConfig{nIdxFile}); %#ok<ASGLU>
    if ~strcmpi('.xml',sExt) 
        fprintf(2,'p4syncConfig:noXmlFile - The specified file is no XML file: %s\n',cFileConfig{nIdxFile});
        bKeep(nIdxFile) = false;
    end
end
cFileConfig = cFileConfig(bKeep);
if isempty(cFileConfig)
    return
end

% init output
sMsg = '';

% loop over configurations
tic;
for nIdxFile = 1:numel(cFileConfig)
    if nVerbose
        fprintf(1,'Read Configuration file: %s\n',cFileConfig{nIdxFile});
    end
    % read XML
    xTree = dsxRead(cFileConfig{nIdxFile},false,0);
    if isfield(xTree,'Configuration') && isfield(xTree.Configuration,'ModuleSetup')
        xSetup = xTree.Configuration.ModuleSetup; % shortcut
    else
        fprintf(2,['p4syncConfig:DIVeConfiguration - The specified file ' ...
            'is no DIVe Configuration: %s\n'],cFileConfig{nIdxFile});
        return
    end
    
    % determine Content folder/depot path
    if nargin < 2
        p4switch(cFileConfig{nIdxFile},false);
    end
    cPath = pathparts(cFileConfig{nIdxFile});
    cRoot = cPath(1:end-4);
    
    % get pathes of DIVe elements
    cSync = pfiCfgSetup2Path(xSetup,cRoot);
    
    if nVerbose
        fprintf(1,'Sync Content of file: %s\n',cFileConfig{nIdxFile});
    end
    % sync pathes of workspace to specified version ID
    if nargin < 2
        sMsgAdd = p4fileBatch('sync %s',cSync,12);
    else
        sMsgAdd = p4fileBatch(sprintf('-c %s sync %%s',sClient),cSync,12);
    end
end
if nVerbose
    fprintf(1,'...done. (%is)',toc);
end
sMsg = strGlue({sMsg,sMsgAdd},char(10));
return

% =========================================================================

function cSync = pfiCfgSetup2Path(xSetup,cRoot)
% PFICFGSETUP2PATH creates from ModuleSetups of a DIVe Configuration a cell
% with the pathes
%
% Syntax:
%   cSync = pfiCfgSetup2Path(xSetup)
%
% Inputs:
%   xSetup - structure (1xn) with fields of ModuleSetups of a DIVe
%            Configuration
%    cRoot - cell with strings of root path folder levels (contains
%            "Content" folder)  
%
% Outputs:
%   cSync - cell (1xm) with strings of all relevant folders containing
%           Modules, DataSets and SupportSets in P4 syntax for p4 sync to
%           the specified version
%
% Example: 
%   cSync = pfiCfgSetup2Path(xSetup)

% create sync depot pathes
cSync = cell(200,1);
nSync = 0;
cLevel = {'species','family','type'};
for nIdxSetup = 1:numel(xSetup)
    
    % add Module 
    xMod = xSetup(nIdxSetup).Module;
    cLogHier = {'Content',xMod.context,xMod.species,xMod.family,xMod.type};
    cModule = {'Module',xMod.variant,[xMod.variant '.xml']};
    cModelSet = {'Module',xMod.variant,xMod.modelSet,'...'};
    % add Module XML
    nSync = nSync + 1;
    cSync{nSync} = [strGlue([cRoot cLogHier cModule],filesep) '@' xMod.versionId];
    % add ModelSet
    nSync = nSync + 1;
    cSync{nSync} = [strGlue([cRoot cLogHier cModelSet],filesep) '@' xMod.versionId];
    
    % loop over DataSets
    if isfield(xSetup(nIdxSetup),'DataSet')
        for nIdxData = 1:numel(xSetup(nIdxSetup).DataSet)
            xDat = xSetup(nIdxSetup).DataSet(nIdxData); % shortcut
            nLevel = find(strcmpi(xDat.level,cLevel)); % level ID
            cData = {'Data',xDat.classType,xDat.variant,'...'};
            % add DataSet
            nSync = nSync + 1;
            cSync{nSync} = [strGlue([cRoot cLogHier(1:2+nLevel) cData],filesep) '@' xDat.versionId];
        end
    end
    
    % loop over SupportSets
    if isfield(xSetup(nIdxSetup),'SupportSet')
        for nIdxSupport = 1:numel(xSetup(nIdxSetup).SupportSet)
            xSup = xSetup(nIdxSetup).SupportSet(nIdxSupport); % shortcut
            nLevel = find(strcmpi(xSup.level,cLevel)); % level ID
            cSup = {'Support',xSup.name,'...'};
            % add SupportSet
            nSync = nSync + 1;
            cSync{nSync} = [strGlue([cRoot cLogHier(1:2+nLevel) cSup],filesep) '@' xSup.versionId];
        end
    end
end
cSync = cSync(1:nSync);
return
