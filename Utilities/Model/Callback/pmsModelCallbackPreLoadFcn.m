% DIVeMB PreLoadFcn

% restore simulation settings
% check if platform is started
if ~exist('sMP','var')
    % try to recover actual DIVe MB platform
    % determine dmb path for start function
    cFilePath = pathparts(get_param(bdroot,'FileName'));
    sFileStart = fullfile(cFilePath{1:end-3},'startDIVeMB.m');

    % start DIVe ModelBased
    if exist(sFileStart,'file')
        umsMsg('DIVe',3,['WARNING: sMP variable missing in workspace - ' ...
                         'autostarting DIVe ModelBased now.\n']);
        run(sFileStart);
    else
        error(['ERROR: sMP variable missing in workspace - please '...
           'start DIVe MB first.\n       (automatic recovery failed ' ...
           'due to non-standard location of simulation folder.)\n']);
    end
end

sMP = pmsModelReload(get_param(bdroot,'FileName'),sMP);
