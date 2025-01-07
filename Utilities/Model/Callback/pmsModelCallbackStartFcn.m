% DIVeMB StartFcn

% co-simulation initialization
if isfield(sMP.cfg,'cosim')
    if strcmp(sMP.cfg.cosim(1).current.mode,'Master')
        sMP.cfg.cosim = csmMasterStart(sMP);
    else
        save(fullfile(sMP.cfg.run(end).path,'wsModelStart.mat'));
    end
end

% catch timestamp at start of simulation
sMP.cfg.run(end).start = now;
