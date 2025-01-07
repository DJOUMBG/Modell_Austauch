function [bStatus,sModelName,cPathAdd] = dmdModuleTest(sFileXml,sModelSet,sFileDat,cData,varargin)
% DMDMODULETEST test a single DIVe module with constant input from ref data.
% Create a test model of a module with the specified modelset library, its
% reference datasets and a constant input from the reference initIO
% dataset. Basic run of 10s, except stimuli are provided. Intended for
% formal check of one modelset of a DIVe module, its model, data and
% support sets - or for unit testing.
%
% Syntax:
%   dmdModuleTest(sFileXml,sModelSet)
%   dmdModuleTest(sFileXml,sModelSet,sFileDat)
%   dmdModuleTest(sFileXml,sModelSet,sFileDat,cData)
%   dmdModuleTest(sFileXml,sModelSet,sFileDat,cData,sPar,sValue)
%   [bStatus,sModelName,cPathAdd] = dmdModuleTest(sFileXml,sModelSet,...)
%
% Inputs:
%    sFileXml - string with absolute filepath of module xml file
%   sModelSet - string with model set name, if only one exists or empty
%               argument is provided, the first ModelSet is used, if
%               argument is omitted and more than one exists, user is asked
%               in dialogue
%    sFileDat - string with absolute filepath of a data source file
%               containing stimuli vectors for inports and a "time" vector,
%               all inports without stimuli are stuffed with constants from
%               initIO reference dataset variant, source file is read by
%               uniread
%       cData - cell with strings to define DataSet variant configuration
%               (nx1) - strings define DataSet className slots of Module
%                       to be selected manually/interactively
%               (nx2) - (:,1): string with DataSet className for configuration
%                       (:,2): string with DataSet variant for className
%                              slot, if empty interactive selection
%    varargin - cell with settings (solver + log) as parameter name and value pairs
%               'FixedStep' - string with solver stepsize, e.g. '0.005'
%               'sampleTime' - string with sampling rate e.g. '0.01'
%               'DataLoggingMaxPoints' - string with max log points e.g. '5000'
%               'Decimation' - (old) string with max log points e.g. '5000'
%               'Assertion' - boolean (true/false) if assertions on min/max and signal type should be applied
%               'timeEnd' - string with stop value or variable in workspace
%
% Outputs:
%      bStatus - boolean with test success status
%   sModelName - string with name of test model
%     cPathAdd - cell (1xm) with strings of pathes, which were added to the
%                Matlab path by dmdModuleTest (when output argument is
%                used, the Matlab path is not reset to pre-dmdModuleTest
%                state
%
% Example:
%   sXmlModule = 'c:\dirsync\08Helix\11d_main\com\DIVe\Content\phys\eng\simple\transient\Module\std\std.xml'
%   dmdModuleTest(sXmlModule)
%   dmdModuleTest(sXmlModule,'sfcn_w64_R2016a')
%   dmdModuleTest(sXmlModule,'sfcn_w64_R2016a','C:\temp\test_eng_simple.mat')
%   dmdModuleTest(sXmlModule,'sfcn_w64_R2016a','C:\temp\test_eng_simple.mat',{'mainData','OM471FE1'})
%   dmdModuleTest(sXmlModule,'sfcn_w64_R2016a','C:\temp\test_eng_simple.mat',{'mainData','OM471FE1'},'sampleTime','0.01')
%   dmdModuleTest(sXmlModule,'sfcn_w64_R2016a','C:\temp\test_eng_simple.mat',{'mainData','OM471FE1'},'FixedStep','0.001','sampleTime','0.01')
%   dmdModuleTest(sXmlModule,'sfcn_w64_R2016a','C:\temp\test_eng_simple.mat',{'mainData','OM471FE1'},'timeEnd','20','sampleTime','0.01')
%   dmdModuleTest(sXmlModule,'sfcn_w64_R2016a','',{},'Assertion',true)
%
% See also: dirPattern, dpsLoadStandard, dsxRead, fullfileSL, pathparts,
% slcAlignInOut, slcSetBlockPosition, structUnify
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2014-11-14

% init outputs
bStatus = false;
sModelName = '';

%% input check & fix
% path of xml file
if nargin < 1
    [sFileXmlName,sPathXml] = uigetfile( ...
        {'*.xml','DIVe Module Description (xml)'; ...
        '*.*',  'All Files (*.*)'}, ...
        'Open Module Description (*.xml)',...
        'MultiSelect','off');
    if isequal(sFileXmlName,0) % user chosed cancel in file selection popup
        return
    else
        sFileXml = fullfile(sPathXml,sFileXmlName);
    end
else
    if exist(sFileXml,'file') ~= 2
        % check for specified module folder
        [sTrash,sFolder] = fileparts(sFileXml); %#ok<ASGLU>
        if exist(fullfile(sFileXml,[sFolder '.xml']),'file')
            sFileXml = fullfile(sFileXml,[sFolder '.xml']);
        else
            error('buildDIVeSfcn:fileNotFound',['The specified file does not ' ...
                'exist: %s'],sFileXml)
        end
    end
end

% determine basic pathes
sPathXml = fileparts(sFileXml);
cPathXml = pathparts(sFileXml);
sPathContent = fullfile(cPathXml{1:end-7});

% load module XML description (mainly used for data, not for model sets ->
% enable usage in sfcn generation)
xTree = dsxRead(sFileXml);

% get ModelSet and its ID
cModelSet = {xTree.Module.Implementation.ModelSet.type};
if numel(cModelSet) == 1 || (nargin > 1 && isempty(sModelSet))
    % take single ModelSet - no need for selection
    nIdxModelSet = 1;
    sModelSet = cModelSet{nIdxModelSet};
elseif nargin < 2 || ~exist(fullfile(sPathXml,sModelSet),'dir')
    % ask user
    nIdxModelSet = listdlg('ListString',cModelSet,...
        'SelectionMode','single',...
        'ListSize',[300 300],...
        'Name','Select ModelSet',...
        'PromptString','Select ModelSet for test creation:');
    sModelSet = cModelSet{nIdxModelSet};
else
    [bTrash,nIdxModelSet] = ismember(sModelSet,cModelSet); %#ok<ASGLU>
end

% use of stimuli file
cChannel = cell(0,3);
if nargin > 2 && exist(sFileDat,'file')
    bStimuli = true;
    [cChannel,xSource] = readStimuli(sFileDat,cChannel);
else
    bStimuli = false;
    xSource = struct;
end

% fix missing DataSet specification -> use reference DataSets of Module
if nargin < 4
    cData = cell(0,2);
end

% parse logging parameters
bTimeEnd = false;
if nargin > 4
    xLogCfg = parseArgs({'FixedStep',xTree.Module.maxCosimStepsize,''
                         'sampleTime','0.01',''
                         'DataLoggingMaxPoints','',''
                         'LastValue','',''
                         'Decimation','1',''
                         'Assertion',false,''
                         'timeEnd','10',''},...
                         varargin{:});
    if any(strcmp('timeEnd',varargin))
        bTimeEnd = true;
    end
else
    xLogCfg = struct('FixedStep',{'0.005'},...
                     'sampleTime',{'0.01'},...
                     'DataLoggingMaxPoints',{''},...
                     'LastValue',{''},...
                     'Decimation',{'1'},...
                     'Assertion',{false},...
                     'timeEnd',{'10'});
    xLogCfg.FixedStep = xTree.Module.maxCosimStepsize;
end

%% determine library file
bIsMain = ismember({xTree.Module.Implementation.ModelSet(nIdxModelSet).ModelFile.isMain},'1');
sFileMain = xTree.Module.Implementation.ModelSet(nIdxModelSet).ModelFile(bIsMain).name;
[sRest,sMain] = fileparts(sFileMain); %#ok<ASGLU> % remove file extension
sPathModelLib = fullfile(sPathXml,sModelSet,sFileMain); %#ok<NASGU> use in comment

%% create folder for test
sPathRunDir = fullfile(sPathXml,sModelSet,'moduleTest');
mkdir(sPathRunDir);

%% create list of all data files
if bStimuli
    [nStatusFromSmp,xDataSet] = getDataSetsFromSMP(sFileDat,xTree.Module.species);
else
    nStatusFromSmp = 1;
end
if nStatusFromSmp
    xDataSet = getDataSets(xTree.Module.Interface,cPathXml,cData);
end

%% create Simulink diagnostics output file
sFileDiag = fullfile(sPathRunDir, 'SimulinkDiagnostics.txt');
if exist(sFileDiag, 'file')
    delete(sFileDiag)
end
sldiagviewer.diary(sFileDiag, 'UTF-8')
sldiagviewer.diary('on')
% Stop Diary in case of any problem, otherwise sFileDiag will be locked by Matlab (onCleanup is a
% builtin Matlab function cleanup on failure, introduced R2008a) 
hObjCleanup = onCleanup(@() sldiagviewer.diary('off'));

%% create test model
sModelName = [sMain '_test'];
sModelBlockPath = createModel(sMain,sModelName,sPathRunDir,xLogCfg);

%% initialilze module with dpsModuleLoop
cPathAdd = initModule(sModelName,sModelBlockPath,xTree.Module,xDataSet,sModelSet,sPathContent,sPathRunDir);

% move block in position and resize according in-/outputs
slcSetBlockPosition(sModelBlockPath,[450 -1 -1 -1]);
slcResize(sModelBlockPath,50);

%% prepare logging in case of stimuli file used
if bStimuli
    xLog = prepareLogging(sModelName,xLogCfg);
else
    xLog = struct;
end

%% create inport stimulation
[hClock,sTimeName] = createInportStimuli(sModelName,xTree.Module,bStimuli,cChannel,xSource,sMain);

%% create outport display/logging
createOutportSinks(sModelName,sMain,bStimuli,xLog,xTree.Module,xLogCfg);

%% align lines of clock connections (especially to stimuli table lookups)
xLine = get_param(hClock,'LineHandles');
hLineChild = get_param(xLine.Outport,'LineChildren');
for nIdxLine = 1:numel(hLineChild)
    nPos = get_param(hLineChild(nIdxLine),'Points');
    if size(nPos,1) == 3
        nPos(2,1) = nPos(1,1);
        set_param(hLineChild(nIdxLine),'Points',nPos);
    end
end

%% adapt simulation time to stimuli
if bStimuli && ~isempty(sTimeName) && ~bTimeEnd
    nEnd = evalin('base',sprintf('%s(end);',sTimeName));
    set_param(sModelName,'StopTime',num2str(nEnd));
else
    nEnd = str2double(xLogCfg.timeEnd);
end

%% simulate system
bStatus = simulateModel(sModelName,sPathRunDir,nEnd);
sldiagviewer.diary('off')

%% report and cleanup
if bStimuli && exist('logout','var')
    assignin('base','logout',logout) % copy log results to base workspace
end
if nargout < 3 % only when cPathAdd is not requested as output
    cellfun(@rmpath,cPathAdd); % remove added pathes from Matlab path
end

% disp(['<a href="matlab: cd ' fileparts(sPathModelLib) '"> Change to model set directory (library & s-function availability): ' fileparts(sPathModelLib) '</a>']);
% disp(['<a href="matlab: addpath(''' fileparts(sPathModelLib) ''')"> Add model set directory to MATLAB path (library & s-function availability): ' fileparts(sPathModelLib) '</a>']);
return

% =========================================================================

function sModelBlockPath = createModel(sMain,sModelName,sPathRunDir,xLogCfg)
% CREATEMODEL create basic Simulink model
%
% Syntax:
%   createModel(sMain,sModelName,sPathRunDir,xLogCfg)
%
% Inputs:
%         sMain - string with main model name (name of subsystem)
%    sModelName - string with test model name
%   sPathRunDir - string with path of runtime directory
%       xLogCfg - structure with fields of log settings
%
% Outputs:
%   sModelBlockPath - string with Simulink blockpath of subsystem of Module under test
%
% Example:
%   createModel(sMain,sModelName,sPathRunDir,xLogCfg)

% close previous model if necessary
if ismdl(sModelName)
    close_system(sModelName,0);
end

% create model
new_system(sModelName);

% add subsystem
sModelBlockPath = fullfileSL(sModelName,sMain);
add_block('built-in/SubSystem',sModelBlockPath,'Position',[450 75 850 975]);

% apply basic settings
dpsModelSolverOptions(sModelName,'FixedStep01',xLogCfg.FixedStep,xLogCfg.timeEnd);
set_param(sModelName, 'LibraryLinkDisplay', 'user')
set_param(sModelName,'ReturnWorkspaceOutputs','off')
save_system(sModelName,fullfile(sPathRunDir,sModelName));
return

% =========================================================================

function cPathAdd = initModule(sModelName,sModelBlockPath,xModule,xDataSet,sModelSet,sPathContent,sPathRunDir)
% INITMODULE intialize Module with dpsModuleLoop standard function.
%
% Syntax:
%   initModule(sModelName,sModelBlockPath,xModule,xDataSet,sModelSet,sPathContent,sPathRunDir)
%
% Inputs:
%        sModelName - string with Simulink test model name
%   sModelBlockPath - string of blockpath for Module under test
%           xModule - structure with fields of Module XML
%          xDataSet - structure with fields of DataSets according ModuleSetup (contains DataSet
%          variant selections)
%         sModelSet - string with ModelSet to be used
%      sPathContent - string with DIVe Content path used
%       sPathRunDir - string with path of runtime directory
%
% Outputs:
%       cPathAdd - string with pathes added to Matlab path environment
%
% Example:
%   initModule(sModelName,sModelBlockPath,xModule,xDataSet,sModelSet,sPathContent,sPathRunDir)

%% create dummy configuration
xConfiguration.ModuleSetup.name = xModule.species;
xConfiguration.ModuleSetup.initOrder = '1';
xConfiguration.ModuleSetup.Module = xModule;
xConfiguration.ModuleSetup.Module.variant = xModule.name;
xConfiguration.ModuleSetup.Module.modelSet = sModelSet;
xConfiguration.ModuleSetup.DataSet = xDataSet;
xConfiguration.Interface = struct();

%% initialilze module
sPathBefore = path;
cPathAddLoop = dpsModuleLoop(xConfiguration,xModule,sPathContent,sPathRunDir,{sModelBlockPath},1);
save_system(sModelName);

% react on MainModel file type
cModelSet = {xModule.Implementation.ModelSet.type};
[bTrash,nIdxModelSet] = ismember(sModelSet,cModelSet); %#ok<ASGLU>
bIsMain = ismember({xModule.Implementation.ModelSet(nIdxModelSet).ModelFile.isMain},'1');
sFileMain = xModule.Implementation.ModelSet(nIdxModelSet).ModelFile(bIsMain).name;
switch lower(sFileMain(end-3:end))
    case {'.mdl','.slx'}
        % proceed with Matlab wrapper
        
    case '.fmu'
        % check Matlab version
        if verLessThanMATLAB('9.3')
            % error with hint for correct Matlab version
            fprintf(2,['Error on module initialization - for ' ...
                ' native simulation of FMU a Matlab R2017b or newer is needed: %s\n'],sFileMain);
        else
            % create automatic wrapper for blank Funcitonal Mockup Unit (FMU)
            pmsFmuAutoWrapper(sModelBlockPath,sFileMain);
        end
        
    otherwise
        % report error, if main file is neither Simulink file nor fmu
        fprintf(2,['Error on module initialization of - main file is neither a '...
            'Simulink model file (*.mdl,*,slx) nor a FMU file (*.fmu): %s\n'],sFileMain);
        return
end

% discover added pathes
sPathAfter = path;
cPathAdd = setxor(strsplitOwn(sPathBefore,{';'}),strsplitOwn(sPathAfter,{';'}));
fprintf(1,'Added pathes by internal support set scripting: %s\n',strGlue(setxor(cPathAdd,cPathAddLoop),'; '));
return

% =========================================================================

function bStatus = simulateModel(sModelName,sPathRunDir,nEnd)
% SIMULATEMODEL simulate Model with options while catching on errors
%
% Syntax:
%   bStatus = simulateModel(sModelName,sPathRunDir,nEnd)
%
% Inputs:
%    sModelName - string of Simulink test model
%   sPathRunDir - string with path of runtime directory
%          nEnd - integer (1x1) with end time for test
%
% Outputs:
%   bStatus - boolean (1x1) if test succeded (1: pass, 0: fail)
%
% Example:
%   bStatus = simulateModel(sModelName,sPathRunDir,nEnd)

% init output
bStatus = false;

% simulation start procedure with
sPathOrg = pwd;
cd(sPathRunDir);
open_system(sModelName); % make system visible
options = simget(sModelName);
try
    assignin('base','nEnd',nEnd);
    assignin('base','options',options);
    evalin('base',sprintf('sim(''%s'',[0 nEnd],options)',sModelName));
    % sim(sModelName,[0 nEnd],options); % simulation run
    bStatus = true;
    pause(1);
catch xError
    fprintf(2,'dmdModuleTest:simulateModel - error occured during Simulink model start!\n');
    disperror(xError);
    sldiagviewer.reportError(xError);
    fprintf(2,['IMPORTANT: Check the <a href="matlab:winopen(''%s'')">SimulinkDiagnostics.txt</a> ' ...
               'in the test folder for Simulink error messages!\n'],fullfile(pwd,'SimulinkDiagnostics.txt'));
    assignin('base','sMatlabPath',path);
    fprintf(1,'Assigned current Matlab path settings in base workspace variable "sMatlabPath"\n');
    fprintf(1,'Matlab path can be restored after loading workspace via: addpath(sMatlabPath)\n');
    evalin('base','save(''RunWorkspace'')')
    fprintf(1,'Saved current workspace in "RunWorkspace.mat"\n');
    save(fullfile(sPathRunDir,'xErrorRun.mat'),'xError')
    fprintf(1,'Saved Matlab error in  "xErrorRun.mat" (however your issue is more likely in "SimulinkDiagnostics.txt")\n');
    save_system(sModelName);
end
cd(sPathOrg);
return

% =========================================================================

function [hClock,sTimeName] = createInportStimuli(sModelName,xModule,bStimuli,cChannel,xSource,sMain)
% CREATEINPORTSTIMULI create input stimuli and clock display
%
% Syntax:
%   hClock = createInportStimuli(sModelName,xModule,bStimuli,cChannel,xSource,sMain)
%
% Inputs:
%   sModelName - string with Simulink Model filename
%      xModule - structure with fields of Module XML
%     bStimuli - boolean (1x1) if table lookup stimuli are specified
%     cChannel - cell (mxn) with data channels for stimuli
%      xSource - structure with fields of uniread/Morphix structure with stimuli channel data
%        sMain - string with main Subsystem name
%
% Outputs:
%       hClock - handle of clock block
%    sTimeName - string with name of time data channel
%
% Example:
%   hClock = createInportStimuli(sModelName,xModule,bStimuli,cChannel,xSource,sMain)

% init output
sTimeName = '';

% add simulation time display
hClock = add_block('built-in/Clock',fullfileSL(sModelName,'Clock'));
set_param(hClock,'Position',[20 25 40 45],'ShowName','off');
hDisplay = add_block('built-in/Display',fullfileSL(sModelName,'Simulation Time'));
set_param(hDisplay,'Position',[100 23 175 47]);
add_line(sModelName,'Clock/1','Simulation Time/1');

% create inport stimulation
xBI = slcBlockInfo(fullfileSL(sModelName,sMain));
if isfield(xModule.Interface,'Inport')
    for nIdxInport = 1:numel(xModule.Interface.Inport)
        % check for stimuli
        bConstantThis = true;
        if bStimuli
            % check matching stimuli channel for inport
            nFind = find(strcmp(xModule.Interface.Inport(nIdxInport).name,cChannel(:,1)),1,'first');
            
            if ~isempty(nFind)
                bConstantThis = false;
                % prepare data channel
                [sVarName,sTimeName] = dmtDataPrepare(xSource,cChannel,nFind);
                % create lookup block
                hLookup = add_block('built-in/Lookup',...
                    fullfileSL(sModelName,sprintf('lookup_%s',xModule.Interface.Inport(nIdxInport).name)));
                set_param(hLookup,'ShowName','off','InputValues',sTimeName,'Table',sVarName);
                slcSetBlockPosition(hLookup,[150 xBI.PortCon(nIdxInport).Position(2)-20 40 40]);
                add_line(sModelName,'Clock/1',sprintf('lookup_%s/1',xModule.Interface.Inport(nIdxInport).name));
                hLine = add_line(sModelName,[get_param(hLookup,'Name') '/1'],[sMain '/' num2str(nIdxInport)]);
                set_param(hLine,'name',xModule.Interface.Inport(nIdxInport).name);
            end
        end
        
        if bConstantThis
            % add constant
            hConstant = add_block('built-in/Constant',fullfileSL(sModelName,'Stimuli'),'MakeNameUnique','on');
            set_param(hConstant,'Value',['sMP.' xModule.context '.' xModule.species '.in.' ...
                xModule.Interface.Inport(nIdxInport).name])
            slcSetBlockPosition(hConstant,[50 xBI.PortCon(nIdxInport).Position(2)-13 300 26]);
            % connect to block
            add_line(sModelName,[get_param(hConstant,'Name') '/1'],[sMain '/' num2str(nIdxInport)]);
        end
    end
end
return

% =========================================================================

function createOutportSinks(sModelName,sMain,bStimuli,xLog,xModule,xLogCfg)
% CREATEOUTPORTSINKS create all sinks connected to the outport
%
% Syntax:
%   createOutportSinks(sModelName,sMain,bStimuli,xLog,xModule,xLogCfg)
%
% Inputs:
%   sModelName - string with Simulink test model filename
%        sMain - string with main model name of Module
%     bStimuli - boolean (1x1) if stimulis are used -> also enable logging
%         xLog - structure with fields of log settings
%      xModule - structure with fields of DIVe Module XML file
%      xLogCfg - structure with fields of dmdModuleTest additional input arguments
%
% Outputs:
%
% Example:
%   createOutportSinks(sModelName,sMain,bStimuli,xLog,xModule,xLogCfg)
xBI = slcBlockInfo(fullfileSL(sModelName,sMain));
if isfield(xModule.Interface,'Outport')
    for nIdxOutport = 1:numel(xModule.Interface.Outport)
        % outport
        xOutport = xModule.Interface.Outport(nIdxOutport);
        nPosY = xBI.PortCon(xBI.Ports(1)+nIdxOutport).Position(2);
        
        % add display block
        hStimuli = add_block('built-in/Display',fullfileSL(sModelName,'Display'),'MakeNameUnique','on');
        slcSetBlockPosition(hStimuli,[1000 nPosY-13 80 25]);
        set_param(hStimuli, 'ShowName', 'off')
        
        % add type assertion
        if isfield(xLogCfg,'Assertion') && xLogCfg.Assertion
            % move display further right
            slcSetBlockPosition(hStimuli,[1400 nPosY-13 80 26]);
            
            % add signal specification for data type assertion
            hTypeAssert = add_block('built-in/SignalSpecification',...
                fullfileSL(sModelName,['AssertType_' xOutport.name]),...
                'MakeNameUnique','on');
            slcSetBlockPosition(hTypeAssert,[1000 nPosY-13 130 15]);
            set_param(hTypeAssert, 'ShowName', 'off')
            set_param(hTypeAssert,...
                'OutDataTypeStr','double',...
                'Dimensions','1',...
                'VarSizeSig','No',...
                'SignalType','real');
            hLine = add_line(sModelName,[get_param(hTypeAssert,'Name') '/1'],[get_param(hStimuli,'Name') '/1']);
            set_param(hLine,'name',xOutport.name);
            
            % add static range check for min/max assertion
            load_system('simulink')
            hRangeAssert = add_block(sprintf('simulink/Model Verification/Check \nStatic Range'),...
                fullfileSL(sModelName,['AssertMinMax_' xOutport.name]),...
                'MakeNameUnique','on');
            slcSetBlockPosition(hRangeAssert,[1330 nPosY-20 55 15]);
            set_param(hRangeAssert, 'ShowName', 'off')
            
            
            % determine limits (no inf allowed by block)
            % min
            sMin = xOutport.minPhysicalRange;
            if isempty(sMin) || strcmpi('-inf', sMin)
                sMin = '-99999999999';
            end
            % max
            sMax = xOutport.maxPhysicalRange;
            if isempty(sMax) || strcmpi('inf', sMax)
                sMax = '99999999999';
            end
            % SNA value > phys. max ?
            sSNA = xOutport.sna;
            if ~isempty(sSNA)
                % double instead of string
                dMax = str2double(sMax);
                dSNA = str2double(sSNA);
                % Consider rounded values from module xml
                % Usually values inside module xml are rounded to 4 decimal points
                dSNA_4dec = floor(dSNA * 10000) / 10000; % round down to 4 decimal points
                if dSNA_4dec < dSNA % xml value has more than 4 decimal points
                    % Add 6 as additional digit at the end,
                    % since you don't know if the xml value was rounded,
                    % even if it has more than 4 decimal points
                    dSNA = str2double([sSNA '6']);
                else % rounded and original values are equal
                    % Even values like 3 in the xml can be rounded values
                    % from 3.000049 for example
                    dSNA = dSNA + 0.00006;
                end
                % Use SNA instead of phys. max
                if dSNA > dMax
                    sMax = num2str(dSNA, '%.15g');
                end
            end
            % Set Min and Max
            set_param(hRangeAssert,...
                'min',sMin,...
                'max',sMax);
            % Set Assert Callback
            sDispAssert = sprintf('%s < %s or > %s', xOutport.name, sMin, sMax);
            sCallAssert = sprintf('sldiagviewer.reportError(''%s'');', sDispAssert);
            set_param(hRangeAssert, 'callback', sCallAssert);
            
            add_line(sModelName,[get_param(hTypeAssert,'Name') '/1'],[get_param(hRangeAssert,'Name') '/1']);
            
            % point to assertion for line conenction to main subsystem
            hStimuli = hTypeAssert;
        end
        
        % connect to block
        hLine = add_line(sModelName,[sMain '/' num2str(nIdxOutport)],[get_param(hStimuli,'Name') '/1']);
        set_param(hLine,'name',xOutport.name);
        
        % add logging in case of stimuli or dataset
        if bStimuli
            set_param(get_param(hLine,'SrcPortHandle'),xLog.cSetting{:});
        end
    end
end
return

% =========================================================================

function [cChannel,xSource] = readStimuli(sFileDat,cChannel)
% READSTIMULI read stimuli file and extract data channels.
%
% Syntax:
%   [cChannel,xSource] = readStimuli(sFileDat,cChannel)
%
% Inputs:
%   sFileDat - string with filepath of stimuli mat-file with vectors
%   cChannel - cell (0x3) empty cell
%
% Outputs:
%   cChannel - cell (mx3) with stimuli channels and where to find data in xSource
%    xSource - structure with fields of standard uniread/Morphix data structure
%
% Example:
%   [cChannel,xSource] = readStimuli(sFileDat,cChannel)

% init output
% cChannel = cell(0,3);

% read stimuli file
xSource = uniread(sFileDat);

% get list of data channels
% cChannel - cell (mx3) with one line per data channel
% {:,1} - string name of data_channel
% {:,2} - integer with source index of data channel
% {:,3} - integer with subset index of data channel
for nIdxSource = 1:numel(xSource)
    for nIdxSubset = 1:numel(xSource(nIdxSource).subset)
        nChanAdd = numel(xSource(nIdxSource).subset(nIdxSubset).data.name);
        cChannel = [cChannel; ...
            [strtrim(xSource(nIdxSource).subset(nIdxSubset).data.name') ...
            num2cell(repmat(nIdxSource,nChanAdd,1)) ...
            num2cell(repmat(nIdxSubset,nChanAdd,1))]]; %#ok<AGROW>
    end
end
return

% =========================================================================

function xLog = prepareLogging(sModelName,xLogCfg)
% PREPARELOGGING prepare logging with basic settings
%
% Syntax:
%   xLog = prepareLogging(sModelName,xLogCfg)
%
% Inputs:
%   sModelName - string with Model name
%      xLogCfg - structure with fields of logging options from
%
% Outputs:
%   xLog - structure with fields:
%
% Example:
%   xLog = prepareLogging(sModelName,xLogCfg)

% main properties
xLog.type = 'Simulink';
if isfield(xLogCfg,'sampleTime')
    xLog.time = xLogCfg.sampleTime;
else
    % default value matching LDYN sampling
    xLog.time = '0.01';
end

% get log settings
if isfield(xLogCfg,'DataLoggingMaxPoints')
    xLog.DataLoggingMaxPoints = xLogCfg.DataLoggingMaxPoints;
elseif isfield(xLogCfg,'LastValue') % old LDYN field
    xLog.DataLoggingMaxPoints = xLogCfg.LastValue;
else
    xLog.DataLoggingMaxPoints = '';
end
if isempty(xLog.DataLoggingMaxPoints)
    xLog.DataLoggingMaxPoints = '5000';
    xLog.DataLoggingLimitDataPoints = 'off';
else
    xLog.DataLoggingLimitDataPoints = 'on';
end
if isfield(xLogCfg,'Decimation')
    xLog.Decimation = xLogCfg.Decimation;
else % default decimation
    xLog.Decimation = '1';
end

% prepare settings
xLog.cSetting = {'DataLogging','on',...
    'DataLoggingDecimateData','on',...
    'DataLoggingDecimation',xLog.Decimation,...
    'DataLoggingLimitDataPoints',xLog.DataLoggingLimitDataPoints,...
    'DataLoggingMaxPoints',xLog.DataLoggingMaxPoints};
if ~verLessThanMATLAB('9.0') % R2016a and above
    xLog.cSetting = [xLog.cSetting {'DataLoggingSampleTime',xLog.time}];
end

% enable logging on model settings
set_param(sModelName,'SignalLogging','on');
set_param(sModelName,'SignalLoggingName','logout');
set_param(sModelName,'SaveFormat','Array');
return

% =========================================================================

function xDataSet = getDataSets(xInterface,cPathXml,cData)
% GETDATASETS determine DataSet variants used for testing either from reference DataSets or from
% user specification on extended dmdModuleTest interface (argument 4).
%
% Syntax:
%   xDataSet = getDataSets(xTree,cPathXml,cData)
%
% Inputs:
%  xInterface - structure with fields of Module XML interfafce
%    cPathXml - cell (1xn) with path parts of Module XML
%       cData - cell with strings to define DataSet variant configuration
%               (nx1) - strings define DataSet className slots of Module
%                       to be selected manually/interactively
%               (nx2) - (:,1): string with DataSet className for configuration
%                       (:,2): string with DataSet variant for className
%                              slot, if empty interactive selection
%
% Outputs:
%   xDataSet - structure with fields of DataSet from Module XML interface plus variant
%
% Example:
%   xDataSet = getDataSets(xTree,cPathXml,cData)

% add initIO data class
if isfield(xInterface,'DataSetInitIO')
    % old DataSetInitIO tag
    cPathDataVariant = {fullfile(cPathXml{1:end-3},'Data',...
        xInterface.DataSetInitIO.classType,...
        xInterface.DataSetInitIO.reference)};
    cDataClassName = {xInterface.DataSetInitIO.className};
    xDataSet = xInterface.DataSetInitIO;
    xDataSet.variant = xDataSet.reference;
else % DataSet tag with reserved classType/className initIO
    bIsDataSetInitIO = ~cellfun(@isempty, strfind({xInterface.DataSet.className},'initIO')); %#ok<STRCLFH>
    cPathDataVariant = {fullfile(cPathXml{1:end-3},'Data',...
        xInterface.DataSet(bIsDataSetInitIO).classType,...
        xInterface.DataSet(bIsDataSetInitIO).reference)};
    cDataClassName = {xInterface.DataSet(bIsDataSetInitIO).className};
    xDataSet = xInterface.DataSet(bIsDataSetInitIO);
    xDataSet.variant = xDataSet.reference;
end

% add other data classes
cLevel = {'species','family','type'};
if isfield(xInterface,'DataSet')
    for nIdxDataSet = 1:numel(xInterface.DataSet)
        if ~strcmp(xInterface.DataSet(nIdxDataSet).className,'initIO')
            % determine location of data set
            [bTF,nLevel] = ismember(lower(xInterface.DataSet(nIdxDataSet).level),cLevel); %#ok<ASGLU>
            sFileXmlData = fullfile(cPathXml{1:end-6+nLevel},'Data',...
                xInterface.DataSet(nIdxDataSet).classType,...
                xInterface.DataSet(nIdxDataSet).reference);
            
            % add to list
            cPathDataVariant = [cPathDataVariant {sFileXmlData}]; %#ok<AGROW>
            cDataClassName = [cDataClassName {xInterface.DataSet(nIdxDataSet).className}]; %#ok<AGROW>
            xDataSetAdd = xInterface.DataSet(nIdxDataSet);
            xDataSetAdd.variant = xDataSetAdd.reference;
            xDataSet = structConcat(xDataSet,xDataSetAdd);
        end
    end
end

% adapt variants to specified variants
if ~isempty(cData)
    for nIdxSet = 1:numel(xDataSet)
        nClass = find(strcmp(xDataSet(nIdxSet).className,cData(:,1)),1,'first');
        if ~isempty(nClass)
            xDataSet(nIdxSet).variant = cData{nClass,2};
        end
    end
end
return

% =========================================================================

function [nStatus,xDataSet] = getDataSetsFromSMP(sFile,sSpecies)
% GETDATASETSFROMSMP get DataSet variant selection from the Configuration in the sMP variable of a
% WS*.mat file of a previous DIVe simulation
%
% Syntax:
%   [nStatus,xDataSet] = getDataSetsFromSMP(sFile,sSpecies)
%
% Inputs:
%      sFile - string with filepath of WS*.mat file containing a sMP variable
%   sSpecies - string with Module species name (e.g. eng)
%
% Outputs:
%    nStatus - integer (1x1) with status (0:success, 1:failure)
%   xDataSet - structure with fields of ModuleSetup.DataSet  
%       .variant - DataSet variant name
%
% Example: 
%   [nStatus,xDataSet] = getDataSetsFromSMP(sFile,sSpecies)

% check for sMP variable in mat-file
cLoad = who('-file',sFile,'sMP');
if isempty(cLoad)
    nStatus = 1;
    xDataSet = struct;
    return
else
    nStatus = 0;
end

% get sMP variable
xLoad =load(sFile,'sMP');

% get DataSets of Module under test
cSetup = {xLoad.sMP.cfg.Configuration.ModuleSetup.name};
bSpecies = strcmp(sSpecies,cSetup);
if ~any(bSpecies)
    nStatus = 1;
    xDataSet = struct;
    return
end
xDataSet = xLoad.sMP.cfg.Configuration.ModuleSetup(bSpecies).DataSet;
return

% =========================================================================

function [sVarName,sTimeName] = dmtDataPrepare(xSource,cChannel,nChannel)
% DMTDATAPREPARE determine specified data channel, its time data channel
% and make them available in the base workspace.
%
% Syntax:
%   [sVarName,sTimeName] = dmtDataPrepare(xSource,cChannel,nChannel)
%
% Inputs:
%    xSource - structure with fields of a Morphix/Uniread source
%   cChannel - cell (mx3) with channel listing of uniread source
%   nChannel - integer (1x1) with channel id in channel listing cell
%
% Outputs:
%    sVarName - string with variable name of data channel
%   sTimeName - string with variable name of time channel
%
% Example:
%   [sVarName,sTimeName] = dmtDataPrepare(xSource,cChannel,nChannel)


% data channel assigin in base workspace
nSource = cChannel{nChannel,2};
nSubset = cChannel{nChannel,3};
sVarName = cChannel{nChannel,1};
nData = find(strcmp(sVarName,xSource(nSource).subset(nSubset).data.name),1,'first');
assignin('base',sVarName,xSource(nSource).subset(nSubset).data.value(:,nData)');

% identify time channel of subset
cPriority = {'time','Time','mpx_time','mpx_env_time','mpx_eats_time',...
    'mpx_coolsys_time','Zeit','zeit','sec','Zeitstempel','RECZEIT',...
    'BpktLz','TimeDate','ZEIT','WEG'};
nLoop = 0;
nTime = [];
while nLoop <= numel(cPriority) && isempty(nTime)
    nLoop = nLoop + 1;
    nTime = find(strcmp(cPriority{nLoop},xSource(nSource).subset(nSubset).data.name),1,'first');
end
if isempty(nTime)
    nTime = 1;
end

% time channel assigin in base workspace
sSub = genvarname(xSource(nSource).subset(nSubset).name);
sTimeName = sprintf('time_%s',sSub);
bExist = evalin('base',sprintf('exist(''%s'',''var'');',sTimeName));
if ~bExist
    assignin('base',sTimeName,xSource(nSource).subset(nSubset).data.value(:,nTime)');
end
return

% ==================================================================================================
% ======== copied from source file pmsFmuAutoWrapper.m
% ==================================================================================================

function [xInport,xOutport] = pmsFmuAutoWrapper(sSubPath,sFileMain)
% PMSFMUAUTOWRAPPER creates an automatic FMU import block with wrapper
% subsystem, that provides named inports and outports based on the port
% labels in the mask display of the FMU import block. (Tested with Simpack
% and SimX FMUs).
%
% Syntax:
%   [xInport,xOutport] = pmsFmuAutoWrapper(sSubPath,sFileMain)
%
% Inputs:
%    sSubPath - string with complete blockpath including name of the
%               wrapper subsystem
%   sFileMain - string with the FMU filename (should be ismain file)
%
% Outputs:
%    xInport - structure with fields of wrapper subsystem inports:
%       .handle - handle of the inport block
%       .
%   xOutport - structure with fields:
%
% Example:
%   [xInport,xOutport] = pmsFmuAutoWrapper('DIVeMB_Model/physics/test/test_dev_fmu_std','SomeModel.fmu')
%
% See also: pmsFmuAutoWrapper, slcAlignInOut, slcMaskPortLabelParse,
% slcResize, slcSetBlockPosition
%
% Author: Rainer Frey, TP/EAF, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2021-02-18

% define block sizing in Module level 2
nHorBlock = 440; % horizontal begin of model block
nWBlock = 330; % horizontal width of model block

% add wrapper subsystem
if ismdl(sSubPath) % already exists in dmdModuleTest
    hSub = sSubPath;
else
    hSub = add_block('built-in/SubSystem',sSubPath);
end
slcSetBlockPosition(hSub,[nHorBlock 80 nWBlock 400]);
set_param(hSub,'BackgroundColor','[0.9400 0.8800 0.5500]')

% add info about
hDoc = slcSubsystemAdd(hSub,'Info',{},{},[10,10,460,40]);
set_param(hDoc,'ShowName','off','Mask','on','MaskIconFrame','on','BackgroundColor','yellow')
set_param(hDoc,'MaskDisplay',['disp(''Automatically generated wrapper by ' ...
                              'DIVe Simulink Simulation Technology (pmsFmuAutoWrapper)'')']);
if ~verLessThanMATLAB('9.4')
    set_param(hDoc,'MaskIconUnits','Pixels');
end

% add fmu block
hBlock = add_block('built-in/FMU',fullfileSL(sSubPath,'FMU_Import'));
set_param(hBlock,'FMUName',sFileMain); % set FMU file
slcSetBlockPosition(hBlock,[nHorBlock 80 nWBlock 400]);
slcResize(hBlock,30);

% reset positions from automatic Simulink resizinigs
slcSetBlockPosition(hBlock,[-1 50 -1 -1]);
slcSetBlockPosition(hDoc,[10,10,450,30]);

% get ports
[nStatus,cInport,cOutport] = slcMaskPortLabelParse(hBlock);
if nStatus
    % dismatch between parsed port names and number of ports
    return
end

% add inports
xInport = struct('handle',{},'nPosInt',{},'nPosExt',{});
for nIdxPort = 1:numel(cInport)
    % create port block and store properties
    xInport(nIdxPort).handle = add_block('built-in/Inport',...
                                         fullfileSL(sSubPath,cInport{nIdxPort}));
    set_param(xInport(nIdxPort).handle,'Position',[50 nIdxPort*50 80 nIdxPort*50+14]);
    xPortCon = get_param(xInport(nIdxPort).handle,'PortConnectivity');
    xInport(nIdxPort).nPosInt = xPortCon(1).Position;
    % connect to FMU block
    add_line(sSubPath,[cInport{nIdxPort} '/1'],['FMU_Import/' num2str(nIdxPort)]);
end

% add outports
xOutport = struct('handle',{},'nPosInt',{},'nPosExt',{});
for nIdxPort = 1:numel(cOutport)
    % create port block and store properties
    xOutport(nIdxPort).handle = add_block('built-in/Outport',...
                                          fullfileSL(sSubPath,cOutport{nIdxPort}));
    set_param(xOutport(nIdxPort).handle,'Position',[970 nIdxPort*50 1000 nIdxPort*50+14]);
    xPortCon = get_param(xOutport(nIdxPort).handle,'PortConnectivity');
    xOutport(nIdxPort).nPosInt = xPortCon(1).Position;
    % connect to FMU block
    add_line(sSubPath,['FMU_Import/' num2str(nIdxPort)],[cOutport{nIdxPort} '/1']);
end

% get external port positions
xPortCon = get_param(hBlock,'PortConnectivity');
for nIdxPort = 1:numel(cInport)
    xInport(nIdxPort).nPosExt = xPortCon(nIdxPort).Position;
end
for nIdxPort = 1:numel(cOutport)
    xOutport(nIdxPort).nPosExt = xPortCon(numel(cInport)+nIdxPort).Position;
end

% align inports and outports with FMU block
slcAlignInOut(hBlock);
return
