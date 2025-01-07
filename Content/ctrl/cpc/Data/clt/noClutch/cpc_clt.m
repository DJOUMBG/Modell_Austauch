% cpc_noClutch

EEP.ptconf_p_Clutch.ClutchType_u8 = 0;
EEP.ptconf_p_Clutch.ClutchInertiaTrqPri_u16 = round(0 / 2^-12);
EEP.ptconf_p_Clutch.ClutchInertiaTrqSec_u16 = round(0 / 2^-12);

% Clutch stiffness
EEP.ptconf_p_Clutch.ClutchStff_u16 = round(30000 / 2^7);