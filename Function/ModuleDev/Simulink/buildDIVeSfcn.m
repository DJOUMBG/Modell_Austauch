function bStatus = buildDIVeSfcn(sFileXml)
% BUILDDIVESFCN  build a masked s-function from a simple masked Simulink subsystem of DIVe
% with DIVe standard data.
% 
% Syntax:
%   bStatus = buildDIVeSfcn
%   bStatus = buildDIVeSfcn(sFileXml)
%
% Inputs:
%   sFileXml - string with path of DIVe Module XML file
%              or path of DIVe Module variant folder
%
% Outputs:
%   bStatus - boolean (1x1) if s-function generation terminated successful
%
% Example: 
%   buildDIVeSfcn(sFileXml)
%   buildDIVeSfcn('C:\dirsync\06DIVe\01Content\phys\eng\simple\transient\Module\std\std.xml')
%   buildDIVeSfcn('C:\dirsync\06DIVe\01Content\ctrl\mcm\rebuild\MCM21_m04_54\Module\std\std.xml')
%   buildDIVeSfcn('C:\dirsync\06DIVe\01Content\ctrl\mcm\rebuild\MR2_r24\Module\std\std.xml')
%   buildDIVeSfcn('C:\dirsync\06DIVe\01Content\phys\eng\simple\transient\Module\std')
%
%  #Testcase1:
%     addpath(genpath('c:\dirsync\DIVeScripts\'))
%     buildDIVeSfcn('D:\rafrey5\sfcn\Content\bdry\env\air\std\Module\airConst\airConst.xml')
%     dmdModuleTest('D:\rafrey5\sfcn\Content\bdry\env\air\std\Module\airConst','sfcn_w64_R2016a','FixedStep','0.01')
%     dmdModuleTest('D:\rafrey5\sfcn\Content\bdry\env\air\std\Module\airConst','sfcn_w64_R2016a','FixedStep','0.005')
% 
% See also: dirPattern, dmdModuleTest, dpsLoadStandard, dsxRead,
% fullfileSL, pathparts, slcModelSolverOptions, structUnify 
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2014-10-22

% init output
bStatus = false;

% input check
if nargin == 0
    [sFileXmlName,sFileXmlPath] = uigetfile( ...
        {'*.xml','DIVe Module Description (xml)'; ...
        '*.*',  'All Files (*.*)'}, ...
        'Open Module Description (*.xml)',...
        'MultiSelect','off');
    if isequal(sFileXmlName,0) % user chosed cancel in file selection popup
        return
    else
        sFileXml = fullfile(sFileXmlPath,sFileXmlName);
    end
else
    if exist(sFileXml,'dir') == 7
        [sRest,sFolder] = fileparts(sFileXml); %#ok<ASGLU>
        sFileXml = fullfile(sFileXml,[sFolder '.xml']);
        sMsgAdd = '\nAssuming a Module variant folder as input failed as well.';
    else
        sMsgAdd = '';
    end
    if ~exist(sFileXml,'file')
        error('buildDIVeSfcn:fileNotFound','The specified file does not exist: %s%s',sFileXml,sMsgAdd);
    end
end

% load module XML description
sFileXmlPath = fileparts(sFileXml);
cPathXml = pathparts(sFileXml);
xTree = dsxRead(sFileXml);

% adapt solver stepsize to atomic subsystem or Module XML
sSampleTime = '0.005';
% derive from Module XML
if isfield(xTree.Module,'maxCosimStepsize')
    sSampleTime = xTree.Module.maxCosimStepsize;
end

% determine mdl/slx according MATLAB version
bOpen = ismember({xTree.Module.Implementation.ModelSet.type},'open');
xModelSetOpen = xTree.Module.Implementation.ModelSet(bOpen);
if verLessThanMATLAB('8.0')
    sModelExtension = '.mdl';
else
    sModelExtension = '.slx';
end
bIsMain = ismember({xModelSetOpen.ModelFile.isMain},'1');
sModelFile = xModelSetOpen.ModelFile(bIsMain).name;
sModelName = sModelFile(1:end-4);

% prepare directories
sMatlabBitType = regexprep(computer('arch'),'^win','w'); % returns 'w32' or 'w64'
xVersion = ver('MATLAB');
sMatlabRelease = xVersion.Release(2:end-1);
sPathModel = fullfile(sFileXmlPath,'open');
sPathCreate = fullfile(sPathModel,['createSfcn_' sMatlabBitType '_' sMatlabRelease]);
if exist(sPathCreate,'dir')
    clear mex; %#ok<CLMEX> unload for restart after failure
    if verLessThanMATLAB('8.3')
        recycle(sPathCreate);
    else % changed command since MATLAB R2014a
        recycle('on');
        rmdir(sPathCreate,'s');
    end
end
mkdir(sPathCreate); % make directory for sfunction creation

% determine masked subsystem for s-function generation
uiopen(fullfile(sPathModel,sModelFile),true); % open library
cBlockMask = find_system(sModelName,'SearchDepth',1,'BlockType','SubSystem','Mask','on');
if isempty(cBlockMask)
    % Model without parameter doesn't have a mask
    cBlockMask = find_system(sModelName,'SearchDepth',1,'BlockType','SubSystem');
end
sBlockMask = cBlockMask{1};
[sTrash,sBlock] = fileparts(sBlockMask); %#ok<ASGLU>

% create Simulink model for code generation
sPathOrg = pwd;
cd(sPathCreate);
new_system([sModelName '_create']); % create new model for code generation 
open_system([sModelName '_create']);
add_block(sBlockMask,fullfileSL([sModelName '_create'],sBlock)); % copy of open model block
set_param(fullfileSL([sModelName '_create'],sBlock),'LinkStatus','none'); % break link from library
close_system(sModelName,0); % close library
save_system([sModelName '_create'],sModelName); % save model under library name in creation directory
dpsModelSolverOptions(sModelName,'FixedStep01',sSampleTime,'10')
% set_param(sModelName,'Lock','off'); % unlock library

% derive from atomic subsystem properties, if set
cBlock = find_system(sModelName,'SearchDepth',1,'BlockType','SubSystem');
if numel(cBlock) == 1 % only 1 Block in System
    if strcmp(get_param(cBlock{1},'TreatAsAtomicUnit'),'on') % treat as atomic unit
        sSampleTime = get_param(cBlock{1},'SystemSampleTime'); % sample time
        if ~strcmp(sSampleTime,'-1')
            set_param(sModelName,'FixedStep',sSampleTime);
        end
    end
end

% change parameter names in subsystem mask
% sPrefixStruct = ['sMP.' xTree.Module.context '.' xTree.Module.species '.'];
sPrefixVar = ['sMP_' xTree.Module.context '_' xTree.Module.species '_'];
cParameterOrg = get_param(sBlockMask,'MaskValues');
if ~isempty(cParameterOrg)
    % transfer structure names to a single variable name - better than
    % replacing defined structure of e. g. sMP.phys.eng. as IO initialization
    % parameters are covered as well e.g. sMP.phys.eng.out.T_4_gas
    cParameter = regexprep(cParameterOrg,'\.','_');
    set_param(sBlockMask,'MaskValues',cParameter);
else
    cParameter = cell(0,1);
end

% add SupportSet pathes to Matlab path
bdsSupportSetPathAdd(xTree.Module,sFileXmlPath);

% load parameters from all DataSet DataFiles
cLevel = {'species','family','type'};
xData = struct;
if isfield(xTree.Module.Interface,'DataSet')
    for nIdxDataSet = 1:numel(xTree.Module.Interface.DataSet)
        % determine location of data set
        [bTF,nLevel] = ismember(xTree.Module.Interface.DataSet(nIdxDataSet).level,cLevel); %#ok<ASGLU>
        sIsSubSpecies = ''; %#ok<NASGU> reset value
        sSharedDataClassName = ''; %#ok<NASGU> reset value
        sIsSubSpecies = xTree.Module.Interface.DataSet(nIdxDataSet).isSubspecies;
        sFileXmlData = fullfile(cPathXml{1:end-6+nLevel},'Data',...
            xTree.Module.Interface.DataSet(nIdxDataSet).classType,...
            xTree.Module.Interface.DataSet(nIdxDataSet).reference,...
            [xTree.Module.Interface.DataSet(nIdxDataSet).reference,'.xml']);
        % load data
        xDataAdd = dpsLoadStandard(sFileXmlData);
        % if the data set has isSubSpecies = 1
        if str2double(sIsSubSpecies) == 1
            % get the name of sharedDataClassName
            sSharedDataClassName = xTree.Module.Interface.DataSet(nIdxDataSet).className;
            cOldFields = fieldnames(xDataAdd);
            cNewFields = cellfun(@(x) strcat(sSharedDataClassName,'_',x),cOldFields,'UniformOutput',false);
            % rename field names with <dataClassName>_fieldName
            for nIdx = 1:numel(cOldFields)
                xDataAdd.(cNewFields{nIdx}) = xDataAdd.(cOldFields{nIdx});
            end
            xDataAdd = rmfield(xDataAdd,cOldFields);
        end
        xData = structUnify(xData,xDataAdd);
    end
end

if isfield(xTree.Module.Interface,'DataSetInitIO')
   % load initIO data
    sFileXmlData = fullfile(cPathXml{1:end-3},'Data',...
    xTree.Module.Interface.DataSetInitIO.classType,...
    xTree.Module.Interface.DataSetInitIO.reference,...
    [xTree.Module.Interface.DataSetInitIO.reference,'.xml']);
    % load data
    xDataAdd = dpsLoadStandard(sFileXmlData);
    xData = structUnify(xData,xDataAdd);
end

% transfer parameters to workspace with correct extension
assignin('base','xData',xData);
cData = fieldnames(xData);
for nIdxParameter = 1:numel(cData) % standard parameters
    if ~ismember(cData{nIdxParameter},{'in','out'})
        assignin('base',[sPrefixVar cData{nIdxParameter}],xData.(cData{nIdxParameter}));
        eval([sPrefixVar cData{nIdxParameter} ' = xData.(cData{nIdxParameter});']);
    end
end
if isfield(xData,'in') % input signal initial values
    cDataIn = fieldnames(xData.in);
    for nIdxParameter = 1:numel(cDataIn)
        assignin('base',[sPrefixVar 'in_' cDataIn{nIdxParameter}],xData.in.(cDataIn{nIdxParameter}));
        eval([sPrefixVar 'in_' cDataIn{nIdxParameter} ' = xData.in.(cDataIn{nIdxParameter});']);
    end
end
if isfield(xData,'out') % output signal initial values
    cDataOut = fieldnames(xData.out);
    for nIdxParameter = 1:numel(cDataOut)
        assignin('base',[sPrefixVar 'out_' cDataOut{nIdxParameter}],xData.out.(cDataOut{nIdxParameter}));
        eval([sPrefixVar 'out_' cDataOut{nIdxParameter} ' = xData.out.(cDataOut{nIdxParameter});']);
    end
end

% define tunable parameters for Real Time Workshop
sVarTunable = '';
sVarStorageClass = '';
sVarTypeQualifier = '';
for nIdxParameter = 1:numel(cParameter)
    sVarTunable = [sVarTunable cParameter{nIdxParameter} ',']; %#ok<AGROW>
    sVarStorageClass = [sVarStorageClass 'ImportedExtern,']; %#ok<AGROW> 'ImportedExtern','ExportedGlobal'
    sVarTypeQualifier = [sVarTypeQualifier ',']; %#ok<AGROW> <empty>,const
end
sVarTunable = sVarTunable(1:end-1);
sVarStorageClass = sVarStorageClass(1:end-1);
sVarTypeQualifier = sVarTypeQualifier(1:end-1);
set_param(bdroot(sBlockMask),'TunableVars', sVarTunable)
set_param(bdroot(sBlockMask),'TunableVarsStorageClass', sVarStorageClass)
set_param(bdroot(sBlockMask),'TunableVarsTypeQualifier',sVarTypeQualifier)
save_system(sModelName)

% compile s-function
try
    if verLessThanMATLAB('8.0')
        % R2010b
        rtwprivate('ssgensfun', 'Create', sBlockMask); % open dialogue
        rtwprivate('ssgensfun', 'Build'); % create S-Function
    else
        % R2012b ff
        coder.internal.ssGenSfun('Create',sBlockMask) % open dialogue
        coder.internal.ssGenSfun('Build',sBlockMask) % create S-Function
    end
catch %#ok<CTCH>
    disp('S-Function build process failed!');
    xError = lasterror; %#ok<LERR>
    save(fullfile(sPathCreate,'xErrorBuild.mat'),'xError')
    close_system(sModelName,0);
    cd(sPathOrg);
    return
end

% path to new generated block
% sBlockMaskSfcn = fullfileSL('untitled',fileparts(sBlockMask));
sBlockMaskSfcn = fullfileSL('untitled',sBlock);

% close previous system
close_system(sModelName,0);
cd(sPathOrg);

% reset s-function mask parameters to structure 
cParameterSfcn = get_param(sBlockMaskSfcn,'MaskValues');
% cParameterSfcn(end-numel(cParameterOrg)+1:end) = cParameterOrg;
for nIdxParameter = 1:numel(cParameterSfcn)
    [bTF,nID] = ismember(cParameterSfcn{nIdxParameter},cParameter);
    if bTF
        cParameterSfcn{nIdxParameter} = cParameterOrg{nID};
    end
end
set_param(sBlockMaskSfcn,'MaskValues',cParameterSfcn);

% reset prompt strings of mask
cPrompt=get_param(sBlockMaskSfcn,'MaskPromptString');
cPrompt=regexprep(cPrompt,sPrefixVar,'');
set_param(sBlockMaskSfcn,'MaskPromptString',cPrompt);

% remove mask display entries to display port names
set_param(sBlockMaskSfcn,'MaskDisplay','');
set_param(sBlockMaskSfcn,'BackgroundColor','darkgreen');

% create library with sfcn block in sfcn directory
sPathSfcn = fullfile(sFileXmlPath,['sfcn_' sMatlabBitType '_' sMatlabRelease]);
mkdir(sPathSfcn);
new_system(sModelName,'library');
add_block(fullfileSL('untitled',sBlock),sBlockMask);
save_system(sModelName,fullfile(sPathSfcn,[sModelName sModelExtension]));
close_system('untitled',0);
close_system(sModelName,0);
% copy mexfile
copyfile(fullfile(sPathCreate,'*sf.mex*'),[sPathSfcn filesep]);

% delete create directory
clear mex; %#ok<CLMEX> unload to clear lock on directory
if verLessThanMATLAB('8.3')
    recycle(sPathCreate);
else % changed command since MATLAB R2014a
    recycle('on');
    rmdir(sPathCreate,'s');
end

%% test system
% doesn't work in general if module xml doesnot contain newly created
% models sets
% [bStatus,sModelName] = dmdModuleTest(sFileXml,['sfcn_' sMatlabBitType '_' sMatlabRelease]);
bStatus = true;

% delete autosave files
cFileDelete = dirPattern(sPathSfcn,'*.autosave','file');
for nIdxFile = 1:numel(cFileDelete)
    delete(fullfile(sPathSfcn,cFileDelete{nIdxFile}));
end

% close system
if bStatus
    close_system(sModelName,0);
end
return


% ==================================================================================================

function bdsSupportSetPathAdd(xModule,sPathModule)
% BDSSUPPORTSETPATHADD add pathes of Module's SupportSets to Matlab path.
%
% Syntax:
%   bdsSupportSetPathAdd(xModule)
%
% Inputs:
%   xModule - structure with fields of DIVe Module XML
%     .Implementation.SupportSet - structure with SuppportSets of Module
%   sPathModule - string with path of Module (where the XML is) in file system
%
% Outputs:
%
% Example: 
%   bdsSupportSetPathAdd(xModule)

if isfield(xModule.Implementation,'SupportSet') && ...
        ~isempty(xModule.Implementation.SupportSet)
    for nIdxSet = 1:numel(xModule.Implementation.SupportSet)
        % determine support set location
        xSet = xModule.Implementation.SupportSet(nIdxSet);
        sPathSupportSet = fullfile(dpsPathLevel(sPathModule,xSet.level),'Support',xSet.name);
        
        % add SupportSet path to Matlab environment
        addpath(sPathSupportSet);
    end
end
return

