% DIVeMB CloseFcn

% close all Simulink models/libraries
fprintf(1,'dmb:pmsModelCallbackCloseFcn - closing all libraries...\n');
slcSimulinkSystemClose('lib');

% delete ExACT configuration varaible
if exist('ExACT','var'), clear ExACT; end

% delete child processes (cosim clients or SiL bypass)
if isfield(sMP,'platform') && isfield(sMP.platform,'childInstance')
    sMP.platform.childInstance = csmChildKill(sMP.platform.childInstance);
end

% remove path entries of modules and support sets
if ~isempty(sMP.platform.mpath.runtime)
    % capture pathes for late removal
    bLate = ~cellfun(@isempty,regexp(sMP.platform.mpath.runtime,'FMIKit-Simulink'));
    fprintf(1,'dmb:pmsModelCallbackCloseFcn - issue late path removal via pmsTimerPathLateClean(2) ...\n');
    pmsTimerPathLateClean(2,sMP.platform.mpath.runtime(bLate))
    sMP.platform.mpath.runtime = sMP.platform.mpath.runtime(~bLate);
    
    % remove pathes
    fprintf(1,'dmb:pmsModelCallbackCloseFcn - remove pathes added during initialization ...\n');
    sArch = computer('arch');
    if strcmp(sArch(1:3),'win')
        sSep = ';';
    else
        sSep = ':';
    end
    cMatlabPath = strsplitOwn(path,sSep);
    bPath = ismember(sMP.platform.mpath.runtime,cMatlabPath);
    cPath = sMP.platform.mpath.runtime(bPath); % reduce to pathes in Matlab path environement
    try
        rmpath(cPath{:});
    catch ME
        disperror(ME);
    end
    sMP.platform.mpath.runtime = {};
end
fprintf(1,'dmb:pmsModelCallbackCloseFcn - done.\n');
