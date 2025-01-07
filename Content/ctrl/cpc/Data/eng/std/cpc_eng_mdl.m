% Engine Type
e.id = sMP.ctrl.cpc.par.mcm_sys_motor_type_1m;

% Nominal engine power [W]
e.P_nom = sMP.ctrl.cpc.par.mcm_sys_can_performance_class_1m * 1000;

% Engine idle speed
e.omega_idle = sMP.ctrl.cpc.par.mcm_idleSpeed_rpm * pi/30;

% Description: construction level (1 = FE1, 2 = TCO or HDES2020 or PAR42Q)
e.cl = 0;

%% Dummy values to satisfy script cpc3_data_load.m
% It will be overwritten by function mcm2cpc.m anyway

% Exhaust emission standard
e.ees = [];

% Breakpoint vector of engine map velocity values
e.map.omega = [0 1000]/60*2*pi; % [rad/s]

% Vector of engine map full-load torque values
e.map.M_VL = [8000 8000]; % must be high, until mcm2cpc.m get also UnChFullLoadEngTrqCurve_u16 from mcm. Otherwise cpc3_data_loa.m will reduce UnChFullLoadEngTrqCurve_u16 to max M_VL
e.map.M_VL(2, :) = [0 0]; % [Nm]

% Vector of engine map drag torque values
e.map.M_S = [0 0]; % [Nm]

% Vector of engine brake torque values (min & max / level 1,2,3)
e.map.M_B1 = [0 0; 0 0]; % [Nm]
e.map.M_B2 = [0 0; 0 0]; % [Nm]
e.map.M_B3 = [0 0; 0 0]; % [Nm]

% Breakpoint vector of engine map torque values
e.map.M = [0 1]; % [Nm]

% Matrix of engine specific fuel consumption
e.map.b_e = [0 0; 0 0]; % [kg/Ws]

% Engine inertia torque
e.J = []; % [kgm²]

% Engine derate speed [begin; end]
e.omega_derate = [0; 0];  % [rad/s]

% Maximum engine brake speed
e.omega_brk_max = []; % [rad/s]

% Engine brake off speed
e.omega_brk_off = []; % [rad/s]

% Engine brake on speed
e.omega_brk_on = []; % [rad/s]

% Nominal engine speed
% only for NAFTA important, to see, if engine torque is CaptiveR ating 1625 cpc3_data_load
e.n_nom = []; % [rpm]

% Maximum engine speed
e.omega_limit = []; % [rad/s]
