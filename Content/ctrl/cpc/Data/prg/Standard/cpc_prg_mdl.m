%% Vehicle driving program (Fahrpaket)
% Range: [0 10] (based on ag_p_VehConf.SftPrgAv_u8)
% 0 = Power / G0V or G0K
% 1 = Economy / G0U
% 2 = Heavy Duty / G0Y
% 3 = Fleet / G0Z
% 4 = Offroad / G0W
% 5 = Municipal / G0S
% 6 = Fire / G0X
% 7 = Economy+ / G0U (since CPC5)
% 8 = ViabPower / G0K + G3Y
% 9 = ViabEconomy / G0K + G3Y
% 10 = ViabOffroad / G0W + G3Y
v.drv_prog = 0; % Reference: 1

%% Driving mode (Fahrprogram): standard or special
% Range: standard(0) or special(1)
v.drv_mode = 0; % Reference: 1