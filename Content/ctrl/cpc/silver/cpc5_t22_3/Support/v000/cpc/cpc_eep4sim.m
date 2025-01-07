% Change EEP parameter for simulation.
% Should be different then in real vehicle, because ...
% - otherwise problems in simulation expected
% - higher flexibility in simulation possible

% Please sort parameter based on modules alphabetically


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ag: automatic gear selection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Define Shift Program
EEP.ag_p_VehConf.UseSftPrgCodeEep_u8 = 0; % use shift dynamic program code from CAL module, otherwise ShiftPrg_Stat will be not same as cal_g_AgSftPrg_u8
% EEP.ptconf_p_Trans.SftPrgCode_u8 = SftPrgAv_u8(SftPrgIdxOnStart_u8+1), not really necessary, because SftPrg from CAL
% EEP.ag_p_VehConf.SftPrgAv_u8
% EEP.ag_p_VehConf.SftPrgIdxOnStart_u8
EEP.ag_p_VehConf.SftPrgDeact_u8 = 1; % Shift Program Deactivation by Driver, not as defined in CDS(0), take a look at CDS.cal_g_AgSftPrgDep_u2

% Allow to shift manual
EEP.ag_p_VehConf.EnManMd_u8 = 1;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cc: cruise control
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Change Hysteresis limits for variation in simulation (especially for DTNA vehicles needed)
EEP.cc_p_VehConf.MinHyst_u16       = 0; %  0 km/h, Minimum upper hysteresis
EEP.cc_p_VehConf.MaxHyst_u16    = 4000; % 20 km/h, Maximum upper hysteresis
EEP.cc_p_VehConf.MinHystHigh_u16  = 0; %  0 km/h, Minimum upper hysteresis in special Mode (for example Economy)
EEP.cc_p_VehConf.MaxLoHyst_u16 = 4000; % 20 km/h, Maximum lower hysteresis
% Hysteresis Variant
% 0 = continuous & store
% 1 = continuous & no store
% 2 = stepped
% 3 = single
% 4 New HMI & store
% 5 New HMI & no store
EEP.cc_p_VehConf.HystVar_u8 = 4; % New HMI & store

% Change the HMI Concept to SFTP style (or same as known in cpcAux module)
% The driver (cpcAux) is only familiar with the operation of a SFTP, not a Cascadia
EEP.cc_p_VehConf.CCSwitchVar_u8 = 0; % Set / Plus; Resume / Minus (SFTP)
EEP.cc_p_VehConf.SetSpeedMd_u8 = 0; % 0: Step-Ramp-Mode, 1: Continuous-Ramp-Mode
EEP.cc_p_VehConf.SetSpeedIncMode_u8 = 0; % CC Set-Speed Adjustment Unit Mode in km/h (2: CAN)
EEP.cc_p_VehConf.IncRegMd_u2 = 0; % increment 0.5 unit (1: 1 unit)
EEP.cc_p_VehConf.EnAutoResSel_u8 = 1; % enable automatic cruise resume
EEP.cc_p_VehConf.EraseResumeCval_u8 = 0; % do not erase any (CC or LIM) resume value

% Allow to switch CC Modes (may be disabled in Freightliner vehicles)
EEP.cc_p_VehConf.DisModeSwitch_u8 = 3; % ModeSwitches enabled (may not exist in future CPC versions? Use of CC_FuncMode_Rq_Stat_IC in cpcAux instead?)
% Start in CC, so the driver does not need to change CC Mode from ACC
EEP.cc_p_VehConf.StartFuncMd_u4 = 1;
% No input signal toggle (brk, cc, ...) required before Cruise Control activation
EEP.cc_p_VehConf.InSigTogRqd_u8 = 0;

% Disable max CC speed for standard program
EEP.cc_p_VehConf.CCMaxVehSpd_u16 = 65535; % inactive
% % Disable max CC speed for economy program
% EEP.cc_p_VehConf.CCEcoMaxVehSpd_u16 = 65535; % inactive
% % Disable max CC speed for economy+ program
% EEP.cc_p_VehConf.CCEcoPMaxVehSpd_u16 = 65535; % inactive


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cdi: common data interface
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ICUC on Chassis CAN available
EEP.cdi_a_Cal.IcucCcanAv_u1 = 1; % also possible with const input ch_GVC_SysMsg_ICUC = 1

% Define transmission type, if not defined yet
% (needed to get plausible ptconf_g_TransAutLvl_u8 signal: manual / automated / unknown)
if ~isfield(EEP, 'cdi_a_Cal') || ~isfield(EEP.cdi_a_Cal, 'GvcTransType_u4')
    EEP.cdi_a_Cal.GvcTransType_u4 = 2; % MB Transmission Automated Claw
end

% Ensure that source of Endurance Brake Lever is CAN and not LIN,
% so input ch_RetSwPos_Rq_SAM is considered
EEP.cdi_p_VehConf.EbmLeverSrcSel_u2 = 1; % 0: no EBM lever available, 1: CAN, 2: LIN

% Environment Temperature via CCAN (AirTempOutsd_Cval_SCA)
EEP.cdi_p_VehConf.EnvTempSel_u8 = 4;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cust: customization    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Remove stored driver profiles:
% Important, if par file extracted from vehicle. It can store the driver
% profile preferred settings, dependent on driver card
if isfield(EEP, 'cust_a_Cal')
    EEP = rmfield(EEP, 'cust_a_Cal');
end

% Disable Customization Module
% Customization defaults can overwrite settings by other modules.
% Therefore it can probably make more trouble than help for simulation purposes
EEP.cust_p_Cal.CustomizationMode_u8 = 0; % no customization

% % Overwrite PPC settings with customized settings
% EEP.cust_p_Cal.IppcModeDefault_u8 = 0 ; % PPC Off
% EEP.cust_p_Cal.IppcIuModeDefault_u8 = 0 ; % PPC inter urban Off
% EEP.cust_p_Cal.IppcIuAutoSetSpdModeDefault_u8 = 0; % Auto CC set speed Off


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ippc: integrated predictive powertrain control
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Attention, the setting can be overwritten by Custom Module, if enabled
EEP.ippc_p_Conf.StartUpMode_u8 = 3; % IPPC always on (Hauptschalter: 1 an / 0 aus)
EEP.ippc_p_Conf.IuStartUpMode_u8 = 0; % Interurban initial off (curves and crossroads)
EEP.ippc_p_Conf.SpdLimAdptStartUpMode_u8 = 0; % Speed-Limit-Adaption off


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% itpm: integrated torque - power management
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Delete ITPM accumulated values
% If itpm_a_Cal.Save_u16(3) == 0, then itpm_m_Ena_u8 = 0 and ITPM does not work
% (found once in par file from Chris Streck)
if isfield(EEP, 'itpm_a_Cal') && isfield(EEP.itpm_a_Cal, 'Save_u16')
    EEP.itpm_a_Cal = rmfield(EEP.itpm_a_Cal, 'Save_u16');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% lim: limiter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Allow high speed in simulation:
% Not changed for CC for different drive programs, only disabled for
% standard program, see CC section.
% Other drive programs should be changed explicit by user.
kmh_max = 140;
EEP.lim_p_VspeedLim.CustMaxVehSpd_u16 = kmh_max / 0.005;
EEP.lim_p_LegConf.LegMaxVehSpd_u16 = kmh_max  / 0.005;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% pmc2: powertrain monitoring concept level 2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Other parameters: see CPC5_Parameter_Defaults.par
EEP.pmc2_p_VehConf.IfaceChkCrcMc_u32 = 0;
EEP.pmc2_p_VehConf.CplIfaceChkCrcMc_u32 = 4294967295;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ptconf: powertrain configuration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Disable UDS Interface, there is no UDS in this model
EEP.ptconf_p_Veh.UDSReqEn_u8 = 0; % UDS services use disabled

% Not sure, if this is neccessary
% It was a try, to define and consider the retarder characteristc curve by global parameter
EEP.ptconf_a_Eng.ChkSumSingValMCM_u16 = 1;
EEP.ptconf_a_Eng.ChkSumFullLoadTrqCurve_u16 = 1;
EEP.ptconf_a_Eng.ChkSumTopTrqRedCurve_u16 = 1;
EEP.ptconf_a_EngBrk.ChkSumEngBrkStp1MinMCM_u16 = 1;
EEP.ptconf_a_EngBrk.ChkSumEngBrkStp2MinMCM_u16 = 1;
EEP.ptconf_a_EngBrk.ChkSumEngBrkStp3MinMCM_u16 = 1;
EEP.ptconf_a_EngBrk.ChkSumEngBrkStp1MaxMCM_u16 = 1;
EEP.ptconf_a_EngBrk.ChkSumEngBrkStp2MaxMCM_u16 = 1;
EEP.ptconf_a_EngBrk.ChkSumEngBrkStp3MaxMCM_u16 = 1;
EEP.ptconf_a_EngConsum.ChkSumEngConsumMapMCM_u16 = 1;
EEP.ptconf_a_EngFric.ChkSumEngFricTrqMCM_u16 = 1;
EEP.ptconf_p_Ret.ChkSumRCMVIAB_u16 = 1;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% vsp: vehicle speed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Same speed sensor on every vehicle --> mec_veh_transVel as input
% For example: Cascadia vehicles usually use Transmission Outshaft Speed as
% input to derive vehicle speed from that. This could lead to a different
% speed in CPC as in physical model
EEP.vsp_p_VehConf.VehSpdSel_u8 = 2; % C3 (Filter Mode 2) average of all pulses in 10ms


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% xss: extended engine start stop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Enable XSS at initial state, no need to look at last state at ignition off and enable by Switch
EEP.xss_p_Conf.EvalLastStat_u2 = 1;

% Disable Inhibts
EEP.xss_p_Conf.DeactInhbtFunc_u8 = 255;
EEP.xss_p_Conf.DeactShutOffFunc_u8 = 255;
EEP.xss_p_Conf.UpperSysVolt_u8 = 255;

% % Brake Pedal Threshold to activate ESS
% % Fuso vehicles have usually 45%, this could be too high for our driver model
% EEP.xss_p_Conf.BrkPosThresh_u8 = 0.1 / 0.004;

% Disable ESS until models with starter are fully integrated
% Otherwise FUSO configurations could turn off engine and don't start again
EEP.xss_p_Conf.XssEn_u8 = 0;
