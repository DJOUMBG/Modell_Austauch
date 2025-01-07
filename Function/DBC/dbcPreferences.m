function xSetup = dbcPreferences
% DBCPREFERENCES creates standard preferences for the DIVe basic
% configurator.
%
% Syntax:
%   xSetup = dbcPreferences
%
% Inputs:
%
% Outputs:
%   xSetup - structure with fields: 
%     .sPathContent - string with path to DIVe database export
%     .sPathConfiguration - string with path to DIVe configurations
%     .sPathMask    - string with path to mask definition files
%     .moduleFirst  - cell with modules for early priority in setup
%     .moduleLast   - cell with modules for late priority in setup
%     .platform     - string with current platform setting
%     .platformPreference - structure with fields 
%       .ModelBased - structure with field "setPrio"
%       .CodeBased  - structure with field "setPrio"
%       .LDYN       - structure with field "setPrio"
%       .Basic      - structure with field "setPrio"
%         .setPrio  - cell with priority strings for modelset preselection
%     .logging - [optional] structure with logging options      
% 
% Example: 
%   xSetup = dbcPreferences

%% database location in file system = location of SysDM Export structure
% (contains folders of DIVe context: bdry, ctrl, human, phys)
cPathFile = pathparts(mfilename('fullpath'));
cPath = {};
            
% apply detailed path settings for special user groups
if exist('dbcGroupPathManagement','file')
    cPath = dbcGroupPathManagement(cPath,cPathFile);
end

% fallback on local path
if isempty(cPath)
    cPath = {fullfile(cPathFile{1:end-3})};
end

% simple path settings
% cPath = cPath(4); % hard override for debugging purpose
% cPath = {'C:\dirsync\06DIVe\03Platform\01DIVeMB'};

% create pathes
xSetup.cPath              = cPath; % path list for switching base path
xSetup.sPathContent       = fullfile(cPath{1},'Content');
xSetup.sPathConfiguration = fullfile(cPath{1},'Configuration');
xSetup.sPathMask          = fullfile(cPath{1},'Mask');

%% default connectivity flag
xSetup.bConnection = 0; % do not connect to Perforce by standard
% xSetup.bConnection = 1; % connect to Perforce by standard

%% priority lists for first and last modules in module setup
xSetup.moduleFirst = {}; % first in cell will be first in configuration
xSetup.moduleLast = {}; % last in cell will be last in configuration

%% platform setting
xSetup.platform = 'Basic'; % ModelBased | CodeBased | LDYN | Basic

%% priority settings for modelSet pre-selection
xSetup.platformPreference.ModelBased.setPrio = {'sfcn_w64_R2017b','sfcn_w64_R2016a','sfcn_w64_R2014a','open'};
xSetup.platformPreference.CodeBased.setPrio = {'fmu20','fmu10','sfcn_w64_R2016a','sfcn_w64_R2017b','sfcn_w64_R2014a','open'};
xSetup.platformPreference.LDYN.setPrio = {'sfcn_w64_R2016a','open'};
xSetup.platformPreference.Basic.setPrio = {'sfcn_w64_R2016a','sfcn_w64_R2017b','open'};

%% platform logging sampletime options (DIVe MB specific)
xSetup.logging.sampleTime = {'1.0','0.1','0.01','0.005','0.001'}; % s
xSetup.logging.sampleTimeDefault = '0.1'; % s
xSetup.logging.sampleType = {'ToWorkspace','ToASCII','Simulink','LDYN','CSV','MAT','MDF'}; 
xSetup.logging.sampleTypeDefault = 'ToWorkspace'; 
return
