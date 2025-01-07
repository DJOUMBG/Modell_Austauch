% cpc_RO440

% RO440
% former HO6
% source: PTCONF-CPC3.xls, Lars Kaden


%% a.id
% Description: Axle ID
% Unit: [-]
% Size: <1x1>
% Range: 2,4,6,7,8,10,11 (based on cpc3_data_load.m)
% Reference:
a.id = 6;

%% a.i
% Description: Axle ratio
% Unit: [-]
% Size: <1x1>
% Range: [0 10] (based on ptconf_p_Axle.AxleRatio_u16)
% Reference:
% a.i = 3.583;
a.i = sMP.ctrl.cpc.par.axle_iDiff;

%% a.hs.c
% Description: Axle halfshaft stiffness
% Unit: [Nm/rad]
% Size: <1x1>
% Range: [0 8320000] (based on ptconf_p_Axle.HlfShftStff_u16)
% Reference:
a.hs.c = 91140;

%% a.ds.c
% Description: Axle driveshaft stiffness
% Unit: [Nm/rad]
% Size: <1x1>
% Range: [0 8320000] (based on ptconf_p_DrvShft.DrvShftStff_u16)
% Reference:
a.ds.c = 300000;


%========== START Dataset: additionalParams ==========

%% a.n
% Description: a.n(1): number of all wheels, a.n(2): number of driven wheels
% Unit: [-]
% Size: <1x2>
% Range: a.n(1): [4 8] (based on ptconf_p_Veh.NumOfAllWheels_u8), a.n(2): [2 8] (based on conf_p_Veh.NumOfDrvWheels_u8)
% Reference:
% a.n = [4 2];
a.n = sMP.ctrl.cpc.par.axle_config;
if a.n(1,2) ~= 2
    error('Chosen axle and vehicle configuration is not suitable!')
end

%% a.eta
% Description: Axle efficiency
% Unit: [-]
% Size: <1x1>
% Range: [0 1] (based on ptconf_p_Axle.AxleFricEff_u8)
% Reference:
% a.eta = 0.974;
% source: 
if a.i < 3.1
    a.eta = 0.974;
elseif a.i < 3.2
    a.eta = 0.970;
elseif a.i < 4.5
    a.eta = 0.965;
else
    a.eta = 0.96;
end

%========== END Dataset: additionalParams ==========

