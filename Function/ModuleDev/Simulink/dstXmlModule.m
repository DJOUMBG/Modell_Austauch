function dstXmlModule(sEntry,bSignalListNetwork,cExpression,varargin)
% DSTXMLMODULE create a DIVe Module XML and its initIO dataset.
% Create DIVe module content from the DIVe Signal list and a Simulink block
% with DIVe Signal list conform port names with user interaction.
%
% Parts of Content and dependencies
% model -> ports
% model s-fcn -> parameter indices
% signal list -> detailed port attributes and data class initIO variants
% file system -> logical hierarchy, modelset, data classes, support sets
%
% Syntax:
%   dstXmlModule
%   dstXmlModule(sEntry)
%   dstXmlModule(sEntry,bSignalListNetwork,cExpression)
%   dstXmlModule(sEntry,bSignalListNetwork,cExpression,varargin)
%
% Inputs:
%        sEntry - handle of Simulink block (DIVe wrapper) or
%                 string with main model file (mdl, slx, fmu) or
%                 string with modelSet path or
%                 string with DIVe module variant path
%                 string with DIVe module XML filepath
%   bSignalListNetwork - boolean on dialogue for DIVe signal list from
%                        network drive
%   cExpression - cell (mx2) for file attribute determination with
%                   (:,1): string with attribute name
%                          'isMain' -> regexp for ModelFile with isMain=true 
%                          'copyToRunDirectory' -> regexp for ModelFile with copyToRunDirectory=true 
%                          'supportSet' -> regexp for used SupportSet of Module 
%                          'dataSetClassType' -> dataset classes of Module 
%                          'initIO' -> regexp for initIO variant creation selection
%                          'initIOReference' -> regexp for initIO reference dataset 
%                          'sortPrioDataSet' -> cell (1xn) with strings
%                                          for DataSet className priority order
%                          'sortPrioSupportSet' -> cell (1xn) with string
%                                          for support set priority order
%                          'dataSetClassType' -> regexp for classes to add
%                          'supportSet' -> regexp for SupportSets to add
%                   (:,2): string with regular expression to determine
%                          files with attribute value = true or to
%                          determine used DataSets/used SupportSets/initIO
%                          DataSet variants to be created/ reference
%                          dataset of classType initIO
%             varargin - [only for old syntax on DataSet classTypes and SupportSets to add]
%
% Outputs:
%
% Example:
%   dstXmlModule
%   dstXmlModule(gcb)
%   dstXmlModule(['C:\dirsync\06DIVe\01Content\phys\eng\simple\stationary\Module\std' ...
%                       '\sfcn_w32_R2010bSP1\eng_simple_transient_std.mdl'])
%   dstXmlModule(pwd,false,{'isMain','(\.mdl)$|(\.slx)$';'copyToRunDirectory',''})
% % Example of specific selections
%   dstXmlModule(pwd,false,...
%                   {'supportSet','example$';...
%                    'dataSetClassType','^mainData$';...
%                    'initIO','^std$|sna|ldStd';...
%                    'initIOReference','ldStd'})
% % Example of select all datasets, supportset, initIO variants
%   dstXmlModule(pwd,false,...
%                   {'supportSet','.*';...
%                    'dataSetClassType','.*';...
%                    'initIO','.*';...
%                    'initIOReference','std'})
% 
% % Complex Examples:
% dstXmlModule(sPathXcmSilMil,false,...
%                   {'isMain','[am]cm_[ms]il_.*\.mdl$';... % main file
%                    'copyToRunDirectory','';... % none
%                    'supportSet','.*';... % all
%                    'dataSetClassType','.*';... % all
%                    'initIO','^std$';... % only std variant
%                    'initIOReference','std'}) % std initIO as reference
% dstXmlModule(sPathLookup,false,...
%                   {'supportSet','';... % none - CAUTION: different for VITOS
%                    'dataSetClassType','lookup';... 
%                    'initIO','^std$'})
%
% Subfunctions: dstFolderMatlabVersionNext,
% dstModuleHeaderGen(sName,sType,sFamily,sSpecies,... ,
% dstModuleImplementationGen, dstModuleInterfaceGen,
% dstModuleInterfaceToolGen, dstModuleMdlComfortDetection,
% dstModulePortListGet, dstSimulinkBlockDetermination, verLessThanOther
%
% See also: dbColumn2Struct, dbread, dirPattern,
% dstExtendXmlModuleParameter, dstFileTagCreate, dstInitIOVariantsCreate,
% dstXmlModule, dstXmlSupportSet, dsxWrite, getFileVersionFmu,
% getFileVersionSimpack, getFileVersionSimulink, ismdl, pathparts,
% slcBlockInfo, strGlue, strsplitOwn, structAdd, uiopen, verLessThanMATLAB,
% versionAliasMatlab
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49 711 8485 3325
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2014-06-25

% specification version
sSpecVersion = '1.2.0';

%% check input
if nargin < 1 
    sEntry = ''; % details in input check function
end 
if nargin < 2
    bSignalListNetwork = false;
end
if nargin < 3
    cExpression = {}; % details in input check function
end
% input case handling checks for Module (XML) detection and silent interface
[xModule,xOther,cExpression,hBlock] = dmcInputParse(sEntry,cExpression,nargin,varargin{:});

%% get port list information
[xPort,xSource] = dstModulePortListGet(xOther.cPath,bSignalListNetwork);

%% try to retrieve previous XML
if exist(xOther.sXml,'file')
    xTreeOrg = dsxRead(xOther.sXml);
else
    xTreeOrg = structInit({'Module'});
end

%% create module header
% create structure for XML header
sModuleRef = fullfile(xModule.species,xModule.family,xModule.type,'Module',xModule.name);
xTree.Module = dstModuleHeaderGen(xModule,sSpecVersion,'1.0',xTreeOrg);

%% module implementation part (ModelSets and SupportSets)
if exist('xTreeOrg','var') && isfield(xTreeOrg,'Module') && ~isempty(xTreeOrg)
    xModuleAdd = dstModuleImplementationGen(fullfile(xOther.cPath{:}),...
        xTreeOrg.Module.Implementation.ModelSet,cExpression);
else
    xModuleAdd = dstModuleImplementationGen(fullfile(xOther.cPath{:}),...
        struct('type',{},'ModelFile',{}),cExpression);
end
xTree.Module = structAdd(xTree.Module,xModuleAdd); % add structure part to existing structure

%% split for Simulink or FMU background
% get mainfile of ModelSet 
if isempty(xOther.sFileMain)
    bSet = strcmp(xOther.sModelSet,{xTree.Module.Implementation.ModelSet.type}); % find specified ModelSet
    bMain = strcmp('1',{xTree.Module.Implementation.ModelSet(bSet).ModelFile.isMain}); % find mainfile
    xOther.sFileMain = xTree.Module.Implementation.ModelSet(bSet).ModelFile(bMain).name;
    [sTrash,sTrash2,xOther.sFileMainExt] = fileparts(xOther.sFileMain); %#ok<ASGLU> % split file extension
end

% get Module info according mainfile extension
sFile = fullfile(xOther.cPath{:},xOther.sModelSet,xOther.sFileMain);
switch lower(xOther.sFileMainExt)
    case {'.mdl','.slx'}
        [cInport,cOutport,xParam] = dstModuleSfcnParse(sFile,hBlock);
    case {'.fmu'}
        [cInport,cOutport,xParam] = dstModuleFmuParse(sFile);
    case {'.mexw32'}
        % exception case of Peter Hamann (eng.detail.gtfrm as s-function
        % for Silver)
        sFile = fullfile(xOther.cPath{:},'open','eng_detail_gtfrm_std_open.mdl');
        if exist(sFile,'file')
            [cInport,cOutport,xParam] = dstModuleSfcnParse(sFile,'');
        else
            error('dstXmlModule:unknownMainFile',...
                'Main files of this type are not covered in dstXmlModule: %s',xOther.sFileMain);
        end
    otherwise
        error('dstXmlModule:unknownMainFile',...
            'Main files of this type are not covered in dstXmlModule: %s',xOther.sFileMain); 
end

%% module interface part except parameters
% notify user regarding the collection for which initIO is created
fprintf(1,'\nGeneration of initIO dataset variants for %s\n',sModuleRef);
xModuleAdd = dstModuleInterfaceGen(cInport,cOutport,fullfile(xOther.cPath{:}),xPort,xSource,cExpression);

% determine initIO reference value
if isfield(xModuleAdd.Interface,'DataSetInitIO')
    if isfield(xModuleAdd.Interface.DataSetInitIO,'reference')
        sInitIOReference = xModuleAdd.Interface.DataSetInitIO.reference;
    else % trigger error
        sInitIOReference = '';
    end
else
    bInitIO = strcmp('initIO',{xModuleAdd.Interface.DataSet.classType});
    if any(bInitIO)
        sInitIOReference = xModuleAdd.Interface.DataSet(bInitIO).reference;
    else % trigger error
        sInitIOReference = '';    
    end
end

% check existence of initIO reference for generation approval
if isempty(sInitIOReference)
    fprintf(2,'\nError: Module XML could not be generated for <a href="matlab:winopen(''%s'')">%s</a>\n',...
    fullfile(xOther.cPath{:}),sModuleRef);
    return
end

% add interface structure part to existing structure
xTree.Module = structAdd(xTree.Module,xModuleAdd);

% expand classNames with issubspecies tag based on SupportSet "issubspecies"
[xTree.Module,cClassSubspecies] = dstSubspeciesDataSetExpansion(xTree.Module,xOther.cPath);

% apply DataSet priority sorting
xTree.Module.Interface.DataSet = dstDataSetSort(xTree.Module.Interface.DataSet,cExpression);

%% add parameters to the interface part
xTree.Module = dstExtendXmlModuleParameter(xOther.cPath,xTree.Module,xParam,cClassSubspecies);

% close model
if ismdl(sEntry)
    close_system(bdroot(sEntry));
end

%% write XML
dsxWrite(xOther.sXml,xTree);
fprintf(1,'<a href="matlab:open(''%s'')">Add comment to Module XML file %s</a>\n',...
    xOther.sXml, [xOther.cPath{end} '.xml']);
return

% =========================================================================

function [xModule,xOther,cExpression,hBlock] = dmcInputParse(sEntry,cExpression,nArgin,varargin)
% DMCINPUTPARSE input parsing and fixing of complex input.
%
% Syntax:
%   [xModule,xOther,cExpression,hBlock] = dmcInputParse(sEntry,cExpression,nArgin,varargin)
%
% Inputs:
%        sEntry - handle of Simulink block (DIVe wrapper) or
%                 string with main model file (mdl, slx, fmu) or
%                 string with modelSet path or
%                 string with DIVe module variant path
%                 string with DIVe module XML filepath
%   cExpression - cell (mx2) for file attribute determination 
%                 if omitted at main function input: empty cell
%        nArgin - integer (1x1) with number of arguments of main function
%      varargin - additional arguments of main function
%
% Outputs:
%      xModule - structure (1x1) with fields of logical hierarchy:
%         .name    - string with name of Module
%         .type    - string with type of Module
%         .family  - string with family of Module
%         .species - string with species of Module
%         .context - string with context of Module
%       xOther - structure (1x1) with fields:
%         .cPath      - cell (1xm) with folders of Module variant path
%         .sModelSet  - string with name of ModelSet to use for Module XML
%                       generation
%         .sXml       - string with filepath of Module XML
%         .sFileMain  - string with name of main model file in ModelSet
%         .sFileMainExt  - string with extension of main model file
%   cExpression - cell (mx2) for file attribute determination
%        hBlock - char (1xn) with simulink block path of model (wrapper
%                 block level)
%
% Example: 
%   [xModule,xOther,cExpression,hBlock] = dmcInputParse(sEntry,cExpression,nArgin,varargin)

%% nargin parsing
if isempty(sEntry) % try to detect block from simulink
    hBlock = gcb; % get current Simulink block
    if isempty(hBlock) || ... % no block selected
            strcmp(hBlock(1:8),'simulink') || ...
            strcmp(hBlock(1:6),'gtlink') % current block is only a native simulink library
        % user file selection
        [sFile,sPath] = uigetfile( ... % file selelction for simulink model
            {'*.mdl;*.slx;*.fmu','Covered models (*.mdl,*.slx,*.fmu)'; ...
            '*.*',  'All Files (*.*)'}, ...
            'Select main model file',...
            'MultiSelect','off');
        if isnumeric(sFile) % cancel in model file selection
            disp('Main model selection canceled by user - stopped dstXmlModule execution.')
            return
        end
        
        % assign file path for block determination
        sEntry = fullfile(sPath,sFile);
        hBlock = '';
    else
        % split file from Simulink block
        sEntry = get_param(bdroot(hBlock),'FileName');
    end
else
    hBlock = '';
end % input argument available
if isempty(cExpression)
    cExpression = {'',''}; % ask user for file attributes
end
if nArgin > 3
    if (isnumeric(varargin{1}) || islogical(varargin{1})) && varargin{1}
        % patch old switch behaviour of adding all supportsets
        if ismember('dataSetClassType',cExpression(:,1))
            fprintf(2,['Error - dstXmlModule: mixted old syntax with ' ...
                'extended expression! Flag to add all DataSet classTypes ' ...
                'is ignored for Module "%s"!'],sEntry);
        else
            cExpression = [cExpression; {'dataSetClassType','.*'}];
        end
    end
end
if nArgin > 4
    if (isnumeric(varargin{2}) || islogical(varargin{2})) && varargin{2}
        % patch old switch behaviour of adding all supportsets
        if ismember('supportSet',cExpression(:,1))
            fprintf(2,['Error - dstXmlModule: mixed old syntax with ' ...
                'extended expression! Flag to add all SupportSet is ignored ' ...
                'for Module "%s"!'],sEntry);
        else
            cExpression = [cExpression; {'supportSet','.*'}];
        end
    end
end

%% path split up
% split file from path
if exist(sEntry,'file') == 2
    bFile = true;
    [sPath,sName,sExt] = fileparts(sEntry);
else
    bFile = false;
    sPath = sEntry;
end

% split path
cPath = pathparts(sPath);

% detect Module level
nModule = find(strcmp('Module',cPath));
if isempty(nModule)
    error('dstXmlModule:dmcInputParse',...
        ['Specified entry (1st argument to dstXmlModule) is not a ' ...
         'folderpath with Module folder: %s\n'],fullfile(cPath{:}));
end

% assign logical hierarchy
xModule.name = cPath{nModule+1};
xModule.type = cPath{nModule-1};
xModule.family = cPath{nModule-2};
xModule.species = cPath{nModule-3};
xModule.context = cPath{nModule-4};

% assign other information
xOther.cPath = cPath(1,1:nModule+1);
xOther.sModelSet = '';
xOther.sXml = '';
xOther.sFileMain = '';
xOther.sFileMainExt = '';
if numel(cPath) > nModule+1
    xOther.sModelSet = cPath{nModule+2};
end
if bFile % derive files
    if numel(cPath) == nModule+1
        xOther.sXml = [sName,sExt];
    elseif numel(cPath) == nModule+2
        xOther.sXml = fullfile(xOther.cPath{:},[xOther.cPath{end},'.xml']);
        xOther.sFileMain = [sName,sExt];
        xOther.sFileMainExt = sExt;
    end
else
    xOther.sXml = fullfile(xOther.cPath{:},[xOther.cPath{end},'.xml']);
end

%% detect ModelSet for port determination (priority logic)
if isempty(xOther.sModelSet)
    cModelSet = dirPattern(fullfile(xOther.cPath{:}),'*','folder');
    
    % prio 0 - single ModelSet
    if numel(cModelSet) == 1
        xOther.sModelSet = cModelSet{1};
        return
    end
    
    % prio 1 - sfcn of actual Matlab wrapper intentionally made for DIVe
    xOther.sModelSet = dstFolderMatlabVersionNext(cModelSet); 
    if ~isempty(xOther.sModelSet)
        return
    end
    
    % prio 2 - any sfcn (not only this or newer)
    nSfcn = find(strncmp('sfcn',cModelSet,4));
    if ~isempty(nSfcn)
        xOther.sModelSet = cModelSet{nSfcn(1)};
        return
    end
    
    % prio 3 - fmu  
    nFmu = find(strncmpi('fmu',cModelSet,3));
    if ~isempty(nFmu)
        xOther.sModelSet = cModelSet{nFmu(1)};
        return
    end
    
    % prio 4 - open
    if any(strcmp('open',cModelSet))
        xOther.sModelSet = 'open';
        return
    end

end

return

% =========================================================================

function xModule = dstModuleImplementationGen(sModulePath,xModelSet,cExpression)
% DSTMODULEIMPLEMENTATIONGEN create a MATLAB structure representation of
% the implementation part of a DIVe module xml content.
%
% Syntax:
%   xModule = dstModuleImplementationGen(sModulePath,xModelSet,cExpression)
%
% Inputs:
%   sModulePath - string with path of module (e. g. where the module XML is)
%     xModelSet - [optional] structure with modelsets of previous XML
%   cExpression - cell (mx2) for file attribute determination with
%                   (:,1): string with attribute name
%                          'supportSet' -> regexp for used SupportSet of Module 
%                   (:,2): string with regular expression to determine
%                          used SupportSets
%
% Outputs:
%   xModule - structure with fields:
%     .Implementation  - structure with fields
%       .ModelSet    - structure with fields
%         ...
%       .SupportSet  - [optional] structure with fields
%         ...
%
% Example:
%   xModule = dstModuleImplementationGen(pwd,struct('type',{},'ModelFile',{}),{'',''})

% check input
if nargin < 2
    xModelSet = struct('type',{},'ModelFile',{});
end
if nargin < 3
    cExpression = {'',''};
end
cModelSetOrg = {xModelSet.type};

%% determine model sets
cModelSet = dirPattern(sModulePath,{'*'},'folder');
bFindInfoFolder = strcmp('info',cModelSet); % find "info" folder
cModelSet = cModelSet(~bFindInfoFolder); % ignore "info" folder
for nIdxModelSet = 1:numel(cModelSet)
    % Model set attributes
    xModule.Implementation.ModelSet(nIdxModelSet).type = cModelSet{nIdxModelSet};
    
    % determine files of model set
    sPathFile = fullfile(sModulePath,cModelSet{nIdxModelSet});
    bModelSet = strcmp(cModelSet{nIdxModelSet},cModelSetOrg);
    if any(bModelSet)
        xModule.Implementation.ModelSet(nIdxModelSet).ModelFile = dstFileTagCreate(sPathFile,...
            {'isMain','copyToRunDirectory'},xModelSet(bModelSet).ModelFile,cExpression);
    else % path 0x0 struct size for correct dstFileTagCreate nargin value
        xModule.Implementation.ModelSet(nIdxModelSet).ModelFile = dstFileTagCreate(sPathFile,...
            {'isMain','copyToRunDirectory'},struct(),cExpression);
    end
    
    % determine execution parameters of model set
    xModelFile = xModule.Implementation.ModelSet(nIdxModelSet).ModelFile;
    sFileMain = xModelFile(strcmp('1',{xModelFile.isMain})).name;
    [sAuthoring,sExecute,sUpComp] = dstModuleToolGet(sPathFile,sFileMain);
    xModule.Implementation.ModelSet(nIdxModelSet).authoringTool = sAuthoring;
    xModule.Implementation.ModelSet(nIdxModelSet).executionTool = sExecute;
    xModule.Implementation.ModelSet(nIdxModelSet).executionToolUpwardCompatible = sUpComp;
end

%% determine support sets
cModulePath = pathparts(sModulePath);
cSupportSetSpecies = dirPattern(fullfile(cModulePath{1:end-4},'Support'),{'*'},'folder');
cSupportSetSpeciesDisp = cellfun(@(x)[x repmat(' ',1,50-numel(x)) '(species)'],cSupportSetSpecies,'UniformOutput',false);
cSupportSetFamily = dirPattern(fullfile(cModulePath{1:end-3},'Support'),{'*'},'folder');
cSupportSetFamilyDisp = cellfun(@(x)[x repmat(' ',1,50-numel(x)) '(family)'],cSupportSetFamily,'UniformOutput',false);
cSupportSetType = dirPattern(fullfile(cModulePath{1:end-2},'Support'),{'*'},'folder');
cSupportSetTypeDisp = cellfun(@(x)[x repmat(' ',1,50-numel(x)) '(type)'],cSupportSetType,'UniformOutput',false);
cSupportSet = [cSupportSetSpecies,cSupportSetFamily,cSupportSetType];
cSupportSetDisp = [cSupportSetSpeciesDisp,cSupportSetFamilyDisp,cSupportSetTypeDisp];

% stop if no support sets where found
if isempty(cSupportSet)
    return
end

% get used support sets
bSupport = strcmp('supportSet',cExpression(:,1)); % check for a regular expression for used SupportSets
if any(bSupport)
    %resolve regular expression pattern to be used
    sRegExp = strtrim(cExpression{bSupport,2});
    
    % get SupportSets used in Module by regular expression
    nSelection = find(~cellfun(@isempty,regexp(cSupportSet,sRegExp,'once')));
    
else
    % ask for used supports set
    nSelection = listdlg('ListString',cSupportSetDisp,...
        'ListSize',[300 400],...
        'PromptString','Select SupportSets of module',...
        'Name','SupportSets'); % dialogue window
end

% resort support sets via silent interface
bSupportSort = strcmp('sortPrioSupportSet',cExpression(:,1)); % check for priority cell
if any(bSupportSort)
    %resolve regular expression pattern to be used
    cPrio = strtrim(cExpression{bSupportSort,2});
    nSelection = dstSortPrio(cPrio,cSupportSet(nSelection),nSelection); % resort selection
end

% extend xml for all selected support sets
cLevel = {'species','family','type'};
for nIdxSupportSet = 1:numel(nSelection)
    % determine level
    nLevel = (nSelection(nIdxSupportSet)>numel(cSupportSetSpecies)) + ...
        (nSelection(nIdxSupportSet)>numel(cSupportSetSpecies)+numel(cSupportSetFamily)) + ...
        1; % level of SupportSet 1: species, 2: family, 3: type
    
    % Support set attributes
    xModule.Implementation.SupportSet(nIdxSupportSet).name = cSupportSet{nSelection(nIdxSupportSet)};
    xModule.Implementation.SupportSet(nIdxSupportSet).level = cLevel{nLevel};
end
return

% =========================================================================

function xModule = dstModuleInterfaceGen(cInport,cOutport,sModulePath,xPort,xSource,cExpression)
% DSTMODULEINTERFACEGEN create module interface structure for XML
% generation, as well as the initIO dataset and its XML
%
% Syntax:
%   xModule = dstModuleInterfaceGen(cInport,cOutport,sModulePath,xPort,xSource,cExpression)
%
% Inputs:
%       cInport - cell (1xm) with strings of inport names 
%      cOutport - cell (1xn) with strings of outport names
%   sModulePath - string with main path of module
%         xPort - structure with all attribute fields of a port
%   cExpression - cell (mx2) for file attribute determination with
%                   (:,1): string with attribute name; 
%                          'dataSetClassType' -> dataset classes of Module 
%                          'initIO' -> regexp for initIO creation selection
%                          'initIOReference' -> regexp for reference dataset 
%                   (:,2): string with regular expression to determine
%                          used DataSets
% Outputs:
%   xModule - structure with fields:
%
% Example:
%   xModule = dstModuleInterfaceGen(hBlock,sModulePath,xPort,cExpression)

% create search field for port signals
cPort = {xPort.name};

% determine port index vectors of Module
[bInport,nInport] = ismember(cInport,cPort);
if any(~bInport)
    disp(char([{'CAUTION: Following Inports were not found in the signal list!'}; cInport(~bInport)]));
    error('dstXmlModule:dstModuleInterfaceGen','Missing inport description in signal list');
end
[bOutport,nOutport] = ismember(cOutport,cPort);
if any(~bOutport)
    disp(char([{'CAUTION: Following Outports were not found in the signal list!'}; cOutport(~bOutport)]));
    error('dstXmlModule:dstModuleInterfaceGen','Missing outport description in signal list');
end

%% create dataset initIO by Inports/Outport
cModulePath = pathparts(sModulePath);
% Create initIO variants
sInitIOReferenceName = dstInitIOVariantsCreate(cModulePath,xPort,xSource,...
                                nInport,nOutport,cExpression);

%% create dataset entries
% add initIO dataset
xModule.Interface.DataSet.className = 'initIO';
xModule.Interface.DataSet.classType = 'initIO';
xModule.Interface.DataSet.level = 'type';
xModule.Interface.DataSet.isSubspecies = '0';
% if initio refernce dataset variant could not be resolved
if isempty(sInitIOReferenceName)
    fprintf(2,'\nError: Module XML generation stopped as initIO reference dataset cannot be resolved');
    return
else % check existence of reference DataSet variant
    sPathInitIOXml = fullfile(cModulePath{1:end-2},'Data','initIO',...
        sInitIOReferenceName,[sInitIOReferenceName '.xml']);
    % if there are no initIO variants then report error
    if ~exist(sPathInitIOXml,'file')
        fprintf(2,['\nError: Module XML generation stopped as there is no ' ...
            'reference <a href="matlab:winopen(''%s'')">InitIO</a> data variant'],...
            fullfile(cModulePath{1:end-2},'Data','initIO'));
        return
    end
    xModule.Interface.DataSet.reference = sInitIOReferenceName;
end

% determine other datasets and create entries
cDataSetSpecies = dirPattern(fullfile(cModulePath{1:end-4},'Data'),{'*'},'folder'); % list folders under Data of species
cDataSetSpeciesSpace = cellfun(@(x)[x repmat(' ',1,50-numel(x)) '(species)'],cDataSetSpecies,'UniformOutput',false);
cDataSetFamily  = dirPattern(fullfile(cModulePath{1:end-3},'Data'),{'*'},'folder'); % list folders under Data of family
cDataSetFamilySpace  = cellfun(@(x)[x repmat(' ',1,50-numel(x)) '(family)'],cDataSetFamily,'UniformOutput',false);
cDataSetType    = dirPattern(fullfile(cModulePath{1:end-2},'Data'),{'*'},'folder'); % list folders under Data of type
cDataSetTypeSpace    = cellfun(@(x)[x repmat(' ',1,50-numel(x)) '(type)'],cDataSetType,'UniformOutput',false);
cDataSetClass = [cDataSetSpecies, cDataSetFamily, cDataSetType];
cDataSetClassSpace = [cDataSetSpeciesSpace, cDataSetFamilySpace, cDataSetTypeSpace];
bInitIO = ismember(cDataSetClass,{'initIO'}); % identify classType initIO
cDataSetClass = cDataSetClass(~bInitIO); % remove classType initIO from cell list
cDataSetClassSpace = cDataSetClassSpace(~bInitIO); % remove classType initIO from cell list

if ~isempty(cDataSetClass)
    bClass = strcmp('dataSetClassType',cExpression(:,1)); % check for a regular expression for used classTypes
    if any(bClass)
        % resolve regular expression pattern to be used
        sRegExp = strtrim(cExpression{bClass,2});
        
        % get DataSet classTypes used in Module by regular expression
        nSelection = find(~cellfun(@isempty,regexp(cDataSetClass,sRegExp,'once')));
    
    else
        % ask for used data class
        nSelection = listdlg('InitialValue',1:numel(cDataSetClass),... %choose all dataSetClasses as default
            'ListString',cDataSetClassSpace,...
            'ListSize',[300 400],...
            'PromptString','Select Data Class Types of module',...
            'Name','Data Class Types'); % dialogue window
    end
    
    % extend xml for all selected data sets
    cLevel = {'species','family','type'};
    bAnyIsStandard = false;
    nData = double(isfield(xModule.Interface,'DataSet'));
    for nIdxClass = 1:numel(nSelection) % for all (remaining) classTypes
        % determine level
        nLevel = (nSelection(nIdxClass)>numel(cDataSetSpecies)) + ...
            (nSelection(nIdxClass)>numel(cDataSetSpecies)+numel(cDataSetFamily)) + ...
            1; % level of DataSet Class 1: species, 2: family, 3: type
        
        % add data set
        xModule.Interface.DataSet(nIdxClass+nData).className = cDataSetClass{nSelection(nIdxClass)};
        xModule.Interface.DataSet(nIdxClass+nData).classType = cDataSetClass{nSelection(nIdxClass)};
        xModule.Interface.DataSet(nIdxClass+nData).level = cLevel{nLevel};
        xModule.Interface.DataSet(nIdxClass+nData).isSubspecies = '0';
        
        % determine reference dataset
        sPathDataClass = fullfile(cModulePath{1:end-5+nLevel},'Data',cDataSetClass{nSelection(nIdxClass)});
        cDataImplementation = dirPattern(sPathDataClass,'*','folder'); % get existing data set folders
        sPathDataXml = fullfile(sPathDataClass,cDataImplementation{1},[cDataImplementation{1} '.xml']);
        if exist(sPathDataXml,'file')
            % read the xml of first data set
            xData = dsxRead(sPathDataXml); 
            % extract reference data set for dataset classType
            xModule.Interface.DataSet(nIdxClass+nData).reference = xData.DataSet.reference; 
            % store level for easier parameter extraction
            xData.DataSet.level = xModule.Interface.DataSet(nIdxClass+nData).level; 
            
            % store information about existence of isStandard files in
            % module's data sets -> triggers parameter index determination
            bAnyIsStandard = bAnyIsStandard || any(ismember({xData.DataSet.DataFile.isStandard},{'1'}));
        else
            error(['XML generation stopped - Missing data set xml: ' sPathDataXml]);
        end
    end
end

%% create port entries in struct
% ensure correct fields of signal list
cValid = {'name','type','unit','sna','minPhysicalRange','maxPhysicalRange',...
    'signalLabel','manualDescription','autoDescription','responsibleTeam',...
    'minAbsoluteRange','maxAbsoluteRange','factorAbs2Phys','offsetAbs2Phys',...
    'signalOrigin','connectorName','connectorType','connectorOrientation',...
    'quantity','moduleSpecies','moduleSubspecies','characteristic',...
    'functionalChain','chainPosition'};
cField = fieldnames(xPort);
bRemove = ~ismember(cField,cValid);
cRemove = cField(bRemove);
for nIdxRemove = 1:numel(cRemove)
    xPort = rmfield(xPort,cRemove{nIdxRemove});
end
% check scope of remainding signal list
cField = fieldnames(xPort);
bCheck = ismember(cValid,cField);
if ~all(bCheck)
    error('dstXmlModule:dstModuleInterfaceGen:invalidSignalList',...
        'The used signal list is missing the columns: %s',...
        strGlue(cValid(~bCheck),','));
end

% assign ports
xModule.Interface.Inport = xPort(nInport);
xModule.Interface.Outport = xPort(nOutport);

% add indices to ports
for nIdxPort = 1:numel(xModule.Interface.Inport)
    xModule.Interface.Inport(nIdxPort).index = num2str(nIdxPort);
end
for nIdxPort = 1:numel(xModule.Interface.Outport)
    xModule.Interface.Outport(nIdxPort).index = num2str(nIdxPort);
end
return

% =========================================================================

function xModule = dstModuleHeaderGen(xModule,sSpecVersion,sVersionModule,xTreeOrg)
% DSTMODULEHEADERGEN construct structure with module base attributes
%
% Syntax:
%   xModule = dstModuleHeaderGen(sName,sType,sFamily,sSpecies,sContext,...
%                   sVersionSpec,sVersionModule,sMaxCosimStepsize,sDescription)
%
% Inputs:
%             xModule - structure (1x1) with fields of logical hierarchy:
%                .name    - string with name of Module
%                .type    - string with type of Module
%                .family  - string with family of Module
%                .species - string with species of Module
%                .context - string with context of Module
%        sSpecVersion - string with specification version number
%      sVersionModule - string with module version number
%            xTreeOrg - structure of original Module XML
%
% Outputs:
%   xModule - structure with fields of DIVe Module XML header line
%
% Example:
%   xModule = dstModuleHeaderGen(struct('name',{'std'},'type',{'dummy'},'family',{'simple'},'species',{'test'},'context',{'phys'}),...
%                   '1.0','1.0',dsxRead('c:\someWorkspace\Content\phys\test\simple\dummy\Module\std\std.xml'))

% initialization
sDescription = '';

% special settings for sMaxCosimStepsize and description
if exist('xTreeOrg','var') && isfield(xTreeOrg,'Module') && ~isempty(xTreeOrg)
    sDescription = xTreeOrg.Module.description;
    sMaxCosimStepsize = xTreeOrg.Module.maxCosimStepsize;
elseif strcmp(xModule.family,'mil')
    sMaxCosimStepsize = '0.005';
elseif strcmp(xModule.species,'eng') && strcmp(xModule.family,'detail')
    sMaxCosimStepsize = '0.005';
elseif strcmp(xModule.species,'mcm') && strcmp(xModule.family,'sil')
    sMaxCosimStepsize = '0.005';
elseif strcmp(xModule.species,'eats') && ~isempty(regexp(xModule.family,'^exact','once'))
    sMaxCosimStepsize = '0.1';
else
    sMaxCosimStepsize = '0.01';
end

% assign values
xModule.xmlns = 'http://www.daimler.com/DIVeModule';
xModule.xmlns0x3Axsi = 'http://www.w3.org/2001/XMLSchema-instance';
xModule.xsi0x3AschemaLocation = ['\\emea.corpdir.net\E019\prj\TG\DIVE\100_doc\110_specification\DIVe_v'...
    strrep(sSpecVersion,'.','') '\XMLSchemes\DIVeModule.xsd'];

% resort for original sorting
xModule = orderfields(xModule,{'xmlns','xmlns0x3Axsi','xsi0x3AschemaLocation',...
                               'name','type','family','species','context'});
xModule.specificationVersion = sSpecVersion;
xModule.moduleVersion = sVersionModule;
xModule.maxCosimStepsize = sMaxCosimStepsize;
xModule.description = sDescription;
return

% =========================================================================

function [sAuthoring,sExecute,sUpComp] = dstModuleToolGet(sPathModelSet,sFileMain)
% DSTMODULETOOLGET create execution and authoring tool information
% for DIVe ModelSet
%
% Syntax:
%   [sAuthoring,sExecute,sUpComp] = dstModuleToolGet(sPathModelSet,sFileMain)
%
% Inputs:
%   sPathModelSet - string with path to folder of ModelSet
%       sFileMain - string wiht main filename of ModelSet (incl. extension)
%
% Outputs:
%   sAuthoring - string with authoring tool (e.g. Simulink_w32_R2010b)
%     sExecute - string with execution tool (e.g. Simulink_w32_R2010b)
%      sUpComp - string upward compatibility flag ('0' or '1')
%
% Example: 
%   sPathModelSet = 'C:\dirsync\06DIVe\03Platform\com\DIVe\Content\ctrl\mcm\sil\M12_51_00_03_EU_HDEP\Module\std\sfcn_w64_R2014a', sFileMain = 'mcm_sil_M12_51_00_03_std.mdl',
%   [sAuthoring,sExecute,sUpComp] = dstModuleToolGet(sPathModelSet,sFileMain)

% init output 
sAuthoring = '';
sExecute = '';
sUpComp = '0';

% get content of modelset directory
cPathModelSet = pathparts(sPathModelSet);
cFile = dirPattern(sPathModelSet,'*','file');
cExtension = regexp(cFile,'\.\w+$','match','once');

% determine Simulink version
cSimulink = cFile(ismember(cExtension,{'.mdl','.slx','.mexw32','.mexw64'}));
if ~isempty(cSimulink)
    if ismember(sFileMain(end-3:end),{'.mdl','.slx'})
        sVersion = getFileVersionSimulink(fullfile(sPathModelSet,sFileMain));
        sVersionDig = versionAliasMatlab(sVersion);
    else
        sVersion = '';
        sVersionDig = '7.5';
    end

    % determine Matlab/Simulink bittype
    if any(strcmpi('.mexw32',cExtension))
        sBit = 'w32';
        sUpComp = '0';
    elseif any(strcmpi('.mexw64',cExtension))
        sBit = 'w64';
        sUpComp = '0';
    else % no mex files
        sUpComp = '1';
        if verLessThanOther(sVersionDig,'9.0')
            % assume open Simulink model which works in 32 and 64 bit
            sBit = 'w3264';
        else
            sBit = 'w64'; % only 64bit MATLAB for R2015b and above
        end
    end
    
    % default values Simulink
    sVersionExtension = regexp(cPathModelSet{end},'_\w+$','match','once');
    sAuthoring = strGlue({'Simulink',sBit,sVersion},'_');
    if strcmp(cPathModelSet{end},'open') % open
        sExecute = strGlue({'Simulink',sBit,sVersion},'_');
        if ismember(cPathModelSet{end-5},{'mcm','acm'}) ...
                && strcmp(cPathModelSet{end-4},'mil')
            sExecute = 'Simulink_w32_R2010bSP1';
        end
    elseif strcmp(cPathModelSet{end}(1:4),'sfcn') % s-function
        sExecute = ['Simulink' sVersionExtension];
    else % neither open nor sfcn (?!? - use for non Simulink)
        sExecute = 'Simulink';
    end
    if ismember(cPathModelSet{end-5},{'mcm','acm'}) ...
            && strcmp(cPathModelSet{end-4},'sil')
        sUpComp = '1';
    end
end
    
% special values for wrapped models
if any(strcmpi('.sil',cExtension))
    % Silver function unit
    sAuthoring = 'Silver';
    sExecute = 'Silver';
    sUpComp = '1';

elseif any(strcmpi('.isx',cExtension))
    % SimulationX function unit
    % determine isx-file
    nIsx = find(strcmpi(cExtension,'.isx'));
    if isempty(nIsx)
        sVersion = 'SimulationX';
    else
        sVersion = getFileVersionSimulationX(fullfile(sPathModelSet,cFile{nIsx(1)}));
    end

    sAuthoring = sVersion;
    sExecute = sVersion;
    sUpComp = '1';
    
elseif strcmp(cPathModelSet{end},'open') ...
        && any(strcmpi(cExtension,'.zip'))
    % zip-file containing Simpack Model information
    
    % determine zip-file
    nZip = find(strcmpi(cExtension,'.zip'));
    if isempty(nZip)
        return % no changes on settings necessary
    end
    
    % determine version string (e.g. w64_20190001)
    sSimpackVersion = getFileVersionSimpack(fullfile(sPathModelSet,cFile{nZip(1)}));
    
    if ~isempty(sSimpackVersion)
        % Simpack model
        sAuthoring = ['Simpack_' sSimpackVersion];
        sExecute = ['Simpack_' sSimpackVersion];
        sUpComp = '0';
    end
    
elseif strncmp(cPathModelSet{end},'silver',6) || ...
        (any(strcmpi('.dll',cExtension)) && ...
         ~(any(strcmpi('.mdl',cExtension)) || any(strcmpi('.slx',cExtension))))
    % Silver dll (assumption) - contains dll file, but no mdl/slx files
    sTool = dstSilverVersionGet;
    sAuthoring = sTool;
    sExecute = sTool;
    sUpComp = '1';
    
elseif strncmp(cPathModelSet{end},'fmu',3) ...
        && any(strcmpi(cExtension,'.fmu'))
    
    % determine fmu-file
    nFmu = find(strcmpi(cExtension,'.fmu'));
    if isempty(nFmu)
        return % no changes on settings necessary
    end
    
    % determine version string (e.g. SimulationX_3_7_0_34479, Simpack_2019x_win64)
    [sAuthoring,sExecute] = getFileVersionFmu(fullfile(sPathModelSet,cFile{nFmu(1)}));
    sUpComp = '0';
end
return

% =========================================================================

function bLess = verLessThanOther(sVer1,sVer2)
% VERLESSTHANOTHER compare version strings (dot separated) against each
% other.
%
% Syntax:
%   bLess = verLessThanOther(sVer1,sVer2)
%
% Inputs:
%   sVer1 - string with version notation e.g. '7.11'
%   sVer2 - string with version notation e.g. '7.11' 
%
% Outputs:
%   bLess - boolean (1x1) if first string is an older version than the
%           second string
%
% Example: 
%   bLess = verLessThanOther('7.3','7.11')
%   bLess = verLessThanOther('8.3','7.11')
%   bLess = verLessThanOther('8.3','8.3')
%
% See also: strsplitOwn
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2018-10-1

% init output
bLess = [];

% decompose strings
cVer1 = strsplitOwn(sVer1,'.');
cVer2 = strsplitOwn(sVer2,'.');

% compare elements
bEqual = true;
nCompare = 0;
nMaxEval = min(numel(cVer1),numel(cVer2));
while bEqual && nCompare<nMaxEval
    nCompare = nCompare+1; % inrecement for verson sublevel
    
    v1 = str2double(cVer1{nCompare});
    v2 = str2double(cVer2{nCompare});
    if v1 < v2
        bLess = true;
        bEqual = false;
    elseif v1 == v2
        bLess = false;
    elseif v1 > v2
        bLess = false;
        bEqual = false;
    end
end
return

% =========================================================================

function [xPort,xSource] = dstModulePortListGet(cPathMdl,bSignalListNetwork)
% DSTMODULEPORTLISTGET get the ports of the DIVe Signallist from the root
% of the model path or by user selection or by the DIVe network share.
%
% Syntax:
%   [xPort,xSource] = dstModulePortListGet(cPathMdl,bSignalListNetwork)
%
% Inputs:
%   cPathMdl - cell (1xn)
%   bSignalListNetwork - boolean on dialogue for DIVe signal list from
%                        network drive
%
% Outputs:
%     xPort - structure with fields:
%   xSource - structure with fields of dbread from DIVe_signals.xlsx :
%            ... (name, location, description)...
%          subset - structure with fields:

%            name: 'DIVeSignalsPorts'
%        location: [1×1 struct]
%     description: ''
%           field: {1×29 cell}
%           value: {6852×29 cell}

%
% Example:
%   xPort = dstModulePortListGet(cPathMdl,bSignalListNetwork)

% try to find signal list in path (comfort functionality
sFilePathSignal = '';
for nIdxFolder = 0:min(11,numel(cPathMdl)-1) % search path to specified model
    cFileSignal = dirPattern(fullfile(cPathMdl{1:end-nIdxFolder}),'DIVe_signals.*','file');
    if ~isempty(cFileSignal)
        if ismember('DIVe_signals.mat',cFileSignal) % prio1 mat-file
            sFilePathSignal = fullfile(cPathMdl{1:end-nIdxFolder},'DIVe_signals.mat');
            break
        elseif ismember('DIVe_signals.xlsx',cFileSignal) % prio2 xlsx-file
            sFilePathSignal = fullfile(cPathMdl{1:end-nIdxFolder},'DIVe_signals.xlsx');
            break
        end
    end
end

% backup use signal list from same workspace
sPathNetwork = fullfile(fileparts(fileparts(mfilename('fullpath'))),'Interface','DIVe_signals.xlsx');
if isempty(sFilePathSignal) 
    if exist(sPathNetwork,'file')
        if bSignalListNetwork
            % function argument says ok for network
            sButton = 'Ok';
        else
            % ask user
            sButton = questdlg({'Do you want to use latest DIVe signal list from same workspace',...
                '...\Interfacing\DIVe_signals.xlsx'},...
                'DIVe signal list','Ok','No','Ok');
        end
        if strcmp(sButton,'Ok')
            sFilePathSignal = sPathNetwork;
        end
    else
        % try to get signal list from MATLAB path
        cMPath = which('-all', 'DIVe_signals.xlsx');
        if ~isempty(cMPath)
            sFilePathSignal = cMPath{1};
            if numel(cMPath) > 1
                fprintf(2,['Warning - dstXmlModule: several <DIVe_signals.xlsx> '...
                           'were found in MATLAB search path! First hit was taken: %s\n'],...
                           sFilePathSignal);
            end

        end
    end
end

% get signal list by user selection
if isempty(sFilePathSignal)
    [sFileSignal,sPathSignal] = uigetfile( ...
        {'*.xls;*.xlsx;*.xlsb;*.xlsm;*.mat','Excel-files (*.xls)'; ...
        '*.*',  'All Files (*.*)'}, ...
        'Select DIVe signal list',...
        'MultiSelect','off');
    if isnumeric(sFileSignal) && sFileSignal == 0
        return % user pressed cancel
    else
        sFilePathSignal = fullfile(sPathSignal,sFileSignal);
    end
end

% get info on Excel sheets in file
xSource = dbread(sFilePathSignal,1); % read directly first sheet
xPort = dbColumn2Struct(xSource(1).subset(1).field(1,:),xSource(1).subset(1).value);
return

% =========================================================================

function sFolderSfcn = dstFolderMatlabVersionNext(cModelSet)
% DSTFOLDERMATLABVERSIONNEXT determine s-function ModelSet folder name of
% next matching Matlab version.
%
% Syntax:
%   sFolderSfcn = dstFolderMatlabVersionNext(cModelSet)
%
% Inputs:
%   cModelSet - cell (1xn) with strings of ModelSets
%
% Outputs:
%   sFolderSfcn - string with name of sfcn ModelSet with next matching
%                 Matlab version. Empty if there is no matching version.
%
% Example: 
%   sFolderSfcn = dstFolderMatlabVersionNext({'open','fmu10','sfcn_w32_R2010bSP1','sfcn_w64_R2014a'})

% details of this version
sMatlabBitType = regexprep(computer('arch'),'^win','w'); % returns 'w32' or 'w64'
xVersion = ver('MATLAB');
sMatlabRelease = xVersion.Release(2:end-1); % remove brackets from '(R2010bSP1)'

% determine next matching ModelSet
sVersionThis = ['sfcn_' sMatlabBitType '_' sMatlabRelease];
if any(strcmp(sVersionThis,cModelSet))
    % use this specific MATLAB version
    sFolderSfcn = sVersionThis;
else
    % determine next matching Matlab version of available ModelSet
    % details of ModelSets
    cVersion = regexp(cModelSet,'(?<=^sfcn_w\d+_)R\d{4}\w','match','once');
    cBit = regexp(cModelSet,'(?<=^sfcn_)w\d+(?=_R\d{4}\w)','match','once');
    
    % compare this Version against ModelSets
    cVersionNum = cell(size(cModelSet));
    bUse = false(size(cModelSet));
    for nIdxSet = 1:numel(cModelSet)
        if ~isempty(cVersion{nIdxSet})
            cVersionNum{nIdxSet} = versionAliasMatlab(cVersion{nIdxSet});
            bUse(nIdxSet) = strcmp(cBit{nIdxSet},sMatlabBitType) && ...
                ~verLessThanMATLAB(cVersionNum{nIdxSet});
        end
    end
    
    % take next or failure exit
    if any(bUse)
        % automatically use next matching version
        nUse = find(bUse);
        sFolderSfcn = cModelSet{nUse(1)};
    else
        % no matching version available
        sFolderSfcn = '';
    end
end
return

% =========================================================================

function [sTool,sSet] = dstSilverVersionGet
% DSTSILVERVERSIONGET determine the installed Silver version and generate
% the ModelSet string and Execution/Authoring Tool string.
%
% Syntax:
%   [sTool,sSet] = dstSilverVersionGet
%
% Inputs:
%
% Outputs:
%   sTool - string of Execution/Authoring tool e.g. Silver_030520
%    sSet - string of ModelSet e.g. silver_dll_w32
%
% Example: 
%   [sTool,sSet] = dstSilverVersionGet

% query silver via system shell
[nStatus,sMsg] = system('silver --version');

if nStatus
    % query failed
    sTool = 'Silver';
    sSet = 'silver_dll';
else
    % parse version from feedback string (differs between old version 3/4 and new FlexLM Silver
    sVersion = strtrim(regexprep(sMsg,{'[A-Z]\-','\(.*\)'},{'',''})); % remove release type identifier of versions newer than silver 4
    cVersion = strsplitOwn(sVersion,{'.','-'});
    nVersion = cellfun(@str2double,cVersion);

    % determine bit type
    if nVersion(1) > 3
        sBit = 'w64';
    else
        sBit = 'w32';
    end
    % create strings
    sTool = sprintf('Silver_%02i%02i%02i',nVersion);
    sSet = sprintf('silver_dll_%s',sBit);
end

return

% =========================================================================

function xDataSet = dstDataSetSort(xDataSet,cExpression)
% DSTDATASETSORT resort DataSet structure vector according priority setting of silent interface.
%
% Syntax:
%   xDataSet = dstDataSetSort(xDataSet,cExpression)
%
% Inputs:
%      xDataSet - structure (1xn) with fields: 
%       .className - string with className instance
%       ...
%   cExpression - cell (mx2) 
%
% Outputs:
%      xDataSet - structure (1xn) resorted: 
%       ...
%
% Example: 
%   xDataSet = dstDataSetSort(xDataSet,cExpression)

% resort data sets via silent interface
bDataSort = strcmp('sortPrioDataSet',cExpression(:,1)); % check for priority cell
if any(bDataSort)
    %resolve regular expression pattern to be used
    cPrio = strtrim(cExpression{bDataSort,2});
    cDataSetName = {xDataSet.className};
    nSelection = dstSortPrio(cPrio,cDataSetName,1:numel(cDataSetName)); % resort selection
    xDataSet = xDataSet(nSelection);
end
return

% =========================================================================

function nSelection = dstSortPrio(cPrio,cSet,nSelection)
% DSTSORTPRIO resorts a ID selection vector of a cell of strings so that all
% strings matching the priority strings are at the front of the ID
% selection vector.
%
% Syntax:
%   nSelection = dstSortPrio(cPrio,cSet,nSelection)
%
% Inputs:
%        cPrio - cell (1xm) of strings with priority entries 
%         cSet - cell (1xn) of strings with set (only selected elements)
%   nSelection - integer (1xn) with IDs of selected set elements
%
% Outputs:
%   nSelection - integer (1x1) with IDs of selected set elements re-ordered
%
% Example: 
%   nSelection = dstSortPrio({'bla','init','log','zGlob','blub'}, {'zGlob','colb','init','log','other','calb'},[1,2,3,4,6])

[bSetInPrio,nIdPrio] = ismember(cSet,cPrio); % get sort order of Support sets in Prio

nIdSel = 1:numel(nSelection); % base vector of selection elements
nIdSelRed = nIdSel(bSetInPrio); % selection IDs which can be found in prio cell
nIdPrioRed = nIdPrio(bSetInPrio); % prio elements, which are contained in selection

[nIdPrioRedSort,nSort_nIdPrioRed] = sort(nIdPrioRed); %#ok<ASGLU> % sort prio elements found selection elements
nIdSelRedSorted = nIdSelRed(nSort_nIdPrioRed); % resort selection IDs which are in prio cell according prio cell order

nSelection = [nSelection(nIdSelRedSorted) nSelection(~bSetInPrio)]; % re-combine prio part and non-prio part
return

% =========================================================================

function [xModule,cClass] = dstSubspeciesDataSetExpansion(xModule,cModulePath)
% DSTSUBSPECIESSET expands the interface section of a Module XML by
% multiple DataSet classNames for specified DataSet classTypes or to set
% the isSubspecies attribute.
% This file is intended for scripting use rather than interactive use.
%
% Syntax:
%   [xModule,cClass] = dstSubspeciesDataSetExpansion(xModule,cModulePath)
%
% Inputs:
%      xModule - structure with XML metadata of DIVe Module with fields
%         .Implementation
%           .SupportSet
%         .Interface
%           .DataSet
%   cModulePath - cell (1xn) with strings of folder of Module path on file
%                 system
%
% Outputs:
%      xModule - structure with XML metadata of DIVe Module
%       cClass - cell (mx2) with
%                 {:,1} string with DataSet classType e.g. 'axle'
%                 {:,2} cell of strings with DataSet classNames for this
%                       DataSet classType e.g. {'axle1','axle2'}
%
% Example: 
%   dstSubspeciesSet(sFileXml,cClass,cSubspecies)
% 
%   % example phys.mec.pointmass.generic to automatically generate
%   % className and issubspecies entries
%   % File in SupportSet "subspecies" with name <species>_subspecies.m contains: 
%   cClass = {'aero',{'aero'};...
%        'axle',{'axle1','axle2','axle3','axle4','trailerAxle1','trailerAxle2','trailerAxle3'};...
%        'brk',{'brk1','brk2','brk3','brk4','trailerBrk1','trailerBrk2','trailerBrk3'};...
%        'clt',{'clt'};...
%        'eng',{'eng'};...
%        'ret',{'ret'};...
%        'sht',{'shtF','shtR'};...
%        'tfc',{'tfc'};...
%        'tx',{'tx'};...
%        'wheel',{'trailerWheel1','trailerWheel2','trailerWheel3','wheel1','wheel2','wheel3','wheel4'}};
% 
%        cClass - cell (mx2) with
%                 {:,1} string with DataSet classType e.g. 'axle'
%                 {:,2} cell of strings with DataSet classNames for this
%                       DataSet classType e.g. {'axle1','axle2'}
%                       appearance order of DataSet classType and className
%                       entries determines the order in the Module XML (non
%                       listed DataSet classTypes will be in front)
%
% See also: dstXmlModule
%
%   Date: 2020-09-15

%% check input
if ~isfield(xModule,'Implementation')
    error('dstSubspeciesSet:noImplementation','The passed Module XML structure has no Implementation field');
end
if ~isfield(xModule,'Interface')
    error('dstSubspeciesSet:noInterface','The passed Module XML structure has no Interface field');
end
if ~isfield(xModule.Interface,'DataSet')
    error('dstSubspeciesSet:noInterface','The passed Module XML structure has no DataSet field');
end

%% determine SupportSet for subspecies definiton
if isfield(xModule.Implementation,'SupportSet') && any(strcmp('subspecies',{xModule.Implementation.SupportSet.name}))
    cLevel = {'species','family','type'};
    bSubspecies = strcmp('subspecies',{xModule.Implementation.SupportSet.name});
    nLevel = find(strcmp(xModule.Implementation.SupportSet(bSubspecies).level,cLevel));
    sPathSupport = fullfile(cModulePath{1:end-5+nLevel},'Support','subspecies');
    if ~exist(sPathSupport,'dir')
        error('dstSubspeciesSet:supportFolderNotFound',...
            'The folder of SupportSet "subspecies" is not on the file system: %s',sPathSupport);
    end
    
    % get file with definiton of classNames
    cFile = dirPattern(sPathSupport,'*subspecies.m','file');
    if isempty(cFile)
         error('dstSubspeciesSet:subspeciesFileNotFound',...
            'A subspecies definition file (*subspecies.m) was not found in folder: %s',sPathSupport);
    end
    sFileSubspecies = fullfile(sPathSupport,cFile{1});
    xData = dpsLoadStandardFile(sFileSubspecies);
    cClass = xData.cClass;
else
    cClass = cell(0,2);
    return
end

%% add DataSet className entries
% loop over DataSets of Module
xDataSet = xModule.Interface.DataSet;
xDataSetNew = structInit(fieldnames(xDataSet(1)));
for nIdxSet = 1:numel(xDataSet)
    % check className entries for classType of this DataSet
    bClassInSpec = strcmp(xDataSet(nIdxSet).classType,cClass(:,1));
    if any(bClassInSpec)
        % get new classNames for this classType
        cClassName = cClass{bClassInSpec,2};
        % loop over classNames of this DataSet classType
        for nIdxName = 1:numel(cClassName)
            % check existence of className
            bName = strcmp(cClassName{nIdxName},{xDataSet.className});
            bTransfer = strcmp(cClassName{nIdxName},{xDataSetNew.className});

            if ~any(bName) % className does not exist yet
                % create className entry
                xDataSetNew(end+1) = xDataSet(nIdxSet); %#ok<AGROW>
                xDataSetNew(end).className = cClassName{nIdxName};
                xDataSetNew(end).isSubspecies = '1'; % ensure isSubspecies setting
                
            else % className exists already in original file
                % check singularity
                if sum(bName) > 1
                    nName = find(bName);
                    fprintf(2,['CAUTION (dstSubspeciesSet): multiple entries ' ...
                        'of className "%s" found in input file "%s" ' ...
                        '- this is not DIVe conform!\n'],cClassName{nIdxName},...
                        sFileSubspecies);
                    bName = nName(1);
                end
                
                if ~any(bTransfer)
                    % transfer DataSet className Entry
                    xDataSetNew(end+1) = xDataSet(bName); %#ok<AGROW>
                    xDataSetNew(end).isSubspecies = '1'; % ensure isSubspecies setting
                end
            end % if
        end % for classNames
        
    else % no classNames defined - transfer DataSet entry
        xDataSetNew(end+1) = xDataSet(nIdxSet); %#ok<AGROW>
    end % if spec for classType exists
end % for DataSets
%% update XML structure
xModule.Interface.DataSet = xDataSetNew;
return
