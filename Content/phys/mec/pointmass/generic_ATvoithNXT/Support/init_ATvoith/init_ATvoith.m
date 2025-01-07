
function [] = init_ATvoith(varargin)

%% read input arguments:
if mod(nargin,2)==0
    for k=1:nargin/2
        if strcmp( varargin{2*k-1},'cPathDataVariant' )
            cPathDataVariant = varargin{2*k};
        elseif strcmp( varargin{2*k-1},'sPathRunDir' )
            sPathRunDir = varargin{2*k};
        elseif false
        end
    end
else
    error('number of arguments not even --> use argument/value pairs')
end

[pathstr_supportSet,name,ext] = fileparts(which(mfilename));

pathSplit = regexp(cPathDataVariant','\','split');
classTypes = cellfun(@(x) x{find(strcmp(x,'Data'))+1}, pathSplit, 'UniformOutput', false);

%% Identify Dataset for Voith DataClass "tx_ATvoith" --> then extract Path to chosen DataSet
idxMain = find(strcmp('tx_ATvoith',classTypes)==1);
pathstr = cPathDataVariant{idxMain};

%% Get sMP structure from base workspace
sMP = evalin('base','sMP');

%% Load selected Voith data from mat-files to sMP-structure
load(fullfile(pathstr,'DIWA_BB_Par_NXT.mat'))
sMP.phys.mec.tx.DIWA_BB_ParNames = DIWA_BB_ParNames_NXT;
clear DIWA_BB_ParNames
sMP.phys.mec.tx.DIWA_BB_ParValues = DIWA_BB_ParValues_NXT;
clear DIWA_BB_ParValues

%% Copy Voith_Data folder to Run directory
copyfile(fullfile(pathstr,'Voith_Data_NXT'),fullfile(sPathRunDir,'Voith_Data_NXT'));

% 
% for k = 1:length(classTypes)
%     switch classTypes{k}
%         case 'axle'
%             nlLoadParam('sMP.ctrl.tcm', fullfile(cPathDataVariant{k},'axle.m'), sMP);
%         case 'ret'
%             nlLoadParam('sMP.ctrl.tcm', fullfile(cPathDataVariant{k},'ret.m'), sMP);
%         case 'veh'
%               nlLoadParam('sMP.ctrl.tcm', fullfile(cPathDataVariant{k},'veh.m'), sMP);
%         otherwise
%             % do nothing
%     end
% end

%% get additional data

% Efficiency Axles
if sMP.phys.mec.mec_iDiffAxle < 3.1
    etaAxle = 0.974;
elseif sMP.phys.mec.mec_iDiffAxle < 3.2
    etaAxle = 0.970;
elseif sMP.phys.mec.mec_iDiffAxle < 4.5
    etaAxle = 0.965;
else
    etaAxle = 0.95; % changed according to Mr. Suelzer from 0.96
end

% Retarder characteristics
% --> global parameter von tcm

% Vehicle Mass - Gelenkbus (6x2,6x4 --> leer 18t), Solobus (4x2 --> leer 11t)
if sMP.phys.mec.mec_axleConfig(1,1) ==4
    voith.mVeh_empty = 10893; % based on average empty vehicle weight 2018/2019  
else
    voith.mVeh_empty = 16281; % based on average empty vehicle weight 2018/2019
end
voith.mVeh_load = sMP.phys.mec.mec_massVehicle_kg - voith.mVeh_empty;

% mec internal data
voith.mVeh  = sMP.phys.mec.mec_massVehicle_kg/1000; % Vehicle mass [t]
voith.rDyn  = sMP.phys.mec.mec_rWheelDriven/1000; % Wheel radius [m]
voith.iA    = sMP.phys.mec.mec_iDiffAxle; % Ratio of axle
voith.rhoAir= sMP.phys.mec.aero.aeroRhoAirDensity_kgpm3; % 
voith.fRFzg = sMP.phys.mec.mec_fRollCoeffOverall; %
% global parameters of mcm/rebuild
voith.eng_idleSpeed = sMP.phys.mec.mcm_globCalc_lig_eng_speed_des_std;
voith.eng_maxSpeed = sMP.phys.mec.mcm_osg_eng_speed_max_1m;
voith.eng_maxTorque = max(sMP.phys.mec.mcm_tbf_trq_max_r0_2m);
% additional data
voith.etaAxle = etaAxle; 

%% overwrite data

% powertrain data
sMP.phys.mec.tx.DIWA_BB_ParValues = fcChangeDiwaParam(sMP.phys.mec.tx.DIWA_BB_ParValues, sMP.phys.mec.tx.DIWA_BB_ParNames, ...
    'FZG_mVeh', voith.mVeh);
sMP.phys.mec.tx.DIWA_BB_ParValues = fcChangeDiwaParam(sMP.phys.mec.tx.DIWA_BB_ParValues, sMP.phys.mec.tx.DIWA_BB_ParNames, ...
    'FZG_rDyn', voith.rDyn);
sMP.phys.mec.tx.DIWA_BB_ParValues = fcChangeDiwaParam(sMP.phys.mec.tx.DIWA_BB_ParValues, sMP.phys.mec.tx.DIWA_BB_ParNames, ...
    'FZG_iA', voith.iA );
% mcm data
sMP.phys.mec.tx.DIWA_BB_ParValues = fcChangeDiwaParam(sMP.phys.mec.tx.DIWA_BB_ParValues, sMP.phys.mec.tx.DIWA_BB_ParNames, ...
    'ENG_idleSpeed', voith.eng_idleSpeed);
sMP.phys.mec.tx.DIWA_BB_ParValues = fcChangeDiwaParam(sMP.phys.mec.tx.DIWA_BB_ParValues, sMP.phys.mec.tx.DIWA_BB_ParNames, ...
    'ENG_maxSpeed', voith.eng_maxSpeed);
sMP.phys.mec.tx.DIWA_BB_ParValues = fcChangeDiwaParam(sMP.phys.mec.tx.DIWA_BB_ParValues, sMP.phys.mec.tx.DIWA_BB_ParNames, ...
    'ENG_maxTorque', voith.eng_maxTorque);
% Further values
sMP.phys.mec.tx.DIWA_BB_ParValues = fcChangeDiwaParam(sMP.phys.mec.tx.DIWA_BB_ParValues, sMP.phys.mec.tx.DIWA_BB_ParNames, ...
     'rhoAir', voith.rhoAir);
 sMP.phys.mec.tx.DIWA_BB_ParValues = fcChangeDiwaParam(sMP.phys.mec.tx.DIWA_BB_ParValues, sMP.phys.mec.tx.DIWA_BB_ParNames, ...
     'fRFzg', voith.fRFzg);
sMP.phys.mec.tx.DIWA_BB_ParValues = fcChangeDiwaParam(sMP.phys.mec.tx.DIWA_BB_ParValues, sMP.phys.mec.tx.DIWA_BB_ParNames, ...
    'FZG_etaAxle', voith.etaAxle);
sMP.phys.mec.tx.DIWA_BB_ParValues = fcChangeDiwaParam(sMP.phys.mec.tx.DIWA_BB_ParValues, sMP.phys.mec.tx.DIWA_BB_ParNames, ...
    'FZG_mVeh_empty', voith.mVeh_empty);
sMP.phys.mec.tx.DIWA_BB_ParValues = fcChangeDiwaParam(sMP.phys.mec.tx.DIWA_BB_ParValues, sMP.phys.mec.tx.DIWA_BB_ParNames, ...
    'FZG_mVeh_load', voith.mVeh_load);

%% update sMP structure in base workspace
assignin('base','sMP',sMP);
