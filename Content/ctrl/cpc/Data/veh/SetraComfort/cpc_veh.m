EEP.ptconf_p_Veh.VehClass_u8 = 14;
EEP.ptconf_p_Veh.VehType_u8 = 23;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Aerodynamic parameter below can by overwritten by aero datasets      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

EEP.ptconf_p_Veh.VehFrontArea_u16 = round(9.25 / 2^-4);
EEP.ptconf_p_Veh.VehDragCoeff_u8 = round(0.33 / 2^-7);