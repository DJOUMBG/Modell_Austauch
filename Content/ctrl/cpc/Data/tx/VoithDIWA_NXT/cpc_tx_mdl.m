% cpc_VoithDIWA

% transmission Voith DIWA
% source: PTCONF-CPC3.xls Elisha Lauer
%

%% t.id
% Description: Transmission ID
% Unit: [-]
% Size: <1x1>
% Range: (based on cpc3_data_load.m)
% Reference:

% 31: G140-8K
% 41: G211-12K
% 42: G280-16K
% 44: G230-12K
% 45: G281-12K
% 46: G330-12K
% 54: GO240-8K
% 220: DIWA.6
t.id = 220;

%% t.type
% Description: Transmission Type
% Unit: [-]
% Size: <1x1>
% Range: based on PTCONF-CPC3.xls
% Reference: 0 G211-12K
t.type = []; % type can be directly defined if t.id = 99

%% t.n_min
% Description: Number of reverse gears
% Unit: [-]
% Size: <1x1>
% Range: [-1 -8] (based on ptconf_p_Trans.RevGearNum_u8)
% Reference:
t.n_min = -1;

%% t.n_max
% Description: Number of forward gears
% Unit: [-]
% Size: <1x1>
% Range: [5 16] (based on ptconf_p_Trans.ForwGearNum_u8)
% Reference:
t.n_max = 7;


%========== START Dataset ==========

%% t.i
% Description: Vector of transmission ratios
% Unit: [-]
% Size: <(number of forward+backward+neutral) x1>
% Range: [-20 20] (based on ptconf_p_Trans.GearRatio_s16 <1x25>)
% Reference: [t.n_min:t.n_max]
t.i = [-2.98; 0; 1.36; sMP.ctrl.cpc.par.tx_iTxAllFw(2:7)'];

% Compare transmission ratio from TCM and CPC
% if any(abs(t.i(end-t.n_max+1:end) - sMP.ctrl.cpc.par.tx_iTxAllFw(1:t.n_max)') > 0.02) % any ratio difference is higher than 0.02
%    % Check only forward gears
%    error('Please check the configured Transmission! It seems that different transmissions for CPC and TCM are configured!')
% end


%% t.eta
% Description: Vector of transmission efficiency values
% Unit: [-]
% Size: <(number of forward+backward+neutral) x1>
% Range: [0 1] (based on ptconf_p_Trans.GearFricEff_u8 <1x25>)
% Reference: [t.n_min:t.n_max]
t.eta = [0.98; 0; 0.98; 0.98; 0.98; 1; 0.98; 0.98; 0.98];

%% t.J
% Description: Vector of transmission inertia torque values
% Unit: [kgm²]
% Size: <(number of forward+backward+neutral) x1>
% Range: [0 10] (based on ptconf_p_Trans.TransInertiaTrq_u16 <1x25>)
% Reference: [t.n_min:t.n_max]
t.J = [0; 0; 0; 0; 0; 0; 0; 0; 0];

%========== END Dataset ==========

