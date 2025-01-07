function xcm_sil_Support_init(varargin)
% XCM_SIL_SUPPORT_INIT support function of DIVe xcm.sil for data set
% load and initialization.
%
% Syntax:
%   xcm_sil_Support_init(varargin)
%
% Inputs:
%        sPathRunDir - string with run directory of simulation
%      sPathModelLib - string with directory of used modelset
%    sModelBlockPath - string with blockpath of module inside of main model
%   cPathDataVariant - cell with strings of directories of selected data
%                      set variants
%
% Outputs:
%
% Example: 
%   xcm_sil_Support_init('sPathRunDir','','sPathModelLib','','sModelBlockPath','','cPathDataVariant',{'',''})

% input argument parsing
xArg = parseArgs({'sPathRunDir','','';...
                  'sPathModelLib','','';...
                  'sModelBlockPath','','';
                  'cPathDataVariant',{},''}...
                  ,varargin{:});
cPathModelLib = pathparts(xArg.sPathModelLib);

% determine species
[sPathDump,sFileData] = fileparts(xArg.cPathDataVariant{1}); %#ok<ASGLU>
xTree = dsxRead(fullfile(xArg.cPathDataVariant{1},[sFileData '.xml']));
sEcuType = xTree.DataSet.species;

%% generate file pathes as sMP parameters
% determine data set variant information
xData = struct('path',{},'class',{},'variant',{});
for nIdxData = 1:numel(xArg.cPathDataVariant)
    cPathData = pathparts(xArg.cPathDataVariant{nIdxData});
    xData(nIdxData).path = xArg.cPathDataVariant{nIdxData};
    xData(nIdxData).class = cPathData{end-1};
    xData(nIdxData).variant = cPathData{end};
end

% create dataset file pathes as variables for s-function input
cFileDef = {'sFileE2PData' 'e2pData' '*.dcm';...
         'sFileMainData' 'mainData' '*.dcm';...
         'sFileLogging' 'instrument' '*.txt'
		 'sFileInitEcu' 'initEcu' '*.txt'};
% get structure variable from base workspace
sMP = evalin('base','sMP');
for nIdxFile = 1:size(cFileDef,1)
    % determine dataset structure ID
    bData = strcmp(cFileDef{nIdxFile,2},{xData.class});
    
    % determine file in dataset
    cFileSet = dirPattern(xData(bData).path,cFileDef{nIdxFile,3},'file');
    
    % assign parameter in sMP structure
    sMP.ctrl.(sEcuType).(cFileDef{nIdxFile,1}) = fullfile(xData(bData).path,cFileSet{1});
end
sMP.ctrl.(sEcuType).sFileOutput = fullfile(xArg.sPathRunDir,[sEcuType '_silver_raw.txt']);
assignin('base','sMP',sMP);

% ensure dcm file correction
cDcmOrg = dirPattern(xData(bData).path,cFileDef{nIdxFile,3},'file'); % check for .org file
if isempty(cDcmOrg)
    % check to correct main data file (if correction was already done, it
    % will not be repeated, see code of spsSilDcmCorrection)
    spsSilDcmCorrection(sMP.ctrl.(sEcuType).sFileMainData); 
end

% load extraData from dcm to workspace
[extraDataMain,extraDataInit] = extraData;
[extraDataMainValues,extraDataMainValuesFail] = dcmRead(sMP.ctrl.(sEcuType).sFileMainData,extraDataMain);
[extraDataInitValues,extraDataInitValuesFail] = dcmRead(sMP.ctrl.(sEcuType).sFileE2PData,extraDataInit);
if ~isempty(extraDataMainValues)
    extraDataMainValidNames = fieldnames(extraDataMainValues);
    for DataMainIdx = 1:length(extraDataMainValidNames)
        currentName = extraDataMainValidNames{DataMainIdx};
        if ~all(size(extraDataMainValues.(currentName))>1)
            extraDataMainValues.(currentName) = extraDataMainValues.(currentName)';
        end
    end
    sMP.ctrl.mcm = structUnify(sMP.ctrl.(sEcuType),extraDataMainValues);
end
if ~isempty(extraDataInitValues)
    extraDataInitValuesNames = fieldnames(extraDataInitValues);
    for DataInitIdx = 1:length(extraDataInitValuesNames)
        currentName = extraDataInitValuesNames{DataInitIdx};
        if ~all(size(extraDataInitValues.(currentName))>1)
            extraDataInitValues.(currentName) = extraDataInitValues.(currentName)';
        end
    end
    sMP.ctrl.mcm = structUnify(sMP.ctrl.mcm,extraDataInitValues);
end
if isfield(sMP.ctrl.mcm,'tbf_trq_max_r1_x_eng_speed') && sum(sMP.ctrl.mcm.tbf_trq_max_r1_x_eng_speed) == 0
    sMP.ctrl.mcm.tbf_trq_max_r1_x_eng_speed = [1/1000:1/1000:length(sMP.ctrl.mcm.tbf_trq_max_r1_x_eng_speed)/1000]';
end
if isfield(sMP.ctrl.mcm,'osg_eng_speed_max_r0_1m') && ~isfield(sMP.ctrl.mcm,'osg_eng_speed_max_1m')
    sMP.ctrl.mcm.osg_eng_speed_max_1m = sMP.ctrl.mcm.osg_eng_speed_max_r0_1m;
end
if isfield(sMP.ctrl.mcm,'e2p_sys_engine_brake_variant') && ~isfield(sMP.ctrl.mcm,'E2P_SYS_ENGINE_BRAKE_VARIANT')
    sMP.ctrl.mcm.E2P_SYS_ENGINE_BRAKE_VARIANT = sMP.ctrl.mcm.e2p_sys_engine_brake_variant;
end
% get sample rate
bInstr = strcmp('instrument',{xData.class});
sFileSampleRate = fullfile(xData(bInstr).path,'SampleRate.asc');
if exist(sFileSampleRate,'file')
    nFid = fopen(sFileSampleRate,'r');
    vSampleRate = fscanf(nFid,'%f',1);
    fclose(nFid);
else
    fprintf(1,'Missing sample rate for SiL instrumentation (default = 0.1s used): %s\n',xData(bInstr).path);
    vSampleRate = 0.1;
end
sMP.ctrl.(sEcuType).sSampleRate = num2str(vSampleRate);

if exist('sMP')
	if isfield(sMP,'cfg') && isfield(sMP.cfg,'Configuration') && isfield(sMP.cfg.Configuration,'ModuleSetup')
		auxMcmInit_maxCosimStepSize = sMP.cfg.Configuration.ModuleSetup(find(ismember({sMP.cfg.Configuration.ModuleSetup.name},{'mcm','mcm1'}))).Module.maxCosimStepsize;
    end
end
if exist('auxMcmInit_maxCosimStepSize')
    %do nothing auxMcmInit_maxCosimStepSize already created
elseif ~isempty(bdroot)
	auxMcmInit_maxCosimStepSize = get_param(bdroot,'FixedStep');
else
	auxMcmInit_maxCosimStepSize = 0.1; %Assuming 5000 1/min --> per crank tooth 0.0002 sec
end

% create user config string
sMP.ctrl.(sEcuType).user_config = [ '-a ' sMP.ctrl.mcm.sFileMainData ...
                                    ' -b ' sMP.ctrl.mcm.sFileE2PData ...
                                    ' -c ' num2str(auxMcmInit_maxCosimStepSize)....
                                    ' -d ' sMP.ctrl.mcm.sFileOutput ...
                                    ' -e ' sMP.ctrl.mcm.sFileLogging ...
                                    ' -f ' sMP.ctrl.mcm.sSampleRate ...
                                    ' -g ' sMP.ctrl.mcm.sFileInitEcu ...
                                    ' -h ' sMP.ctrl.mcm.sFileInitEcu ...
                                    ' -i mcm_finalE2Ps.txt' ...
                                    ' -X ' sMP.ctrl.mcm.sMARC ...
                                    ' -Y TCP -Z 5555 -W 3' ];

assignin('base','sMP',sMP);

% load data class instrument
sClassLoad = 'instrument';
bClass = strcmp(sClassLoad,{xData.class});
if any(bClass) && ismdl(xArg.sModelBlockPath)
    % get parameter structure from instrumentatino m-file
    xTree = dsxRead(fullfile(xData(bClass).path,[xData(bClass).variant '.xml']));
    nMFile = find(~cellfun(@isempty,regexp({xTree.DataSet.DataFile.name},'\.m$','once')));
    if ~isempty(nMFile) && exist(fullfile(xData(bClass).path,xTree.DataSet.DataFile(nMFile(1)).name),'file')
        xParInstr = dpsLoadStandardFile(fullfile(xData(bClass).path,xTree.DataSet.DataFile(nMFile(1)).name));
        
        % prepare structures for instrumentation (info patching and
        % xChannel.mat loading)
        sPathChannelMat = fullfile(cPathModelLib{1:end-3},'Support','instrument');
        [xParInstr.xInstrument,xParInstr.xSwitch] = spsEcuInstrumentPrepare(xParInstr.xInstrument,xParInstr.xSwitch,xArg.sModelBlockPath,sPathChannelMat);
        
        % ECU instrumentation
        % CAUTION: instrumentation lists rely partly on physical values which
        % are not available in DIVe, hence full instrumentation can be only in
        % DIVe ModelBased
        slcInstrument(xParInstr.xInstrument);
    end
    
    % copy SiL Alias files to runtime directory
    nCsvFile = find(~cellfun(@isempty,regexp({xTree.DataSet.DataFile.name},'^SiL_Alias.*\.csv$','once')));
    for nIdxFile = 1:numel(nCsvFile)
        copyfile(fullfile(xData(bClass).path,xTree.DataSet.DataFile(nCsvFile(nIdxFile)).name),...
                 fullfile(xArg.sPathRunDir,xTree.DataSet.DataFile(nCsvFile(nIdxFile)).name));
    end
end

% check for MVA conversion (is loaded already as isStandard dataset)
bMva = strcmp(sMP.ctrl.(lower(cPathModelLib{end-6})).MVA,{'on','stationary'});
if any(bMva) && ismdl(xArg.sModelBlockPath)
    % option value
    sOption = sMP.ctrl.(lower(cPathModelLib{end-6})).MVA;
    
    % get current StopFcn of Simulink model
    sStopFcn = get_param(bdroot(xArg.sModelBlockPath),'StopFcn');
    
    if isempty(strfind('spsPostProcessMemoryProtection',sStopFcn))
        % find postprocessing part
        nPostEnd = strfind(sStopFcn,'% execute user-defined postprocessing file');
        
        % add MVA conversion to StopFcn
        sStopFcn = [sStopFcn(1:nPostEnd-1) ...
            '% convert MVA data, if available' char(10) ...
            'spsPostProcessMemoryProtection(sMP.cfg.run(end).path,tout(end),''' sOption ''')' char(10) ...
            char(10) ...
            sStopFcn(nPostEnd:end)];
        set_param(bdroot(xArg.sModelBlockPath),'StopFcn',sStopFcn);
    end
end

% % check for MARC startup/interface
% if ~strcmp(sMP.ctrl.(lower(cPathModelLib{end-6})).MARC,'off') && ...
%         exist(fullfile(cPathModelLib{1:end-4},'Support','gk'),'dir')
%     spsMARCInitialization(xArg.sPathRunDir,... % run path of platform
%         fullfile(cPathModelLib{1:end-4},'Support','gk'),... % path MARC csv files
%         bdroot(xArg.sModelBlockPath),... % name of main Simulink model
%         59846,... % Port for XCP protocol
%         0,... % verbosity level - standard:0, debug: 10
%         1,... % autostart of MARC measurement with simulation start
%         1,... % autostop of MARC measurement with simulation end
%         0); % additional scaling on Simulink XCP server side to double
% end

%% prepare and open a bypass instance
if strcmp(cPathModelLib{end-2}(1:3),'bp_')
    % load bypass data
    % load default dataset (if compiler switch is included in bypass model
    % default data is necessary because it will not be included in .dcm
    % file
    cFile = dirPattern(fullfile(cPathModelLib{1:end-1},'bypass'),'*.mat','file');
    xParDef = load(fullfile(cPathModelLib{1:end-1},'bypass',cFile{1}));
    sMP.ctrl.(sEcuType) = structUnify(sMP.ctrl.(sEcuType),xParDef.sMP.ctrl.(sEcuType));
    xCell.cParameterNames = fieldnames(xParDef.sMP.ctrl.(sEcuType));
    [xBypassDataMainValues,xTrash] = dcmRead(sMP.ctrl.(sEcuType).sFileMainData,xCell.cParameterNames);
    if ~isempty(xBypassDataMainValues)
        sMP.ctrl.(sEcuType) = structUnify(sMP.ctrl.(sEcuType),xBypassDataMainValues);
    end
    [xBypassDataInitValues,xTrash] = dcmRead(sMP.ctrl.(sEcuType).sFileE2PData,xCell.cParameterNames);
    if ~isempty(xBypassDataInitValues)
        sMP.ctrl.(sEcuType) = structUnify(sMP.ctrl.(sEcuType),xBypassDataInitValues);
    end
    
    % load data class instrument
    sClassLoad = 'bpInstrument';
    bClass = strcmp(sClassLoad,{xData.class});
    if any(bClass)
        xTree = dsxRead(fullfile(xData(bClass).path,[xData(bClass).variant '.xml']));
        nMFile = find(~cellfun(@isempty,regexp({xTree.DataSet.DataFile.name},'\.m$','once')));
        if ~isempty(nMFile) && exist(fullfile(xData(bClass).path,xTree.DataSet.DataFile(nMFile(1)).name),'file')
            xParBpInstr = dpsLoadStandardFile(fullfile(xData(bClass).path,xTree.DataSet.DataFile(nMFile(1)).name));
            % prepare structures for instrumentation (info patching and
            % xChannel.mat loading)
            sPathChannelMat = fullfile(cPathModelLib{1:end-3},'Support','bpInstrument');
            [xParBpInstr.xInstrument,xParInstr.xSwitch] = spsEcuInstrumentPrepare(...
                xParBpInstr.xInstrument,...
                struct('sFrameName',{}),... % not relevant for bypass
                '',... % ModelPath -> empty as instrumenation channel defintion on bypass is explicit
                sPathChannelMat);
            sMP.ctrl.(sEcuType).bpInstrument.xInstrument = xParBpInstr.xInstrument;
            
        end
    end

    
    % overload bypass parameters with bypass variation data
    bData = strcmp('bypassVariation',{xData.class});
    cFile = dirPattern(xData(bData).path,'*.m','file');
    xPar = dpsLoadStandardFile(fullfile(xData(bData).path,cFile{1}));
    sMP.ctrl.(sEcuType) = structUnify(sMP.ctrl.(sEcuType),xPar);
    assignin('base','sMP',sMP);

    % open instance
    createBypassInstance(fileparts(xArg.sPathModelLib),xArg.sPathRunDir)
end
return
