% cpc_noTfc

% no transfer case

% Transfer case ID
% Range: 0, 100, 1400, 2800, 3000 (based on cpc3_data_load.m)
x.id = 0;

% Transfer case efficiencies
% Range: [0 1] (based on ptconf_p_TransCase.TransCaseFricGearEff_u8)
% [neutral, 1st gear, 2nd gear]
x.eta = [0 1 0];

% Transfer case ratios
% Range: [0 10] (based on ptconf_p_TransCase.TransCaseGearRatio_u16)
% [neutral, 1st gear, 2nd gear]
x.i = [0 1 0];

% Transfer case differential constant
% Range: [0 1] (based on ptconf_p_TransCase.TransCasePlanRatio_u16)
x.N = 0;

% Number of transfer case gears 
% Range: [1 4] (based on ptconf_p_TransCase.TransCaseGearNum_u8)
x.n = 1;


%% Transfer Case states
% State of transfer case
% 0 = AllWheelDrive Front&Rear Axle locked
% 1 = AllWheelDrive Front&Rear Axle not locked
% 2 = FrontAxleDriven
% 3 = RearAxleDriven
x.z = 3;

% Current transfer case gear 
% 0 = Neutral
% 1 = OnRoad 
% 2 = OffRoad
if sMP.ctrl.cpc.par.tfc_stTrfGrBoxHi == 3 % 0=HIGH/onroad; 1=LOW/offroad; 3=none
    x.n0 = 1;
else
    error('Please check transfer case parameters! MEC with tfc and CPC without tfc!')
end