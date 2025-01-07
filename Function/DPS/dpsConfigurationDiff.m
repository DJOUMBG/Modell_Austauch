function xDiff = dpsConfigurationDiff(sFile1,sFile2,nOutput)

% check input
if nargin < 3
    nOutput = 1;
end
[sFile1,sFile2,bError] = checkFiles(sFile1,sFile2,nOutput);
if bError
    return
end

% load configurations
try
    xConfig{1} = dsxRead(sFile1);
catch ME
    fprintf(2,'Error: This configuration could not be read by dsxRead: %s \n',sFile1);
    fprintf(2,[ME.message '\n']);
end
try
    xConfig{2} = dsxRead(sFile2);
catch ME
    fprintf(2,'Error: This configuration could not be read by dsxRead: %s \n',sFile2);
    fprintf(2,[ME.message '\n']);
end

%% check name and tags of configuration
if nOutput == 1
    fprintf(1,'Comparing header of Configurations:\n');
end
cRemove = {'xmlns','xmlns0x3Axsi','xsi0x3AschemaLocation','ModuleSetup',...
           'Interface','MasterSolver','OptionalContent'};
xHead = cell(1,2);
for n = 1:2
    xHead{n} = xConfig{n}.Configuration; 
    bRemove = isfield(xHead{n},cRemove);
    xHead{n} = rmfield(xHead{n},cRemove(bRemove)); 
end
[xDiff.header.Diff.file1,xDiff.header.Diff.file2,...
    xDiff.header.XOr.file1,xDiff.header.XOr.file2] = structDiff(xHead{1},xHead{2},nOutput);

%% check module order & occurence 
if nOutput == 1
    fprintf(1,'\nComparing module order and occurence:\n');
end
xSetup = cell(1,2);
for nIdxFile = 1:2
    % code shortcut
    xSetup{nIdxFile} = xConfig{nIdxFile}.Configuration.ModuleSetup;
    
    % get context and species of module on higher level
    for nIdxSetup = 1:numel(xSetup{nIdxFile})
        xSetup{nIdxFile}(nIdxSetup).context = xSetup{nIdxFile}(nIdxSetup).Module.context;
        xSetup{nIdxFile}(nIdxSetup).species = xSetup{nIdxFile}(nIdxSetup).Module.species;
    end
    
    % check availability of initialization order
    bEmpty = cellfun(@isempty,{xSetup{nIdxFile}.initOrder});
    if any(bEmpty)
        nEmpty = find(bEmpty);
        fprintf(2,['Error: In Configuration %i the following ModuleSetups ' ...
            'are empty: \n'],nIdxFile);
        for nIdxEmpty = nEmpty
            fprintf(2,'\t\t%i\t%s\n',nIdxEmpty,xSetup{nIdxFile}(nIdxEmpty).name);
        end
    end
    
    % resort setup according initialization order
    nOrder = str2double({xSetup{nIdxFile}.initOrder});
    [nOrderNew,nSort] = sort(nOrder);
    if any(nOrder~=nOrderNew)
        % resort ModuleSetup structures according initialization order
        xSetup{nIdxFile} = xSetup{nIdxFile}(nSort);
        
        % state resorting
        fprintf(2,['Warning: In Configuration %i the ModuleSetups are not ' ...
            'sorted according initialization order.\n'],nIdxFile);
    end
    
    % get module species and context
    cSpecies{nIdxFile} = {xSetup{nIdxFile}.species}; %#ok<AGROW>
    cContext{nIdxFile} = {xSetup{nIdxFile}.context}; %#ok<NASGU>
end

% check unique species modules
[cXOr,nXOr1,nXOr2] = setxor(cSpecies{1},cSpecies{2}); %#ok<ASGLU>
if ~isempty(nXOr1)
    xDiff.setup.set.XOr.file1 = cSpecies{1}(nXOr1);
    fprintf(2,'Error: The following species are only defined in Configuration 1:\n');
    for nIdxSpecies = 1:numel(nXOr1)
        fprintf(2,'\t%s\n',cSpecies{1}{nIdxSpecies});
    end
end
if ~isempty(nXOr2)
    xDiff.setup.set.XOr.file2 = cSpecies{2}(nXOr2);
    fprintf(2,'Error: The following species are only defined in Configuration 2:\n');
    for nIdxSpecies = 1:numel(nXOr2)
        fprintf(2,'\t%s\n',cSpecies{2}{nIdxSpecies});
    end
end

% check initialization order
[cSpeciesBoth,nBoth1,nBoth2] = intersect(cSpecies{1},cSpecies{2}); %#ok<ASGLU>
bRed1 = ismember(cSpecies{1},cSpeciesBoth);
bRed2 = ismember(cSpecies{2},cSpeciesBoth);
cSpeciesRed{1} = cSpecies{1}(bRed1);
cSpeciesRed{2} = cSpecies{2}(bRed2);
bOrderDiff = ~strcmp(cSpeciesRed{1},cSpeciesRed{2});
if any(bOrderDiff)
    % output preparation
    xDiff.setup.initOrder.species = cSpeciesRed{1}(bOrderDiff);
    [bMember1,nMember1] = ismember(xDiff.setup.initOrder.species,cSpecies{1}); %#ok<ASGLU>
    xDiff.setup.initOrder.file1 = nMember1;
    [bMember2,nMember2] = ismember(xDiff.setup.initOrder.species,cSpecies{2}); %#ok<ASGLU>
    xDiff.setup.initOrder.file2 = nMember2;
    
    % messages
    if nOutput == 1
        fprintf(2,['Error: Configuration 2 has a different initialization ' ...
            'order for the following species:\n']);
        for nIdxSpecies = 1:numel(xDiff.setup.initOrder.file2)
            fprintf(2,'\t%i\t%s\n',xDiff.setup.initOrder.file2(nIdxSpecies),...
                cSpecies{2}{xDiff.setup.initOrder.file2(nIdxSpecies)});
        end
    end
end

% check ModuleSetup names
cSetupName1 = {xSetup{1}(bRed1).name};
cSetupName2 = {xSetup{2}(bRed2).name};
bNameDiff = ~strcmp(cSetupName1,cSetupName2);
nNameDiff = find(bNameDiff);
if any(bNameDiff)
    % messages
    if nOutput == 1
        fprintf(2,'Warning: Encountered different ModuleSetup names.\n');
        fprintf(2,'\tfile1:\t\tfile2:\n');
        for nIdxSpecies = nNameDiff
            fprintf(2,'\t%s\t\t%s\n',cSetupName1{nIdxSpecies},cSetupName2{nIdxSpecies});
        end
    end
end
    
%% check module details
% reduce to same sets of modules
xSetup{1} = xSetup{1}(bRed1);
xSetup{2} = xSetup{2}(bRed2);

for nIdxSetup = 1:numel(xSetup{1})
    % check module selection
    if nOutput == 1
        fprintf(1,'\nComparing Module "%s" direct Module settings\n',xSetup{1}(nIdxSetup).name);
    end
    [xDiff.setup.module(nIdxSetup).file1,xDiff.setup.module(nIdxSetup).file2] = ...
        structDiff(xSetup{1}(nIdxSetup).Module,xSetup{2}(nIdxSetup).Module,nOutput);
    
    % check dataset classes
    if nOutput == 1
        fprintf(1,'\nComparing Module "%s" dataset classNames\n',xSetup{1}(nIdxSetup).name);
    end
    cDataClass1 = {xSetup{1}(nIdxSetup).DataSet.className};
    cDataClass2 = {xSetup{2}(nIdxSetup).DataSet.className};
    [cXOr,nXOr1,nXOr2] = setxor(cDataClass1,cDataClass2);  %#ok<ASGLU>
    if ~isempty(nXOr2)
        xDiff.setup.dataset(nIdxSetup).XOr.file1 = cDataClass1(nXOr1);
        fprintf(2,['Error: Configuration 1 misses in module "%s" the ' ... 
            'dataset classNames:\n'], xSetup{1}(nIdxSetup).name);
        for nIdxSet = 1:numel(nXOr2)
            fprintf(2,'\t%s\n',cDataClass2{nIdxSet});
        end
    end
    if ~isempty(nXOr1)
        xDiff.setup.dataset(nIdxSetup).XOr.file2 = cDataClass2(nXOr2);
        fprintf(2,['Error: Configuration 2 misses in module "%s" the ' ... 
            'dataset classNames:\n'], xSetup{1}(nIdxSetup).name);
        for nIdxSet = 1:numel(nXOr1)
            fprintf(2,'\t%s\n',cDataClass1{nIdxSet});
        end
    end

    % check dataset className details
    for nIdxData = 1:numel(xSetup{1}(nIdxSetup).DataSet)
        % check if className is in both configurations
        [bConf2,nConf2] = ismember(xSetup{1}(nIdxSetup).DataSet(nIdxData).className,...
                {xSetup{2}(nIdxSetup).DataSet.className});
        if bConf2
            % state current comparison point
            if nOutput == 1
                fprintf(1,'\nComparing Module "%s" dataset details for "%s"\n',...
                    xSetup{1}(nIdxSetup).name,xSetup{1}(nIdxSetup).DataSet(nIdxData).className);
            end
            
            % compare details of datasets
            [xDiff.setup.dataset(nIdxSetup).detail.file1,xDiff.setup.dataset(nIdxSetup).detail.file2] = ...
                structDiff(xSetup{1}(nIdxSetup).DataSet(nIdxData),...
                           xSetup{1}(nIdxSetup).DataSet(nConf2),nOutput);
        end % if exist in both configs
    end % for all datasets
end % for all moduleSetups

%% check main solver settings
if nOutput == 1
    fprintf(1,'\nComparing MasterSolver settings \n');
end
[xDiff.solver.file1,xDiff.setup.file2] = ...
    structDiff(xConfig{1}.Configuration.MasterSolver,...
               xConfig{2}.Configuration.MasterSolver,nOutput);

%% check interface
disp(' ')
disp(' ')
disp('Caution: The interface check is not yet implemented')
disp(' ')

%% check optional content
if isfield(xConfig{1}.Configuration,'OptionalContent') 
    if isfield(xConfig{2}.Configuration,'OptionalContent') 
        % check optional content
    else
        % state optional content only in config 1
        xDiff.optional.xFile1 = xConfig{1}.Configuration.OptionalContent;
        if nOutput == 1
            fprintf(1,['\nWarning: Configuration 1 contains ' ...
                '"OptionalContent", while Configuration 2 does not.\n']);
        end
    end
else
    if isfield(xConfig{2}.Configuration,'OptionalContent')
        % state optional content only in config 2
        xDiff.optional.xFile2 = xConfig{2}.Configuration.OptionalContent;
        if nOutput == 1
            fprintf(1,['\nWarning: Configuration 2 contains ' ...
                '"OptionalContent", while Configuration 1 does not.\n']);
        end
    end
end

return

% =========================================================================

function [sFile1,sFile2,bError] = checkFiles(sFile1,sFile2,nMode)
% CHECKFILES checks and ensures existence of specified files - otherwise
% returns error flag
%
% Syntax:
%   [sFile1,sFile2,bError] = checkFiles(sFile1,sFile2)
%
% Inputs:
%   sFile1 - string with filepath of file
%   sFile2 - string with filepath of file
%    nMode - integer with operation mode (1: ask user for file location)
%
% Outputs:
%   sFile1 - string with filepath of file
%   sFile2 - string with filepath of file
%   bError - boolean with error flag (true: error occurred)
%
% Example: 
%   [sFile1,sFile2,bError] = checkFiles(sFile1,sFile2)

% init output
bError = false;

% check file 1
if ~exist(sFile1,'file') 
    if nMode == 1
        sPath = fileparts(sFile1);
        if ~exist(sPath,'dir')
            sPath = pwd;
        end
        % get Configuration to open
        [sLoadName,sLoadPath] = uigetfile( ...
            {'*.xml','DIVe Configuration (.xml)'; ...
            '*.*',  'All Files (*.*)'}, ...
            'Select 1st DIVe Configration',...
            sPath);
        if isequal(sLoadName,0) % user chosed cancel in file selection popup
            fprintf(2,['Error: File 1 does not exist - two DIVe configurations ' ...
                'are needed for comparison!\n']);
            bError = true;
        end
        sFile1 = fullfile(sLoadPath,sLoadFile);
    else
        % direct error message
        fprintf(2,'Error: File 1 does not exist: %s\n',sFile1);
        bError = true;
    end
end

% check file 2
if ~exist(sFile2,'file') 
    if nMode == 1
        sPath = fileparts(sFile2);
        if ~exist(sPath,'dir')
            sPath = pwd;
        end
        % get Configuration to open
        [sLoadName,sLoadPath] = uigetfile( ...
            {'*.xml','DIVe Configuration (.xml)'; ...
            '*.*',  'All Files (*.*)'}, ...
            'Select 2nd DIVe Configration',...
            sPath);
        if isequal(sLoadName,0) % user chosed cancel in file selection popup
            fprintf(2,['Error: File 2 does not exist - two DIVe configurations ' ...
                'are needed for comparison!\n']);
            bError = true;
        end
        sFile2 = fullfile(sLoadPath,sLoadFile);
    else
        % direct error message
        fprintf(2,'Error: File 2 does not exist: %s\n',sFile1);
        bError = true;
    end
end
return


