% cd*A offset (negative: ..., positive: ... )
cdA_offset_sta= [0 1 2 3]; % Blind position [-]
cdA_offset_m2 = [0 0 0 0]; % cd*A offset [m²]

% Manual Shift for eActros
bShiftManual = 0;
s_shift_wait = 2;
kmh_upshift = [255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255];
kmh_downshift = [-255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255];

% Cruise Control Function Mode
% See also signal CC_FuncMode_Stat
% 0 None
% 1 Limiter
% 2 Combined CC (with engine retarder)
% 3 Drive CC (without engine retarder)
% 4 Adaptive CC
% 5 Adaptive CC+
CCFunc = 2;

% CruiseControl speed can by changed by PPC without driver intervention
bCCbyPPC = 0;

% Transfer Case / Gearbox (should be overwritten by mec)
tfc_id = 0; % not used yet, info from mec needed
tfc_gear = 3; % 0:HIGH/onroad 1:LOW/offroad 2:NEUTRAL 3:NONE
tfc_trqDistribution = [50 50]; % [0 100] if front axle disengaged

% Drive program Selection
% 0 = Power / G0V or G0K
% 1 = Economy / G0U
% 2 = Heavy Duty / G0Y
% 3 = Fleet / G0Z
% 4 = Offroad / G0W
% 5 = Municipal / G0S
% 6 = Fire / G0X
% 7 = Economy+ / G0U (since CPC5)
% 8 = ViabPower / G0V + G3Y
% 9 = ViabEconomy / G0V/GOW + G3Y
% 10 = ViabOffroad / G0W + G3Y
% 100 = Standard
% 255 = No change, keep as it set by CPC at start
ShiftPrg = 255;