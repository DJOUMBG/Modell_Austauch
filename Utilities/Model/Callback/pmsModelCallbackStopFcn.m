%% DIVeMB StopFcn

disp('*********************')
sMP.cfg.run(end).end = now;

% display performance information
if exist('tout','var')
    [sMP.cfg.run(end).vSim,sMP.cfg.run(end).vInit, sMP.cfg.run(end).fRealtime] = ...
        dpsSimTimeDisp(sMP.cfg.run(end),tout(end));
else
    umsMsg('DIVe',3,'CAUTION: Simulation end time not available for correct performance evaluation!');
    [sMP.cfg.run(end).vSim,sMP.cfg.run(end).vInit, sMP.cfg.run(end).fRealtime] = ...
        dpsSimTimeDisp(sMP.cfg.run(end),str2double(sMP.cfg.Configuration.MasterSolver.timeEnd));
end
disp('*********************')

% trigger clear mex timer
pmsTimerClearMex;

% trigger drop of old silver license connections
dpsTimerLicSilverDrop;

%% co-simulation management
if isfield(sMP.cfg,'cosim')
    if strcmp(sMP.cfg.cosim(1).current.mode,'Master')
        % stop co-simulation management
        csmMasterStop(sMP);
        % loop over all clients
        for nIdxClient = 1:numel(sMP.cfg.cosim.client)
            % collect E2P 
            sFileE2p = fullfile(sMP.cfg.cosim.client(nIdxClient).path,'finalE2P.mat');
            if exist(sFileE2p,'file') == 2
                % load Client E2P values
                load(sFileE2p);
            end
            % collect ExACT results
            sPathResult = fullfile(sMP.cfg.cosim.client(nIdxClient).path,'results');
            if exist(sPathResult,'dir')==7
               [nStatus,sMsg] = copyfile(sPathResult,fullfile(sMP.cfg.run(end).path,'results'),'f');
            end
        end
    else
        % save client workspace
        save(fullfile(sMP.cfg.run(end).path,'wsModelStop.mat'));
    end
end

%% start postprocessing
umsMsg('DIVe',1,'dmb: Start postprocessing...')% save workspace

% remove object of Dassault FMI Toolkit, which prevents saving workspace
clear ans; 

% LDYN log structure reduction
xLogCfg = dcsCfgLogSetupGet(sMP.cfg.Configuration);
if isfield(xLogCfg,'sampleType') && ismember(xLogCfg.sampleType,{'LDYN'})
    if exist('logout','var')
        logout = ldReduceLogoutTimeSignals(logout);
    else
        umsMsg('DIVe',3,'dmb: Modell StopFcn - sampleType LDYN requires at least one logged signal.')
    end
end
clear xLogCfg

% save workspace or LDYN special save options
sFileSave = sprintf('WS%02i%02i%02i_%02i%02i%02.0f_%s.mat',datevec(now) - [2000 0 0 0 0 0],sMP.cfg.nameshort);
xVar = whos;
if any([xVar.bytes] > 2.1475e+09)
    clear xVar
    save(sFileSave,'-v7.3');
else
    clear xVar
    save(sFileSave);
end

% store final E2P values
if ~isempty(who('finalE2P*'))
    save(fullfile(sMP.cfg.run(end).path,'finalE2P.mat'),'finalE2P*');
end
% execute user-defined postprocessing file
if exist('UserPostProcessingFcn','file')
    UserPostProcessingFcn;
end
if isfield(sMP,'platform') && isfield(sMP.platform,'cPostExec') && ~isempty(sMP.platform.cPostExec)
    dpsPostprocessingMatlab(sMP.platform.cPostExec,sMP.cfg.run(end).path);
end
umsMsg('DIVe',1,'dmb: Postprocessing finished.')

% result copy to DIVeONE/pipeline target
sFileResultTarget = fullfile(fileparts(sMP.cfg.run(end).path),'ResultCopyTarget.txt');
if exist(sFileResultTarget,'file')
    nFid = fopen(sFileResultTarget,'r');
    ccLine = textscan(nFid,'%s');
    fclose(nFid);
    xSim.pathRun = sMP.cfg.run(end).path;
    xSim.simType = 'Simulink';
    xSim.pathWork = fileparts(sMP.cfg.run(end).path);
    dqsResultCopy(xSim,ccLine{1}{1},'pmsModelCallbackStopFcn')
end

% change to original directory
cd(sMP.cfg.run(end).pathStart);
