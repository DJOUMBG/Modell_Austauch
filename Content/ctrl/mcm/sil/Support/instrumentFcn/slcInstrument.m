function hBlockAdd = slcInstrument(xInstrument)
% SLCINSTRUMENT add instrumentation (logging/display) to specified Simulink
% signals.
%
% Syntax:
%   hBlockAdd = slcInstrument(xInstrument)
%
% Inputs:
%      hSystem - handle or string with blockpath of system to be
%                instrumented
%   xInstrument(1) - structure vector with information for instrumentation
%                    groups. Contains fields:
%    .sName             - string with instrumentation group/file name
%    .sSensor           - string with instrumenation/sensor type:
%                           ToDisc, Display, ToWorkspace, ViTOS
%    .vSampleRate       - value with sample rate of instrumentation group
%    .cChannelFile      - cell with strings of channel info .mat files
%    .hSystemBase       - handle/string with block (path) of the Simulink 
%                         subsystem, on which the instrumentation
%                         information is based and where any central blocks
%                         are placed.
%    .sBlockOrigin      - string with block path of original sensor block
%                         path
%    .cBlockProperties  - 
%    .sSignalNameProperty - 
%    .xChannel          - structure vector with fields:
%      .sName           - string with signal name in output
%      .sBlockPath      - string with blockpath of block to signal
%      .sPortType       - port type of block, which is connected to signal
%      .nPort           - integer with port number of block connected to signal
%      .nVector           - integer with vector index of signal
%
% Outputs:
%   hBlockAdd - handle 
%
% Example: 
%   hBlockAdd = slcInstrument(xInstrument)
%
% BuildCommand:
% [FileLinked,LinkList,ExceptionList,DoubleFunctionRemoved] = buildRelease(which('slcAddInstrument'),'s',{},{matlabroot},{},{})
%
%
% Subfunctions: createBlockInstrument, createBlockInstrumentRemote,
% createOutputSubsystem, slcPositionMax, slcReplaceToWorkspaceByToStore 
%
% See also: fullfileSL, ismdl, pathpartsSL, slcBlockInfo, slcDisableLink,
% slcLoadEnsure 
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2013-03-26


% Output initialization
hBlockAdd = [];

if ~isempty(xInstrument)
    % bp instrument hands over empty string
    if isempty(xInstrument(1).hSystemBase)
        vPositionMaxMemory = slcPositionMax(bdroot(gcs));
    else
        vPositionMaxMemory = slcPositionMax(xInstrument(1).hSystemBase);
    end
else
    return
end

% loop over instrumentation structures (creates one output each)
cDataStore = {};
nSuccess = 0;
nFail = 0;
for nIdxInstr = 1:numel(xInstrument)
    
    % get sensor block properties
    switch xInstrument(nIdxInstr).sSensor 
        case 'ToDisc'
              xInstrument(nIdxInstr).sBlockOrigin = 'built-in/ToWorkspace'; 
              xInstrument(nIdxInstr).cBlockProperties = {};
              xInstrument(nIdxInstr).sSignalNameProperty = '';
              xInstrument(nIdxInstr).nBlockSize = [250 16];
            
        case 'Display'
              xInstrument(nIdxInstr).sBlockOrigin = 'built-in/Display'; 
              xInstrument(nIdxInstr).cBlockProperties = {};
              xInstrument(nIdxInstr).sSignalNameProperty = '';
              xInstrument(nIdxInstr).nBlockSize = [80 20];
            
        case 'DisplayCentral'
              xInstrument(nIdxInstr).sBlockOrigin = 'built-in/Display'; 
              xInstrument(nIdxInstr).cBlockProperties = {};
              xInstrument(nIdxInstr).sSignalNameProperty = '';
              xInstrument(nIdxInstr).nBlockSize = [80 20];
            
        case 'ToWorkspace' 
              xInstrument(nIdxInstr).sBlockOrigin = 'built-in/ToWorkspace'; 
              xInstrument(nIdxInstr).cBlockProperties = {};
              xInstrument(nIdxInstr).sSignalNameProperty = '';
              xInstrument(nIdxInstr).nBlockSize = [250 16];
            
        case 'ViTOS'
              xInstrument(nIdxInstr).sBlockOrigin = 'slcVITOS/VITOS Display'; 
              xInstrument(nIdxInstr).cBlockProperties = {};
              xInstrument(nIdxInstr).sSignalNameProperty = '';
              xInstrument(nIdxInstr).nBlockSize = [40 16];
            
        otherwise
            disp(['ERROR:slcInstrument - unknown sensor block: ' ...
                xInstrument(nIdxInstr).sSensor '. Instrument ID ' ...
                num2str(nIdxInstr) 'skipped...']);
            continue
    end
    
    % create tag for identification of instrumentation set
    sStorePrefix = regexp(xInstrument(nIdxInstr).sName,'^\w+','match','once');
    
    % unlock bdroot (instrumentation of Library)
    % bp instrument hands over empty string
    if ~isempty(xInstrument(nIdxInstr).hSystemBase)
        set_param(bdroot(xInstrument(nIdxInstr).hSystemBase),'Lock','off');
    end

    % generate output subsystems
    if ismember(xInstrument(nIdxInstr).sSensor,{'ToWorkspace','ToDisc'});
        % bp instrument hands over empty string
        if ~isempty(xInstrument(nIdxInstr).hSystemBase)
            [hOutput,hBlockAdd] = createOutputSubsystem(xInstrument(nIdxInstr).hSystemBase,...
                sStorePrefix,xInstrument(nIdxInstr).vSampleRate);
        else
            [hOutput,hBlockAdd] = createOutputSubsystem(bdroot(gcs),...
                sStorePrefix,xInstrument(nIdxInstr).vSampleRate);
        end
    end
    
    % add instrumentation block in model
    cSystemPathOutput = pathpartsSL(hOutput); % split output system path

    % loop over all instrumentation connections
    for nIdxChannel = 1:numel(xInstrument(nIdxInstr).xChannel)
        if isempty(xInstrument(nIdxInstr).xChannel(nIdxChannel).sBlockPath)
            nFail = nFail + 1;
            disp(['Instrumentation of channel ' xInstrument(nIdxInstr).xChannel(nIdxChannel).sName ...
                '(' num2str(nIdxInstr) ':' num2str(nIdxChannel) ') skipped due to empty block path.']);
            continue
        end
        
        % determine block for sensor instrumentation
        xInstrument(nIdxInstr).xChannel(nIdxChannel).sBlockPath = fullfileSL(xInstrument(nIdxInstr).hSystemBase,...
                            xInstrument(nIdxInstr).xChannel(nIdxChannel).sBlockPath);
        
        % check availability of target
        if ismdl(xInstrument(nIdxInstr).xChannel(nIdxChannel).sBlockPath)
            % check for double channel names in DataStoreMemory usage
            if ismember(xInstrument(nIdxInstr).xChannel(nIdxChannel).sName,cDataStore)
                nIdxName = 2;
                while ismember([xInstrument(nIdxInstr).xChannel(nIdxChannel).sName num2str(nIdxName)],cDataStore)
                    nIdxName = nIdxName + 1;
                end
                xInstrument(nIdxInstr).xChannel(nIdxChannel).sName = ...
                    [xInstrument(nIdxInstr).xChannel(nIdxChannel).sName num2str(nIdxName)];
            end
            
            % create instrumentation block
            [bState,hBlockAddAdd,cDataStore] = createBlockInstrument(xInstrument(nIdxInstr).xChannel(nIdxChannel),...
                               hOutput,...
                               xInstrument(nIdxInstr).sBlockOrigin,...
                               xInstrument(nIdxInstr).nBlockSize,sStorePrefix,...
                               cDataStore,...
                               vPositionMaxMemory);
            if bState
                nSuccess = nSuccess + 1;
                hBlockAdd = [hBlockAdd hBlockAddAdd]; %#ok<AGROW>
            else
                nFail = nFail + 1;
            end
        else
            nFail = nFail + 1;
            disp(['Instrumentation of channel ' xInstrument(nIdxInstr).xChannel(nIdxChannel).sName ...
                ' (' num2str(nIdxInstr) ':' num2str(nIdxChannel) ...
                ') skipped due to invalid block path: ' ...
                xInstrument(nIdxInstr).xChannel(nIdxChannel).sBlockPath]);
        end % if availability of target
    end % for
    
    % change to workspace blocks to disc storage block (ASCII)
    switch xInstrument(nIdxInstr).sSensor
        case 'ToDisc'
            xBISystemOutput = slcBlockInfo(hOutput);
            slcReplaceToWorkspaceByToStore(xBISystemOutput.BlockPath);
        otherwise
    end
end

% final message
disp(['Switching and instrumentation of ' xInstrument(end).hSystemBase ' finished:']);
disp([sprintf('% 4.0f',nSuccess) ' sensors successful instrumented.']);
disp([sprintf('% 4.0f',nFail) ' sensors failed placement']);
return

% =========================================================================

function [bState,hBlockAdd,cDataStore] = createBlockInstrument(xChannel,hOutput,...
    sBlockOrigin,nBlockSize,sStorePrefix,cDataStore,vPositionMaxMemory)
% CREATEBLOCKINSTRUMENT create blocks for signal instrumentation.
%
% Syntax:
%   [hBlockAdd,cDataStore] = createBlockInstrument(xChannel,hOutput,sBlockOrigin,nBlockSize,sStorePrefix,cDataStore)
%
% Inputs:
%       xChannel - structure with fields: 
%        .sName      - string with signal name in output
%        .sBlockPath - string with blockpath of block to signal
%        .sPortType  - port type of block, which is connected to signal
%        .nPort      - port number of block, which is connected to signal
%        .nVector    - integer with vector index of signal
%        hOutput - handle/string with blockpath of output collection subsystem
%   sBlockOrigin - string with blockpath of instrumentation block
%     nBlockSize - integer (1x2) with target size of instrumenation block
%   sStorePrefix - string with tag of output
%     cDataStore - cell with strings of channel names which are connected
%                  via DataStoreMemory blocks (unique names needed!)
%    vPositionMaxMemory - vector with maximum block in base model before
%                         instrumentation
%
% Outputs:
%         bState - boolean for successful block instrumentation
%      hBlockAdd - handle vector with all added blocks
%     cDataStore - cell with strings of channel names which are connected
%                  via DataStoreMemory blocks (unique names needed!)
%
% Example: 
%   [hBlockAdd,cDataStore] = createBlockInstrument(xChannel,hOutput,sBlockOrigin,nBlockSize,sStorePrefix,cDataStore)

% initialize output
hBlockAdd = [];
bState = true;

% get parent
sParent = get_param(xChannel.sBlockPath,'Parent');
cSystemPathTarget = pathpartsSL(sParent); % split target block path
slcDisableLink(sParent);
            
% create blockposition information for local block
nOffset = [30 20]; % offset of block (x-axis is distance, y-axis is mid of block) from source block position
xBlockInfo = slcBlockInfo(xChannel.sBlockPath);
if strcmp(xChannel.sPortType,'Inport')
    if xChannel.nPort <= xBlockInfo.Ports(1)
        nPortPos = xBlockInfo.PortCon(xChannel.nPort).Position; % get position of port
    else
        disp(['Skipped instrumentation as block inports (' num2str(xBlockInfo.Ports(1)) ...
        ') are less than specified (' num2str(xChannel.nPort) ') in channel '  ' ' xChannel.sName ': ' xChannel.sBlockPath]);
        bState = false;
        return
    end
    nPosition = [nPortPos(1)-nOffset(1)-nBlockSize(1) nPortPos(2)+nOffset(2)-0.5*floor(nBlockSize(2))];
    nPosition = [nPosition nPosition+nBlockSize]; 
elseif strcmp(xChannel.sPortType,'Outport')
    if xChannel.nPort <= xBlockInfo.Ports(2)
        nPortPos = xBlockInfo.PortCon(xBlockInfo.Ports(1)+xChannel.nPort).Position; % get position of port
    else
        disp(['Skipped instrumentation as block outports (' num2str(xBlockInfo.Ports(2)) ...
        ') are less than specified (' num2str(xChannel.nPort) ') in channel ' xChannel.sName ': ' xChannel.sBlockPath]);
        bState = false;
        return
    end
    nPosition = [nPortPos(1)+nOffset(1)  nPortPos(2)+nOffset(2)-0.5*floor(nBlockSize(2))];
    nPosition = [nPosition nPosition+nBlockSize]; 
end

% check virtual subsystem (usage of Goto/From or DataStoreMemory for remote instrumentation blocks) 
bIsSubsystemVirtual = true; % initialize value
cSystemPathOutput = pathpartsSL(hOutput); % split target block path
if ismember(sBlockOrigin,{'built-in/ToWorkspace'})
    % for all subsystem levels of block instrumentation target, which are different from output subsystem path
    for nIdxPathLevel = find(~ismember(cSystemPathTarget,cSystemPathOutput),1,'first'):length(cSystemPathTarget) 
        if strcmpi(get_param(fullfileSL(cSystemPathTarget(1:nIdxPathLevel)),'IsSubsystemVirtual'),'off') % if subsystem is not virtual
            bIsSubsystemVirtual = false; % set flag to false (use data store memory instead of Goto/From)
        end
    end
end

% add block at signal source for signal transfer to central storage block
hBlockAdd = [];
% ToWorkspace blocks will be placed in a separate subsystem to allow arbitrary sample times
if ismember(sBlockOrigin,{'built-in/ToWorkspace'}) 
    % add signal selector
    if isfield(xChannel,'nVector')
        nPositionSelector = [nPosition(1) mean(nPosition([2,4]))-10 nPosition(1)+20 mean(nPosition([2,4]))+10];
        nPosition = nPosition + [60 0 60 0];
        hBlockSelector = add_block('built-in/Selector',...
            fullfileSL(sParent,['Selector_' xChannel.sName]),...
            'MakeNameUnique','on',...
            'ShowName','off',...
            'Position',nPositionSelector,...
            'InputPortWidth','-1',...
            'Indices',num2str(xChannel.nVector));
        xBlockSelector = slcBlockInfo(hBlockSelector);
        hBlockAdd(end+1) = hBlockSelector;
        bSelector = true;
    else
        bSelector = false;
    end
    
    % add goto/DataStoreWrite block
    sMemoryInit = '';
    if bIsSubsystemVirtual
        hBlockNext = add_block('built-in/Goto',fullfileSL(sParent,['Goto_' xChannel.sName]),...
            'MakeNameUnique','on',...
            'Position',nPosition,...
            'GotoTag',[sStorePrefix '_' xChannel.sName],...
            'TagVisibility','global',...
            'Backgroundcolor','Green');
        hBlockAdd(end+1) = hBlockNext; 
    else
        % add block
        hBlockNext = add_block('built-in/DataStoreWrite',fullfileSL(sParent,['DataStoreWrite_' xChannel.sName]),...
            'MakeNameUnique','on',...
            'Position',nPosition,...
            'DataStoreName',[sStorePrefix '_' xChannel.sName],...
            'Backgroundcolor','Green');
        hBlockAdd(end+1) = hBlockNext; 
        
        % check for initial value in source block
        if strcmp('UnitDelay',get_param(xChannel.sBlockPath,'BlockType'))
            sInit = get_param(xChannel.sBlockPath,'X0');
            if strcmp('sMP.',sInit(1:min(4,numel(sInit)))) 
                sMemoryInit = [sInit '(' num2str(xChannel.nVector) ')'];
            end
        end
    end
    xBlockInfoNext = slcBlockInfo(hBlockNext);
    
    % adjust handle names for connection to source
    if bSelector
        add_line(sParent,xBlockSelector.PortHandles.Outport(1),xBlockInfoNext.PortHandles.Inport(1));
        hBlock = hBlockSelector;
    else
        hBlock = hBlockNext;
    end
elseif strcmp(sBlockOrigin,'slcVITOS/VITOS Display') % VITOS runtime oject creator
    slcLoadEnsure('slcVITOS'); % pre-load library
    hBlock = add_block(sBlockOrigin,fullfileSL(sParent,[get_param(sBlockOrigin,'BlockType') '_' xChannel.sName]),...
        'MakeNameUnique','on',...
        'Position',nPosition,...
        'Tag',xChannel.sName,...
        'Backgroundcolor','Gray');
    hBlockAdd(end+1) = hBlock; 
    
else % other sink block (e. g. display)
    % pre load source block library if necessary
    cPathBlockSource = pathpartsSL(sBlockOrigin); % split source block path
    if ~strcmpi(cPathBlockSource{1},'built-in')
        slcLoadEnsure(cPathBlockSource{1});
    end
    
    % add block
    hBlock = add_block(sBlockOrigin,fullfileSL(sParent,[get_param(sBlockOrigin,'BlockType') '_' xChannel.sName]),...
        'MakeNameUnique','on',...
        'Position',nPosition);
    hBlockAdd(end+1) = hBlock; 
end
xBlockInfoNew = slcBlockInfo(hBlock);

% connect block and check for sample rate 0.04s (needs addtional rate transition) 
bRateTransAdd = false; % bit for critical sample rate
if strcmp(xChannel.sPortType,'Inport')
    xPortSourceBlockInfo = slcBlockInfo(xBlockInfo.PortCon(xChannel.nPort).SrcBlock);
    hPortSource = xPortSourceBlockInfo.PortHandles.Outport(xBlockInfo.PortCon(xChannel.nPort).SrcPort+1);
    % check source block for sample rate
    if strcmpi(get_param(xPortSourceBlockInfo.Handle,'BlockType'),'SubSystem') && ...
            (strcmpi(get_param(xPortSourceBlockInfo.Handle,'SystemSampleTime'),'0.04') || ...
             strcmpi(get_param(xPortSourceBlockInfo.Handle,'SystemSampleTime'),'0.08'))
        bRateTransAdd = true;
    end
elseif strcmp(xChannel.sPortType,'Outport')
    hPortSource = xBlockInfo.PortHandles.(xChannel.sPortType)(xChannel.nPort);
    % check source block for sample rate
    if strcmpi(get_param(xBlockInfo.Handle,'BlockType'),'SubSystem') && ...
            (strcmpi(get_param(xBlockInfo.Handle,'SystemSampleTime'),'0.04') || ...
             strcmpi(get_param(xBlockInfo.Handle,'SystemSampleTime'),'0.08'))
        bRateTransAdd = true;
    end
else
    bState = false;
    error('slcAddInstrument:UnknownPortType',['The port type of list entry ' ...
          num2str(nIdxChannel) ' is unknown: ' xChannel.sPortType]);
end
add_line(sParent,hPortSource,xBlockInfoNew.PortHandles.Inport(1));

% add output block with arbitrary sample times
if ismember(sBlockOrigin,{'built-in/ToWorkspace'})
    [hBlockAddAdd,cDataStore] =  createBlockInstrumentRemote(xChannel,hOutput,...
        sStorePrefix,bIsSubsystemVirtual,bRateTransAdd,cDataStore,vPositionMaxMemory,sMemoryInit);
    hBlockAdd = [hBlockAdd hBlockAddAdd];
end % if ToWorkspace
return

% =========================================================================

function [hBlockAdd,cDataStore] = createBlockInstrumentRemote(xChannel,...
    hOutput,sStorePrefix,bIsSubsystemVirtual,bRateTransAdd,cDataStore,...
    vPositionMaxMemory,sMemoryInit)
% CREATEBLOCKINSTRUMENTREMOTE create the remote instrumentation blocks in
% the output subsystem. This includes From/DataStoreRead blocks, double
% type conversions, 1-2 rate transitions and the instrumentation block.
%
% Syntax:
%   [hBlockAdd,cDataStore] = createBlockInstrumentRemote(xChannel,hOutput,...
%                       sStorePrefix,bIsSubsystemVirtual,bRateTransAdd,...
%                       cDataStore,vPositionMaxMemory,sMemoryInit)
%
% Inputs:
%              xChannel - structure with fields: 
%               hOutput - handle/string with blockpath of output collection
%                         subsystem
%          sStorePrefix - string with tag of output
%   bIsSubsystemVirtual - boolean to indicate signal origin in virtual
%                         subsystem (use Goto/From instead of
%                         DataStoreMemory)
%         bRateTransAdd - boolean to add an additional 10ms rate transition
%                         as signal source is 40ms (->transfer to 100ms...)
%            cDataStore - cell with strings of channel names which are connected
%                         via DataStoreMemory blocks (unique names needed!)
%    vPositionMaxMemory - vector with maximum block in base model before
%                         instrumentation
%    sMemoryInit        - string with initialization value parameter for
%                         DataStoreMemory block
%
% Outputs:
%      hBlockAdd - handle vector with added blocks 
%     cDataStore - cell with strings of channel names which are connected
%                  via DataStoreMemory blocks (unique names needed!)
%
% Example: 
%   [hBlockAdd,cDataStore] = createBlockInstrumentRemote(xChannel,hOutput,...
%                   sStorePrefix,bIsSubsystemVirtual,bRateTransAdd,cDataStore)

% get position of output block set in output subsystem
nPositionMax = slcPositionMax(hOutput);

% add From/DataStoreRead block
hBlockAdd = [];
if bIsSubsystemVirtual % Goto/From block used
    hBlockFrom = add_block('built-in/From',fullfileSL(hOutput,['From_' xChannel.sName]),...
        'MakeNameUnique','on',...
        'Position',[50 nPositionMax(4)+30 300 nPositionMax(4)+50],...
        'GotoTag',[sStorePrefix '_' xChannel.sName]);
    hBlockAdd(end+1) = hBlockFrom;
else % DataStoreMemory block used
    % add to DataStoreMemory list
    cDataStore{end+1} = xChannel.sName;
    
    % add DataStoreRead
    hBlockFrom = add_block('built-in/DataStoreRead',fullfileSL(hOutput,['DataStoreRead_' xChannel.sName]),...
        'MakeNameUnique','on',...
        'Position',[50 nPositionMax(4)+30 300 nPositionMax(4)+50],...
        'DataStoreName',[sStorePrefix '_' xChannel.sName]);
    hBlockAdd(end+1) = hBlockFrom;

    % get instrumentation block source parent system
    sParent = get_param(xChannel.sBlockPath,'Parent');
    cSystemPathTarget = pathpartsSL(sParent); % split target block path
    
    % add DataStoreMemory on first level connecting output system and signal source
    cSystemPathOutput = pathpartsSL(hOutput);
    hSystemMemory = fullfileSL(cSystemPathTarget(1:find(~ismember(...
        cSystemPathTarget,cSystemPathOutput),1,'first')-1)); % path of first connecting level
    % get max position of data store memory blocks
    nPositionMaxStore = slcPositionMax(hSystemMemory,'BlockType','DataStoreMemory'); 
    if nPositionMaxStore(4) == 0
        nPositionMaxStore(4) = 50; % initial value for first block
    end
    vPositionMemory = [vPositionMaxMemory(3)+100 nPositionMaxStore(4)+25 ...
        vPositionMaxMemory(3)+450 nPositionMaxStore(4)+50]; % add DataStoreMemory blocks to the right
    hMemory = add_block('built-in/DataStoreMemory',fullfileSL(hSystemMemory,['Memory_' xChannel.sName]),...
        'MakeNameUnique','on',...
        'Position',vPositionMemory,...
        'DataStoreName',[sStorePrefix '_' xChannel.sName]);
    hBlockAdd(end+1) = hMemory;
    
    % try to set the determined InitialValue for the DataStoreMemory block
    if ~isempty(sMemoryInit)
        try
            set_param(hMemory,'InitialValue',sMemoryInit);
        catch ME
            fprintf(1,['slcInstrument: setting of initial value failed for ' ...
                'channel "%s" in DataStoreMemory block of instrumentation.\n'],xChannel.sName);
        end
    end
end
xBlockFrom = slcBlockInfo(hBlockFrom);

% % add signal selector
% if isfield(xChannel,'nVector') && ...
%         ~isempty(xChannel.nVector) 
%     nPosition = [330 nPositionMax(4)+30 350 nPositionMax(4)+50];
%     hBlockSelector = add_block('built-in/Selector',...
%             fullfileSL(hOutput,['Selector_' xChannel.sName]),...
%         'MakeNameUnique','on',...
%         'ShowName','off',...
%         'Position',nPosition,...
%         'InputPortWidth','-1',...
%         'Indices',num2str(xChannel.nVector));
%     xBlockSelector = slcBlockInfo(hBlockSelector);
%     hBlockAdd(end+1) = hBlockSelector;
%     add_line(hOutput,xBlockFrom.PortHandles.Outport(1),xBlockSelector.PortHandles.Inport(1));
%     bSelector = true;
% else
%     bSelector = false;
% end
bSelector = false;

% add data type conversion block
nPosition = [370 nPositionMax(4)+30 410 nPositionMax(4)+50];
hBlockDataTypeConversion = add_block('built-in/DataTypeConversion',...
    fullfileSL(hOutput,['DataTypeConversion_' xChannel.sName]),...
    'MakeNameUnique','on',...
    'ShowName','off',...
    'Position',nPosition,...
    'OutDataTypeStr','double');
xBlockDataTypeConversion = slcBlockInfo(hBlockDataTypeConversion);
hBlockAdd(end+1) = hBlockDataTypeConversion;
if bSelector
    % connect selector with data type conversion
    add_line(hOutput,xBlockSelector.PortHandles.Outport(1),...
        xBlockDataTypeConversion.PortHandles.Inport(1));
else
    % connect from block with data type conversion
    add_line(hOutput,xBlockFrom.PortHandles.Outport(1),...
        xBlockDataTypeConversion.PortHandles.Inport(1));
end

% add rate transition block
nPosition = [500 nPositionMax(4)+30 520 nPositionMax(4)+50];
hBlockRateTransition = add_block('built-in/RateTransition',...
    fullfileSL(hOutput,['RateTransition_' xChannel.sName]),...
    'MakeNameUnique','on',...
    'Position',nPosition,...
    'OutPortSampleTime',['vSampleTimeOut' sStorePrefix]);
xBlockRateTransition = slcBlockInfo(hBlockRateTransition);
hBlockAdd(end+1) = hBlockRateTransition;

if bRateTransAdd
    % add intermediate rate transition block (located before final rate
    % transition)
    nPosition = [430 nPositionMax(4)+30 450 nPositionMax(4)+50];
    hBlockRateTransitionAdd = add_block('built-in/RateTransition',...
        fullfileSL(hOutput,['RateTransition_' xChannel.sName]),...
        'MakeNameUnique','on',...
        'Position',nPosition,...
        'OutPortSampleTime','0.01');
    xBlockRateTransitionAdd = slcBlockInfo(hBlockRateTransitionAdd);
    hBlockAdd(end+1) = hBlockRateTransitionAdd;
    
    % connect data type conversion with intermediate rate transition
    add_line(hOutput,xBlockDataTypeConversion.PortHandles.Outport(1),...
        xBlockRateTransitionAdd.PortHandles.Inport(1));
    % connect intermediate rate transition with final rate transition
    add_line(hOutput,xBlockRateTransitionAdd.PortHandles.Outport(1),...
        xBlockRateTransition.PortHandles.Inport(1));
else
    % connect data type conversion with final rate transition
    add_line(hOutput,xBlockDataTypeConversion.PortHandles.Outport(1),...
        xBlockRateTransition.PortHandles.Inport(1));
end

% add to workspace block
nPosition = [610 nPositionMax(4)+30 930 nPositionMax(4)+50];
hBlockToWorkspace = add_block('built-in/ToWorkspace',fullfileSL(hOutput,['ToWorkspace_' xChannel.sName]),...
    'MakeNameUnique','on',...
    'Position',nPosition,...
    'VariableName',[sStorePrefix '__' xChannel.sName],...
    'SaveFormat','Array',...
    'MaxDataPoints','inf',...
    'SampleTime',['vSampleTimeOut' sStorePrefix]);
xBlockToWorkspace = slcBlockInfo(hBlockToWorkspace);
hBlockAdd(end+1) = hBlockToWorkspace;

% connect final rate transition with ToWorkspace
hLine = add_line(hOutput,xBlockRateTransition.PortHandles.Outport(1),xBlockToWorkspace.PortHandles.Inport(1));
set_param(hLine,'Name',[sStorePrefix '__' xChannel.sName]);
return

% =========================================================================

function [hOutput,hBlockAdd] = createOutputSubsystem(hSystem,sStorePrefix,vSampleRate)
% SLCOUTPUTSUBSYSTEMCREATE create an output subsystem for central
% collection of to disc parameters.
%
% Syntax:
%   [hOutput,hBlockAdd] = slcOutputSubsystemCreate(hSystem,sStorePrefix,vSampleRate)
%
% Inputs:
%        hSystem - handle of parent simulink system to create the block in
%   sStorePrefix - string with prefix of instrumentation block
%    vSampleRate - value (1x1) with sample time in seconds
%
% Outputs:
%   hOutput - handle of new subsystem for instrumentation
%
% Example: 
%   [hOutput,hBlockAdd] = slcOutputSubsystemCreate('NLib_mcm_m04_54_00_50/MCM__M04_54_00_50','Debug',0.1)

% intialize output
hBlockAdd = [];

% input check
if ~ischar(hSystem)
    hSystem = fullfileSL(get_param(hSystem,'Parent'),get_param(hSystem,'Name'));
end

% disable link of target system
slcDisableLink(hSystem);

% determine system position information
vPositionMax = slcPositionMax(hSystem);
if vPositionMax(4)>250 && vPositionMax(1)>500
    vPositionLeft = 80;
else
    vPositionLeft = vPositionMax(1);
end    

% add subsystem block
hSystemOutput = add_block('built-in/SubSystem',fullfileSL(hSystem,['ToDisc ' sStorePrefix]),...
    'MakeNameUnique', 'on',...
    'Position', [vPositionLeft, vPositionMax(4)+50, vPositionLeft+40, vPositionMax(4)+50+40],...
    'Backgroundcolor', 'Green',...
    'InitFcn',['if ~exist(''' ['vSampleTimeOut' sStorePrefix ] ...
               ''',''var''), assignin(''base'',''' ['vSampleTimeOut' ...
               sStorePrefix] ''',' num2str(vSampleRate) '); end']); % intialize output sample rate to 100ms
hOutput = fullfileSL(get_param(hSystemOutput,'Parent'),get_param(hSystemOutput,'Name'));
hBlockAdd(end+1) = hSystemOutput;
% generate sample time variable in base workspace
assignin('base',['vSampleTimeOut' sStorePrefix],vSampleRate);

% add time vector output
% add clock block
hBlock = add_block('built-in/Clock',fullfileSL(hOutput,'Clock'),...
    'MakeNameUnique', 'on',...
    'Position', [50 50 70 70],...
    'Backgroundcolor', 'Gray');
xBlockClock = slcBlockInfo(hBlock);
hBlockAdd(end+1) = hBlock;

% add rate transition block
hBlock = add_block('built-in/RateTransition',fullfileSL(hOutput,'RateTransition_Clock'),...
    'MakeNameUnique', 'on',...
    'Position', [150 50 170 70],...
    'OutPortSampleTime',['vSampleTimeOut' sStorePrefix],...
    'Backgroundcolor', 'Gray');
xBlockRateTransition = slcBlockInfo(hBlock);
hBlockAdd(end+1) = hBlock;

% add to workspace block
hBlock = add_block('built-in/ToWorkspace',fullfileSL(hOutput,'ToWorkspace_Clock'),...
    'MakeNameUnique', 'on',...
    'Position', [230 50 370 70],...
    'VariableName',[sStorePrefix '__' 'time'],...
    'SaveFormat','Array',...
    'MaxDataPoints','inf',...
    'SampleTime',['vSampleTimeOut' sStorePrefix],...
    'Backgroundcolor', 'Gray');
xBlockToWorkspace = slcBlockInfo(hBlock);
hBlockAdd(end+1) = hBlock;

% connect blocks
add_line(hOutput,xBlockClock.PortHandles.Outport(1),xBlockRateTransition.PortHandles.Inport(1));
hLine = add_line(hOutput,xBlockRateTransition.PortHandles.Outport(1),xBlockToWorkspace.PortHandles.Inport(1));
set_param(hLine,'Name',[sStorePrefix '__' 'time']);
return

% =========================================================================

function nPositionMax = slcPositionMax(hSystem,varargin)
% SLCPOSITIONMAX determines maximum extension of system content.
%
% Syntax:
%   nPositionMax = slcPositionMax(hSystem,varargin)
%
% Inputs:
%    hSystem - handle or string with blockpath of Simulink system
%   varargin - cell with additional find_system arguments
%
% Outputs:
%   nPositionMax - vector (1x4) with Simulink type position maximum values
%                  in system
%
% Example: 
%   nPositionMax = slcPositionMax(gcs)

cSystemContent = find_system(hSystem,'SearchDepth',1,'FollowLinks','on','Name','CM Internal',varargin{:}); % get xCM Internal block
if ~isempty(cSystemContent) % place system under xCM Internal
    nPositionMax = get_param(cSystemContent{1},'Position');
else % search maximum position occurence
    cSystemContent = find_system(hSystem,'SearchDepth',1,'FollowLinks','on',varargin{:}); % get all simulink elements of current system
    cSystemContent = cSystemContent(2:end);
    nPositionMax = [0 0 0 0]; % initialize maximum positions
    for nIdxContent = 1:length(cSystemContent) % for all blocks in system
        vPositionCurrent = get_param(cSystemContent{nIdxContent},'Position');
        nPositionMax = max(nPositionMax,vPositionCurrent); % store maximum position in current subsystem
    end
end
return

% =========================================================================

function slcReplaceToWorkspaceByToStore(hSystem)
% SLCREPLACETOWORKSPACEBYToDisc replace all ToWorkspace blocks in the
% spcified subsystem by a StoreToDisc block.
%
% Syntax:
%   slcReplaceToWorkspaceByToStore(hSystem)
%
% Inputs:
%   hSystem - handle of the subsystem to replace the to Workspace blocks
%
% Outputs:
%
% Example: 
%   slcReplaceToWorkspaceByToStore(gcs)

% input check
if nargin < 1
    hSystem = gcs;
end

% unlock bdroot (instrumentation of Library)
set_param(bdroot(hSystem),'Lock','off');

% determine ToWorkspace blocks
cToWorkspace = find_system(hSystem,'SearchDepth',1,'FollowLinks','on','BlockType','ToWorkspace');

% store information from blocks
xInfo = struct('xBiToWS',{},'xBiSource',{},'sVariableName',{},'sSignalName',{});
for nIdxToWorkspace = 1:numel(cToWorkspace)
    xInfo(nIdxToWorkspace).xBiToWS       = slcBlockInfo(cToWorkspace{nIdxToWorkspace});
    xInfo(nIdxToWorkspace).xBiSource     = slcBlockInfo(xInfo(nIdxToWorkspace).xBiToWS.PortCon.SrcBlock(1));
    xInfo(nIdxToWorkspace).sVariableName = get_param(cToWorkspace{nIdxToWorkspace},'VariableName');
    xInfo(nIdxToWorkspace).sSignalName   = get_param(xInfo(nIdxToWorkspace).xBiToWS.LineHandles.Inport(1),'Name');
    xInfo(nIdxToWorkspace).sSampleRateVar = get_param(xInfo(nIdxToWorkspace).xBiToWS.Handle,'SampleTime');
end

% determine storage name
sIdentifier = regexp(xInfo(1).sVariableName,'.+(?=__)','match','once');

% remove identifier in case of MVA output
if strcmpi(sIdentifier(1:3),'mva')
    for nIdxBlock = 1:numel(xInfo)
        xInfo(nIdxBlock).sVariableName = regexprep(xInfo(nIdxBlock).sVariableName,'.+__','');
    end
end

% resort info structure according mdl placement
vPosAll = zeros(1,numel(xInfo));
for nIdxInfo = 1:numel(xInfo)
    vPosAll(nIdxInfo) = xInfo(nIdxInfo).xBiToWS.Position(4);
end
[B,IX] = sort(vPosAll); %#ok<ASGLU>
xInfo = xInfo(IX);

% delete blocks
for nIdxInfo = 1:numel(xInfo)
    delete_block(xInfo(nIdxInfo).xBiToWS.Handle); % delete ToWorkspace block
    delete(xInfo(nIdxInfo).xBiToWS.LineHandles.Inport(1)); % delete line to block
end

% add bus creator
vPositionMax = slcPositionMax(hSystem);
hBusCreator = add_block('built-in/BusCreator',fullfileSL(hSystem,'BusCreatorStore'),...
                            'MakeNameUnique','on',...
                            'Position',[vPositionMax(3)+100 50 vPositionMax(3)+105 vPositionMax(4)],...
                            'Inputs',num2str(numel(xInfo)));
xBiBusCreator = slcBlockInfo(hBusCreator);

% add lines to bus creator
for nIdxInfo = 1:numel(xInfo)
    hLine = add_line(hSystem,...
                xInfo(nIdxInfo).xBiSource.PortHandles.Outport(xInfo(nIdxInfo).xBiToWS.PortCon.SrcPort(1)+1),...
                xBiBusCreator.PortHandles.Inport(nIdxInfo));
    set_param(hLine,'Name',xInfo(nIdxInfo).sVariableName);
end

% add storage block
slcLoadEnsure('StoreToDisc');
vPos = xBiBusCreator.PortCon(end).Position;
hStoreToDisc = add_block('StoreToDisc/StoreToDisc',fullfileSL(hSystem,'StoreToDisc'),...
                            'MakeNameUnique','on',...
                            'Position',[vPos(1)+50  vPos(2)-10 vPos(1)+250 vPos(2)+10]);
xStoreToDisc = slcBlockInfo(hStoreToDisc);
hLine = add_line(hSystem,...
                xBiBusCreator.PortHandles.Outport(1),...
                xStoreToDisc.PortHandles.Inport(1)); %#ok<*NASGU>
            
% generate bus information for block
sSignal = '';
for nIdxInfo = 1:numel(xInfo)
    sSignal = [sSignal '''' xInfo(nIdxInfo).sVariableName ''',']; %#ok
end
sSignal = ['{' sSignal(1:end-1) '}'];

% set mask parameters
cParams = get_param(hStoreToDisc,'MaskValues');
cParams{1,1} = xInfo(nIdxToWorkspace).sSampleRateVar; % variable name of sample rate
if strcmpi(sIdentifier(1:3),'mva')
    cParams{2,1} = [sIdentifier '.asc']; % sFileName
else
    cParams{2,1} = [sIdentifier '.txt']; % sFileName
end
cParams{4,1} = sSignal; % sSignal
set_param(hStoreToDisc,'MaskValues',cParams);
return


% =========================================================================
% == linked from file: fullfileSL.m 
% =========================================================================


function str = fullfileSL(varargin)
% FULLFILESL creates a simulink block path from single block names.
%
% Syntax:
%   str = fullfileSL(varargin)
%
% Inputs:
%   varargin - strings with blocknames or a cell with strings
%
% Outputs:
%   str - string with Simulink block path
%
% Example: 
%  str = fullfileSL('MyModel','Subsystem','Constant'); % returns 'MyModel/Subsystem/Constant' 
%  str = fullfileSL({'MyModel','Subsystem','Constant'}); % returns 'MyModel/Subsystem/Constant' 
%
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2013-03-26

% create homogen cell input
strcell = {};
for k = 1:nargin
    try
        if iscell(varargin{k})
            strcell = [strcell, varargin{k}]; %#ok
        else
            strcell = [strcell, varargin(k)]; %#ok
        end
    catch %#ok<CTCH>
        disp(['An error occured with input argument number ' num2str(k)]);
        rethrow(lasterror) %#ok<LERR>
    end
end
   
% remove empty cells
bEmpty = cellfun(@isempty,strcell);
strcell = strcell(~bEmpty);

% create block path
str = strcell{1};
for k = 2:length(strcell)
    str = [str '/' strcell{k}]; %#ok
end
if strcmp(str(end),'/')
    str = str(1:end-1);
end
return


% =========================================================================
% == linked from file: ismdl.m 
% =========================================================================


function bMdl = ismdl(cSystemPath)
% ISMDL checks cSystemPath for being a loaded Simulink model or submodel.
% Alternative implemetation would be with a direct try/catch find_system
% call.
%
% Syntax:
%   bMdl = ismdl(cSystemPath)
%
% Inputs:
%   cSystemPath - string or cell of strings with Simulink model paths
%
% Outputs:
%   bMdl - boolean scalar or vector true/false
%
% Example: 
%  load_system('simulink')
%  bMdl = ismdl('simulink/Sinks/Terminator')
%  bMdl = ismdl({'simulink/Sinks/Terminator','simulink/Sources/Clock'})
%  bMdl = ismdl({'simulink/NoValidSubsystem/Terminator','simulink/Sources/NoValidBlock'})
%
%
% Subfunctions:
% Private functions:
% Other m-files required:
% MAT-files required:
%
% See also: find_system 
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2013-03-26

% path input
if ~iscell(cSystemPath)
    cSystemPath = {cSystemPath};
end

% intialize output
bMdl = false(size(cSystemPath));

% check all model paths
for nIdx = 1:numel(bMdl)
    try
        bMdl(nIdx) = ~isempty(find_system(cSystemPath{nIdx},'SearchDepth',0));
    catch %#ok
        bMdl(nIdx) = false;
    end
end
return


% =========================================================================
% == linked from file: pathpartsSL.m 
% =========================================================================


function cPath = pathpartsSL(sBlockpath)
% PATHPARTSSL decompose a Simulink blockpath into the single model levels.
%
% Syntax:
%   cPath = pathpartsSL(sBlockpath)
%
% Inputs:
%   sBlockpath - string with a block path (slash '/' as model level
%                separator. Slashes as model name components must be
%                doubled '//'
%
% Outputs:
%   cPath - cell (1xn) with string of single model level names
%
% Example: 
%   cPath = pathpartsSL('test1/subsystem1/blockwithunit[kg//h]')
% % returns
% % cPath = 
% %     'test1'    'subsystem1'    'blockwithunit[kg/h]'
%
% Other m-files required: fullfileSL
%
% See also: fullfileSL, fileparts, gcb
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2013-03-26

% initialize output
cPath = {}; 

% separator string
sSep = '/'; 

% find separators
vSepPos = strfind(sBlockpath,sSep);

% catch non-path but single system call
if isempty(vSepPos)
    cPath = {sBlockpath};
    return
end

% remove double separators
vPosDouble = find(diff(vSepPos)==1); % get first element of a double position
vPosDouble = [vPosDouble, vPosDouble+1]; % add second element of double position to list
vSepPos = vSepPos(~ismember(vSepPos,vSepPos(vPosDouble)));
vSepPos = sort(vSepPos);

% remove leading and ending separators
if vSepPos(1) == 1
    vSepPos = vSepPos(2:end);
    sBlockpath = sBlockpath(2:end);
end

if ~isempty(vSepPos) && vSepPos(end) == length(sBlockpath)
    vSepPos = vSepPos(1:end-1);
    sBlockpath = sBlockpath(1:end-1);
end

% split blockpath according separator positions
vSepPos = [vSepPos length(sBlockpath)+1];
nPosLast = 0;
cPath = cell(1,length(vSepPos));
for nPart = 1:length(vSepPos)
%     cPath{nPart} =strrep(sBlockpath(nPosLast+1:vSepPos(nPart)-1),'//','/'); % get part and remove double slash
    cPath{nPart} = sBlockpath(nPosLast+1:vSepPos(nPart)-1); % get part 
    nPosLast = vSepPos(nPart);
end
return



% =========================================================================
% == linked from file: slcBlockInfo.m 
% =========================================================================


function cb = slcBlockInfo(hp)
% slcBlockInfo - generates a structure with important block properties.
% (for lean code with reduced get_param calls)
% 
% Input variables:
% hp            - handle or path to block or handle vector or cell with
%                 block paths
% 
% Output variables:
% cb           - struct with
%   .Name               - string 
%   .Handle             - double/handle
%   .Parent             - string with full path of parent
%   .BlockPath        	- string with full path of block
%   .BlockType          - string with block type
%   .MaskType           - string with mask type
%   .Ports              - vector (1x8) with amount of port types
%                         1: Inport, 2: Outport
%   .PortCon         	- structure (1xNumberOfAllPorts) with
%       .Type           - string with number of port type (1-8)
%       .Position       - vector(1x2) with position
%       .SrcBlock       - handle of source block (only if port is Inport)
%       .SrcPort        - vector with handles of inports
%       .DstBlock       - handle of source block (only if port is Outport)
%       .DstPort        - vector with handles of inports
%   .PortHandles        - structure with
%       .Inport         - vector with handles of inports
%       .Outport        - vector with handles of outports
%       .Enable         - vector with handles 
%       .Trigger        - vector with handles 
%     	.State          - vector with handles 
%     	.LConn          - vector with handles 
%     	.RConn          - vector with handles 
%       .Ifaction       - vector with handles 
%   .LineHandles      	- handle of "upstream" line if branched,  
%       .Inport         - vector with line handles of inports
%       .Outport        - vector with line handles of outports
%       .Enable         - vector with line handles 
%       .Trigger        - vector with line handles 
%     	.State          - vector with line handles 
%     	.LConn          - vector with line handles 
%     	.RConn          - vector with line handles 
%       .Ifaction       - vector with line handles 
%   .Position           - vector (1x4) absolute point extensions of block
%                         (left top right bottom)
%   .Tag                - string with tag of block

% take current block if not specified
if nargin == 0
    hp = gcb;
end

% ensure handle (not path)
if ischar(hp)
    hp = get_param(hp,'Handle');
end


% ensure cell type of hp
if all(ishandle(hp)) 
    hp = num2cell(hp);
end

% reduce to block handles only
tf = cell2mat(cellfun(@(x)strcmpi(get_param(x,'Type'),'block'),hp,'UniformOutput',false));
hp = hp(tf);

% initialize output structure
cb = struct('Name',[],'Handle',[],'Parent',[],'BlockPath',[],... 
            'BlockType',[],'MaskType',[],'Ports',[],...
            'PortCon',[],'PortHandles',[],'LineHandles',[],'Position',[]);
        
% get block information
for k = 1:numel(hp)
    cb(k).Name = get_param(hp{k},'Name');
    cb(k).Handle = get_param(hp{k},'Handle');
    cb(k).Parent = get_param(hp{k},'Parent');
    cb(k).BlockPath = [cb(k).Parent '/' cb(k).Name];
    cb(k).BlockType = get_param(hp{k},'BlockType');
    cb(k).MaskType = get_param(hp{k},'MaskType');
    cb(k).Ports = get_param(hp{k},'Ports');
    cb(k).PortCon = get_param(hp{k},'PortConnectivity');
    cb(k).PortHandles = get_param(hp{k},'PortHandles');
    cb(k).LineHandles = get_param(hp{k},'LineHandles');
    cb(k).Position = get_param(hp{k},'Position');
    cb(k).Tag = get_param(hp{k},'Tag');
end
return


% =========================================================================
% == linked from file: slcDisableLink.m 
% =========================================================================


function sRefBlockPath = slcDisableLink(hBlock)
% SLCDISABLELINK disable the library link of the block in the simulink
% model.
% 
% If a block is linked to a library then its contents cannot be changed as
% long as the link is active. This function disables the link of the
% "hBlock" or its parent subsystem so that its content can be 
% modified. The output "sRefBlockPath" is the path of the "hBlock" in the
% library. Example: let's say that the full path of the input
% "hBlock" is system/subsys1/subsys2/blockName and assumed that
% subsys1 is a link to the library "lib1" then this function returns the
% string "lib1/subsys1/subsys2/blockName".
%
% Syntax:
%   sRefBlockPath = slcDisableLink(hBlock)
%
% Inputs:
%   hBlock - handle or string with blockpath of a simulink block 
%
% Outputs:
%   sRefBlockPath - string with path of the block "hBlock" in the library
%
% Example: 
%   sRefBlockPath = slcDisableLink(hBlock)
%
%
% Subfunctions:
% Private functions:
% Other m-files required:
% MAT-files required:
%
% See also: fullfileSL, pathpartsSL
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2013-03-26

% initialize output
sRefBlockPath = '';

% generate full block path
sBlockParent = get_param(hBlock,'Parent');
sBlockName = get_param(hBlock,'Name');

sBlockPath = [sBlockParent '/' strrep(sBlockName,'/','//')];

% generate cell with blockpath elements (do not use strfind with '/' onto
% the full block path as slash can also be in the block name)
cBlockPath = pathpartsSL(sBlockPath);

% The for-loop is until the parent index is 2 since if nIdxParent = 1 
% then it is the top level model which doesn't have the property "LinkStatus"
for nIdxParent = length(cBlockPath):-1:2
   sParentCurrent = fullfileSL(cBlockPath(1:nIdxParent));
   linkStatus = get_param(sParentCurrent,'LinkStatus');
   if strcmp(linkStatus,'resolved')
       set_param(sParentCurrent,'LinkStatus','inactive');
%        fprintf(1,'debug slcDisableLink: %s\n',sParentCurrent);
       if nIdxParent == length(cBlockPath)
           sRefBlockPath = get_param(sParentCurrent,'AncestorBlock');
       else
           sRefBlockPath = fullfileSL([{get_param(sParentCurrent,'AncestorBlock')} cBlockPath(nIdxParent:end)]);
       end
       return
   end
end
return



% =========================================================================
% == linked from file: slcLoadEnsure.m 
% =========================================================================


function slcLoadEnsure(mdlpath,bVerbose)
% slcLoadEnsure - returns vector with all line handles from specified line
% up to the next trunk line.
% 
% Input variables:
% mdlpath       - string with mdl-name on MATLAB path or mdl-filename with
%                 full path
% bVerbose      - boolean verbose flag: false - no display
%                                       true - display message if no load
% 
% Example call:
% slcLoadEnsure('mymodel')
% slcLoadEnsure('mymodel',false)

if nargin < 2
    bVerbose = false;
end

% divide path
[path,filename,ext] = fileparts(mdlpath);

% check input elements
if ~isempty(path) && exist(path,'dir') ~= 7
    error('slcLoadEnsure:FilepathNotValid',['The specified file path is not valid: ' path]);
end
if ~ismember(exist(mdlpath,'file'),[2,4]) && ~ismember(exist([mdlpath '.mdl'],'file'),[2,4])
    error('slcLoadEnsure:FileNotValid',['The specified file is not valid: ' mdlpath]);
end
if exist(mdlpath,'file')~=4 && ~strcmpi(ext,'.mdl')
    error('slcLoadEnsure:FileNotMdl',['The specified file is no Simulink model: ' mdlpath]);
end
if isempty(path)
    path = pwd;
end
   
% check if specified model is already loaded
TFload = true;
if ismdl(filename) && strcmpi(get_param(filename,'filename'),which(mdlpath))
    TFload = false;
    if bVerbose
        disp(['slcLoadEnsure: ' filename ' is already loaded from path: ' path])
    end
end
   
% load simulink model
if TFload
    load_system(mdlpath);
end
return
