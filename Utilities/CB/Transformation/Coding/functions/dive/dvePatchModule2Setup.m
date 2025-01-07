function xModuleSetupList = dvePatchModule2Setup(xModule,bWithOpen)

% general
xModuleSetup.name = xModule.species;
xModuleSetup.initOrder = '';

% module
xModuleSetup.Module.context = xModule.context;
xModuleSetup.Module.species = xModule.species;
xModuleSetup.Module.family = xModule.family;
xModuleSetup.Module.type = xModule.type;
xModuleSetup.Module.variant = xModule.name;
xModuleSetup.Module.modelSet = '';
xModuleSetup.Module.versionId = '';
xModuleSetup.Module.workState = '0';
xModuleSetup.Module.maxCosimStepsize = xModule.maxCosimStepsize;
xModuleSetup.Module.solverType = '';

% data
xDataSet = struct([]);
for nDat=1:numel(xModule.Interface.DataSet)
    xCurDataSet.level = xModule.Interface.DataSet(nDat).level;
    xCurDataSet.classType = xModule.Interface.DataSet(nDat).classType;
    xCurDataSet.className = xModule.Interface.DataSet(nDat).className;
    xCurDataSet.variant = xModule.Interface.DataSet(nDat).reference;
    xCurDataSet.versionId = '';
    xCurDataSet.workState = '0';
    xDataSet = [xDataSet,xCurDataSet]; %#ok<AGROW>
end
xModuleSetup.DataSet = xDataSet;

% support
xSupportSet = struct([]);
if isfield(xModule.Implementation,'SupportSet')
    for nSup=1:numel(xModule.Implementation.SupportSet)
        xCurSupportSet.name = xModule.Implementation.SupportSet(nSup).name;
        xCurSupportSet.level = xModule.Implementation.SupportSet(nSup).level;
        xCurSupportSet.versionId = '';
        xSupportSet = [xSupportSet,xCurSupportSet]; %#ok<AGROW>
    end
    xModuleSetup.SupportSet = xSupportSet;
else
    xModuleSetup.SupportSet = struct([]);
end

% model sets
xModuleSetupList = struct([]);
for nSet=1:numel(xModule.Implementation.ModelSet)
    xCurModelSetup = xModuleSetup;
    sModelSetType = xModule.Implementation.ModelSet(nSet).type;
    if ~(strcmpi(sModelSetType,'open') && ~bWithOpen)
        xCurModelSetup.Module.modelSet = sModelSetType;
        xModuleSetupList = [xModuleSetupList,xCurModelSetup]; %#ok<AGROW>
    end
end

return