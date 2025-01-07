function addDIVeMatlabScriptingPaths()
    sCwd =  regexp(pwd, '\', 'split');
    sRootPath = cell2mat([strcat(sCwd(1:length(sCwd)-4), '\')]);
    cMatLabScriptDir = {fullfile(sRootPath, 'Utilities'), fullfile(sRootPath, 'Function')};
    cellfun(@(x) addpath(genpath(x)), cMatLabScriptDir, 'UniformOutput',false);
return