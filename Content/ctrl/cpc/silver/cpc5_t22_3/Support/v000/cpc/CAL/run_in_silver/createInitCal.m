function createInitCal(EEP, INIT_FILE)
% CREATEINITCAL create init file for CAL module based on EEP data
% Example: init_template.txt
%
%
% Syntax:  createInitCal(EEP, INIT_FILE)
%
% Inputs:
%          EEP - [.] EEP parameter structure
%    INIT_FILE - [''] Init file name to write
%
% Outputs:
%     -
%
% Example: 
%    createInit(EEP, INIT_FILE)
%
%
% Author: PLOCH37
% Date:   13-Jan-2020

%% ------------- BEGIN CODE --------------

fid = fopen(INIT_FILE, 'w');
fprintf(fid, 'sw_p_VehConf.EnAg_u1=1;\r\n');
fprintf(fid, 'ptconf_g_CombustionClass_u8=%d;\r\n', EEP.ptconf_a_Eng.CombustionClass_u8); % 52 = Euro6
fprintf(fid, 'ptconf_g_EngType_u8=%d;\r\n', EEP.ptconf_a_Eng.EngType_u8); % 5 = OM471
fprintf(fid, 'ptconf_g_RetType_u8=%d;\r\n', EEP.ptconf_p_Ret.RetType_u8); % 0 = No Retarder
fprintf(fid, 'ptconf_g_TransType_u8=%d;\r\n', EEP.ptconf_p_Trans.TransType_u8); % 0 = G211
fprintf(fid, 'ag_g_ReqSftPrgNum_u8=%d;\r\n', EEP.ag_p_VehConf.SftPrgAv_u8(EEP.ag_p_VehConf.SftPrgIdxOnStart_u8+1)); % 100 = Standard
fprintf(fid, 'ag_p_VehConf.SftPrgAv_u8[0]=%d;\r\n', EEP.ag_p_VehConf.SftPrgAv_u8(1)); % 0 = Power
fprintf(fid, 'ag_p_VehConf.SftPrgAv_u8[1]=%d;\r\n', EEP.ag_p_VehConf.SftPrgAv_u8(2)); % 1 = Economy
fprintf(fid, 'ag_p_VehConf.SftPrgAv_u8[2]=%d;\r\n', EEP.ag_p_VehConf.SftPrgAv_u8(3)); % 100 = Standard
fprintf(fid, 'cal_m_DrivingProgramRng_u8[0]=%d;\r\n', EEP.ag_p_VehConf.SftPrgAv_u8(1));
fprintf(fid, 'cal_m_DrivingProgramRng_u8[1]=%d;\r\n', EEP.ag_p_VehConf.SftPrgAv_u8(2));
fprintf(fid, 'cal_m_DrivingProgramRng_u8[2]=%d;\r\n',EEP.ag_p_VehConf.SftPrgAv_u8(3));
fclose(fid);