%% Inports:
mec_veh_transPos = 0; % [m], phys: 0..Inf
mec_veh_transVel = 0; % [m/s], phys: -70..70
mec_eng_speedCrankshaft = 800; % [rpm], phys: 0..10000, abs: 0..10000
mec_tx_stCltAct = 0; % [-], phys: 0..1, abs: 0..1
cpc_SysStat_sta = 1; % [-]
tcm_Clutch_Stat = 0; % [-], phys: 0..10000, abs: 0..10000
env_roadPos_m = 0; % [m]
mcm_EngSpd_Cval_PT = 1200; % [rpm], phys: 0..10485.6, abs: 0..10485.6
mcm_EngTrq_Cval_PT = 500; % [Nm], phys: -5000..8107, abs: -5000..8107
mcm_EngFrictTrq_Cval_PT = 0; % [Nm], phys: -5000..8107, abs: -5000..8107
cpc_cc_p_CcSecure_LowSwitchOnVehSpd_u8 = 30; % [kmh]
cpc_CC_Actvn_Stat_PT = 0; % [-], phys: 0..2
tcm_iGbDes = 1; % [-], phys: -100..100, abs: -100..100
