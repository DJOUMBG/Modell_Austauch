% cpc_RO440

% RO440
% former HO6
% source: VariantCoding_PTConf_WT18.xls, Lars Kaden


% Front
EEP.ptconf_p_AxleFront.AxleType_u8 = 0;
EEP.ptconf_p_AxleFront.AxleRatio_u16 = 0;
EEP.ptconf_p_AxleFront.AxleFricEff_u8 = 0;
EEP.ptconf_p_AxleFront.HlfShftStff_u16 = 0;

% Efficiency
i = dep.axle_iDiff;
if i < 3.1
    eta = 0.974;
elseif i < 3.2
    eta = 0.970;
elseif i < 4.5
    eta = 0.965;
else
    eta = 0.96;
end

% Rear
EEP.ptconf_p_AxleRear.AxleType_u8 = 6;
EEP.ptconf_p_AxleRear.AxleRatio_u16 = round(i / 2^-11);
EEP.ptconf_p_AxleRear.AxleRatio1_u16 = round(i / 2^-11);
EEP.ptconf_p_AxleRear.AxleRatio2_u16 = 1 / 2^(-11);
EEP.ptconf_p_AxleRear.AxleFricEff_u8 = round(eta / 2^-7);
EEP.ptconf_p_AxleRear.HlfShftStff_u16 = round(91140 / 2^7);
