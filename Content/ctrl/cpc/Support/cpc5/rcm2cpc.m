function [EEP, mdl] = rcm2cpc(EEP, mdl, par)
% RCM2CPC Convert RCM parameter to CPC parameter
% Represents the Diagnosis UDS communication between RCM and CPC
%
%
% Syntax:  [EEP, mdl] = rcm2cpc(EEP, mdl, par)
%
% Inputs:
%    EEP - [.] current EPROM structure of the CPC
%    mdl - [.] mdl structure with model parameters
%    par - [.] global parameter structure, which also includes RCM parameter
%
% Outputs:
%    EEP - [.] new EPROM structure of the CPC
%    mdl - [.] mdl structure with model parameters that also provides global parameter
%
% Example: 
%    [EEP, mdl] = rcm2cpc(EEP, mdl, par);
%
%
% Author: PLOCH37
% Date:   29-Jan-2020

%% Parameter of RCM: full load curve 
rpm_RCM = par.rcm_x_ret_GW_rpm;
Nm_RCM = par.rcm_y_ret_M_max;

%% Get speed sample points of the retarder as in the C-Code to define torque parameter
if isempty(mdl) || ~isfield(mdl, 'r_rpm')
    % Parameter of CPC: engine and transmission
    rpm_Eng = EEP.ptconf_a_EngBrk.EngBrkStp3TrqCrvEngSpds_u8 * 16;
    
    nForwGear = EEP.ptconf_p_Trans.ForwGearNum_u8;
    iTrans = EEP.ptconf_p_Trans.GearRatio_s16;
    idxLastGear = find(iTrans ~=0, 1, 'last');
    if (idxLastGear - 9) == nForwGear % first gear starts at index 10
        iLastGear = iTrans(idxLastGear) / 2^10;
    else
        error('%s: Last gear (%d) doesn''t fit number of forward gears (%d)', mfilename, idxLastGear - 9, nForwGear)
    end
    
    % Algorithm in the C-Code (see ptconf_g_RetSpd_u8)
    rpm_Ret(9:16) = rpm_Eng(1:8) / iLastGear;
    rpm_Ret(1:8) = rpm_Ret(9) * [1:1:8] / 9;
else
    % Sample points of the retarder could be provided, becauce CPC was
    % already running during the initialisaton for a short time to get
    % shift parameter (see cal_data_load.m)
    rpm_Ret = mdl.r_rpm;
end


%% Retarder full load curve 
% CPC retarder parameter
if EEP.ptconf_p_Ret.RetType_u8
    Nm_Ret = interp1(rpm_RCM, Nm_RCM, rpm_Ret, 'linear', 'extrap');
    EEP.ptconf_p_Ret.RetMaxBrkTrqs_u16 = round((-Nm_Ret + 5000) / 0.2);
    % Global / dependent parameter, for example for PPC
    mdl.r_rpm = rpm_Ret;
    mdl.r_Nm = Nm_Ret;
else
    EEP.ptconf_p_Ret.RetMaxBrkTrqs_u16 = 65535 * ones(1, 16); % SNA
end

