function [cpc] = init_cpc_ldyn(cpc, sPathRunDir)
% INIT_CPC_LDYN load cpc parameterfiles
%
%
% Syntax:  [cpc] = init_cpc_ldyn(cpc, sPathRunDir)
%
% Inputs:
%            cpc - [.] cpc input structure
%    sPathRunDir - [.] input structure
%
% Outputs:
%    cpc - [.]  cpc output structure
%
% Example: 
%    sMP.ctrl.cpc = init_cpc_ldyn(sMP.ctrl.cpc, sPathRunDir);

%% Definitions
CPC_TYPE     = 'CPC5';
FILE_PAR     = 'cpc_eep.par'; % EEP par file
FILE_PAR_CAL = 'cpc_cal.par'; % CAL par file (optional)
FILE_DEFAULT = 'cpc_defaults.txt'; % default init file

% Init empty variables
glo      = []; % global parameter
EEP      = []; % EEP (raw values)
EEP_file = []; % EEP from base par file
EEPtype  = []; % EEPtype
cal      = []; % cal (physical values) from init run
CAL      = []; % CAL (raw values) from par file (optional)
sFilePar = ''; % base parameter file
sFileCDS = ''; % Calibration Data Set (CDS) file


%% Getting Inputs
sDir = cpc.path; % dataset directories
dep  = cpc.dep;  % dependent local parameter, that should by overwritten by global parameter
par  = cpc.dep;  %#ok<NASGU> % support also old datasets. For example in cpc_axle.m: i = par.axle_iDiff

% Add path of datasets
sField = fieldnames(sDir);
for k = 1:length(sField)
    addpath(sDir.(sField{k}));
end

% Parameter files
sFileParDest = fullfile(sPathRunDir, FILE_PAR);     % destination of EEP par file
sFileParCAL  = fullfile(sPathRunDir, FILE_PAR_CAL); % destination of CAL par file
sFileDefDest = fullfile(sPathRunDir, FILE_DEFAULT); % destination of default init file
sFileDefSrc  = fullfile(sDir.init,   FILE_DEFAULT); %      source of default init file

%% Create EEPROM paramaters
cpc_eep

% Create EEPROM paramater file
CreateCANapeParFile(sFileParDest, EEP, CPC_TYPE, 0, EEPtype);


%% Read init values for simulation
init = read_silver_par_file(sFileDefSrc);
init0 = init; % backup original init values


%% Create Calibration Data (AG Parameter)
glo.CPC_TYPE = CPC_TYPE;
cpc_cds

% Optional CAL par file
if exist(sFileParCAL, 'file')
    CAL = read_par_file(sFileParCAL); % raw cal values
end


%% Update EEP with Retarder Charecteristics
[EEP, glo] = rcm2cpc(EEP, glo, dep);

% Create EEPROM paramater file
CreateCANapeParFile(sFileParDest, EEP, CPC_TYPE)


%% Create cpc_defaults.txt including CAL parameter for initial values of CPC
if isequal(init, init0)
    % Append CAL values to init default file
    write_silver_par_file(cal, sFileDefDest, 'a', 'CAL values') % append CAL values
else % init values have changed during initialization
    % Write new init default file
    write_silver_init({init, cal}, sFileDefDest)
end


%% Set dependent parameter for PPC
glo = cpc4ppc(glo, EEP, cal);


%% Provide global parameter
% For Driver
glo.Nm_Ref = max(0.2 * EEP.ptconf_a_Eng.TrbChFullLoadEngTrqCurve_u16 - 5000);




%% Copy to output structure
cpc.mdl     = glo;      % only for information for comparison with older CPC SIL models
cpc.glo     = glo;      % provide global parameter for other modules (dependency.xml)
cpc.init    = init;     % only for information
cpc.cal     = cal;      % only for information, (physical values) from init run
cpc.CAL     = CAL;      % only for information, (raw values) from par file (optional)
cpc.EEP     = EEP;      % only for information, and for PPC (raw values)
cpc.EEP_file = EEP_file; % only for information, EEP from base par file


%% Create user_config string for Silver DLL
cpc.user_config = cpc_user_cfg(cpc);


%% Only for information / result documentation
cpc.filePar = sFilePar; % base parameter file of EEP values
cpc.fileCDS = regexprep(sFileCDS, '^0*', ''); % Calibration Data Set file without leading 0
% Remove dataset path. 
% Only dataset name is interesting for documentation.
% Otherwise: always differences in sMP between two simulations
cpc = rmfield(cpc, 'path');
sData = fieldnames(sDir);
for k = 1:length(sData)
    [~, cpc.dataset.(sData{k})] = fileparts(sDir.(sData{k}));
end


function [sFile] = getFileInDir(sDir, sFileType)
% GETFILEINDIR get full location of existing file (.m ord .mdl) inside directory
%
%
% Syntax:  [sFile] = getFileInDir(sDir)
%
% Inputs:
%      sDir - [''] Path to directory (String)
% sFileType - [''] File type
%
% Outputs:
%    sFile - [''] URL to file (String)
%
% Example: 
%    sFile = getFileInDir(sDir.c);
%    sFile = getFileInDir(sDir.(sMDL));
%    sFile = getFileInDir(sDir, '*.m');
%    sFile = getFileInDir(sDir, '*.mdl');

if nargin == 2
    % sFileType defined 
    sFiles = dir(fullfile(sDir, sFileType));
else
    % Prio 1: m-files
    sFiles = dir(fullfile(sDir, '*.m'));
    % Prio 2: mdl-files
    if isempty(sFiles)
        sFiles = dir(fullfile(sDir, '*.mdl'));
    end
end

% only files, no directories
sFiles = sFiles(~[sFiles.isdir]);
% only names
sFiles = {sFiles.name}';
% more than 1 file in folder?
if length(sFiles) == 1
    sFile = fullfile(sDir, sFiles{1});
elseif isempty(sFiles) && nargin == 2
    % defined sFileType not found
    sFile = '';
else
    error('no parameter file or more than one file found in folder')
end


function [EEP] = load_mdl(EEP, par, sDir, sMDL)
% LOAD_MDL load parameter file into EEP structure
%
%
% Syntax:  [EEP] = load_mdl(EEP, par, sDir, sMDL)
%
% Inputs:
%     EEP - [.] Input EEP structure
%     par - [.] par structure with necessary global parameters
%    sDir - [''] Directory path to paramter file (String)
%    sMDL - [''] fieldname of sructure (String)
%
% Outputs:
%    EEP - [.] Output EEP structure
%
% Example: 
%    EEP = load_mdl(EEP, par, sDir, 'e'); % Engine
%    EEP = load_mdl(EEP, par, sDir, 't'); % Transmission


% creating par structure for dependend parameter
sMP.ctrl.cpc.par = par; %#ok<STRNU>
% getting full file path
sFile = getFileInDir(sDir.(sMDL));
% run parameterset
run(sFile)


function write_silver_init(C, sFile)
% Write Silver init file for signals from more than one structure

% Merge structures
Y = C{1}; % take first element from cell array as base
for k = 2:length(C) % merge other elements from cell array
    X = C{k};
    sField = fieldnames(X);
    for n = 1:length(sField)
        Y.(sField{n}) = X.(sField{n});
    end
end
% Write Silver init file
write_silver_par_file(Y, sFile)
