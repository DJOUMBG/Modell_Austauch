% function [EEP, sPar, sCDS] = cpc_data_load(EEP, dep)

%% Read Base configuration

% Get Vehicle Class and Type
cpc_veh
% Select main par file dependent on Vehicle Class and Type

% ##### Vehicle Class #####
% 1 = SFTP vehicle class 963 (heavy duty on road vehicle)
% 2 = SFTP vehicle class 964 (heavy duty off road vehicle)
% 3 = Atego 3 (vehicle class 967)
% 4 = Mercedes Citaro
% 5 = Mercedes CapaCity
% 6 = Setra Low Floor
% 7 = Mercedes Bus Low Entry
% 8 = Mercedes Conecto
% 9 = Mercedes Intouro
% 10 = Mercedes Integro
% 11 = Mercedes Travego
% 12 = Mercedes Tourismo
% 13 = Setra MultiClass
% 14 = Setra ComfortClass
% 15 = Setra TopClass
% 16 = Setra double-deck
% 17 = Mercedes bus chassis
% 20 = U4000
% 21 = U5000
% 22 = U300
% 23 = U400
% 24 = U500
% 25 = Econic Diesel
% 26 = Econic NGT
% 27 = Zetros
% 28 = Special Chassis
% 30 = AUB / HDT
% 31 = SFTP Brazil
% 50 = Freightliner Heavy Duty
% 51 = Freightliner Medium Duty
% 60 = SFTP FUSO on road vehicle
% 61 = SFTP FUSO off road vehicle
% 62 = EvoBus FUSO FNC (Fuso New Coach)
VehClass = EEP.ptconf_p_Veh.VehClass_u8;

% ##### Vehicle Type #####
% 1 = Rigid truck
% 2 = Tipper
% 3 = Concrete mixer
% 4 = Tractor
% 5 = Municipal utility vehicle
% 6 = Fire engine
% 7 = multi purpose vehicle
% 21 = city bus
% 22 = intercity bus
% 23 = coach
% 24 = bus chassis
% 100 = eActros
% 101 = eP4 6x4
% 102 = eP4 4x2
% 103 = eM2 4x2
% 104 = eEconic
VehType = EEP.ptconf_p_Veh.VehType_u8;

% Axle Configuration
sAxleConf = sprintf('%dx%d', dep.axle_config);

% Engine ID
EngID = dep.mcm_sys_motor_type_1m;

sPar = ''; % name of main par file
sCDS = ''; % name of CDS file
switch VehClass
    
    case 1 % SFTP 963 = Actros
        switch VehType
            case 1 % Rigid truck, for example Actros 2540 L
                sPar = '963W1529_2010013A_200110_GTTT'; % C963.020, 3-Achs Wechselbruekenfahrzeug 6x2 Fernverkehr 
            case 4 % Tractor, for example Actros 1845 LS
                sPar = '963W1528_2010013A_200110_GTTT'; % C963.403, 2-Achs Sattelzugmaschine 4x2 Fernverkehr
            otherwise % Rigid truck
                sPar = '963W1529_2010013A_200110_GTTT';
        end

    case 2 % SFTP 964 = Arocs
        switch VehType
            case 2 % Tipper
                sPar = '964V450_2010014A_200114_GTTT'; % C964.231, 4-Achs Kipper 8x4 
            case 3 % Concrete mixed
                sPar = '964V334_2010013A_200110_GTTT'; % C964.218, 3-Achs Betonmischer 6x6
                disp('it seems to be a tipper, not a mixer')
            case 4 % Tractor
                sPar = '964V488_2010034A_200625_GTTT'; % C964.418, 4-Achs SLT Schwerlsatzugmaschine Viab 8x6
            otherwise % Tipper
                fprintf('VehType %d not defined, use Tipper as base\n', VehType);
                sPar = '964V450_2010014A_200114_GTTT';
        end
        
    case 3 % Atego 3 (vehicle class 967)
        sPar = '967V253_2010034A_200614_GTTT'; % C967.025, 2-Achs Atego 4x2 
        
    case {4,5,6,7,8,9,10,11,12,13,14,15,16,17} % Mercedes or Setra Bus
        sPar = 'MD51PE_GO250_OM470FE1_315_2A_EBS4_SWR'; % Stefan Walter (BUS/PPE-DC) 14.06.2021
        
    case 31 % SFTP Brazil
        % sPar = '963V1525_2010013A_200110_GTTT'; % C963.424, 3-Achs Sattelzugmaschine, 6x4 Brasilien
        sPar = '963V1056_2010034A_201201_GLSANTO'; % Tractor, 6x4 
        
    case {50, 51} % Freightliner
        % sPar = 'FRCV536_20100032A_200313_Handmade'; % Olvier Stanko (TP/XMD) 03.09.2020
        sPar = 'CPC5_E95065_12Aug2020'; % Steven Soliz (TP/XNS) 13.08.2020
        
    case {60, 61} % SFTP FUSO
        switch VehType
            case 1 % Rigid truck / Cargo
                switch sAxleConf
                    case '6x2'
                        switch EngID
                            case 936
                                % T1017X FU 6x2R Cargo 6S10 (OM936) + G211-12
                                sPar = 'T1017X_L961V60 FU MDEG WT20 200317_2shift_ 33A';
                                sCDS = 'FUSO_TRUCK_ECO_C1';
                            case 470
                                % T1014X FU 6x2R Cargo 6R20 (OM470FE1) + G211-12
                                sPar = 'T1014X_L961V51 FU WT20 200617_2shift_ 34A';
                                sCDS = 'FUSO_TRUCK_ECO_C2';
                            case 471
                                % T1024X FS 8x4 Cargo 6R20 (base: OM470FE1) + G230-12
                                sPar = 'T1014X_L961V51 FU WT20 200617_2shift_ 34A - OM471'; % temporary
                                sCDS = 'FUSO_TRUCK_ECO_C3';
                        end
                    case '6x4'
                        sCDS = 'FUSO_TRUCK_ECO_C1';
                        switch EngID
                            case 936
                                % T1017X FU 6x2R Cargo 6S10 (OM936) + G211-12
                                sPar = 'T1017X_L961V60 FU MDEG WT20 200317_2shift_ 33A';
                            case 470
                                % T1014X FU 6x2R Cargo 6R20 (OM470FE1) + G211-12
                                sPar = 'T1014X_L961V51 FU WT20 200617_2shift_ 34A';
                        end
                    case '8x4'
                        switch EngID
                            case 936
                                % T1019X FS 8x4 Cargo 6S10 (OM936) + G211-12
                                sPar = 'T1019X L961V64 FS MDEG WT20 200513_ 34A';
                                sCDS = 'FUSO_TRUCK_ECO_C1';
                            case 470
                                % T1024X FS 8x4 Cargo 6R20 (OM470FE1) + G230-12
                                sPar = 'T1024X_L961V126 FS HDEP WT20 200615_2shift_ 34A';
                                sCDS = 'FUSO_TRUCK_ECO_C3';
                            case 471
                                % T1024X FS 8x4 Cargo 6R20 (base: OM470FE1) + G230-12
                                sPar = 'T1024X_L961V126 FS HDEP WT20 210112_2shift_ 34A - OM471'; % temporary
                                sCDS = 'FUSO_TRUCK_ECO_C3';
                        end
                end
            case 2 % Tipper
                sCDS = 'FUSO_TRUCK_OFFROAD';
                switch EngID
                    case 470
                        % T1020X FV-D 6x4 Tipper 6R20 (OM470FE1) + G211-12
                        sPar = 'T1020X L961V89 FV-D HDEP WT20 200618_3shift_ 34A';
                    case 936
                        % T1022X FV-D 6x4 Tipper 6S10 (OM936) + G211-12
                        sPar = 'T1022X_L961V92 FV-D WT20 200615_3shift_ 34A';
                end
            case 4 % Tractor
                fprintf(1, 'CPC - ToDo: Why are NumOfTrlWheels set to 0 in FUSO tractor main par files?\n');
                switch sAxleConf
                    case '4x2'
                        sCDS = 'FUSO_TRUCK_TR_ECO';
                        switch EngID
                            case 936
                                % T1018X FP-R 4x2 Tractor 6S10 (OM936) + G211-12
                                sPar = 'T1018X_L961V62 FP-R MDEG WT20 200513_2shift_ 34A';
                            case 470
                                % T1015X FP-R 4x2 Tractor 6R20 (OM470FE1) + G211-12
                                sPar = 'T1015X_L961V52 FP-R HDEP WT20 200513_34A_2shift';
                            case 471
                                % T1015X FP-R 4x2 Tractor 6R20 (base: OM470FE1) + G211-12
                                sPar = 'T1015X_L961V52 FP-R HDEP WT20 200513_34A_2shift - OM471'; % temporary
                        end
                    case '6x4'
                        switch EngID
                            case 470
                                % T1021X FV-R 6x4 Tractor 6R20 (OM470FE1) + G330-12
                                sPar = 'T1021X_L961V90 FV-R WT20 200618_3shift_ 34A';
                                sCDS = 'FUSO_TRUCK_TR_POWER';
                            case 471
                                % Tractor 6x4 for AUS/NZ market
                                % OM471 EuroVI 375kW/2500Nm + G330-12
                                sPar = 'T989X_L961V123 FV WT20 200520_3shift_ 34A';
                                sCDS = 'FUSO_TRUCK_EXP_HEAVY';
                        end
                end
        end
        
    case 62 % EvoBus FUSO FNC (Fuso New Coach)
        sPar = ''; 
       
    otherwise
        error('Unknown VehClass %d', VehClass)
end


%% Override default selection by user defined parameter files
if exist('sParUser', 'var') && ~isempty(sParUser)
    sPar = sParUser;
end
if exist('sCDSUser', 'var') && ~isempty(sCDSUser)
    sCDS = sCDSUser;
end


%% Load main par file
% Remove .mat or .par extension from sPar (It is used in post processing)
[~, ~, sParExt] = fileparts(sPar);
if strcmp(sParExt, '.mat')
    [~, sPar] = fileparts(sPar);
elseif strcmp(sParExt, '.par')
    [~, sPar] = fileparts(sPar);
end
% Load file
try 
    % mat file
    sFilePar = [sPar '.mat'];
    EEP = load(sFilePar);
catch
    % par file
    sFilePar = [sPar '.par'];
    EEP = read_par_file(sFilePar);
    % Copy to run directory for comparison or interpretation of parameter
    copyfile(which(sFilePar), fullfile(sPathRunDir, sFilePar));
end
EEP_file = EEP; % only for information as backup
