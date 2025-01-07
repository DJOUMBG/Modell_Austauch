function [EEP, mdl] = mcm2cpc(EEP, mdl, par)
% MCM2CPC Convert MCM parameter to CPC parameter
% Represents the Diagnosis UDS communication between MCM and CPC
%
%
% Syntax:  [EEP, mdl] = mcm2cpc(EEP, mdl, par)
%
% Inputs:
%    EEP - [.] current EPROM structure of the CPC
%    mdl - [.] mdl structure of the CPC-SIL (here only the not necessary field are removed)
%    par - [.] global parameter structure, which also includes MCM parameter
%
% Outputs:
%    EEP - [.] new EPROM structure of the CPC
%    mdl - [.] mdl structure of the CPC-SIL (current CPC-SIL model still need some field of this structure)
%
% Example: 
%    [CPC3_EEP, mdl] = mcm2cpc(CPC3_EEP, mdl, par);
%    [CPC3_EEP, mdl] = mcm2cpc([], mdl, par);
%    [CPC3_EEP, mdl] = mcm2cpc([], [], par);
%
%
% Subfunctions: calcEngSpeedEbmOnAndOff, ebsOnOrOff
%
% Author: ploch37
% Date:   07-Dec-2015

% sMP = evalin('base', 'sMP');

%% Consistency Check
if any(par.mcm_tbf_trq_max_r0_2m(17:end) ~= 0)
    error('more than 16 fullload torque values')
end

%% UDS (Unified Diagnostic Services = Diagnose-Kommunikationsprotokoll)
% sollte folgende Parameter von der MCM zur Verfügung stellen können
% - ptconf_p_Eng
% - ptconf_p_EngFric
% - ptconf_p_EngBrk
% - ptconf_p_EngConsum

% diag_g_UDS22hTgtECUId_u8 = 1; % 1: MCM
% diag_g_UDS22hId1_u8 = 207;
% diag_g_UDS22hId2_u8 = ...;

%% ID1 = 207, ID2 = 6, FullLoad Map
% Vector of engine map speeds [1/min]: e_n = 0.16*CPC3_EEP.ptconf_p_Eng.FullLoadEngTrqCurvesEngSpds_u16
% Vector of engine map torques [Nm]: e_M = 0.2*CPC3_EEP.ptconf_p_Eng.TrbChFullLoadEngTrqCurve_u16-5000
% Derate speed interval length [1/min]: e_n_derate = 0.16*CPC3_EEP.ptconf_p_Eng.EngDerateSpdInt_u16
if any(par.mcm_tbf_trq_max_r0_2m < 0)
    error('negative fullload torque?')
end
EEP.ptconf_a_Eng.FullLoadEngTrqCurvesEngSpds_u16    = round(par.mcm_tbf_trq_max_r0_x_eng_speed(1:16)' / 0.16); % [rpm]
EEP.ptconf_a_Eng.TrbChFullLoadEngTrqCurve_u16       = round((par.mcm_tbf_trq_max_r0_2m(1:16)' + 5000) / 0.2); % [Nm]
[~, idx] = min(par.mcm_osg_trq_red_fac_2m);
EEP.ptconf_a_Eng.EngDerateSpdInt_u16                = round(par.mcm_osg_trq_red_fac_x_over_speed(idx) /0.16); % [rpm] % OSG_READ_END_TOP_SPEED_LIM - OSG_READ_BEGIN_TOP_SPEED_LIM

%% ID1 = 207, ID2 = 7, TopTrq Map
% Vector of engine map speeds [1/min]: e_n = 0.16*CPC3_EEP.ptconf_p_Eng.TopTrqRedEngTrqCurveEngSpds_u16
% Vector of engine map torques [Nm]: e_M = 0.2*CPC3_EEP.ptconf_p_Eng.TopTrqRedFullLoadEngTrqCurve_u16-5000
% Derate speed interval length [1/min]: e_n_derate = 0.16*CPC3_EEP.ptconf_p_Eng.TopTrqRedEngDerateSpdInt_u16
if any(par.mcm_tbf_trq_max_r1_2m < 0)
    error('negative top torque reduced torque?')
end
if any(par.mcm_tbf_trq_max_r1_2m ~= 0)
    % with TopTorque
    EEP.ptconf_a_Eng.TopTrqRedEngTrqCurveEngSpds_u16    = round(par.mcm_tbf_trq_max_r1_x_eng_speed(1:16)' / 0.16); % [rpm]
    EEP.ptconf_a_Eng.TopTrqRedFullLoadEngTrqCurve_u16   = round((par.mcm_tbf_trq_max_r1_2m(1:16)' + 5000) / 0.2); % [Nm]
    EEP.ptconf_a_Eng.TopTrqRedEngDerateSpdInt_u16       = EEP.ptconf_a_Eng.EngDerateSpdInt_u16; % [rpm] % OSG_READ_END_TOP_SPEED_LIM - OSG_READ_BEGIN_TOP_SPEED_LIM
    if any(par.mcm_tbf_trq_max_r1_2m(1:16) == 0)
        error('a value of top torque reduced torque is zero?')
    end
else
    % without TopTorque
    EEP.ptconf_a_Eng.TopTrqRedEngTrqCurveEngSpds_u16    = 65535 * ones(1,16); % SNA
    EEP.ptconf_a_Eng.TopTrqRedFullLoadEngTrqCurve_u16   = 65535 * ones(1,16); % SNA
    EEP.ptconf_a_Eng.TopTrqRedEngDerateSpdInt_u16       = 65535; % SNA
end

%% ID1 = 207, ID2 = 19, Rate2Trq Map
% Vector of engine map speeds [1/min]: e_n = 0.16*CPC3_EEP.ptconf_a_Eng.Rate2EngTrqCurvesEngSpds_u16
% Vector of engine map torques [Nm]: e_M = 0.2*CPC3_EEP.ptconf_a_Eng.Rate2EngTrqCurve_u16-5000
% Derate speed interval length [1/min]: e_n_derate = 0.16*CPC3_EEP.ptconf_a_Eng.Rate2EngDerateSpdInt_u16
if exist('mcm_tbf_trq_max_r2_2m', 'var') && any(par.mcm_tbf_trq_max_r2_2m < 0)
    error('negative rate2 torque')
end
if exist('mcm_tbf_trq_max_r2_2m', 'var') && any(par.mcm_tbf_trq_max_r2_2m ~= 0)
    % with 3rd Torque
    EEP.ptconf_a_Eng.Rate2EngTrqCurvesEngSpds_u16   = round(par.mcm_tbf_trq_max_r2_x_eng_speed(1:16)' / 0.16); % [rpm]
    EEP.ptconf_a_Eng.Rate2EngTrqCurve_u16           = round((par.mcm_tbf_trq_max_r2_2m(1:16)' + 5000) / 0.2); % [Nm]
    EEP.ptconf_a_Eng.Rate2EngDerateSpdInt_u16       = EEP.ptconf_a_Eng.EngDerateSpdInt_u16; % [rpm] % OSG_READ_END_TOP_SPEED_LIM - OSG_READ_BEGIN_TOP_SPEED_LIM
    if any(par.mcm_tbf_trq_max_r2_2m(1:16) == 0)
        error('a value of rate2 torque is zero?')
    end
else
    % without 3rd Torque, but meaningfull values needed if TopTorque is used
    EEP.ptconf_a_Eng.Rate2EngTrqCurvesEngSpds_u16   = EEP.ptconf_a_Eng.FullLoadEngTrqCurvesEngSpds_u16;  % [rpm] meaningfull values
    EEP.ptconf_a_Eng.Rate2EngTrqCurve_u16           = 0 * ones(1,16);
    EEP.ptconf_a_Eng.Rate2EngDerateSpdInt_u16       = EEP.ptconf_a_Eng.EngDerateSpdInt_u16;    
end

%% ID1 = 207, ID2 = 8 (Was ist der Unterschied zu FullLoad?), DynFullLoad Map, kein extra PTCONF parameter
% Vector of engine map speeds [1/min]: e_n = 0.16*CPC3_EEP.ptconf_p_Eng.FullLoadEngTrqCurvesEngSpds_u16 % tbf_trq_max_r0_x_eng_speed
% Vector of engine map torques [Nm]: e_M = 0.2*CPC3_EEP.ptconf_p_Eng.TrbChFullLoadEngTrqCurve_u16-5000 % EPF_READ_FULL_LOAD_CURVE_R0
% Derate speed interval length [1/min]: e_n_derate = 0.16*CPC3_EEP.ptconf_p_Eng.EngDerateSpdInt_u16

%% ID1 = 207, ID2 = 9 (Was ist der Unterschied zu TopTrq?), DynTopTrq Map, kein extra PTCONF parameter
% Vector of engine map speeds [1/min]: e_n = 0.16*CPC3_EEP.ptconf_p_Eng.TopTrqRedEngTrqCurveEngSpds_u16 % tbf_trq_max_r1_x_eng_speed
% Vector of engine map torques [Nm]: e_M = 0.2*CPC3_EEP.ptconf_p_Eng.TopTrqRedFullLoadEngTrqCurve_u16-5000 % EPF_READ_FULL_LOAD_CURVE_R1
% Derate speed interval length [1/min]: e_n_derate = 0.16*CPC3_EEP.ptconf_p_Eng.TopTrqRedEngDerateSpdInt_u16

%% ID1 = 207, ID2 = 20 (Was ist der Unterschied zu Rate2Trq Map?), DynRate2Trq Map, kein extra PTCONF parameter

%% ID1 = 207, ID2 = 17 (mdl.e.id statt EngType_u8?), Parameters
% Engine ID [-]: e_ID = mdl.e.id ??? müsste eher CPC3_EEP.ptconf_p_Eng.EngType_u8 sein sys_motor_type_1m. ACHTUNG: keine direkte Zuordnung, sondern mapping erforderlich
% Engine EURO [-]: e_EURO = CPC3_EEP.ptconf_p_Eng.CombustionClass_u8
% Engine inertia torque [kgm²]: e_J = CPC3_EEP.ptconf_p_Eng.EngInertiaTrq_u16*2^(-12)
% Maximum permitted engine brake velocity [rad/s]: e_omega_brk = CPC3_EEP.ptconf_p_Eng.MaxPermEngBrkSpd_u16*0.16/60*2*pi
% Warn buzzer engine velocity [rad/s]: e_omega_warn = CPC3_EEP.ptconf_p_Eng.WarnBuzzEngSpd_u16*0.16/60*2*pi
% Maximum short time engine acceleration velocity [rad/s]: e_omega_acc = CPC3_EEP.ptconf_p_Eng.MaxEngSpdGov0EngSpd_u16*0.16/60*2*pi
% Minimum engine brake velocity [rad/s]: e_omega_min_brk = CPC3_EEP.ptconf_p_Eng.MinEngBrkSpd_u16*0.16/60*2*pi
% Maximum engine brake velocity [rad/s]: e_omega_max_brk = CPC3_EEP.ptconf_p_Eng.MaxEngBrkSpd_u16*0.16/60*2*pi
% Engine brake variant [-]: e_brk_var = CPC3_EEP.ptconf_p_Eng.EngBrkVar_u1
if ~isfield(EEP.ptconf_a_Eng, 'EngType_u8') || isempty(EEP.ptconf_a_Eng.EngType_u8) || EEP.ptconf_a_Eng.EngType_u8 == 255
    switch par.mcm_sys_motor_type_1m
        case 934
            EEP.ptconf_a_Eng.EngType_u8 = 2;
        case 936
            EEP.ptconf_a_Eng.EngType_u8 = 3;
        case 470 % DD11
            EEP.ptconf_a_Eng.EngType_u8 = 4;
        case 471 % DD13
            EEP.ptconf_a_Eng.EngType_u8 = 5;
        case 473 % DD16
            EEP.ptconf_a_Eng.EngType_u8 = 6;
        case 472 % DD15
            EEP.ptconf_a_Eng.EngType_u8 = 15;
        case 924
            EEP.ptconf_a_Eng.EngType_u8 = 20;
        case 926
            EEP.ptconf_a_Eng.EngType_u8 = 21;
        case 460
            EEP.ptconf_a_Eng.EngType_u8 = 23;
        otherwise
            error('engine type unknown')
    end
end
EEP.ptconf_a_Eng.CombustionClass_u8     = par.mcm_sys_can_engine_char_1m; % [-] 
EEP.ptconf_a_Eng.EngInertiaTrq_u16      = round(par.mcm_sys_can_trq_inertia_1m / 2^(-12)); % [kgm²] sys_can_trq_inertia
EEP.ptconf_a_Eng.MaxPermEngBrkSpd_u16   = round(par.mcm_epf_ebm_overspeed_1m / 0.16); % [rpm] 
EEP.ptconf_a_Eng.WarnBuzzEngSpd_u16     = round(par.mcm_epf_warn_overspeed_1m / 0.16); % [rpm] 
EEP.ptconf_a_Eng.MaxEngSpdGov0EngSpd_u16 = round(par.mcm_osg_eng_speed_max_ext_1m / 0.16);  % [rpm]

switch EEP.ptconf_a_Eng.CombustionClass_u8
    case 3 % not defined for CPC5, but in CPC3: Euro 3
        EEP.ptconf_a_Eng.CombustionClass_u8 = 50;
    case 4 % Euro 4 is mapped to Euro 5 in CAL
        EEP.ptconf_a_Eng.CombustionClass_u8 = 51;
    case 5 % not defined for CPC5, but in CPC3: Euro 5
        EEP.ptconf_a_Eng.CombustionClass_u8 = 51;
    case 6 % not defined for CPC5, but in CPC3: Euro 6
        EEP.ptconf_a_Eng.CombustionClass_u8 = 52;
    case 13 % not defined for CPC5, but in CPC3: EPA 13
        EEP.ptconf_a_Eng.CombustionClass_u8 = 10;
    case 70 % PJP09 not supported by CPC5, but JP17 / J-OBD II
        EEP.ptconf_a_Eng.CombustionClass_u8 = 71;
    case 72 % China 6 --> Euro 6
        EEP.ptconf_a_Eng.CombustionClass_u8 = 52;
end

% Lower switch off and on engine speed value of engine brake step 2 at 80°C engine oil temperature
[ebsOnEngSpd, ebsOffEngSpd] = calcEngSpeedEbmOnAndOff ( ...
    par.mcm_ebm_ebs1_temp_speed_cond_on_2m, par.mcm_ebm_ebs1_temp_speed_cond_off_2m, par.mcm_ebm_ebs1_temp_speed_cond_x_speed, ...
    par.mcm_ebm_ebs2_temp_speed_cond_on_2m, par.mcm_ebm_ebs2_temp_speed_cond_off_2m, par.mcm_ebm_ebs2_temp_speed_cond_x_speed);
% Off
rpm = round(ebsOffEngSpd / 0.25) * 0.25; % Auflösung in der Diagnose Schnittstelle berücksichtigen. Unklar, ob round/ceil/floor
EEP.ptconf_a_Eng.MinEngBrkSpd_u16 = round(rpm / 0.16);  % [rpm]
% On
rpm = round(ebsOnEngSpd / 0.25) * 0.25; % Auflösung in der Diagnose Schnittstelle berücksichtigen. Unklar, ob round/ceil/floor
EEP.ptconf_a_Eng.MaxEngBrkSpd_u16 = round(rpm / 0.16);  % [rpm]

EEP.ptconf_a_Eng.EngBrkVar_u8 = par.mcm_sys_get_eng_brk_performance;  % [-]

%% ID1 = 207, ID2 = 11, Brake Map 1 Min
% Vector of engine map speeds [1/min]: e_n = CPC3_EEP.ptconf_p_EngBrk.EngBrkStp1TrqCrvEngSpds_u8*16
% Vector of engine map brake torques [Nm]: e_M_B = (CPC3_EEP.ptconf_p_EngBrk.EngBrkStp1MinBrkTrqs_u16-25000)*0.2
EEP.ptconf_a_EngBrk.EngBrkStp1TrqCrvEngSpds_u8  = round(par.mcm_cac_br_trq_ebs_x_rpm' / 16); % [rpm]
EEP.ptconf_a_EngBrk.EngBrkStp1TrqCrvEngSpds_u16 = round(par.mcm_cac_br_trq_ebs_x_rpm' / 0.16); % [rpm]
EEP.ptconf_a_EngBrk.EngBrkStp1MinBrkTrqs_u16    = round((par.mcm_cac_br_trq_ebs1_max_2m' + 5000) / 0.2); % [Nm]

%% ID1 = 207, ID2 = 12 (In SIL ID2 = 11?), Brake Map 2 Min
% Vector of engine map speeds [1/min]: e_n = CPC3_EEP.ptconf_p_EngBrk.EngBrkStp2TrqCrvEngSpds_u8*16
% Vector of engine map brake torques [Nm]: e_M_B = (CPC3_EEP.ptconf_p_EngBrk.EngBrkStp2MinBrkTrqs_u16-25000)*0.2
EEP.ptconf_a_EngBrk.EngBrkStp2TrqCrvEngSpds_u8  = round(par.mcm_cac_br_trq_ebs_x_rpm' / 16); % [rpm]
EEP.ptconf_a_EngBrk.EngBrkStp2TrqCrvEngSpds_u16 = round(par.mcm_cac_br_trq_ebs_x_rpm' / 0.16); % [rpm]
EEP.ptconf_a_EngBrk.EngBrkStp2MinBrkTrqs_u16    = round((par.mcm_cac_br_trq_ebs2_max_2m' + 5000) / 0.2); % [Nm]

%% ID1 = 207, ID2 = 13 (In SIL ID2 = 11?), Brake Map 3 Min
% Vector of engine map speeds [1/min]: e_n = CPC3_EEP.ptconf_p_EngBrk.EngBrkStp3TrqCrvEngSpds_u8*16
% Vector of engine map brake torques [Nm]: e_M_B = (CPC3_EEP.ptconf_p_EngBrk.EngBrkStp3MinBrkTrqs_u16-25000)*0.2
EEP.ptconf_a_EngBrk.EngBrkStp3TrqCrvEngSpds_u8  = round(par.mcm_cac_br_trq_ebs_x_rpm' / 16); % [rpm]
EEP.ptconf_a_EngBrk.EngBrkStp3TrqCrvEngSpds_u16 = round(par.mcm_cac_br_trq_ebs_x_rpm' / 0.16); % [rpm]
EEP.ptconf_a_EngBrk.EngBrkStp3MinBrkTrqs_u16    = round((par.mcm_cac_br_trq_ebs3_max_2m' + 5000) / 0.2); % [Nm]

%% ID1 = 207, ID2 = 14 (In SIL ID2 = 11?), Brake Map 1 Max
% Vector of engine map speeds [1/min]: e_n = CPC3_EEP.ptconf_p_EngBrk.EngBrkStp1TrqCrvEngSpds_u8*16
% Vector of engine map brake torques [Nm]: e_M_B = (CPC3_EEP.ptconf_p_EngBrk.EngBrkStp1MaxBrkTrqs_u16-25000)*0.2
EEP.ptconf_a_EngBrk.EngBrkStp1MaxBrkTrqs_u16    = round((par.mcm_cac_br_trq_ebs1_min_2m' + 5000) / 0.2); % [Nm]

%% ID1 = 207, ID2 = 15 (In SIL ID2 = 11?), Brake Map 2 Max
% Vector of engine map speeds [1/min]: e_n = CPC3_EEP.ptconf_p_EngBrk.EngBrkStp2TrqCrvEngSpds_u8*16
% Vector of engine map brake torques [Nm]: e_M_B = (CPC3_EEP.ptconf_p_EngBrk.EngBrkStp2MaxBrkTrqs_u16-25000)*0.2
EEP.ptconf_a_EngBrk.EngBrkStp2MaxBrkTrqs_u16    = round((par.mcm_cac_br_trq_ebs2_min_2m' + 5000) / 0.2); % [Nm]

%% ID1 = 207, ID2 = 16 (In SIL ID2 = 11?), Brake Map 3 Max
% Vector of engine map speeds [1/min]: e_n = CPC3_EEP.ptconf_p_EngBrk.EngBrkStp3TrqCrvEngSpds_u8*16
% Vector of engine map brake torques [Nm]: e_M_B = (CPC3_EEP.ptconf_p_EngBrk.EngBrkStp3MaxBrkTrqs_u16-25000)*0.2
EEP.ptconf_a_EngBrk.EngBrkStp3MaxBrkTrqs_u16    = round((par.mcm_cac_br_trq_ebs3_min_2m' + 5000) / 0.2); % [Nm]

%% ID1 = 207, ID2 = 18, (keine EEP sondern mdl Werte?) Consumption Map
% Vector of engine map velocities [rad/s]: e_omega = mdl.e.map.omega
% Vector of engine map torques [Nm]: e_M = mdl.e.map.M
% Matrix of engine fuel consumption [kg/Ws]: e_b_e = mdl.e.map.b_e
% Number of Zylinders [-]: e_z = mdl.e.z ???? mcm ??? sys_cylinder_value_1m
rpm = par.mcm_tfc_fm_tm_x_eng_speed'; % [rpm]
Nm = par.mcm_tfc_fm_tm_y_trq'; % [Nm]
mgpstr = par.mcm_tfc_fm_tmh_3m'; % [mg/str] tfc_fm_3m
nCyl = par.mcm_sys_cylinder_value_1m; % [-] wird eigentlich nicht über Diagnose übergeben, sondern ahängig von dem Motortyp selber von CPC festgelegt
% calculation of g/kWh
[rpm2, Nm2] = meshgrid(rpm, Nm');
mgpr = mgpstr * nCyl / 2;  % mg/stroke/cylinder -> mg/r (info: 2 revolution per stroke) 
kgh = mgpr .* rpm2 * 60 / 1e6; % mg/r -> kg/h
gkWh = kgh * 1000 ./ (Nm2 .* rpm2 * pi/30 / 1000); % kg/h -> g/kWh
% setting EEP Parameters
idx_Nm0 = Nm == 0;
gkWh(idx_Nm0,:) =  1562.5; % = 50000 * 2^(-5), maximal valid EEP value
% Attention: Do not round values
% Otherwise: Can lead to errors with interp2 in uds22h_init_EngConsMap
% Original Resolution in UDS: 0.25rpm, 0.2Nm
% EEP Data Resolution: 16rpm, 20Nm
EEP.ptconf_a_EngConsum.EngConsumMapEngSpds_u8       = (rpm / 16); % [rpm]
EEP.ptconf_a_EngConsum.EngConsumMapEngTrqs_u8       = (Nm / 20); % [Nm]
EEP.ptconf_a_EngConsum.EngConsumMapFuelMass_u16     = (gkWh / 2^(-5)); % [g/kWh]

%% ID1 = 207, ID2 = 19, Friction Map (In der MCM OBD2 (v1.236, 2012-02-23) eher ID2=23)
% Vector of engine map speeds [1/min]: e_n = CPC3_EEP.ptconf_p_EngFric.EngFricTrqMapEngSpd_u8*16
% Vector of engine map tempretures [°C]: e_T = (CPC3_EEP.ptconf_p_EngFric.EngFricTrqMapTemp_u8-100)*1
% Vector of engine map drag torques [Nm]: e_M_S = (CPC3_EEP.ptconf_p_EngFric.EngFricTrqMapTrq_u16-25000)*0.2
EEP.ptconf_a_EngFric.EngFricTrqMapEngSpd_u8 = round(par.mcm_tic_trq_loss_fric_x_eng_speed' / 16); % [rpm] 
EEP.ptconf_a_EngFric.EngFricTrqMapTemp_u8   = round(par.mcm_tic_trq_loss_fric_y_t_eng_oil' + 100); % [°C] 
EEP.ptconf_a_EngFric.EngFricTrqMapTrq_u16   = round((-par.mcm_tic_trq_loss_fric_3m' + 5000) / 0.2); % [Nm]


% ?????????????????????????????????????????????????????????????????????????
% ptconf_p_Eng.UnChFullLoadEngTrqCurve_u16 = ???
% -> wird nicht über Diagnose, sondern über CAN_ Signale bedatet
% ?????????????????????????????????????????????????????????????????????????


%% necessary for CPC3_Input Simulink model
% init:
    % e_M_max = max(max(e_map_M_VL));
    % e_M_S_max = max(-e_map_M_S);
    % e_M_B1_max = max(max(-e_map_M_B1));
    % e_M_B2_max = max(max(-e_map_M_B2));
    % e_M_B3_max = max(max(-e_map_M_B3));
    % e_M_B_max = max([e_M_S_max e_M_B1_max e_M_B2_max e_M_B3_max]);
    % 
    % r_M_max = max(r_map_M_VL);
    % 
    % if (x_ID == 2800)
    %     c3_position = 1;
    % else
    %     c3_position = 0;
    % end
% Vector of engine map velocities [rad/s]: e_map_omega = mdl.e.map.omega
% --> wird intern nicht gebraucht
% Vector of engine map fullload torques [Nm]: e_map_M_VL = mdl.e.map.M_VL
% --> wird indirekt (siehe init) gebraucht
% Vector of engine map drag torques [Nm]: e_map_M_S = mdl.e.map.M_S
% --> wird indirekt (siehe init) gebraucht
% Vector of engine map brake torques (level 1) [Nm]: e_map_M_B1 = mdl.e.map.M_B1
% --> wird indirekt (siehe init) gebraucht
% Vector of engine map brake torques (level 2) [Nm]: e_map_M_B2 = mdl.e.map.M_B2
% --> wird indirekt (siehe init) gebraucht
% Vector of engine map brake torques (level 3) [Nm]: e_map_M_B3 = mdl.e.map.M_B3
% --> wird indirekt (siehe init) gebraucht

% --> geändert zu:

% init:
    % if (x_ID == 2800)
    %     c3_position = 1;
    % else
    %     c3_position = 0;
    % end
% max. engine torque [Nm]: e_M_max = max(0.2*CPC3_EEP.ptconf_p_Eng.TrbChFullLoadEngTrqCurve_u16-5000)
% max. engine brake torque [Nm] (positive value): e_M_B_max = -(min([CPC3_EEP.ptconf_p_EngFric.EngFricTrqMapTrq_u16(:);CPC3_EEP.ptconf_p_EngBrk.EngBrkStp3MinBrkTrqs_u16(:);CPC3_EEP.ptconf_p_EngBrk.EngBrkStp3MinBrkTrqs_u16(:);CPC3_EEP.ptconf_p_EngBrk.EngBrkStp3MinBrkTrqs_u16(:)]) * 0.2 -5000)


%% necessary for CPC UDS Simulink model (Consumption Map)
% init:
    % % Umrechung [kg/Ws] nach [mg/ASP/Zylinder]
    % for i = 1:length(e_M)
    %     for j = 1:length(e_omega)
    %        e_b_e(i, j) = 4*pi*10^6*e_b_e(i, j)*e_M(i)/e_z;
    %     end;
    % end;
    % ...
% Vector of engine map velocities [rad/s]: e_omega = mdl.e.map.omega
% Vector of engine map torques [Nm]: e_M = mdl.e.map.M
% Matrix of engine fuel consumption [kg/Ws]: e_b_e = mdl.e.map.b_e
% Number of Zylinders [-]: e_z = mdl.e.z

% --> geändert zu:
% init:
    % ...
% Vector of engine map velocities [rad/s]: e_omega = CPC3_EEP.ptconf_p_EngConsum.EngConsumMapEngSpds_u8 * 16 * pi/30
% Vector of engine map torques [Nm]: e_M = CPC3_EEP.ptconf_p_EngConsum.EngConsumMapEngTrqs_u8 * 20
% Matrix of engine fuel consumption [g/kWh]: e_b_e = CPC3_EEP.ptconf_p_EngConsum.EngConsumMapFuelMass_u16 * 2^(-5)

%% entferne einige Motor mdl Daten, um sicher zu gehen, dass diese nicht wo anders gebraucht werden, ohne es zu bemerken
try mdl.e = rmfield(mdl.e, 'map'); end
try mdl.e = rmfield(mdl.e, 'omega_derate'); end
try mdl.e = rmfield(mdl.e, 'omega_brk_max'); end
try mdl.e = rmfield(mdl.e, 'omega_brk_off'); end
try mdl.e = rmfield(mdl.e, 'omega_brk_on'); end
try mdl.e = rmfield(mdl.e, 'omega_limit'); end
% mdl.e = rmfield(mdl.e, 'omega_idle'); muss aktuell noch bleiben, da es im Modell verwendet wird
try mdl.e = rmfield(mdl.e, 'z'); end
try mdl.e = rmfield(mdl.e, 'J'); end


function [ebsOnEngSpd, ebsOffEngSpd] = calcEngSpeedEbmOnAndOff ( ...
    ebm_ebs1_temp_speed_cond_on_2m, ebm_ebs1_temp_speed_cond_off_2m, ebm_ebs1_temp_speed_cond_x_speed, ...
    ebm_ebs2_temp_speed_cond_on_2m, ebm_ebs2_temp_speed_cond_off_2m, ebm_ebs2_temp_speed_cond_x_speed)
% aus Mail von J. Gerhard, 23.11.2015
Tswitch = 80;
ebs1OnEngSpd = ebsOnOrOff(ebm_ebs1_temp_speed_cond_on_2m,ebm_ebs1_temp_speed_cond_x_speed,Tswitch);
ebs2OnEngSpd = ebsOnOrOff(ebm_ebs2_temp_speed_cond_on_2m,ebm_ebs2_temp_speed_cond_x_speed,Tswitch);

ebs1OffEngSpd = ebsOnOrOff(ebm_ebs1_temp_speed_cond_off_2m,ebm_ebs1_temp_speed_cond_x_speed,Tswitch);
ebs2OffEngSpd = ebsOnOrOff(ebm_ebs2_temp_speed_cond_off_2m,ebm_ebs2_temp_speed_cond_x_speed,Tswitch);

ebsOnEngSpd = min(ebs1OnEngSpd,ebs2OnEngSpd);
ebsOffEngSpd = min(ebs1OffEngSpd,ebs2OffEngSpd);


function [engSpd] = ebsOnOrOff(ebm_ebs_temp_speed_cond_2m,ebm_ebs_temp_speed_cond_x_speed,Tswitch)
% aus Mail von J. Gerhard, 23.11.2015
ebsPos = find(ebm_ebs_temp_speed_cond_2m>Tswitch,1,'last')+1;
if ebsPos > 1
    if ebm_ebs_temp_speed_cond_2m(ebsPos)<ebm_ebs_temp_speed_cond_2m(ebsPos-1)
        % interpolation
        engSpd = ebm_ebs_temp_speed_cond_x_speed(ebsPos)- ...
            (ebm_ebs_temp_speed_cond_x_speed(ebsPos) - ebm_ebs_temp_speed_cond_x_speed(ebsPos-1)) *...
            (ebm_ebs_temp_speed_cond_2m(ebsPos) -Tswitch)/(ebm_ebs_temp_speed_cond_2m(ebsPos)-ebm_ebs_temp_speed_cond_2m(ebsPos-1));
    else
        engSpd = ebm_ebs_temp_speed_cond_x_speed(ebsPos);
    end
else
    engSpd = ebm_ebs_temp_speed_cond_x_speed(1);
end
if isinf(engSpd)
    engSpd = ebm_ebs_temp_speed_cond_x_speed(ebsPos);
end