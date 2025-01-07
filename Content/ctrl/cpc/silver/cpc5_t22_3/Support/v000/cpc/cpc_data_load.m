% function [EEP] = cpc_data_load(EEP, dep)

%% Change Parameter based on vehicle config

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ptconf_a_Eng                                                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cpc_eng % Engine (usually not necessary)
EEP = mcm2cpc(EEP, [], dep); % Get Data from MCM (Engine)

% Consider Euro 7
if EEP.ptconf_a_Eng.CombustionClass_u8 == 53
    EEP.ptconf_a_Eng.CombustionClass_u8 = 52; % Euro 6
    fprintf(1, 'CPC: Euro 7 not supported yet, set Euro 6 instead\n');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ptconf_p_Trans                                                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cpc_tx

EEP.ptconf_p_Trans.TransStff_u16 = zeros(1,27);
EEP.ptconf_p_Trans.TransStff_u16(EEP.ptconf_p_Trans.GearRatio_s16~=0) = round(100000 / 2^7);
% Check of gear ratios
if any(abs(EEP.ptconf_p_Trans.GearRatio_s16) > 25000)
    error('Gear ratios > %.1f not supported by CPC5', 25000 * 2^-10);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ptconf_p_Clutch                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cpc_clt

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ptconf_p_Axle                                                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cpc_axle

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ptconf_p_Ret                                                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cpc_ret

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ptconf_p_Tire                                                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cpc_wheel

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ptconf_p_TransCase                                                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cpc_tfc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ptconf_p_Veh                                                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cpc_veh
cpc_aero

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ag_p_VehConf                                                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cpc_prg


%% Parameter dependencies

% Vehicle Class and Drivetrain Types
VehClass    = EEP.ptconf_p_Veh.VehClass_u8;
VehType     = EEP.ptconf_p_Veh.VehType_u8;
EngType     = EEP.ptconf_a_Eng.EngType_u8;
ClutchType  = EEP.ptconf_p_Clutch.ClutchType_u8;
TransType   = EEP.ptconf_p_Trans.TransType_u8;
RetType     = EEP.ptconf_p_Ret.RetType_u8;

% Identified by clutch and retarder type
isViab = any(ClutchType == (10:11)) && (RetType == 10);

% Engine power rating from MCM
kW_eng = dep.mcm_sys_can_performance_class_1m;

% Axle Configuration
sAxleConf = sprintf('%dx%d', dep.axle_config);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ptconf_p_Veh, ptconf_p_Tire                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TopTorque
if any(EEP.ptconf_a_Eng.TopTrqRedFullLoadEngTrqCurve_u16 == 65535) ... % any paramter is SNA
        || isequal( ... % both curves are equal
        EEP.ptconf_a_Eng.TopTrqRedFullLoadEngTrqCurve_u16, ...
        EEP.ptconf_a_Eng.TrbChFullLoadEngTrqCurve_u16)
    % without TopTorque
    EEP.ptconf_p_Veh.FlcSelPar_u8 = 0;
else
    % with TopTorque
    if VehClass == 31 ... % SFTP Brazil
            || any(TransType == [2,47]) % G281-12K, G291-12K
        % TopTorque extended (Code M0E + M4V)
        % TT gears defined in AG-CAL:
        % - cal_g_AgLowestTopTrqGearDyn_u8
        % - cal_g_AgLowestTopTrqGearPermanent_u8
        EEP.ptconf_p_Veh.FlcSelPar_u8 = 5;
    else
        % TopTorque (Code M0E)
        % TT gear defined in AG-CAL:
        % - cal_g_AgLowestTopTrqGear_u8
        EEP.ptconf_p_Veh.FlcSelPar_u8 = 2;
    end
end

% Number of wheels
% Trailer
switch VehType
    case 4 % Tractor
        switch VehClass
            case 50 % Freightliner Heavy Duty
                nWheel = 4;
            otherwise
                nWheel = 6;
        end
    otherwise
        nWheel = 0;
end
EEP.ptconf_p_Tire.NumOfTrlWheels_u8 = nWheel;
% Front Driven
switch sAxleConf
    case {'4x4', '6x6', '8x6'} 
        nWheel = 2;
    case {'8x8'}
        nWheel = 4;
    otherwise
        nWheel = 0;
end
EEP.ptconf_p_Veh.NumOfFrontDrvWheels_u8 = nWheel;
% All
EEP.ptconf_p_Veh.NumOfAllWheels_u8 = dep.axle_config(1);
% Driven
EEP.ptconf_p_Veh.NumOfDrvWheels_u8 = dep.axle_config(2);

% CustomType for shift parameter
if any(VehClass == (4:17)) % Bus
    if EEP.ptconf_p_Veh.NumOfAllWheels_u8/2 == 2
        EEP.ptconf_p_Veh.CustomType_u8 = 8; % twoaxle_short
    else
        EEP.ptconf_p_Veh.CustomType_u8 = 10; % threeaxle_short
    end
    % No CustomType for Mercedes bus chassis
    if VehClass == 17
        EEP.ptconf_p_Veh.CustomType_u8 = 0;
    end
    % No CustomType for manual 6-gear-transmission
    if strcmp('6D', cpc_cds_def(TransType, 'TransType'))
        EEP.ptconf_p_Veh.CustomType_u8 = 255; % none
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ptconf_p_DrvShft, ptconf_p_AxleFront                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch sAxleConf
    case {'4x4', '6x6', '8x6', '8x8'}
        EEP.ptconf_p_DrvShft.DrvShftStff_u16(1) = EEP.ptconf_p_DrvShft.DrvShftStff_u16(2);
        EEP.ptconf_p_AxleFront.AxleType_u8      = EEP.ptconf_p_AxleRear.AxleType_u8;
        EEP.ptconf_p_AxleFront.AxleRatio_u16    = EEP.ptconf_p_AxleRear.AxleRatio_u16;
        EEP.ptconf_p_AxleFront.AxleFricEff_u8   = EEP.ptconf_p_AxleRear.AxleFricEff_u8;
        EEP.ptconf_p_AxleFront.HlfShftStff_u16  = EEP.ptconf_p_AxleRear.HlfShftStff_u16;
    otherwise
        EEP.ptconf_p_DrvShft.DrvShftStff_u16(1) = 0;
        EEP.ptconf_p_AxleFront.AxleType_u8      = 0;
        EEP.ptconf_p_AxleFront.AxleRatio_u16    = 0;
        EEP.ptconf_p_AxleFront.AxleFricEff_u8   = 0;
        EEP.ptconf_p_AxleFront.HlfShftStff_u16  = 0;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% etp_p_EbmEngConf                                                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OM936
if EngType == 3
	EEP.etp_p_EbmEngConf.EngBrkStagePrio_u8 = 255;
else
    % by default, priority on stage 1
	EEP.etp_p_EbmEngConf.EngBrkStagePrio_u8 = 1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% etp_p_EbmConf                                                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch EngType
    case {20, 21, 2, 3} % OM924, OM926, OM934, OM936
        EEP.etp_p_EbmConf.LeverPosToBrkStage_u8=[0 3 3 3 3 3];
        EEP.etp_p_EbmConf.TorqueByLeverPos1_u16 = (EEP.ptconf_a_EngBrk.EngBrkStp1MaxBrkTrqs_u16(1:8) + EEP.ptconf_a_EngBrk.EngBrkStp1MaxBrkTrqs_u16(1:8))/2;
        EEP.etp_p_EbmConf.TorqueByLeverPos1_u16 = round(EEP.etp_p_EbmConf.TorqueByLeverPos1_u16);
        EEP.etp_p_EbmConf.TorqueByLeverPos3_u16 = EEP.ptconf_a_EngBrk.EngBrkStp3MinBrkTrqs_u16(1:8);
        EEP.etp_p_EbmConf.TorqueByLeverPos2_u16 = round((EEP.etp_p_EbmConf.TorqueByLeverPos1_u16 + EEP.etp_p_EbmConf.TorqueByLeverPos1_u16)/2);
        EEP.etp_p_EbmConf.TorqueByLeverPos4_u16 = EEP.etp_p_EbmConf.TorqueByLeverPos3_u16;
        EEP.etp_p_EbmConf.TorqueByLeverPos5_u16 = EEP.etp_p_EbmConf.TorqueByLeverPos3_u16;
    case 4 % OM470
        EEP.etp_p_EbmConf.LeverPosToBrkStage_u8=[0 1 3 3 3 3];
        EEP.etp_p_EbmConf.TorqueByLeverPos1_u16 = (EEP.ptconf_a_EngBrk.EngBrkStp1MaxBrkTrqs_u16(1:8) + EEP.ptconf_a_EngBrk.EngBrkStp1MaxBrkTrqs_u16(1:8))/2;
        EEP.etp_p_EbmConf.TorqueByLeverPos1_u16 = round(EEP.etp_p_EbmConf.TorqueByLeverPos1_u16);
        EEP.etp_p_EbmConf.TorqueByLeverPos3_u16 = EEP.ptconf_a_EngBrk.EngBrkStp3MinBrkTrqs_u16(1:8);
        EEP.etp_p_EbmConf.TorqueByLeverPos2_u16 = round((EEP.etp_p_EbmConf.TorqueByLeverPos1_u16 + EEP.etp_p_EbmConf.TorqueByLeverPos1_u16)/2);
        EEP.etp_p_EbmConf.TorqueByLeverPos4_u16 = EEP.etp_p_EbmConf.TorqueByLeverPos3_u16;
        EEP.etp_p_EbmConf.TorqueByLeverPos5_u16 = EEP.etp_p_EbmConf.TorqueByLeverPos3_u16;
    case {5, 23} % OM471, OM460
        EEP.etp_p_EbmConf.LeverPosToBrkStage_u8=[0 1 3 3 3 3];
        EEP.etp_p_EbmConf.TorqueByLeverPos1_u16 = (EEP.ptconf_a_EngBrk.EngBrkStp1MaxBrkTrqs_u16(1:8) + EEP.ptconf_a_EngBrk.EngBrkStp1MaxBrkTrqs_u16(1:8))/2;
        EEP.etp_p_EbmConf.TorqueByLeverPos1_u16 = round(EEP.etp_p_EbmConf.TorqueByLeverPos1_u16);
        EEP.etp_p_EbmConf.TorqueByLeverPos3_u16 = EEP.ptconf_a_EngBrk.EngBrkStp3MinBrkTrqs_u16(1:8);
        EEP.etp_p_EbmConf.TorqueByLeverPos2_u16 = round((EEP.etp_p_EbmConf.TorqueByLeverPos1_u16 + EEP.etp_p_EbmConf.TorqueByLeverPos1_u16)/2);
        EEP.etp_p_EbmConf.TorqueByLeverPos4_u16 = EEP.etp_p_EbmConf.TorqueByLeverPos3_u16;
        EEP.etp_p_EbmConf.TorqueByLeverPos5_u16 = EEP.etp_p_EbmConf.TorqueByLeverPos3_u16;
    case 15 % OM472
        EEP.etp_p_EbmConf.LeverPosToBrkStage_u8=[0 1 3 3 3 3];
        EEP.etp_p_EbmConf.TorqueByLeverPos1_u16 = (EEP.ptconf_a_EngBrk.EngBrkStp1MaxBrkTrqs_u16(1:8) + EEP.ptconf_a_EngBrk.EngBrkStp1MaxBrkTrqs_u16(1:8))/2;
        EEP.etp_p_EbmConf.TorqueByLeverPos1_u16 = round(EEP.etp_p_EbmConf.TorqueByLeverPos1_u16);
        EEP.etp_p_EbmConf.TorqueByLeverPos3_u16 = EEP.ptconf_a_EngBrk.EngBrkStp3MinBrkTrqs_u16(1:8);
        EEP.etp_p_EbmConf.TorqueByLeverPos2_u16 = round((EEP.etp_p_EbmConf.TorqueByLeverPos1_u16 + EEP.etp_p_EbmConf.TorqueByLeverPos1_u16)/2);
        EEP.etp_p_EbmConf.TorqueByLeverPos4_u16 = EEP.etp_p_EbmConf.TorqueByLeverPos3_u16;
        EEP.etp_p_EbmConf.TorqueByLeverPos5_u16 = EEP.etp_p_EbmConf.TorqueByLeverPos3_u16;
    case 6 % OM473
        EEP.etp_p_EbmConf.LeverPosToBrkStage_u8=[0 1 3 3 3 3];
        EEP.etp_p_EbmConf.TorqueByLeverPos1_u16 = (EEP.ptconf_a_EngBrk.EngBrkStp1MaxBrkTrqs_u16(1:8) + EEP.ptconf_a_EngBrk.EngBrkStp1MaxBrkTrqs_u16(1:8))/2;
        EEP.etp_p_EbmConf.TorqueByLeverPos1_u16 = round(EEP.etp_p_EbmConf.TorqueByLeverPos1_u16);
        EEP.etp_p_EbmConf.TorqueByLeverPos3_u16 = EEP.ptconf_a_EngBrk.EngBrkStp3MinBrkTrqs_u16(1:8);
        EEP.etp_p_EbmConf.TorqueByLeverPos2_u16 = round((EEP.etp_p_EbmConf.TorqueByLeverPos1_u16 + EEP.etp_p_EbmConf.TorqueByLeverPos1_u16)/2);
        EEP.etp_p_EbmConf.TorqueByLeverPos4_u16 = EEP.etp_p_EbmConf.TorqueByLeverPos3_u16;
        EEP.etp_p_EbmConf.TorqueByLeverPos5_u16 = EEP.etp_p_EbmConf.TorqueByLeverPos3_u16;
    otherwise
        warning('Engine %d not supported'); %#ok<WNTAG>
end

% VIAB
if isViab
    EEP.etp_p_EbmConf.LeverTrqLimMd_u8 = 3;
else
    EEP.etp_p_EbmConf.LeverTrqLimMd_u8 = 0;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% etp_p_EngSpd                                                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch EngType
    case 2 % OM934
        rpm = 688;
    case 3 % OM936
        rpm = 600;
    case {4, 5, 15, 6} % HDEP (OM470...473), without PTO
        if any(VehClass == (4:17)) % Bus
            rpm = 560;
        else
            rpm = 496;
        end
    otherwise
        rpm = 560;
end
EEP.etp_p_EngSpd.DefaultIdleSpd_u16 = rpm / 0.16;
EEP.etp_p_EngSpd.EcoastIdleSpd_u16 = 65535; % default: 500 rpm

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% lim_p_TrqLimFel                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% default values, if enabled
EEP.lim_p_TrqLimFel.EnFlag_u8 = 0;
EEP.lim_p_TrqLimFel.GearRatio_u16 = [0.5 2 10] / 0.001 + 25000;
EEP.lim_p_TrqLimFel.EngSpd_u8 = 255 * ones(1,7); % [rpm]
EEP.lim_p_TrqLimFel.MaxAccTrq_u8 = 255 * ones(7,3); % [Nm]
EEP.lim_p_TrqLimFel.EnWithCcFlag_u8 = 0;
EEP.lim_p_TrqLimFel.EnWithEcoMdFlag_u8 = 1;
EEP.lim_p_TrqLimFel.EnWithAgFlag_u8 = 1;
EEP.lim_p_TrqLimFel.DeactTrqRamp_u16 = (1 + 5000) / 0.2; % [Nm/10ms]
EEP.lim_p_TrqLimFel.ActTrqRamp_u16 = (2 + 5000) / 0.2; % [Nm/10ms]

EEP.lim_p_TrqLimFel.DisWithIppcFlag_u8 = 2;
% 0 = not active 
% 1 = No FEL if IPPC is active
% 2 = React only on IPPC Request if IPPC is active

% Parameter     FEL by CPC-AG (IPPC off)    FEL by CPC-AG (IPPC on)     FEL by IPPC
% 0             1                           1                           1
% 1             1                           0                           0
% 2             1                           0                           1

switch EngType
    case 5 % OM471 (Brazil)
        % usually only for 390 kW, but only effective if EnFlag_u8=1
        EEP.lim_p_TrqLimFel.DeactTrqRamp_u16 = (1 + 5000) / 0.2;
        EEP.lim_p_TrqLimFel.ActTrqRamp_u16 = (2 + 5000) / 0.2;
        EEP.lim_p_TrqLimFel.EngSpd_u8 = [1296 1376 1456 1552 1648 1904 2000] / 16;
        EEP.lim_p_TrqLimFel.MaxAccTrq_u8 = [
            130 130 130 130 130 130 130
            130 130 118 103  92  89  80
            130 130 130 130 130 130 130
            ]'; % *20 --> Nm
    case 23 % OM460 (Brazil)
        EEP.lim_p_TrqLimFel.DeactTrqRamp_u16 = (2 + 5000) / 0.2;
        EEP.lim_p_TrqLimFel.ActTrqRamp_u16 = (1 + 5000) / 0.2;
        EEP.lim_p_TrqLimFel.EngSpd_u8 = [896 1296 1376 1456 1552 1648 1904] / 16;
        switch kW_eng
            case 375
                EEP.lim_p_TrqLimFel.MaxAccTrq_u8 = [
                    120 120 120 120 120 120 120
                    120 120 120 95  87  84  75
                    120 120 120 120 120 120 120
                    ]'; % *20 --> Nm
            case 350
                EEP.lim_p_TrqLimFel.MaxAccTrq_u8 = [
                    115 115 115 115 115 115 115
                    115 115 115 90  88  82  70
                    115 115 115 115 115 115 115
                    ]'; % *20 --> Nm
            case 330
                EEP.lim_p_TrqLimFel.MaxAccTrq_u8 = [
                    110 110 110 110 110 110 110
                    110 110 110 90  83  77  65
                    110 110 110 110 110 110 110
                    ]'; % *20 --> Nm
        end
end

% Enable Fuel Efficiency Limitation (FEL)
switch TransType
    case {47, 48} % G291-12, G340-12
        switch EngType
            case 5 % OM471 (Brazil)
                switch kW_eng
                    case 390
                        EEP.lim_p_TrqLimFel.EnFlag_u8 = 1;
                end
            case 23 % OM460 (Brazil)
                switch kW_eng
                    case {330, 350, 375}
                        EEP.lim_p_TrqLimFel.EnFlag_u8 = 1;
                end
        end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% lim_p_TrqLim, lim_p_TrqLimTransIn                                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% OM473 460 kW in Verbindung mit G280 und K7
if kW_eng == 460 && ...
        EngType == 6 && ... % OM473
        TransType == 4 && ... % G280
        ClutchType == 207 % K7
    EEP.lim_p_TrqLimDsd.En_u8 = 1;
    EEP.lim_p_TrqLimDsd.GearRatio_u16 = [25500 26100 35500];
    EEP.lim_p_TrqLimDsd.Speed_u8 = [31 44 56 69 81 94 106];
    EEP.lim_p_TrqLimDsd.MaxAccTrq_u8 = [ ...
        150 150 150 150 150 150 150
        140 140 140 140 140 140 140
        130 130 130 130 130 130 130 ...
    ]';
% OM473 460 kW in Verbindung mit G280 und VIAB
elseif isViab && (kW_eng == 460) && ...
        EngType == 6 &&  ... % OM473
        TransType == 4 % G280
    EEP.lim_p_TrqLimDsd.En_u8 = 1;
    EEP.lim_p_TrqLimDsd.GearRatio_u16 = [25500 26100 35500];
    EEP.lim_p_TrqLimDsd.Speed_u8 = [31 44 56 69 81 94 106];
    EEP.lim_p_TrqLimDsd.MaxAccTrq_u8 = [ ...
        150 150 150 150 150 150 150
        150 150 150 150 150 150 150
        130 130 130 130 130 130 130 ...
    ]';
else
    EEP.lim_p_TrqLimDsd.En_u8 = 0;
    EEP.lim_p_TrqLimDsd.GearRatio_u16 = 65535 * ones(1,3);
    EEP.lim_p_TrqLimDsd.Speed_u8 = 255 * ones(1,7);
    EEP.lim_p_TrqLimDsd.MaxAccTrq_u8 = 255 * ones(7,3);
end

% VIAB
if isViab
    EEP.lim_p_TrqLimTransIn.MinTrqMergeEn_u8 = 1;
    EEP.lim_p_TrqLimTransIn.BrkTrqLimEn_u8 = 1;
    EEP.lim_p_TrqLimTransIn.BrkTrqLimSpds_u16 = [3100 6250 7500 8750 10000 11250 12500 13750 15000 16250];
    EEP.lim_p_TrqLimTransIn.BrkTrqLimMaxTrqs_u8 = [ ...
        250 200 150 100 100 100 100 100 100 100
        250 200 150 100 100 100 100 100 100 100
        250 200 150 100 100 100 100 100 100 100
        250 200 150 100 100 100 100 100 100 100
        250 200 150 100 100 100 100 100 100 100
        250 200 150 100 100 100 100 100 100 100
        250 200 155 110 110 110 110 110 110 110
        250 200 155 110 110 110 110 110 110 110
        255 255 255 255 255 255 255 255 255 255
        250 172 141 110 110 110 110 110 110 110
        250 172 141 110 110 110 110 110 110 110
        250 166 133 100 100 100 100 100 100 100
        250 166 133 100 100 100 100 100 100 100
        250 143 100 100 100 100 100 100 100 100
        250 143 100 100 100 100 100 100 100 100
        250 143 100 100 100 100 100 100 100 100
        250 143 100 100 100 100 100 100 100 100
        250 143 100 100 100 100 100 100 100 100
        250 143 100 100 100 100 100 100 100 100
        250 143 100 100 100 100 100 100 100 100
        250 143 100 100 100 100 100 100 100 100
        250 143 100 100 100 100 100 100 100 100
        250 143 100 100 100 100 100 100 100 100
        250 100 100 100 100 100 100 100 100 100
        250 100 100 100 100 100 100 100 100 100
    ]';
else
    EEP.lim_p_TrqLimTransIn.MinTrqMergeEn_u8 = 0;
    EEP.lim_p_TrqLimTransIn.BrkTrqLimEn_u8 = 0;
    EEP.lim_p_TrqLimTransIn.BrkTrqLimSpds_u16 = 65535 * ones(1,10);
    EEP.lim_p_TrqLimTransIn.BrkTrqLimMaxTrqs_u8 = 255 * ones(10,25);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cc_a_Cal, cc_p_VehConf                                                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Cruise control deactivation speed threshold (relative to min. activation speed)
if any(EEP.ag_p_VehConf.SftPrgAv_u8(1) == (8:10)) % VIAB
    EEP.cc_p_VehConf.SwitchOffVehSpdThresh_u8 = 10 * 2;
else
    EEP.cc_p_VehConf.SwitchOffVehSpdThresh_u8 = 5 * 2;
end

if any(VehClass == (50:51)) % Freightliner
    EEP.cc_p_VehConf.NormHyst_u16 = 1400;          % 7 km/h
    EEP.cc_p_VehConf.MinHyst_u16 = 800;            % 4 km/h
    EEP.cc_p_VehConf.MinHystHigh_u16 = 400;        % 2 km/h
    EEP.cc_p_VehConf.MaxHyst_u16 = 3000;           % 15 km/h
    EEP.cc_p_VehConf.NormLoHyst_u16 = 800;         % 4 km/h
    EEP.cc_p_VehConf.MinLoHyst_u16 = 0;            % 0 km/h
    EEP.cc_p_VehConf.MaxLoHyst_u16 = 2000;         % 10 km/h
    EEP.cc_p_VehConf.HystVar_u8 = 2;               % CC Band Switch
    EEP.cc_p_VehConf.BrkPdlCCOff_u8 = 1;           % always deactivate CC at Brake Pedal
    EEP.cc_p_VehConf.CCSwitchVar_u8 = 1;           % Resume / Plus; Set / Minus
    EEP.cc_p_VehConf.InhbtEcoRollConcept_u8 = 1;   % NAFTA
    EEP.cc_p_VehConf.SetSpeedMd_u8 = 1;            % NAFTA
    EEP.cc_p_VehConf.CCEcoMaxVehSpd_u16 = 140 * 200; % no limit for Maximum Cruise Control Vehicle Speed in ECO Mode
    EEP.cc_p_VehConf.CCEcoPMaxVehSpd_u16 = 140 * 200; % no limit for Maximum Cruise Control Vehicle Speed in ECO+ Mode
else
    EEP.cc_p_VehConf.NormHyst_u16 = 800;           % 4 km/h
    EEP.cc_p_VehConf.MinHyst_u16 = 300;            % 1.5 km/h
    EEP.cc_p_VehConf.MinHystHigh_u16 = 300;        % 1.5 km/h
    EEP.cc_p_VehConf.MaxHyst_u16 = 3000;           % 15 km/h
    EEP.cc_p_VehConf.NormLoHyst_u16 = 800;         % 4 km/h
    EEP.cc_p_VehConf.MinLoHyst_u16 = 0;            % 0 km/h
    EEP.cc_p_VehConf.MaxLoHyst_u16 = 2000;         % 10 km/h
    EEP.cc_p_VehConf.HystVar_u8 = 4;               % PP2018 HMI
    EEP.cc_p_VehConf.BrkPdlCCOff_u8 = 0;           % not always deactivate CC at Brake Pedal
    EEP.cc_p_VehConf.CCSwitchVar_u8 = 0;           % Set / Plus; Resume / Minus
    EEP.cc_p_VehConf.InhbtEcoRollConcept_u8 = 0;   % SFTP
    EEP.cc_p_VehConf.SetSpeedMd_u8 = 0;            % SFTP
    EEP.cc_p_VehConf.CCEcoMaxVehSpd_u16 = 85 * 200; % Maximum Cruise Control Vehicle Speed in ECO Mode
    EEP.cc_p_VehConf.CCEcoPMaxVehSpd_u16 = 82 * 200; % Maximum Cruise Control Vehicle Speed in ECO+ Mode
end
if VehClass == 31 % Brazil
    EEP.cc_p_VehConf.CCEcoMaxVehSpd_u16 = 110 * 200;
end

% Smart Cruise Control = Cruise Control Limitation (CCL)
if VehClass == 31 % Brazil
    switch sAxleConf
        case '6x4'
            CclTrqLim = [100 95.2 88 65.2 20.0 10.0 5.2] / 0.4; % [%]
        case '6x2'
            CclTrqLim = [100 95.2 88 70.0 25.2 15.2 5.2] / 0.4; % [%]
        case '4x2'
            CclTrqLim = [100 95.2 88 70.0 30.0 20.0 5.2] / 0.4; % [%]
        otherwise
            CclTrqLim = [100 95.2 88 70.0 30.0 20.0 5.2] / 0.4; % [%]
    end
    EEP.cc_p_VehConf.CclTrqLim_u8 = CclTrqLim;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ag_p_VehConf                                                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

EEP.ag_p_VehConf.MaxKickDownGearPos_s8 = EEP.ptconf_p_Trans.ForwGearNum_u8 - 1;
if EEP.ptconf_p_Trans.ForwGearNum_u8 == 12 && any(EEP.ag_p_VehConf.SftPrgAv_u8(1) == [1 3 7]) % ECONOMY, FLEET, ECOPLUS
    EEP.ag_p_VehConf.MaxKickDownGearPos_s8 = 12;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ap_p_TrqConf                                                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch EngType % as comment: max known torque so far
    case 2 % OM934
        Nm = 1041.6; % 900
    case 3 % OM936
        Nm = 1553.6; % 1400
    case 4 % OM470
        Nm = 2372.8; % 2200
    case 5 % OM471
        Nm = 2782.4; % 2600
    case 6 % OM473
        Nm = 3192; % 3000
    case 23 % OM460
        Nm = 2577.6; % 2400
    otherwise % 5:OM472, 20:OM924, 21:OM926
        % Take max torque from par file
        Nm = EEP.ap_p_TrqConf.MaxApTrq_u16 * 0.2 - 5000;
end
% Max full load torque
Nm_Eng_max = max(EEP.ptconf_a_Eng.TrbChFullLoadEngTrqCurve_u16 * 0.2 - 5000);
% Check, if max full load torque higher than max Accelerator Pedal torque
if Nm_Eng_max > Nm
    % Round up to the next 102.4 and increase by 102.4 Nm (resolution of pmc2 parameter) 
    pmc2_raw = ceil((Nm_Eng_max + 5000) / 102.4) + 1;
    pmc2_phys = pmc2_raw * 102.4 - 5000;
    Nm = pmc2_phys;
    fprintf('%s: max. AccPdl torque increased to %.1f Nm\n', mfilename, Nm)
end
% Set parameter
EEP.ap_p_TrqConf.MaxApTrq_u16           = (Nm + 5000) / 0.2;
EEP.pmc2_p_VehConf.ApMaxTrq_u8          = (Nm + 5000) / 102.4;
EEP.pmc2_p_VehConf.SicEngRefTrq_u8      = (Nm + 5000) / 102.4;
EEP.pmc2_p_VehConf.CplApMaxTrq_u8       = 255 - EEP.pmc2_p_VehConf.ApMaxTrq_u8;
EEP.pmc2_p_VehConf.CplSicEngRefTrq_u8   = 255 - EEP.pmc2_p_VehConf.SicEngRefTrq_u8;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% itpm_a_Cal                                                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

EEP.itpm_a_Cal.DefVehMass_u16 = round(dep.veh_m_kg / 4);
EEP.itpm_a_Cal.DefDynWheelRad_u16 = round(dep.wheel_r_d / 1000 / 2^(-15));