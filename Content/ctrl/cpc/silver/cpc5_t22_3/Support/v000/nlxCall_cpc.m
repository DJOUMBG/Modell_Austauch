function [] = nlxCall_cpc(varargin)

%% Read input arguments:
if mod(nargin,2)==0
    for k=1:nargin/2
        switch varargin{2*k - 1}
            case 'sPathRunDir'
                sPathRunDir = varargin{2*k};
            case 'cPathDataVariant'
                cPathDataVariant = varargin{2*k};
        end
    end
else
    error('number of arguments not even --> use argument/value pairs')
end


%% Get sMP structure from base workspace and set paths of parameter slots
sMP = evalin('base','sMP');
pathSplit = regexp(cPathDataVariant','\','split');
classTypes = cellfun(@(x) x{find(strcmp(x,'Data'))+1}, pathSplit, 'UniformOutput', false);
for k = 1:length(classTypes)
    switch classTypes{k}
        case 'prg'
            sMP.ctrl.cpc.path.prg = cPathDataVariant{k}; % Driving Program
        case 'aero'
            sMP.ctrl.cpc.path.aero = cPathDataVariant{k}; % Aerodynamic
        case 'axle'
            sMP.ctrl.cpc.path.a = cPathDataVariant{k}; % Axle
        case 'tfc'
            sMP.ctrl.cpc.path.x = cPathDataVariant{k}; % Transfer Case
        case 'clt'
            sMP.ctrl.cpc.path.c = cPathDataVariant{k}; % Clutch
        case 'tx'
            sMP.ctrl.cpc.path.t = cPathDataVariant{k}; % Transmission
        case 'ret'
            sMP.ctrl.cpc.path.r = cPathDataVariant{k}; % Retarder
        case 'wheel'
            sMP.ctrl.cpc.path.w = cPathDataVariant{k}; % Wheel
        case 'veh'
            sMP.ctrl.cpc.path.v = cPathDataVariant{k}; % Vehicle
        case 'eng'
            sMP.ctrl.cpc.path.e = cPathDataVariant{k}; % Engine
        case 'cds'
            sMP.ctrl.cpc.path.cds = cPathDataVariant{k}; % Calibration Data Set (AG Parameter)
        case 'eep'
            sMP.ctrl.cpc.path.eep = cPathDataVariant{k}; % EEPROM
        case 'init'
            sMP.ctrl.cpc.path.init = cPathDataVariant{k}; % init values
        case 'debug'
            sMP.ctrl.cpc.path.debug = cPathDataVariant{k}; % debug signal definition
        case 'depPar'
            sMP.ctrl.cpc.path.depPar = cPathDataVariant{k}; % dependent parameter
        otherwise
            % do nothing
    end
end


%% Add CPC Support Set path and init CPC
sPathSupport = fileparts(mfilename('fullpath'));
addpath(fullfile(sPathSupport, 'cpc')) % support path
addpath(fullfile(sPathSupport, 'cpc', 'par')) % main par files
sMP.ctrl.cpc = init_cpc_ldyn(sMP.ctrl.cpc, sPathRunDir);


%% Update sMP structure in base workspace
assignin('base','sMP',sMP);
