function dmsPemsEvaluateSim(sPath,bSilent)
% DMSPEMSEVALUATESIM evaluate PEMS on a DIVe MB simulation. Wrapper file to
% generate the input for dmsPemsEvaluate from DIVe MB simulation results
% with phys.eng.detail.gtrm and ctrl.mcm.mil/sil models.
%
% Syntax:
%   dmsPemsEvaluateSim(sPath)
%   dmsPemsEvaluateSim(sPath,bSilent)
%
% Inputs:
%     sPath - string with path of DIVeMB result folder
%   bSilent - boolean if user dialogues shall be avoided
%
% Outputs:
%
% Example: 
%   dmsPemsEvaluateSim(pwd,true)
%
% See also: dmsPemsEvaluate, dmsPemsEvaluateSim, uniread
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2018-05-14

%% check input
if nargin < 1
    % get GLM project folder
    [sPath] = uigetdir(pwd,...
        'Open folder with PEMS results');
    if isnumeric(sPath) && sPath == 0, return; end
end
if nargin < 2
    bSilent = false;
end

%% settings
% settings of PEMS evaluation
data.percentiles = [90 95 100];% %
data.worklimitprz = [0 9 10];

%% load data
% load transient data
sFileCollect = fullfile(sPath,'MVA_collectAll.mat');
if exist(sFileCollect,'file')
    xSource = uniread(sFileCollect);
else
    fprintf(1,['dmsPemsEvaluateSim: No MVA_collectAll.mat file - stopping ' ...
        'evaluation as necessary input is missing.\n']);
    return
end

% assign transient data with downsampling to 1Hz
data.reczeit = (xSource.subset.data.value(1,1):1:xSource.subset.data.value(end,1))'; % [s] time
bMeff = strcmp(xSource.subset.data.name,'MEFFW');
data.meff = interp1(xSource.subset.data.value(:,1),...
    xSource.subset.data.value(:,bMeff),data.reczeit,'linear'); % [Nm]
bNmot = strcmp(xSource.subset.data.name,'NMOTW');
data.nmot = interp1(xSource.subset.data.value(:,1),...
    xSource.subset.data.value(:,bNmot),data.reczeit,'linear'); % min-1
bTwa = strcmp(xSource.subset.data.name,'TWA');
if any(bTwa)
    data.twa = interp1(xSource.subset.data.value(:,1),...
        xSource.subset.data.value(:,bTwa),data.reczeit,'linear'); %°C
end

bMNoxh = strcmp(xSource.subset.data.name,'MNOXH');
if any(bMNoxh)
    % usually not available (for testing)
    data.mnoxh = interp1(xSource.subset.data.value(:,1),...
        xSource.subset.data.value(:,bMNoxh),data.reczeit,'linear');
else
    % asign transient data for NOx calculation
    bNoxn = strcmp(xSource.subset.data.name,'NOXN');
    data.noxn = interp1(xSource.subset.data.value(:,1),...
        xSource.subset.data.value(:,bNoxn),data.reczeit,'linear'); % molfrac
    bMlonl = strcmp(xSource.subset.data.name,'MLONL');
    data.mlonl = interp1(xSource.subset.data.value(:,1),...
        xSource.subset.data.value(:,bMlonl),data.reczeit,'linear'); % kg/h
    bMbonl = strcmp(xSource.subset.data.name,'MBONL');
    data.mbonl = interp1(xSource.subset.data.value(:,1),...
        xSource.subset.data.value(:,bMbonl),data.reczeit,'linear'); % kg/h
    bMbee = strcmp(xSource.subset.data.name,'MBEE');
    data.mbee = interp1(xSource.subset.data.value(:,1),...
        xSource.subset.data.value(:,bMbee),data.reczeit,'linear'); % kg/h
end

% determine stationary file
xFileWS = dir(fullfile(sPath,'WS*.mat'));
cFileWS = {xFileWS.name};
cPrompt = arrayfun(@(x)[sprintf('% 7.2fMb',x.bytes./1024^2) '  ' datestr(x.datenum) '  ' x.name],...
                   xFileWS,'UniformOutput',false);
if numel(cFileWS) > 1
    if bSilent
        fprintf(1,['dmsPemsEvaluateSim: Multiple workspace files - stopping ' ...
            'evaluation as user input in silent mode is needed.\n']);
        return
    else
        nFile = listdlg('Name','Select Workspace File',...
            'SelectionMode','single',...
            'ListSize',[700 250],...
            'PromptString','Please select the DIVeMB WS File',...
            'ListString',cPrompt);
        if isempty(nFile)
            fprintf(1,'dmsPemsEvaluateSim: User canceled file selection.\n');
            return
        end
    end
else
    nFile = 1;
end

% load stationary simulation data
xTree = load(fullfile(sPath,cFileWS{nFile}),'sMP');
if isfield(xTree,'sMP') 
    % get power rating from mcm dataset
    vPowerRating = xTree.sMP.ctrl.mcm.sys_can_performance_class_1m; % [kW]
    nCylinder = xTree.sMP.ctrl.mcm.sys_cylinder_value_1m; % [-]
    
    % get coolant outlet temperature as steady state
    if ~isfield(data,'twa')
        data.twa = ones(size(data.reczeit)) .* xTree.sMP.phys.eng.in.eng_CoolantEngineOut_Temperature;
    end
    
    % get engine model
    cSetupName = {xTree.sMP.cfg.Configuration.ModuleSetup.name};
    bSetupName = strcmp('eng',cellfun(@(x)x(1:3),cSetupName,'UniformOutput',false));
    if any(bSetupName)
        cClassName = {xTree.sMP.cfg.Configuration.ModuleSetup(bSetupName).DataSet.className};
        bClass = strcmp('mainData',cClassName);
        sEngine = xTree.sMP.cfg.Configuration.ModuleSetup(bSetupName).DataSet(bClass).variant;
        sEngine = regexp(sEngine,'^[a-zA-Z0-9]+','match','once');
    end
else
    fprintf(2,'Missing sMP variable in file:\n%s\n',fullfile(sPath,cFileWS{nFile}));
    return
end

% WHTC working window
% windowwork = 35.2; %kWh
% Info from Metodi Aleksandrov, Übersicht_MDEG_WHTC_Arbeit_NNL, 18.05.2018 12:17
%                EngineType     kW  kWh_of_WHTC  Measurement_comment
cWhtcWork = {    'OM934DTCEU6'	170	15.19	 'BB462 934ES3684'
                 'OM934DTCEU6'	155	14.28	 'BB453 934ES3684'
                 'OM934STCEU6'	130	12.41	 'BB149 934ES4028'
                 'OM934STCEU6'	115	10.52	 'BB140 934ES4028'
                 'OM936DTCEU6'	260	23.29	 'BB323 936ED4035'
                 'OM936DTCEU6'	235	21.5	 'BB315 936ED4035'
                 'OM936STCEU6'	220	20.39	 'BB719 936ES4033'
                 'OM936STCEU6'	200	18.65	 'BB437 936ES4033'
                 'OM936STCEU6'	175	16.56	 'BB495 936ES4033'
                 'OM936hDTCEU6'	260	23.5	 ''
                 'OM936hDTCEU6'	220	20.4	 ''
                 'OM471TestDummy'	380	35.2	 ''};
% reduce to engine type
bWork = strcmp(sEngine,cWhtcWork(:,1));
if any(bWork)
    cWhtcWork = cWhtcWork(bWork,:);
else
    fprintf(2,['WHTC work of engine type could not be determined from '...
        'internal table! Stopping evaluation...\n']);
    return
end
bRating = vPowerRating==cell2mat(cWhtcWork(:,2));
if any(bRating)
    cWhtcWork = cWhtcWork(bRating,:);
    vWorkWhtc = cWhtcWork{1,3};
else
    fprintf(2,['WHTC work of engine type could not be determined from '...
        'internal table! Stopping evaluation...\n']);
    return
end
             
if ~any(bMNoxh)
    % NOx massflow calculation and MBONL backup
    if max(data.mbonl)<0.001 % assume non consistent MBONL dataset
        data.mbonl = data.mbee.*data.nmot*0.5*nCylinder*60*1e-6; % mg/injection -> kg/h take MBEE instead
    end
    data.makh = (data.mlonl+data.mbonl)*1000; % g/h exhaust massflow
    data.mnoxh = data.noxn .* data.makh .* (46/28.98) ./ 1000000; % g/h NOx molfraction -> NOx massflow
end

%% call evaluation function (transfer of Kai Hoffmann from EM-Tool)
PEMS = dmsPemsEvaluate(data, vPowerRating, vWorkWhtc);
save(fullfile(sPath,'PEMS_results.mat'),'PEMS');

%% Plot generation
% labels
nWorkLim = length(data.worklimitprz);
cXTickLabel = cell(1,nWorkLim);
for nIdxLim = 1:nWorkLim
    cXTickLabel{nIdxLim} = char([num2str(data.worklimitprz(nIdxLim)), '%']);
end

% titles
nPerc = length(data.percentiles);
cTitle = cell(1,nPerc);
for nIdxPerc = 1:nPerc
    cTitle{nIdxPerc} = char(['Percentil ', num2str(data.percentiles(nIdxPerc)), '%']);
end

% Create figure
hFigure = figure;

% Create subplot
for nIdxPlot=1:length(data.percentiles)
    
    hPlot(nIdxPlot) = subplot(1,nIdxPerc,nIdxPlot,'Parent',hFigure,'XTickLabel',cXTickLabel,...
        'XTick',1:nIdxLim);
    % Uncomment the following line to preserve the Y-limits of the axes
    ylim(hPlot(nIdxPlot),[0 1]);
    box(hPlot(nIdxPlot),'on');
    grid(hPlot(nIdxPlot),'on');
    hold(hPlot(nIdxPlot),'all');
    
    % Create bar
    hBarGroup = bar(PEMS.perc{nIdxPlot},'Parent',hPlot(nIdxPlot));
    
    % Create xlabel
    xlabel('Power-Threshhold');
    
    if nIdxPlot == 1
        % Create ylabel
        ylabel('spec. NOx [g/kWh]');
    end
    
    % Create title
    title(cTitle{nIdxPlot});
    
    % add bar value as label
    GUIPlotBarValueAdd(hBarGroup,'%6.3f')
end

% export plot figure
% save figure
saveas(hFigure,fullfile(sPath,'PEMS_results.fig'));
% save figure as jpg
saveas(hFigure,fullfile(sPath,'PEMS_results.jpg'));
return

% =========================================================================

function xWindow = dmsPemsEvaluate(xInput, vPowerRated, vWorkWhtc)
% DMSPEMSEVALUATE evaluate measurement data for PEMS Euro VI NOx emissions.
%
% Syntax:
%   xWindow = dmsPemsEvaluate(xInput,vPowerRated,vWorkWhtc)
%
% Inputs:
%        xInput - structure with fields: 
%          .reczeit - vector (nx1) with time [s] of input data
%          .meff    - vector (nx1) with effective torque [Nm] of input data
%          .nmot    - vector (nx1) with engine speed [1/min] of input data
%          .twa     - vector (nx1) with temperature of coolant water outlet [°C] of input data
%          .mnoxh   - vector (nx1) with massflow of NOx [g/h] of input data
%          .percentiles - vector (1xm) with percentiles [%] of input data
%          .worklimitprz   - vector (1xo) with limit treshhold for power [%] of input data
%   vPowerRated - value (1x1) with rated power of engine [kW]
%   vWorkWhtc - value (1x1) with work of full WHTC [kWh]
%
% Outputs:
%   xWindow - structure with fields: 
%     .end          - value (nx1) with  [14461×1 double]
%     .start        - value (nx1) with  [14461×1 double]
%     .avpowerend   - value (nx1) with  [14461×1 double]
%     .avpowerstart - value (nx1) with  [14461×1 double]
%     .avmnoxend    - value (nx1) with  [14461×1 double]
%     .avmnoxstart  - value (nx1) with  [14461×1 double]
%     .size         - value (nx1) with  [14461×1 double]
%     .avpower      - value (nx1) with  [14461×1 double]
%     .avpowerprz   - value (nx1) with  [14461×1 double]
%     .avmnox       - value (nx1) with  [14461×1 double]
%     .avspecnox    - value (1x1) with average specific NOx 
%     .ok           - boolean (nx1) with  [14461×1 logical]
%     .valid        - boolean (nxm) with  [14461×3 logical]
%     .avspecnoxvalid - value (nxm) with  [14461×3 double]
%     .perc         - cell (1x3) with 1×3 cell}
%     .CF           - cell (1x3) with 1×3 cell}
%     .minspecnox   - value (1x1) with 0.089295399762820
%     .maxspecnox   - value (1x1) with 0.816562305822853
%     .winsum       - value (1x1) with 10087
%     .winvalid     - vector (1x3) with  [10087 9748 8267]
%     .prozwinvalid - vector (1x3) with 1 0.966392386239714 0.819569743233865]
%     .cumworktotal - value (1x1) with 2.025727130150602e+02
%     .ratiocumwork - value (1x1) with ratio of cumulative NOx
%     .windowavspecnox - value (1x1) with 0.259825218424557
%
% Example: 
%   xWindow = dmsPemsEvaluate(xInput,vPowerRated,vWorkWhtc)
%
% See also: dmsPemsEvaluate, dmsPemsEvaluateSim, uniread
%
% Author: Rainer Frey, TP/EAD, Daimler AG 
%         (original transfer of EM-Tool from Excel to Matlab by Kai
%         Hoffmann)
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2018-05-14

%% read data
% messdata = importdata(messdatei);
% reczeit = messdata(:,1); %sec
% meff = messdata(:,2); %Nm
% nmot = messdata(:,3); %min-1
% twa = messdata(:,4); %°C
% mnoxh = messdata(:,5); % g/h

vReczeit = xInput.reczeit; %sec
vMeff = xInput.meff; %Nm
vNmot = xInput.nmot; %min-1
vTwa = xInput.twa; %°C
vMnoxh = xInput.mnoxh; % g/h
vPercentiles = xInput.percentiles; % %
vPowerTreshhold = xInput.worklimitprz; %

vTimestep = vReczeit(2)-vReczeit(1);

%% Input values (legal settings)
zeitlimit = 900; % [s]
twalimit = 70; % [°C]
workcummmax = 1000; %kWh accumulated
legallimit = 0.46; %g/kWh Euro VI limit for NOx

%% calculate
% limitations
bTimeValid = (vReczeit >= zeitlimit);
bTwaValid = (vTwa >= twalimit);
bRelease = bTimeValid | bTwaValid;
vTimeStep = [diff(vReczeit);diff(vReczeit(end-1:end))]; % vector with timesteps
vTimeValid = vTimeStep .* bRelease;

% power
vPeff = max(2.* pi .* vNmot./60 .* vMeff./1000 ,0); % [kW] power (limited to positive)
vPeffCum = cumsum(vPeff.*vTimeValid); % [kWs] % TODO ggf. Ergänzung nötig für Freigabepausen

% work
vWorkCum = cumsum(vPeff.* vTimeValid)./3600; % [kWh] integrated to given timepoint

% NOx mass as accumulated
vMNoxCum = cumsum(vMnoxh.*3600.* vTimeValid)./3600; % [g] mass NOx integrated to given timepoint 

% assign output/init
nStart = inf(size(vReczeit));
vReczeitStart = inf(size(vReczeit));
vPowerEnd = vPeffCum; % [kWs]
vPowerStart = inf(size(vPeffCum)); % [kWs]
vMNoxEnd = vMNoxCum;
vMNoxStart = inf(size(vMNoxCum));

% define window according WHTC work 
vWorkTarget = vWorkCum - vWorkWhtc;
nStartLimit = find(vWorkTarget>=0 , 1);

% loop over possible work windows
for nIdxLe = nStartLimit:length(vReczeit)
    nStart(nIdxLe) = find(vWorkCum >= vWorkTarget(nIdxLe),1); % index where integrated work is larger than WHTC work
    vReczeitStart(nIdxLe) = vReczeit(nStart(nIdxLe)); % [s] start time of window
    vPowerStart(nIdxLe) = vPeffCum(nStart(nIdxLe)); % [kWs] integrated power at start of possible window
    vMNoxStart(nIdxLe) = vMNoxCum(nStart(nIdxLe)); % integrated NOx mass at start of possible window
end

vPeriod = vReczeit - vReczeitStart; % [s] active window periods, CAUTION no real Window end detection
vPowerAverage = (vPowerEnd - vPowerStart) ./ vPeriod; % [kW]
vPowerAveragePct = vPowerAverage/vPowerRated * 100;

vMNoxAverage = (vMNoxEnd - vMNoxStart) ./ vPeriod; % [g/h] average over window
vMNoxAverageSpecific = vMNoxAverage ./ vPowerAverage; % [g/kWh] specific average over window
wo = isinf(vMNoxAverageSpecific); vMNoxAverageSpecific(wo)=0;
wo = isnan(vMNoxAverageSpecific); vMNoxAverageSpecific(wo)=0;


bWindow = (vWorkCum < workcummmax) & (vWorkCum >= vWorkWhtc);
bWindow(isinf(bWindow))=0;
bWindow(isnan(bWindow))=0;

for nIdxTreshhold = 1:length(vPowerTreshhold)
    
    xWindow.valid(:,nIdxTreshhold) = vPowerAveragePct > vPowerTreshhold(1,nIdxTreshhold);
    wo = isinf(xWindow.valid(:,nIdxTreshhold)); 
    xWindow.valid(wo)=0;
    wo = isnan(xWindow.valid(:,nIdxTreshhold)); 
    xWindow.valid(wo)=0;
    
    xWindow.avspecnoxvalid(:,nIdxTreshhold) = xWindow.valid(:,nIdxTreshhold) .* vMNoxAverageSpecific;
    
    for nIdxPer=1:length(vPercentiles)
        xWindow.perc{nIdxPer}(:,nIdxTreshhold) = percentilehm(xWindow.avspecnoxvalid(:,nIdxTreshhold),vPercentiles(nIdxPer));
        xWindow.CF{nIdxPer}(:,nIdxTreshhold) = xWindow.perc{nIdxPer}(:,nIdxTreshhold)/ legallimit;
    end
    
end
avspecnox = vMNoxAverageSpecific(vMNoxAverageSpecific~=0);

% assign output
xWindow.end = vReczeit;
xWindow.start = vReczeitStart;
xWindow.nstart = nStart;
xWindow.avpowerend = vPowerEnd;
xWindow.avpowerstart = vPowerStart;
xWindow.avmnoxend = vMNoxEnd;
xWindow.avmnoxstart = vMNoxStart;

xWindow.size = vPeriod;
xWindow.avpower = vPowerAverage;
xWindow.avpowerprz = vPowerAveragePct;

xWindow.avmnox = vMNoxAverage; %g/h
xWindow.avspecnox = vMNoxAverageSpecific; %g/kWh

xWindow.ok = bWindow;

xWindow.minspecnox = min(avspecnox);
xWindow.maxspecnox = max(avspecnox);

xWindow.winsum = sum(xWindow.ok);
xWindow.winvalid = sum(xWindow.valid);
xWindow.prozwinvalid = xWindow.winvalid / xWindow.winsum;

xWindow.cumworktotal = max(vWorkCum);
xWindow.ratiocumwork = xWindow.cumworktotal/vWorkWhtc;
xWindow.avspecnox = sum(vMnoxh)/(xWindow.cumworktotal * vTimestep * 3600);
xWindow.windowavspecnox = sum(xWindow.avspecnoxvalid)/xWindow.winvalid;
return

% =========================================================================

function val = percentilehm(arr, pct)
% PERCENTILEHM percentile calculation
%
% Syntax:
%   val = percentilehm(arr,pct)
%
% Inputs:
%   arr - 
%   pct - percentile limit
%
% Outputs:
%   val - 
%
% Example: 
%   val = percentilehm(arr,pct)
arr = arr(arr ~= 0); % only keep non-empty points
len = length(arr); % number of non-empty points
ind = floor(pct/100*len); % index of 90% of points 
newarr = sort(arr); % sort array upward
val = newarr(ind); % take lowest 90% of points
return
