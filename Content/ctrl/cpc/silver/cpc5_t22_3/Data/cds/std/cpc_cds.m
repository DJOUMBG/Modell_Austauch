% Here you could define cal parameter and overwrite them as needed.
% Then you should disable the cal module in the CPC with cal.cal_m_EnCal_u8 = 0;
% All cal parameter must be defined here if cal.cal_m_EnCal_u8 == 0
% Otherwise original parameter from CDS file will be used.
%
% cal parameter should have physical and not raw values here.
% Therefore you cannot use read_par_file here.

% Select CDS Hex file
% sCDS = ''; % select hex file from this folder (useful, if you have only 1)
switch EEP.ptconf_p_Veh.VehClass_u8
    case {1, 2}
        sCDS = 'SFTP';
    case 3
        sCDS = 'NGA';
    case 17 % Mercedes bus chassis
        sCDS = 'BUS_BRAZIL';
    case 31
        sCDS = 'MB_BRAZIL';
    case {4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16} % Bus
        sTrans = cpc_cds_def(EEP.ptconf_p_Trans.TransType_u8, 'TransType');
        switch sTrans
            case '6D'
                sCDS = 'EVOBUS_MANUAL';
            case '8D'
                sCDS = 'EVOBUS_AMT';
            otherwise
                % For example for automatic transmissions:
                % define CDS file anyway, even it is not needed
                sCDS = 'EVOBUS_AMT';
        end
    otherwise
        sCDS = '';
end

% Search for file
sFileCDS = cpc_getHexFile(sCDS, sDir.cds);

% Copy CDS Hex file to Simulation Run Directory to fullfile CPC Module
% requirements, but will not be used, if cal.cal_m_EnCal_u8 = 0
copyfile(fullfile(sDir.cds, sFileCDS), fullfile(sPathRunDir, 'cpc_cds.hex'))

% Run CPC for 10s to get cal parameter (only, if 1 program available)
if sum(EEP.ag_p_VehConf.SftPrgAv_u8 ~= 255) == 1
    [cal, glo] = cal_data_load(sPathRunDir, glo, EEP);
else
    % Run some basic checks, but don't change cal parameter
    cal_data_load(sPathRunDir, glo, EEP);
end

% Read cal parameter from previous Debug Run
% cal = read_silver_par_file(fullfile(sDir.cds, 'cpc_cds.txt')); % read Silver output file
% Disable CAL Module for complete CPC
% cal.cal_m_EnCal_u8 = 0;

% Overwrite cal paramater
% cal4sim overwrites original cal parameter with most reasonable one for simulation
cpc_cal4sim


%% Examples to overwrite parameter

% % Set max startgear to 2nd gear
% cal.cal_o_AgMaxStartGearForw_s8 = 2;

% % Set pull up release rpm for AccPdl >= 80% to 2100 rpm for all gears
% cal.cal_o_AgSpdThreshFwdPullUpRelTrq_u16(:,3) = 2100;

% % Set pull up mass and road gradient offset to 0 rpm
% cal.cal_o_AgSpdThreshFwdPullUpRelMass_s16(:) = 0;
% cal.cal_o_AgSpdThreshFwdPullUpRelGrad_s16(:) = 0;

% % Reduce pull up target rpm by 50 rpm for 10th and 11th gear
% cal.cal_o_AgSpdThreshFwdPullUpReqTrq_u16(10:11,:) = cal.cal_o_AgSpdThreshFwdPullUpReqTrq_u16(10:11,:) - 50;

% % Define individual pull down release rpm for every gear
% cal.cal_o_AgSpdThreshFwdPullDownRelTrq_u16 = [
%     850 900 950
%     850 900 950
%     850 900 950
%     850 900 950
%     850 900 950
%     850 900 950
%     850 900 950
%     850 900 950
%     850 900 950
%     850 900 950
%     850 900 950
%     850 900 950
%     0 0 0
%     0 0 0
%     0 0 0
%     0 0 0
%     ];