% Use ratio of gear 2 to 7 from dependent local parameter
EEP.ptconf_p_Trans.TransType_u8 = 20;
EEP.ptconf_p_Trans.GearRatio_s16 = round([0	0	0	0	0	0	0	-2.98 0 1.36 dep.tx_iTxAllFw(2:7)	0	0	0	0	0	0	0	0	0	0	0] / 2^-10);
EEP.ptconf_p_Trans.GearFricEff_u8 = round([0	0	0	0	0	0	0	0.98 0 0.98 0.98 0.98 1.0 0.98 0.98	0.98	0	0	0	0	0	0	0	0	0	0	0] / 2^-7);
EEP.ptconf_p_Trans.TransInertiaTrq_u16 = round([0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0] / 2^-12);
EEP.ptconf_p_Trans.ForwGearNum_u8 = 7;
EEP.ptconf_p_Trans.RevGearNum_u8 = 1;
