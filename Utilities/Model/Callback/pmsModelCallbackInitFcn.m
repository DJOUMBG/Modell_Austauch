% DIVeMB InitFcn

% increment run structure entry
sMP.cfg.run(end+1).username = sMP.platform.user.username;
sMP.cfg.run(end).computername = sMP.platform.user.computername;
sMP.cfg.run(end).path = fileparts(which(bdroot));
sMP.cfg.run(end).pathStart = cd(sMP.cfg.run(end).path);
sMP.cfg.run(end).init = now;
sMP.cfg.run(end).start = -1;
sMP.cfg.run(end).end = -1;
sMP.cfg.run(end).vInit = -1;
sMP.cfg.run(end).vSim = -1;
sMP.cfg.run(end).fRealtime = -1;

% co-simulation initialization
if isfield(sMP.cfg,'cosim')
    if strcmp(sMP.cfg.cosim(1).current.mode,'Master')
        [sMP.cfg.run(end).hJobObject,sMP.cfg.cosim] = csmMasterInit(sMP);
    else
        save(fullfile(sMP.cfg.run(end).path,'wsModelInit.mat'));
    end
end
