% cpc_wheel_RRC005

% wheel
% 

%% w.f_R
% Description: Wheel rolling resistance coefficient
% Unit: [-]
% Size: <1x1>
% Range: [0 0.48828125] (based on ptconf_p_Tire.TireRollResCoeff_u8)
w.f_R = 0.005;

%% w.r_d
% Description: Dynamic wheel radius
% Unit: [m]
% Size: <1x1>
% Range: [0 1.983642578125] (based on itpm_p_Conf.DefDynWheelRad_u16)
% Reference:
% w.r_d = 0.492;
w.r_d = sMP.ctrl.cpc.par.wheel_r_d / 1000;
