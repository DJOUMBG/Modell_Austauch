function [mdl] = cpc4ppc(mdl, EEP, CAL)
% CPC4PPC Prepares CPC parameter for PPC
% Represents the Diagnosis UDS communication between PPC and CPC
%
%
% Syntax:  [mdl] = cpc4ppc(mdl, EEP)
%
% Inputs:
%    mdl - [.] mdl structure with parameters that are provided as global parameter
%    EEP - [.] EEP structure of CPC
%
% Outputs:
%    mdl - [.] mdl structure with parameters that are provided as global parameter
%
% Example: 
%    mdl = cpc4ppc(mdl, EEP);
%
%
% Author: PLOCH37
% Date:   29-Jan-2020


%% Setting dependent parameter for PPC

% Driving Program
switch EEP.ag_p_VehConf.UseSftPrgCodeEep_u8
    case 0 % from CAL
        mdl.v_drv_prog = EEP.ag_p_VehConf.SftPrgAv_u8(EEP.ag_p_VehConf.SftPrgIdxOnStart_u8 + 1);
    case 1 % from EEP (PTCONF)
        mdl.v_drv_prog = EEP.ptconf_p_Trans.SftPrgCode_u8;
    otherwise % for example with external transmissons like AT from Voith or ZF
        mdl.v_drv_prog = 255;
end

% Driving Mode
if EEP.ag_p_VehConf.SftPrgAv_u8(EEP.ag_p_VehConf.SftPrgIdxOnStart_u8 + 1) == 100
    mdl.v_drv_mode = 0; % Standard
else
    mdl.v_drv_mode = 1; % Special
end

% Lowest gear to which TopTorque is applied
% (also needed for Driving Performance in PostProcessing)
% Todo: maybe even better to use CPC Signal that will be send to PPC?
if any(EEP.ptconf_p_Veh.FlcSelPar_u8 == [2,4]) % TT gear defined in AG-CAL: cal_g_AgLowestTopTrqGear_u8
    if isfield(CAL, 'cal_g_AgLowestTopTrqGear_u8')
        % TT gear is defined by user
        mdl.LowestTopTrqGear = CAL.cal_g_AgLowestTopTrqGear_u8;
    else
        % TT so far only known as last gear in 12th gear transmissions
        mdl.LowestTopTrqGear = 12;
    end
elseif EEP.ptconf_p_Veh.FlcSelPar_u8 == 5 % TT 2.0
    if isfield(CAL, 'cal_g_AgLowestTopTrqGearExtended_u8')
        % TT gear is defined by user
        mdl.LowestTopTrqGear = CAL.cal_g_AgLowestTopTrqGearExtended_u8;
    else
        % 251 leads in PPC, that it works as TT 2.0 with
        % cal_g_DynLowestTopTrqGear_u8
        % cal_g_PermLowestTopTrqGear_u8
        % Will not work with Driving Performance calculation in PostProcessing
        mdl.LowestTopTrqGear = 251;
    end
else
    mdl.LowestTopTrqGear = 0;
end

% Engine ID
switch EEP.ptconf_a_Eng.EngType_u8
    case 2
        mdl.e_id = 934;
    case 3
        mdl.e_id = 936;
    case 4
        mdl.e_id = 470;
    case 5
        mdl.e_id = 471; % DD13
    case 6
        mdl.e_id = 473; % DD16
    case 15
        mdl.e_id = 472; % DD15
    case 20
        mdl.e_id = 924;
    case 21
        mdl.e_id = 926;
    case 23
        mdl.e_id = 460;
    otherwise
        mdl.e_id = 0; % not defined
end

% FE1 or FE0 engine
switch EEP.ptconf_a_Eng.EngType_u8
    case {4, 5, 15} % HDEP OM470, OM471/DD13, OM472/DD15
        disp('FE1 engine assumed for PPC')
        mdl.isFE1Engine = 1;
    otherwise
        mdl.isFE1Engine = 0;
end

% Captive Rating
disp('No Captive Rating assumed for PPC')
mdl.isNaftaCaptiveRating = 0;

% Retarder
if EEP.ptconf_p_Ret.RetType_u8 == 0
    mdl.r_rpm = [0; 2500];
    mdl.r_Nm =  [0; 0];
end