function [xInstrument,xSwitch] = spsEcuInstrumentPrepare(xInstrument,xSwitch,sPathModel,sPathMat)
% SPSECUINSTRUMENTPREPARE prepare instrumentation structure for usage by
% loading data channels from specified files.
%
% Syntax:
%   spsEcuInstrumentPrepare(xInstrument,xSwitch,sPathModel,sPathMat)
%
% Inputs:
%   xInstrument     - structure with fields: 
%     .sName        - string with name of output file
%     .sSensor      - string with sensor type: ToDisc, Display, ToWorkspace, ViTOS
%     .vSampleRate  - value with sample rate
%     .cChannelFile - cell with strings of data channel description files
%   xSwitch         - structure vector with fields: 
%     .sFrameName   - string with name of ECU frame to be switched to an
%                     open Simulink frame 
%        sPathModel - string with Simulink block path of ECU model block
%                     (will be patched into channel description to prevent
%                     time intensive find_system call) 
%        sPathMat - string with path of xChannel_xy.mat files
%
% Outputs:
%   xInstrument - structure with fields: 
%     .sName        - string with name of output file
%     .sSensor      - string with sensor type: ToDisc, Display, ToWorkspace, ViTOS
%     .vSampleRate  - value with sample rate
%     .cChannelFile - cell with strings of data channel description files
%     .hSystemBase  - handle/string with block (path) of the Simulink 
%                     subsystem, on which the instrumentation information
%                     is based and where any central blocks are placed. 
%     .xChannel     - structure vector with fields:
%       .sName      - string with storage name of data channel
%       .sBlockPath - string with Simulink block path of data channel
%                     origin
%       .sPortType  - string with porttype of data channel origin
%                     {Inport|Outport}
%       .nPort      - integer with port index
%   xSwitch     - structure vector with fields: 
%     .sFrameName   - string with name of ECU frame to be switched to an
%                     open Simulink frame 
%
% Example: 
%   [xInstrument,xSwitch] = spsEcuInstrumentPrepare(xInstrument,xSwitch,sPathModel,sPathMat)

% input check
if ~exist('sPathMat','var')
    sPathMat = '';
end
[sPathParent,sModel] = fileparts(sPathModel);

% check Simulink model for availability of complete main bus
if ~isempty(sPathParent)
    bMain = ~isempty(find_system(sPathParent,...
        'SearchDepth',1,'BlockType','Inport','Name','main [Bus]'));
else 
    bMain = false;
end

% prepare data structure for each instrumentation setup
cOutputMVA = {};
for nIdxInstr = 1:numel(xInstrument)
    % add handle of base instrumentation subsystem
    xInstrument(nIdxInstr).hSystemBase = sPathParent;
    
    % initialize substructure of data channels
    xInstrument(nIdxInstr).xChannel = struct('sName',{},'sBlockPath',{},...
                                             'sPortType',{},'nPort',{},'nVector',{});
    
    % for all specified channel files
    for nIdxFile = 1:numel(xInstrument(nIdxInstr).cChannelFile)
        % load instrumentation channels
        if isempty(sPathMat) || ~exist(sPathMat,'dir')
            xLoad = load(which(xInstrument(nIdxInstr).cChannelFile{nIdxFile}));
        else
            xLoad = load(fullfile(sPathMat,xInstrument(nIdxInstr).cChannelFile{nIdxFile}));
        end
        % patch vector size information
        if ~isfield(xLoad.xChannel,'nVector')
            for nIdxChannel = 1:numel(xLoad.xChannel)
                xLoad.xChannel(nIdxChannel).nVector = 1;
            end
        end
        
        % merge structures
        xInstrument(nIdxInstr).xChannel = structConcat(xInstrument(nIdxInstr).xChannel,xLoad.xChannel);
    end
    
    % ensure unique instrumentation name within block
    [cUnique,nUnique] = unique({xInstrument(nIdxInstr).xChannel.sName}); 
    if numel(cUnique) < numel(xInstrument(nIdxInstr).xChannel)
        % display 
        fprintf(2,['Double channel names (%1.0f of %1.0f) were skipped '...
            'during the instrumentation of "%s" for file "%s":\n'],...
            numel(xInstrument(nIdxInstr).xChannel)-numel(cUnique),...
            numel(xInstrument(nIdxInstr).xChannel),...
            sPathModel,xInstrument(nIdxInstr).sName);
        bOmit = true(1,numel(xInstrument(nIdxInstr).xChannel));
        [bOmit(sort(nUnique))] = deal(false);
        cOmit = {xInstrument(nIdxInstr).xChannel(bOmit).sName};
        for nIdxOmit = 1:numel(cOmit)
            fprintf(2,'   %s\n',cOmit{nIdxOmit});
        end
    end
     xInstrument(nIdxInstr).xChannel = xInstrument(nIdxInstr).xChannel(sort(nUnique));
   
    % check all channels
    bOutputMVA = false(1,numel(xInstrument(nIdxInstr).xChannel));
    for nIdxChannel = 1:numel(xInstrument(nIdxInstr).xChannel)
        % check for additional needed open frame
        sFrame = regexp(xInstrument(nIdxInstr).xChannel(nIdxChannel).sBlockPath,...
                        '(?<=/)\w+_frame(?=/)','match','once');
        if ~isempty(sFrame) && ~any(strcmp(sFrame,{xSwitch.sFrameName}))
            xSwitch(end+1).sFrameName = sFrame; %#ok<AGROW>
        end
        
        % check for MVA output channels
        sOutputMVA = regexp(xInstrument(nIdxInstr).xChannel(nIdxChannel).sBlockPath,...
                            'OutputMVA\w+(?=/)','match','once');
        if ~isempty(sOutputMVA) % channel is in block OutputMVA (signals of foreign modules)
            % list of MVA channels
            bOutputMVA(nIdxChannel) = true;
            % add OutputMVa variant
            if ~any(strcmp(sOutputMVA,cOutputMVA))
                cOutputMVA{end+1} = sOutputMVA; %#ok<AGROW>
            end
        else % instrument channel is not in special block OutputMVA
            % patch ECU block name into channel blockpath
            xInstrument(nIdxInstr).xChannel(nIdxChannel).sBlockPath = fullfileSL(...
                sModel,xInstrument(nIdxInstr).xChannel(nIdxChannel).sBlockPath);
        end
    end % for xChannel
    
    % delete OutputMVA channels, if platform does not provide "main [Bus]"
    % for OutputMVA connections (outputMVA uses non-module channels)
    if ~bMain
        xInstrument(nIdxInstr).xChannel = xInstrument(nIdxInstr).xChannel(~bOutputMVA);
    end
end % for  xInstrument

% add OutputMVA subsystem to module wrapper
if bMain && ~isempty(cOutputMVA)
    % load OutputMVA lib
    slcLoadEnsure('OutputMVA');
    
    % copy block into wrapper
    if ismdl(sPathModel)
        nPosBlock = get_param(sPathModel,'Position');
    else % not present due to co-simulation
        nPosBlock = [55 55 400 600];
        fprintf(2,['CAUTION: ECU instrumentation is limited, as ECU model ' ...
            'is in another co-simulation instance.']);
    end
    for nIdxOut = 1:numel(cOutputMVA)
        hBlock = add_block(fullfileSL('OutputMVA',cOutputMVA{nIdxOut}),...
            fullfileSL(fileparts(sPathModel),cOutputMVA{nIdxOut}));
        slcSetBlockPosition(hBlock,[nPosBlock(1),nPosBlock(4)+150,-1,-1]);
        add_line(fileparts(sPathModel),'main [Bus]/1',[cOutputMVA{nIdxOut} '/1'],...
            'autorouting','on');
    end
    
    % close OutputMVA library
    close_system('OutputMVA');
end
return
