% cpc_retVoithDIWA

% source: PTCONF-CPC3.xls Elisha Lauer
% Voith DIWA integrated Retarder
% 

%% r.id
% Description: Retarder ID
% Unit: [-]
% Size: <1x1>
% Range: 0, 2, 21, 221, 222 (based on cpc3_data_load.m)
% Reference:
% based on cpc3_data_load.m: 0 no retarder, 2 Voith SWR 21, ZF EcoLife 221, Voith DIWA 222
r.id = 222;

%% r.J
% Description: Retarder inertia torque
% Unit: [kgm²]
% Size: <1x1>
% Range: [0 1] (based on ptconf_p_Ret.SecRetInertiaTrq_u16)
% Reference:
% r.J = 0.017;
% source: PTCONF
r.J = 0;


%========== START Dataset: addMaps ==========

%% r.map.omega
% Description: Breakpoint vector of retarder velocity values
% Unit: [rad/s]
% Size: <51x1>
% Range:
% Reference: UDS interface CPC - RCM

if isempty(sMP.ctrl.cpc.par.rcm_x_ret_GW_rpm)
    error('No characteristic curve for Retarder defined, but needed in CPC');
end
tmpRetGW = sMP.ctrl.cpc.par.rcm_x_ret_GW_rpm*(2*pi/60);
r.map.omega = (min(tmpRetGW):(max(tmpRetGW)-min(tmpRetGW))/50:max(tmpRetGW))';
r.map.n = r.map.omega * 30/pi; % necessary for global parameter for PPC
clear tmpRetGW;


%% r.map.M_VL
% Description: Vector of retarder full-load torque values
% Unit: [Nm]
% Size: <51x1>
% Range: [0 5000] (based on r.map.M_max)
% Reference: r.map.omega
% Reference: UDS interface CPC - RCM

r.map.M_VL = interp1(sMP.ctrl.cpc.par.rcm_x_ret_GW_rpm*(2*pi/60), sMP.ctrl.cpc.par.rcm_y_ret_M_max, r.map.omega, 'linear', 'extrap');

%% r.map.M_max
% Description: Retarder max. torque
% Unit: [Nm]
% Size: <1x1>
% Range: [0 5000] (based on etp_p_EbmRetConf.AbsRetMaxTrq_u8)
% Reference: 
r.map.M_max = max(r.map.M_VL);

%========== END Dataset: addMaps ==========

