% 0 = Power / G0V or G0K
% 1 = Economy / G0U
% 2 = Heavy Duty / G0Y
% 3 = Fleet / G0Z
% 4 = Offroad / G0W
% 5 = Municipal / G0S
% 6 = Fire / G0X or G0I (Airport)
% 7 = Economy+ / G0U (since CPC5)
% 8 = ViabPower / G0V + G3Y
% 9 = ViabEconomy / G0V/GOW + G3Y
% 10 = ViabOffroad / G0W + G3Y
% 100 = Standard
% 102 = StandardHeavyDuty G0V/GOW + G3Y
EEP.ag_p_VehConf.SftPrgAv_u8 = [100 255 255]; % Standard inactive inactive
EEP.ag_p_VehConf.SftPrgIdxOnStart_u8 = 0; % first program selected

% For eCPC/CPC6 only
% No Standard defined in Energy Management Module defined yet, but exist in AG --> use Eco instead
EEP.enm_p_Conf.EnergyModeAv_u8 = [1 255 255]; % Eco inactive inactive (eCPC)
EEP.enm_p_Conf.EgyMdAv_u8      = [1 255 255]; % Eco inactive inactive (CPC6)