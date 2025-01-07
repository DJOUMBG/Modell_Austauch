function dstDependentParameter(sPath,cGlobal,cDependent)
% DSTDEPENDENTPARAMETER generate a dependent parameter XML with
% specifications of global parameters and local dependent parameters.
% If more than 2 input parameters are utilized the
% ..\Interface\DIVe_GlobalParameter.xlsx next to this function is
% automatically used (silent mode without query).
% 
% Usage:
%  1. create classification folder for a "dependentParameter" dataClass
%  2. create a dataset variant folder
%  3. ensure all your needed global parameters are in the
%     DIVe_GlobalParameter.xlsx 
%  4. execute this functions with the dataset variant folder path specified
%  5. use dstXmlDataSet to create the DIVe dataset XML for the dataset
%     variant
%  6. if there was no dependentParameter dataClass for the intended module,
%     please recreate the module XML with dstXmlModule
%
% Syntax:
%   dstDependentParameter(sPath)
%   dstDependentParameter(sPath,cGlobal)
%   dstDependentParameter(sPath,cGlobal,cDependent)
%
% Inputs:
%        sPath - string with path of dependent parameter dataset variant folder
%      cGlobal - cell (1xm) with strings of global parameters generated  
%                from local source parameters of this module
%   cDependent - cell (1xn) with strings of global parameter names which
%                will be written to local dependent parameters
%
% Outputs:
%
% Example: 
%   dstDependentParameter(pwd)
%   % dummy example of CPC - not for real use!
%   dstDependentParameter(pwd,{'cpc_e_id','cpc_e_Nm_max','cpc_eep_ptconf'},...
%   {'mcm_osg_trq_red_fac_2m','mcm_cac_br_trq_ebs1_min_2m','mcm_cac_br_trq_ebs3_min_2m'})
%
% Subfunctions: dstDependentParameterListGet
%
% See also: dbColumn2Struct, dbread, pathparts
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2016-06-24

% check input
if nargin < 1
    sPath = pwd;
end

% define spec version
sSpecVersion = '1.0.0';

% determine this species
cPath = pathparts(sPath);
bContext = ismember(cPath,{'bdry','ctrl','human','phys','pltm'});
if any(bContext)
    nSpecies = find(bContext) + 1;
    sSpecies = cPath{nSpecies};
else
    sSpecies = '';
end

% get already defined global parameters from DIVe list
xGlobal = dstDependentParameterListGet(sPath,nargin>2);

% pre-sort global parameter if they are from this species or not
if ~isempty(sSpecies)
    bSpecies = strcmp(sSpecies,{xGlobal.species});
    if strcmp(sSpecies,'mec3d')
         bSpeciesMec = strcmp('mec',{xGlobal.species});
         bSpecies = bSpecies | bSpeciesMec;
    end
    nAllGlob = find(bSpecies);
    nAllDependent = find(~bSpecies);
else
    nAllGlob = 1:numel(xGlobal);
    nAllDependent = 1:numel(xGlobal);
end

% get pre-selection for local dependent parameter selection
if isfield(xGlobal,'destinationParameterStruct') && ~isempty(sSpecies)
    bLocDepSelect = false(1,numel(nAllDependent));
    for nIdxDep = 1:numel(nAllDependent)
        sLocDepPar = xGlobal(nAllDependent(nIdxDep)).destinationParameterStruct;
        if ~isempty(sLocDepPar)
            cPar = strsplitOwn(sLocDepPar,';');
            if strcmp(sSpecies,'mec3d')
                bLocDepSelect(nIdxDep) = any(~cellfun(@isempty,...
                    regexp(cPar,'^sMP\.\w+\.mec\w*\.','once')));
            else
                bLocDepSelect(nIdxDep) = any(~cellfun(@isempty,...
                    regexp(cPar,['^sMP\.\w+\.' sSpecies '\.'],'once')));
            end
        end
    end
    nLocDepSelect = find(bLocDepSelect);
else
    nLocDepSelect = [];
end

if nargin < 2
    % ask for used global variables to set
    if ~isempty(nAllGlob)
        nSelGlob = listdlg('ListString', {xGlobal(nAllGlob).globalName}, ...
            'ListSize', [350 350], ...
            'Name', 'GlobalParameter', ...
            'PromptString', {'Select the GlobalParameters of the Module:', ...
            'local source parameters that will ', ...
            'be provided for other modules'}); % dialogue window
    else
        nSelGlob = [];
    end
else
    % match input with global parameters (sourced from this species)
    [bHit,nPos] = ismember(cGlobal,{xGlobal(nAllGlob).globalName});
    nSelGlob = nPos(bHit);
    if any(~bHit)
        fprintf(2,'Requested global parameters from local source parameters not found in DIVe_GlobalParameter.xlsx column A:\n');
        fprintf(2,'  %s\n',cGlobal{~bHit});
        error('dstDependentParameter:inputMissingInDIVeList', ...
            ['The parameters listed above have been requested on the silent ' ...
            'interface, but are not in the DIVe_GlobalParameter.xlsx column A.']);
    end
end

if nargin < 3
    % ask for used global variables to get (local dependent parameters)
    if ~isempty(nAllDependent)
        nSelDependent = listdlg('ListString', {xGlobal(nAllDependent).globalName}, ...
            'ListSize', [350 350], ...
            'Name', 'LocalParameter', ...
            'PromptString', {'Select DependentParameter of Module:', ...
            'global parameters, that overwrite local parameters', ...
            'of this Module'}, ...
            'InitialValue', nLocDepSelect); % dialogue window
    else
        nSelDependent = [];
    end
else
    % match input with dependent parameters (overwritten in this species)
    [bHit,nPos] = ismember(cDependent,{xGlobal(nAllDependent).globalName});
    nSelDependent = nPos(bHit);
    if any(~bHit)
        fprintf(2,'Requested global parameters for local dependent parameters not found in DIVe_GlobalParameter.xlsx column A:\n');
        fprintf(2,'  %s\n',cDependent{~bHit});
        error('dstDependentParameter:inputMissingInDIVeList', ...
            ['The parameters listed above have been requested on the silent ' ...
            'interface, but are not in the DIVe_GlobalParameter.xlsx column A.']);
    end
end

if (isempty(nAllGlob) || isempty(nSelGlob)) && ...
        (isempty(nAllDependent) || isempty(nSelDependent))
    % no XML to be created
    return
end

% create basic XML structure
xTree.Dependency.xmlns = 'http://www.daimler.com/DIVeDependency';
xTree.Dependency.xmlns0x3Axsi = 'http://www.w3.org/2001/XMLSchema-instance';
xTree.Dependency.xsi0x3AschemaLocation = ['\\emea.corpdir.net\E019\prj\TG\DIVE\100_doc\110_specification\DIVe_v'...
    strrep(sSpecVersion,'.','') '\XMLSchemes\DIVeDependency.xsd'];

% add all global parameters
nGlob = nAllGlob(nSelGlob);
for nIdxPar = 1:numel(nGlob)
    xTree.Dependency.GlobalParameter(nIdxPar).name = xGlobal(nGlob(nIdxPar)).globalName; % description of global parameter
    xTree.Dependency.GlobalParameter(nIdxPar).parameter = xGlobal(nGlob(nIdxPar)).parameter; % name of source parameter
    xTree.Dependency.GlobalParameter(nIdxPar).subspecies = xGlobal(nGlob(nIdxPar)).subspecies; % subspecies of source parameter
    xTree.Dependency.GlobalParameter(nIdxPar).description = xGlobal(nGlob(nIdxPar)).description; % description of global parameter
    xTree.Dependency.GlobalParameter(nIdxPar).dimension = xGlobal(nGlob(nIdxPar)).dimension; %
    xTree.Dependency.GlobalParameter(nIdxPar).minimum = xGlobal(nGlob(nIdxPar)).minimum; %
    xTree.Dependency.GlobalParameter(nIdxPar).maximum = xGlobal(nGlob(nIdxPar)).maximum; %
    xTree.Dependency.GlobalParameter(nIdxPar).unit = xGlobal(nGlob(nIdxPar)).unit; %
    % TODO ? add determination of multiple source parameters?
end

% add all dependent parameters
nDependent = nAllDependent(nSelDependent);
for nIdxPar = 1:numel(nDependent)
    % try to capture local dependent name
    if ~isempty(xGlobal(nDependent(nIdxPar)).destinationParameterStruct)
        cPar = strsplitOwn(xGlobal(nDependent(nIdxPar)).destinationParameterStruct,';');
        if strcmp(sSpecies,'mec3d')
            cParName = regexp(cPar,'(?<=^sMP\.\w+\.mec\w*\.).+','match','once');
        else
            cParName = regexp(cPar,['(?<=^sMP\.\w+\.' sSpecies '\.).+'],'match','once');
        end
        nMatch = find(~cellfun(@isempty,cParName));
        if isempty(nMatch)
            sParName = '';
        else % at least one hit found
            sParName = cParName{nMatch(1)};
        end
    else
        sParName = '';
    end
    
    % create structure
    xTree.Dependency.LocalParameter(nIdxPar).globalName = xGlobal(nDependent(nIdxPar)).globalName; % name of global parameter
    xTree.Dependency.LocalParameter(nIdxPar).name = sParName; % name of local dependent parameter to be added by user
    xTree.Dependency.LocalParameter(nIdxPar).description = xGlobal(nDependent(nIdxPar)).description; %
    xTree.Dependency.LocalParameter(nIdxPar).dimension = xGlobal(nDependent(nIdxPar)).dimension; %
    xTree.Dependency.LocalParameter(nIdxPar).minimum = xGlobal(nDependent(nIdxPar)).minimum; %
    xTree.Dependency.LocalParameter(nIdxPar).maximum = xGlobal(nDependent(nIdxPar)).maximum; %
    xTree.Dependency.LocalParameter(nIdxPar).unit = xGlobal(nDependent(nIdxPar)).unit; %
    xTree.Dependency.LocalParameter(nIdxPar).subspecies = ''; % subspecies of local parameter -> to be filled manually, by standard in .name field  
    xTree.Dependency.LocalParameter(nIdxPar).optionalRead = xGlobal(nDependent(nIdxPar)).optionalRead; % optional read status
end

% ensure path existence
if ~exist(sPath,'dir')
    mkdir(sPath);
end

% write XML
sFilePath = fullfile(sPath,'dependency.xml');
dsxWrite(sFilePath,xTree);
disp(['<a href="matlab:open(''' sFilePath ...
    ''')">Set local parameters in new file dependency.xml</a>']);

% create DataSet variant XML file, if not existing already
[sRest,sFolder] = fileparts(sPath); %#ok<ASGLU>
if ~exist(fullfile(sPath,[sFolder '.xml']),'file')
    dstXmlDataSet(sPath,{'isStandard','';'executeAtInit','';'copyToRunDirectory',''});
end
return

% =========================================================================

function xGlobal = dstDependentParameterListGet(sPath,bListNetwork)
% DSTDEPENDENTPARAMETERLISTGET get the dependent parameter list of DIVe
% from the root of the dataset path or by user selection or by the DIVe
% network share.
%
% xGlobal:
%   xGlobal = dstDependentParameterListGet(sPath,bListNetwork)
%
% Inputs:
%          sPath - string of path to search for DIVe_GlobalParameter.xlsx
%   bListNetwork - boolean on dialogue for DIVe list from network drive
%
% Outputs:
%   xGlobal - structure with fields: 
%     .globalName  - string with name of global parameter
%     .description - string with description of global parameter
%     .dimension   - string with dimension
%     .minimum     - string with minimum value of parameter
%     .maximum     - string with maximum value of parameter
%     .unit        - string with unit of parameter
%     .optionalRead - string for read GlobalParameter during LocalDependent 
%                     Parameter evaluation and given messages
%                      0: warning, if GlobalParameter not available
%                      0: no message, if GlobalParameter not available
%     .context     - string with context of source module
%     .species     - string with species of source module
%     .subspecies  - string with subspecies of source parameter
%     .parameter   - string with name of source parameter
%     .sourceParameterStruct - string with struct of source parameter in
%                              Matlab workspace during runtime
%     .destinationParameterStruct - string with semicolon separated list of 
%                              structs of local dependent parameters of
%                              Modules utilizing this GlobalParameter
%
% Example: 
%   xGlobal = dstModulePortListGet(sPath,bListNetwork)

% check input
if nargin < 1
    sPath = pwd;
end
if nargin < 2
    bListNetwork = false;
end

% check for direct specification of DIVe GlobalParameter list
sPathFileParameter = '';
[sPathOnly,sFile,sExt] = fileparts(sPath); %#ok<ASGLU>
if exist(sPath,'file') && strcmpi([sFile,sExt],'DIVe_GlobalParameter.xlsx')
    sPathFileParameter = sPath;
end

% try to find signal list in path (comfort functionality
cPath = pathparts(sPath);
if isempty(sPathFileParameter)
    for nIdxFolder = 0:min(11,numel(cPath)-1) % search path to specified model
        sPathFile = fullfile(cPath{1:end-nIdxFolder},'DIVe_GlobalParameter.xlsx');
        if exist(sPathFile,'file')
            sPathFileParameter = sPathFile;
            break
        end
    end
end

% backup use network signal list user
sPathNetwork = fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))),'Interface','DIVe_GlobalParameter.xlsx');

if isempty(sPathFileParameter) && exist(sPathNetwork,'file')
    if bListNetwork
        % function argument says ok for network
        sButton = 'Ok';
    else
        % ask user
        sButton = questdlg({'Do you want to use latest DIVe GlobalParameter list from Perforce workspace',...
            '...\Interface\DIVe_GlobalParameter.xlsx'},...
            'DIVe GlobalParameter list','Ok','No','Ok');
    end
    if strcmp(sButton,'Ok')
        sPathFileParameter = sPathNetwork;
    end
end

% get signal list by user selection
if isempty(sPathFileParameter)
    [sFile,sPath] = uigetfile( ...
        {'*.xls;*.xlsx;*.xlsb;*.xlsm;*.mat','Excel-files (*.xls)'; ...
        '*.*',  'All Files (*.*)'}, ...
        'Select DIVe GlobalParameter list',...
        'MultiSelect','off');
    if isnumeric(sFile) && sFile == 0
        return % user pressed cancel
    else
        sPathFileParameter = fullfile(sPath,sFile);
    end
end

% get info on Excel sheets in file
xSource = dbread(sPathFileParameter,1); % read directly first sheet
xGlobal = dbColumn2Struct(xSource(1).subset(1).field(1,1:13),xSource(1).subset(1).value(:,1:13));

% check parameter minimum consistency
cCheck = {'globalName','context','species','parameter'};
bCheck = true(size(xGlobal));
for nIdxCheck = 1:numel(cCheck)
    % perform check on property
    cTest = {xGlobal.(cCheck{nIdxCheck})};
    bThisCheck = ~cellfun(@isempty,cTest);
    
    % report negative results
    if any(~bThisCheck)
        fprintf(2,'dstDependentParameter - the mandatory property "%s" has not been filled for list entries:\n',cCheck{nIdxCheck});
        nFail = find(~bThisCheck);
        for nIdxFail = 1:numel(nFail)
           fprintf(2,'    Excel line: %i  globalName: %s   parameter: %s\n',nFail(nIdxFail)+1,...
               xGlobal(nFail(nIdxFail)).globalName,xGlobal(nFail(nIdxFail)).parameter);
        end
    end
    
    % apply
    bCheck = bCheck & bThisCheck;
end
return
