% cpc_noClutch

% 151026 - lauerel
% source: PTCONF-CPC.xls Elisha Lauer
% Keine Kupplung (Dummy) für Wandler-Automatgetriebe
% 
% 151123 - wenschw: Changed ParameterSet Name from cpc_cltDummy to cpc_noClutch

%% t.c.id
% Description: Clutch ID
% Unit: [-]
% Size: <1x1>
% Range: 0, 202, 203, 204, 207, 210 (based on cpc3_data_load.m)
% Reference:
t.c.id = 0;

%% t.c.J_p
% Description: Inertia torque of primary side of clutch
% Unit: [kgm²]
% Size: <1x1>
% Range: [0 10] (based on ptconf_p_Clutch.ClutchInertiaTrqPri_u16)
% Reference:
t.c.J_p = 0;

%% t.c.J_s
% Description: Inertia torque of secondary side of clutch
% Unit: [kgm²]
% Size: <1x1>
% Range: [0 10] (based on ptconf_p_Clutch.ClutchInertiaTrqSec_u16)
% Reference:
t.c.J_s = 0;

%% t.c.c
% Description: Clutch stiffness
% Unit: [Nm/rad]
% Size: <1x1>
% Range: [1280 8320000] (based on ptconf_p_Clutch.ClutchStff_u16)
% Reference:
t.c.c = 30000;
