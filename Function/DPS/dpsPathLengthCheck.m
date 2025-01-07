function cFileViolation = dpsPathLengthCheck(xCfg,sPathContent,nMax)
% DPSPATHLENGTHCHECK checks the filepath length of files directly identified in DIVe Element XMLs,
% which are referenced by a Configuration.
%
% Syntax:
%   cFileViolation = dpsPathLengthCheck(xCfg,sPathContent,nMax)
%
% Inputs:
%           xCfg - structure of loaded DIVe Configuration by dcsConfigLoad
%            .Configuration - structure of DIVe Configuration XML
%              .ModuleSetup - structure (1xn) with ModuleSetups configured
%            .xml.Module - structure (1xn) of Module XML conent (similar sort order as in
%                          Configuration XML structure)
%   sPathContent - string with path of DIVe Content for Configuration
%           nMax - integer (1x1) with maximum path length
%
% Outputs:
%   cFileViolation - cell (mxn) 
%
% Example: 
%   sConfig = 'C:\dirsync\08Helix\11d_main\com\DIVe\Configuration\Bench_Powerpack\TD_Reference\OM471FE1_390kW_EUVIe_GATS20TE2_EP5060BB2803_WHTC_PH1.xml';
%   cPathConfig = pathparts(sConfig);
%   sPathContent = fullfile(cPathConfig{1:end-4},'Content');
%   xCfg = dcsConfigLoad(sConfig,sPathContent,'testLoad: ',0,0)
%   cFileViolation = dpsPathLengthCheck(xCfg,sPathContent,255)
%
% Subfunctions: getDataFiles, getModelFiles, getSupportFiles
%
% See also: dsxRead
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-8485-3325
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2022-10-06

%% loop through Modules to collect all files related to DIVe Configuration and specified in DIVe XMLs
cFile = cell(0,1);
for nIdxSetup = 1:numel(xCfg.Configuration.ModuleSetup)
    % shortcuts
    xSetup = xCfg.Configuration.ModuleSetup(nIdxSetup);
    xModule = xCfg.xml.Module(nIdxSetup);
    cLogicalHierarchy = {sPathContent,xSetup.Module.context,xSetup.Module.species,...
                         xSetup.Module.family,xSetup.Module.type};
    
    % collect Module files
    cFilePath = getModelFiles(xSetup,xModule,cLogicalHierarchy);
    cFile = [cFile; cFilePath]; %#ok<AGROW>
    
    % collect DataFiles
    cFilePath = getDataFiles(xSetup,xModule,cLogicalHierarchy);
    cFile = [cFile; cFilePath]; %#ok<AGROW>
    
    % collect SupportFiles
    cFilePath = getSupportFiles(xModule,cLogicalHierarchy);
    cFile = [cFile; cFilePath]; %#ok<AGROW>    
end

%% check file length
bViolation = cellfun(@(x)numel(x)>nMax,cFile);
cFileViolation = cFile(bViolation);
return

% =============================================================================================

function cFile = getModelFiles(xSetup,xModule,cLogicalHierarchy)
% GETMODELFILES determine full filepathes of all ModelFiles stated in XML. and XML file
%
% Syntax:
%   cFile = getModelFiles(xSetup,xModule,cLogicalHierarchy)
%
% Inputs:
%              xSetup - structure of single ModuleSetup from DIVe Configuration
%             xModule - structure of Module XML file content 
%   cLogicalHierarchy - cell (1xn) with path elements from content path to type level
%
% Outputs:
%   cFile - cell (mx1) of strings with filepathes specified by Module XML
%
% Example: 
%   cFile = getModelFiles(xSetup,xModule,cLogicalHierarchy)

% add Module file
cFile = {fullfile(cLogicalHierarchy{:},'Module',xSetup.Module.variant,[xSetup.Module.variant '.xml'])};
% add ModelSet files
bSet = strcmp(xSetup.Module.modelSet,{xModule.Implementation.ModelSet.type});
cFileSet = {xModule.Implementation.ModelSet(bSet).ModelFile.name};
cFilePath = cellfun(@(x)fullfile(cLogicalHierarchy{:},'Module',...
    xSetup.Module.variant,xSetup.Module.modelSet,x),cFileSet,'UniformOutput',false);
cFile = [cFile; cFilePath'];
return

% =============================================================================================

function cFile = getDataFiles(xSetup,xModule,cLogicalHierarchy)
% GETDATAFILES determine full filepathes of all DataFiles stated in XML and XML file.
%
% Syntax:
%   cFile = getDataFiles(xSetup,xModule,cLogicalHierarchy)
%
% Inputs:
%              xSetup - structure of single ModuleSetup from DIVe Configuration
%             xModule - structure of Module XML file content 
%   cLogicalHierarchy - cell (1xn) with path elements from content path to type level
%
% Outputs:
%   cFile - cell (mx1) of strings with filepathes specified by DataSet XML
%
% Example: 
%   cFile = getDataFiles(xSetup,xModule,cLogicalHierarchy)

% init output
cFile = cell(0,1);

%% build list of files for DataSetInitIO (obsolete use - for backward compatibility)
if isfield(xModule.Interface,'DataSetInitIO')
    % determine position of initIO DataSet in ModuleSetup
    bClassInSetup = strcmp('initIO',{xSetup.DataSet.className});
    % get files from XML
    cFileAdd = getDataFilesCore(xModule.Interface.DataSetInitIO,xSetup.DataSet(bClassInSetup),cLogicalHierarchy);
    cFile = [cFile;cFileAdd];
end

%% build list for files of DataSet and global/dependent parameters
if isfield(xModule.Interface,'DataSet')
    for nIdxSet = 1:numel(xModule.Interface.DataSet)
        % shortcut
        xSetModule = xModule.Interface.DataSet(nIdxSet);
        
        % match with Configuration.ModuleSetup
        bClassInSetup = strcmp(xSetModule.className,{xSetup.DataSet.className});
        xSetSetup =  xSetup.DataSet(bClassInSetup);
        
        % get files from XML
        cFileAdd = getDataFilesCore(xSetModule,xSetSetup,cLogicalHierarchy);
        cFile = [cFile;cFileAdd];  %#ok<AGROW>
    end % for set
end
return

% =============================================================================================

function cFile = getDataFilesCore(xSetModule,xSetSetup,cLogicalHierarchy)
% GETDATAFILESCORE gets the XML location and extracts the files there for the output list of
% filepathes.
%
% Syntax:
%   cFile = getDataFilesCore(xSetModule,xSetSetup,cLogicalHierarchy)
%
% Inputs:
%          xSetModule - structure with fields of single DataSet in Module XML
%           xSetSetup - structure with fields of single DataSet in Configuration XML
%   cLogicalHierarchy - cell (1xn) with path elements from full content path to type level
%
% Outputs:
%   cFile - cell (mx1) of strings with filepathes specified by DataSet XML
%
% Example: 
%   cFile = getDataFilesCore(xCfg.xml.Module(1).DataSet(1),xCfg.Configuration.ModuleSetup.DataSet(1),...
%              {'C:','dirsync','08Helix','11d_main','com','DIVe','Content','bdry','env','air','std'})

% path of DataSet variant
nLevel = find(strcmp(xSetModule.level,{'species','family','type'}));
sPathDataSet = fullfile(cLogicalHierarchy{1:end-3+nLevel},'Data',xSetModule.classType,xSetSetup.variant);

% load DataSet XML
sFileXml = fullfile(sPathDataSet,[xSetSetup.variant '.xml']);
xData = dsxRead(sFileXml);
xSetXml = xData.DataSet;

% add file pathes
cFilePath = cellfun(@(x)fullfile(sPathDataSet,x),{xSetXml.DataFile.name},'UniformOutput',false);
cFile = [{sFileXml};cFilePath']; 
return

% =============================================================================================

function cFile = getSupportFiles(xModule,cLogicalHierarchy)
% GETSUPPORTFILES determine full filepathes of all SupportFiles stated in XML and XML file.
% 
% Remark: used xModule(=Module XML) info on SupportSets as this reflects most likely the actual
% file system Module + SupportSet state, as Module & SupportSets consistency is checked by Perforce
% triggers and filesystem copies should be derived from Perforce.
%
% Syntax:
%   cFile = getSupportFiles(xModule,cLogicalHierarchy)
%
% Inputs:
%   cLogicalHierarchy - cell (1xn) with path elements from content path to type level
%
% Outputs:
%   cFile - cell (mx1) of strings with filepathes specified by SupportSet XML
%
% Example: 
%   cFile = getSupportFiles(xSetup,xModule,cLogicalHierarchy)

% init output
cFile = cell(0,1);

% build list for files of SupportSet 
if isfield(xModule.Implementation,'SupportSet') && ...
        ~isempty(xModule.Implementation.SupportSet)
    for nIdxSet = 1:numel(xModule.Implementation.SupportSet)
        % shortcut
        xSet = xModule.Implementation.SupportSet(nIdxSet);
        
        % path of support set
        nLevel = find(strcmp(xSet.level,{'species','family','type'}));
        sPathSupportSet = fullfile(cLogicalHierarchy{1:end-3+nLevel},'Support',xSet.name);
        
        % load support set XML
        sFileXml = fullfile(sPathSupportSet,[xSet.name '.xml']);
        xSupport = dsxRead(sFileXml);
        xSetXml = xSupport.SupportSet;
            
        % add file pathes
        cFilePath = cellfun(@(x)fullfile(sPathSupportSet,x),{xSetXml.SupportFile.name},'UniformOutput',false);
        cFile = [cFile;{sFileXml};cFilePath']; %#ok<AGROW>
    end % for set
end % if support set exists
return

