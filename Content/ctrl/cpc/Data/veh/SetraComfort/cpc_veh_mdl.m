% cpc_BusCoach_std

% Setra ComfortClass
% source: 
% - Stefan Walter (Evobus)
% - Simulation_EcoSail_S515GTHD.par

%% v.class
% Description: Vehicle class
% Unit: [-]
% Size: <1x1>
% Range: [0 250] (based on ptconf_p_Veh.VehClass_u8)
% Reference:
% 4 = Mercedes Citaro
% 5 = Mercedes CapaCity
% 6 = Setra Low Floor
% 7 = Mercedes Bus Low Entry
% 8 = Mercedes Conecto
% 9 = Mercedes Intouro
% 10 = Mercedes Integro
% 11 = Mercedes Travego
% 12 = Mercedes Tourismo
% 13 = Setra MultiClass
% 14 = Setra ComfortClass
% 15 = Setra TopClass
% 16 = Setra double-deck
% 17 = Mercedes bus chassis
% always 15 for Bus, because cpc3_data_load.m recognize Bus only with ID 15
% (needed for example for selecting AG - Calibration DataSet(CDS) for Bus)
v.class = 15;

%% v.type
% Description: Vehicle type
% Unit: [-]
% Size: <1x1>
% Range: [0 250] (based on ptconf_p_Veh.VehType_u8)
% Reference:
% mdl.v.type = 4;

%  1: Rigid truck 
%  2: Tipper 
%  3: Concrete mixer 
%  4: Tractor 
%  5: Municipal utility vehicle 
%  6: Fire engine 
%  7: multi purpose vehicle 
% 21: city bus 
% 22: intercity bus 
% 23: coach 
% 24: bus chassis
v.type = 23;

%% v.m
% Description: Vehicle mass
% Unit: [kg]
% Size: <1x1>
% Range: [0 260000] (based on itpm_p_Conf.DefVehMass_u16)
% Reference:
% v.m = 40000;
v.m = sMP.ctrl.cpc.par.veh_m_kg;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Aerodynamic parameter below can by overwritten by aero datasets      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% v.A
% Description: Vehicle frontal area
% Unit: [m²]
% Size: <1x1>
% Range: [1 15] (based on ptconf_p_Veh.VehFrontArea_u16)
% Reference:
v.A = 9.25;

%% v.c_W
% Description: Vehicle drag coefficient
% Unit: [-]
% Size: <1x1>
% Range: [0.25 1.25] (based on ptconf_p_Veh.VehDragCoeff_u8)
% Reference:
v.c_W = 0.33;

%% cd*A offset (negative: ..., positive: ... )
v.cdA_offset_sta= [0 1 2 3]; % Blind position [-]
v.cdA_offset_m2 = [0 0 0 0]; % cd*A offset [m²]