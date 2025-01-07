function xConfiguration = dcsLoggingPltmExpand(xConfiguration,sPathContent)
% DCSLOGGINGPLTMEXPAND expand LDYN logging datasets in to standard DIVe
% configuraion logging entries.
%
% Syntax:
%   xConfiguration = dcsLoggingPltmExpand(xConfiguration,sPathContent)
%
% Inputs:
%   xConfiguration - structure with fields of a DIVe Configuration
%       .ModuleSetup
%       .Interface
%         .Logging
%         .OpenPort
%         .Signal
%     
%     sPathContent - string with path of DIVe Content folder
%
% Outputs:
%   xConfiguration - structure with fields: 
%
% Example: 
%   xConfiguration = dcsLoggingPltmExpand(xConfiguration,sPathContent)
%
% See also: dpsPathLevel
%
% Author: Rainer Frey, TP/EAC, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2018-02-16

nLog = find(~cellfun(@isempty,regexp({xConfiguration.ModuleSetup.name},'^log','once')));
if isempty(nLog)
    % species log defined
    return
end

% check for pltm.log species
xModule = xConfiguration.ModuleSetup(nLog(1)).Module;
if ~strcmp(xModule.family,'ld') || ~strcmp(xModule.context,'pltm')
    % only LDYN format can be expanded - no CB Silver, etc.
    return
end
bDataSet = strcmp('logcfg',{xConfiguration.ModuleSetup(nLog(1)).DataSet.className});
xDataSet = xConfiguration.ModuleSetup(nLog(1)).DataSet(bDataSet);

% get log dataset file
sPathModule = fullfile(sPathContent,xModule.context,xModule.species,xModule.family,...
    xModule.type,'Module',xModule.variant);
sFileXml = fullfile(dpsPathLevel(sPathModule,xDataSet.level),'Data',xDataSet.classType,...
    xDataSet.variant,[xDataSet.variant '.xml']);
if exist(sFileXml,'file') ~= 2
   % xml-file in dataset
    return
end

% get log data from file
xTree = dsxRead(sFileXml);
nMFile = find(~cellfun(@isempty,regexp({xTree.DataSet.DataFile.name},'\.m$','once')));
sMFile = fullfile(fileparts(sFileXml),xTree.DataSet.DataFile(nMFile(1)).name);
xData = dpsLoadStandardFile(sMFile);
if isfield(xData,'sigLogCfg') && isfield(xData.sigLogCfg,'sig')
    cLog = xData.sigLogCfg.sig;
else
   % no LDYN logging info structure in m-file
    umsMsg('DIVe',2,'dmb: no sigLogCfg.sig structure pltm.log file - stopped logging expansion (%s)',sMFile);
   return
end

% prepare cells for checking log signals
if isfield(xConfiguration.Interface,'OpenPort') && ...
        ~isempty(xConfiguration.Interface.OpenPort)
    cOpenPort = {xConfiguration.Interface.OpenPort.name};
else
    cOpenPort = {};
end
if isfield(xConfiguration.Interface,'Constant') && ...
        ~isempty(xConfiguration.Interface.Constant)
    cConstant = {xConfiguration.Interface.Constant.name};
else
    cConstant = {};
end
if isfield(xConfiguration.Interface,'Signal') && ...
        ~isempty(xConfiguration.Interface.Signal)
    cSignal = {xConfiguration.Interface.Signal.name};
else
    cSignal = {};
end
if isfield(xConfiguration.Interface,'Logging') && ...
        ~isempty(xConfiguration.Interface.Logging)
    cLogging = {xConfiguration.Interface.Logging.name};
else
    xConfiguration.Interface.Logging = struct('name',{},'unit',{},'modelRef',{});
    cLogging = {};
end

% overwrite configuration settings
xSet.Logging = dcsCfgLogSetupGet(xConfiguration,'ToWorkspace','0.1');
if isfield(xData.sigLogCfg,'sampletime')
    if ischar(xData.sigLogCfg.sampletime)
        xSet.Logging.sampleTime = xData.sigLogCfg.sampletime;
    elseif isnumeric(xData.sigLogCfg.sampletime)
        xSet.Logging.sampleTime = num2str(xData.sigLogCfg.sampletime);
    else
        error('dcsLoggingPltmExpand:unknownVarTypeForSampleTime',...
            ['The variable type of xData.sigLogCfg.sampletime is not valid' ...
            'for Simulink Simulation technology (only numeric or string allowed)'...
            ' - please check your pltm.log.ld dataset m-file.'])
    end
end
xConfiguration.Interface.LogSetup = xSet.Logging;
if isfield(xData.sigLogCfg,'decimation')
    xSet.Logging.Decimation = xData.sigLogCfg.decimation;
end
if isfield(xData.sigLogCfg,'lastvalue')
    xSet.Logging.LastValue = xData.sigLogCfg.lastvalue;
end

% expand values on tag "all" -> only outports
if strcmp(cLog{1,1},'all') && strcmp(cLog{1,2},'all')
    cLog = [cConstant'; cOpenPort'; cSignal'];
end

% add logging signals accordingly
for nIdxLog = 1:size(cLog,1)
    if strcmp('all',cLog{nIdxLog,1})
        %% log complete Module
        sModule = cLog{nIdxLog,2};
        % determine signal, constant and openport belonging to species
        if ~exist('cRefSignal','var') % only needed once
            cRefSignal = {xConfiguration.Interface.Signal.modelRefSource};
            cRefSignal = regexp(cRefSignal,'^.+[a-zA-Z]','match','once'); % remove obsolete integer
            cRefSignalDest = arrayfun(@(x)x.destination.modelRef,xConfiguration.Interface.Signal,'UniformOutput',false);
            cRefSignalDest = regexp(cRefSignalDest,'^.+[a-zA-Z]','match','once'); % remove obsolete integer
            cRefSignalDestName = arrayfun(@(x)x.destination.name,xConfiguration.Interface.Signal,'UniformOutput',false);
            cRefOpen = {xConfiguration.Interface.OpenPort.modelRef};
            cRefOpen = regexp(cRefOpen,'^.+[a-zA-Z]','match','once'); % remove obsolete integer
            cRefConst = {xConfiguration.Interface.Constant.modelRef};
            cRefConst = regexp(cRefConst,'^.+[a-zA-Z]','match','once'); % remove obsolete integer
        end
%         bRefSignal = ~cellfun(@isempty,regexp(cRefSignal,['^' sModule],'once'));
        bRefSignal = strcmp(sModule,cRefSignal);
        nRefSignal = find(bRefSignal);
%         bRefSignalDest = ~cellfun(@isempty,regexp(cRefSignalDest,['^' sModule],'once'));
        bRefSignalDest = strcmp(sModule,cRefSignalDest);
        nRefSignalDest = find(bRefSignalDest);
%         bRefOpen = ~cellfun(@isempty,regexp(cRefOpen,['^' sModule],'once'));
        bRefOpen = strcmp(sModule,cRefOpen);
        nRefOpen = find(bRefOpen);
%         bRefConst = ~cellfun(@isempty,regexp(cRefConst,['^' sModule],'once'));
        bRefConst = strcmp(sModule,cRefConst);
        nRefConst = find(bRefConst);
        
        % limit to unique logging (pltm.log vs native configuration logging)
        bDoubleSignal = ismember({xConfiguration.Interface.Signal(bRefSignal).name},...
                                 {xConfiguration.Interface.Logging.name});
        [bRefSignal(nRefSignal(bDoubleSignal))] = deal(false);
        bDoubleSignalDest = ismember(cRefSignalDestName(bRefSignalDest),...
                                 {xConfiguration.Interface.Logging.name});
        [bRefSignalDest(nRefSignalDest(bDoubleSignalDest))] = deal(false);
        bDoubleSignal = ismember({xConfiguration.Interface.OpenPort(bRefOpen).name},...
                                 {xConfiguration.Interface.Logging.name});
        [bRefOpen(nRefOpen(bDoubleSignal))] = deal(false);
        bDoubleSignal = ismember({xConfiguration.Interface.Constant(bRefConst).name},...
                                 {xConfiguration.Interface.Logging.name});
        [bRefConst(nRefConst(bDoubleSignal))] = deal(false);
        
        % add port & signals to logging structure
        if any(bRefSignal) % from signals
            xLogAdd = struct('name',{xConfiguration.Interface.Signal(bRefSignal).name},...
                             'unit',repmat({''},1,sum(bRefSignal)),...
                             'modelRef',{xConfiguration.Interface.Signal(bRefSignal).modelRefSource});
            xConfiguration.Interface.Logging = structConcat(xConfiguration.Interface.Logging,xLogAdd);
        end
        if any(bRefSignalDest) % from signals destination
            xLogAdd = struct('name',cRefSignalDestName(bRefSignalDest),...
                             'unit',repmat({''},1,sum(bRefSignalDest)),...
                             'modelRef',cRefSignalDest(bRefSignalDest));
            xConfiguration.Interface.Logging = structConcat(xConfiguration.Interface.Logging,xLogAdd);
        end
        if any(bRefOpen) % from open ports
            xLogAdd = struct('name',{xConfiguration.Interface.OpenPort(bRefOpen).name},...
                             'unit',repmat({''},1,sum(bRefOpen)),...
                             'modelRef',{xConfiguration.Interface.OpenPort(bRefOpen).modelRef});
            xConfiguration.Interface.Logging = structConcat(xConfiguration.Interface.Logging,xLogAdd);
        end
        if any(bRefConst) % from constants
            xLogAdd = struct('name',{xConfiguration.Interface.Constant(bRefConst).name},...
                             'unit',repmat({''},1,sum(bRefConst)),...
                             'modelRef',{xConfiguration.Interface.Constant(bRefConst).modelRef});
            xConfiguration.Interface.Logging = structConcat(xConfiguration.Interface.Logging,xLogAdd);
        end
        
    elseif ~any(strcmp(cLog{nIdxLog,1},cLogging))
        %% add logging item based on signal or open port information
        bSignal = strcmp(cLog{nIdxLog,1},cSignal);
        bOpenPort = strcmp(cLog{nIdxLog,1},cOpenPort);
        bConstant = strcmp(cLog{nIdxLog,1},cConstant);
        if any(bSignal)
            % add based on signal information
            xConfiguration.Interface.Logging(end+1).name = cLog{nIdxLog,1};
            xConfiguration.Interface.Logging(end).unit = '';
            xConfiguration.Interface.Logging(end).modelRef = ...
                xConfiguration.Interface.Signal(bSignal).modelRefSource;
        elseif any(bOpenPort)
            % add based on OpenPort information
            xConfiguration.Interface.Logging(end+1).name = cLog{nIdxLog,1};
            xConfiguration.Interface.Logging(end).unit = '';
            xConfiguration.Interface.Logging(end).modelRef = ...
                xConfiguration.Interface.OpenPort(bOpenPort).modelRef;
        elseif any(bConstant)
            % add based on OpenPort information
            xConfiguration.Interface.Logging(end+1).name = cLog{nIdxLog,1};
            xConfiguration.Interface.Logging(end).unit = '';
            xConfiguration.Interface.Logging(end).modelRef = ...
                xConfiguration.Interface.Constant(bConstant).modelRef;
        else
            fprintf(1,['   Log by pltm.log (fail): signal "%s" could not be ' ...
                'added, as it is not available in this configuration.\n'],...
                cLog{nIdxLog,1});
        end
    end
end
return