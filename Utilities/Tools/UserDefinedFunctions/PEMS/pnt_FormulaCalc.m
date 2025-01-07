function [sOutputFilename]= pnt_FormulaCalc(sInputFilename)
%pnt_FormulaCalc Takes the processed file from pnt_ResultsAccumulate as
%input and does the additional formula calculation needed for analysis and
%gives the output file path as output argument
%
% Syntax:
%   [sOutputFilename]= pnt_ResultsAccumulate(sInputFilename)
%
%
% Inputs:
%       sInputFilename - String with path of the processed mat file from
%                       pnt_ResultsAccumulate.m
% Outputs:
%       sOutputFilename - string with complete path of the result file
%
% Example:
%   [sOutputFilename]= pnt_FormulaCalc('D:\200110_083506_Atego_detailed_1018L4x2_L967W244_5t8_constCoolant_diffGPS_AJCHAND\B45_Atego_detailed_1018L4x2_L967W244_5t8_constCoolant_diffGPS.mat')
%
% Formulas are taken from Formula_Calc.m file in MBRDI post processing tool and from...
% \\emea.corpdir.net\E019\prj\TG\DIVeModelBased\02UserTD\04Projects\TP-PF...
% RDE-eval\FormulaCalcSignals.m file given by Samuel
%
% Author: Ajesh Chandran, RD I/TBP, MBRDI
%  Phone: +91-80-6149-6368
% MailTo: ajesh.chandran@daimler.com
%   Date: 2020-02-19

%% Defining the variables to be loaded
cRequiredSignals = {'time','MEFFW','NMOTW','TWA','MBONL','MLONL','NOX',...
    'NOXN','MHST','TMCEE','STMCEE','tmc_status','EOMEE','eom_engine_state',...
    'ALPHA','T2SEE','T31','T32','T4','TL','TAB','MHSTHYEE','MHSTCCEE',...
    'T7VEE','T9VEE','T9NEE','can_vehicle_speed','mec_veh_transVel',...
    'mec_veh_transAcc','mec_veh_transPos','mec_veh_massVehicle',...
    'sp_p_turb_out','sp_p_turb_in_bank1','PL','P31','P7VEE',...
    'fis_act_fm_combustion','sEngName','nPowerRating','T7NEE',...
    'MHSTEE','env_altitude_m','ccf_atc_fm_act','nEngMaxTorque','TTAU',...
    'is4_t_doc_in','is4_t_doc_out','is4_t_scr_cat_in','is4_t_scr_cat_out',...
    'CO','CON','CO2','CO2N','O2','O2N','HC','HCN','NH3'}; % Required varibles for NOx calculation
load(sInputFilename,cRequiredSignals{:}); % Loading the required variables for Calculation

%% Formula Evaluation

nSampleTime = time(end)-time(end-1); % Calculating the sample time

% Creating can_veh_speed variable from mec_veh_transVel
if (~exist('can_vehicle_speed'))
    if (exist('mec_veh_transVel'))
        can_vehicle_speed = mec_veh_transVel*(18/5); % Unit conversion from m/s to km/h
        fprintf('mec_veh_transVel signal used as Velocity Signal\n'); % Error Message
    else
        fprintf('mec_veh_transVel Signal absent. Please add the signal to port logging in DBC\n'); % Error Message
        fprintf('Stopping Evaluation\n'); % Error Message
        return
    end
end
% Creating altitude variable for Powerpack with default value 0
if (~exist('env_altitude_m'))
    env_altitude_m = zeros(length(time),1); % Creating a default value of 0 ...
    %for altitude for powerpack simulations
    fprintf('Powerpack simulation: env_altitude_m signal is absent\n'); % Update Message
    fprintf('Default altitude value of 0 m will be plotted instead\n'); % Update Message
end
if (exist('MBONL')&& exist('MLONL'))
    MAKH = MBONL+MLONL; % [kg/h] Exhaust mass flow rate calculated using air intake[kg/h] and fuel mass[kg/h]
else
    fprintf('MBONL and MLONL signal absent cant calculate MAKH\n'); % Error Message
    fprintf('Stopping Evaluation\n'); % Error Message
    return
end

if (exist('MEFFW')&& exist('NMOTW'))
    PEFF = NMOTW.*MEFFW.*(pi/30000); % [kW] Power = 2piNT/60
else
    fprintf('MEFFW & NMOTW signal absent cant calculate PEFF\n'); % Error Message
    fprintf('Stopping Evaluation\n'); % Error Message
    return
end

if ~exist('PL')
    if exist('is4_p_ambient_air')
        PL = is4_p_ambient_air; % MARC to MVA Mapping
    else
        fprintf('PL and is4_p_ambient_air signal absent\n');
        fprintf('Stopping the Evaluation\n');
        return
    end
end

if ~exist('TL')
    if exist('is4_t_ambient_air')
        TL = is4_t_ambient_air; % MARC to MVA Mapping
    else
        fprintf('TL and is4_t_ambient_air signal absent\n');
        fprintf('Stopping the Evaluation\n');
        return
    end
end

if (exist('PL')&& exist('P31'))
    sp_p_turb_in_bank1 = PL+P31; % [mbar] done to convert guage to absolute
else
    fprintf('PL & P31 signal absent cant calculate sp_p_turb_in_bank1\n'); % Error Message
end

if (~exist('sp_p_turb_out')) % Calculation done if signal absent in mcm signal list
    if (exist('PL')&& exist('P7VEE'))
        sp_p_turb_out = PL+P7VEE; % [mbar] done to convert guage to absolute
    else
        fprintf('PL & P7VEE signal absent cant calculate sp_p_turb_out\n'); % Error Message
    end
    
end

if (exist('mec_veh_transPos','var')&& exist('time','var'))% Vehicle simulaiton in DIVe
    Trip_Distance = mec_veh_transPos(end);% Trip distane in m
    Trip_Time = time(end);
elseif (exist('can_vehicle_speed')&& exist('time'))% for measurement data
    dSamplTim = time(end) - time(end-1);
    Trip_Distance_itern = (5/18)*can_vehicle_speed*dSamplTim;
    Trip_Distance_Cum = cumsum(Trip_Distance_itern);
    Trip_Distance = Trip_Distance_Cum(end)*dSamplTim;
    Trip_Time = time(end);
elseif (~exist('can_vehicle_speed')&& exist('time'))% if speed data absent
    Trip_Time = time(end);
    Trip_Distance = [];
    fprintf('Trip Distance cant be calculated \n'); % Error Message
else % None of the required variables present
    Trip_Distance = [];
    Trip_Time = [];
    fprintf('Trip Distance and Trip Time cant be calculated \n'); % Error Message
end
clear Trip_Distance_itern Trip_Distance_Cum dSamplTim
nTestbenchSwitch = 0; % value is 1 for simulation 0 for Test bench. Required for NOX shift correction
nNoxHumidityCorrection = 0; % Value used for NOx humidity correction if 0 no correction
nNOxShift = 4; % Shift required for NOx values in Test bench
nTtauConstant = 12.4; % Used when TTAU signal is absent in the measurement
nAirFuelRatioStoich = 14.56; % Stoichiometric air fuel ratio
if (exist('TTAU'))
    TTAU = mean(TTAU); % Constant value is required for NOx correction factor calculation
else
    TTAU = nTtauConstant; % Feeding contant value
    fprintf('TTAU signal absent using default value of 12.4\n'); % Update Message
end
% Calculation of MNOXH
if (exist('NOX')&& exist('TL'))
    if nTestbenchSwitch
        NOX = [NOX(nNOxShift:end); zeros(nNOxShift-1,1)];
    end
    % Correction calculation given by Samuel
    X0=6.054;
    X1=4.378*10^-1*TTAU;
    X2=1.408*10^-2*TTAU^2;
    X3=2.988*10^-4*TTAU^3;
    X4=3.267*10^-6*TTAU^4;
    XPDT=X0+X1+X2+X3+X4;
    XMLKHT=MLONL.*(PL-XPDT)./(PL-XPDT*(1-6.22*10^-1));
    LAMBONL=XMLKHT./(MBONL*nAirFuelRatioStoich);
    X8=0.044.*MBONL./(MLONL.*(1-XPDT./PL))-0.0038;
    X9=-0.116.*MBONL./(MLONL.*(1-XPDT./PL))+0.0053;
    X7=1./(1+X8.*(7*(622*XPDT./(PL-XPDT))-75)+X9.*1.8.*(TL+273.15-302));
    if nNoxHumidityCorrection
        MNOXH = 0.001587.*NOX.*MAKH.*X7; % Taken from Samuels code
    else
        MNOXH = 0.001587.*NOX.*MAKH; % [g/hr](NOX*MAKH*46)/(28.98*1000)
    end
    MNOX_Cum = zeros(length(MNOXH),1); % Memory allocation
    for nIdx = 1:length(MNOXH)
        if (nIdx==1)
            MNOX_Cum(nIdx) = MNOXH(nIdx)*nSampleTime/3600; % for the first instance
        else
            MNOX_Cum(nIdx) = MNOX_Cum(nIdx-1)+MNOXH(nIdx)*nSampleTime/3600; %[g] Incremental Calculation
        end
        
    end
    MNOX_Total = MNOX_Cum(end); % [g] Total generated NOx in cycle
else
    fprintf('NOx signal absent\n'); % Error Message
    fprintf('Stopping Evaluation\n'); % Error Message
    return
    
end

%Calculation of Work
Work = zeros(length(PEFF),1); % Memory allocation
for nIdx = 1:length(PEFF)
    if (PEFF(nIdx)>0)
        Work(nIdx) = PEFF(nIdx)*nSampleTime/3600; % [kWh] Work = Power * time
    else
        Work(nIdx) = 0; % Work is calculated only when torque is positive
    end
end

%Cumulative work calculation
Work_cum = zeros(length(Work),1); % Memory allocation
for nIdx = 1:length(Work)
    if (nIdx==1)
        Work_cum(nIdx) = Work(nIdx); % for the first instance
    else
        Work_cum(nIdx) = Work_cum(nIdx-1)+Work(nIdx); %[kWh] Incremental Calculation
    end
    
end
Work_Total = Work_cum(end); % [kWh] Total work in the cycle

% Cumulative NOx upon work Calculation MNOXP
MNOXP = MNOX_Cum./Work_cum; % [g/kWh] Vector of cumulative values
MNOXP_Total = MNOX_Cum/Work_Total; % [g/kWh] NOx with respect to total work of the cycle


%% NOXN Calculations
if (exist('NOXN'))
    if nTestbenchSwitch
        NOXN = [NOXN(nNOxShift:end); zeros(nNOxShift-1,1)];
    end
    if nNoxHumidityCorrection
        MNOXHN = 0.001587.*NOXN.*MAKH.*X7; % Taken from Samuels code
    else
        MNOXHN = 0.001587.*NOXN.*MAKH; % [g/hr](NOXN*MAKH*46)/(28.98*1000)
    end
    MNOXN_Cum = zeros(length(MNOXHN),1); % Memory allocation
    for nIdx = 1:length(MNOXHN)
        if (nIdx==1)
            MNOXN_Cum(nIdx) = MNOXHN(nIdx)*nSampleTime/3600; % for the first instance
        else
            MNOXN_Cum(nIdx) = MNOXN_Cum(nIdx-1)+MNOXHN(nIdx)*nSampleTime/3600; %[g] Incremental Calculation
        end
        
    end
    MNOXN_Total = MNOXN_Cum(end); % [g] Total Tailpipe NOx in the cycle
else
    fprintf('NOXN signal absent\n'); % Error Message
    fprintf('Stopping Evaluation\n'); % Error Message
    return
end

% Cumulative NOXN upon work Calculation MNOXPN
MNOXPN = MNOXN_Cum./Work_cum; % [g/kWh] Vector of cumulative values
MNOXPN_Total = MNOXN_Cum/Work_Total; % [g/kWh] NOXN with respect to total work of the cycle

%% CO Calculations
if (exist('CO'))
    MCO = 0.000966.*CO.*MAKH; % [g/hr]
    MCO_Cum = cumsum(MCO)*nSampleTime/3600;
    MCO_Total = MCO_Cum(end); % [g] Total Tailpipe CO in the cycle
    % Cumulative CO upon work Calculation MCOP
    MCOP = MCO_Cum./Work_cum; % [g/kWh] Vector of cumulative values
    MCOP_Total = MCO_Cum/Work_Total; % [g/kWh] CO with respect to total work of the cycle
else
    fprintf('CO signal absent\n'); % Error Message
    MCO_Total = 0;
end



%% CON Calculations
if (exist('CON'))
    MCON = 0.000966.*CON.*MAKH; % [g/hr]
    MCON_Cum = cumsum(MCON)*nSampleTime/3600;
    MCON_Total = MCON_Cum(end); % [g] Total Tailpipe NOx in the cycle
    % Cumulative CON upon work Calculation MCONP
    MCONP = MCON_Cum./Work_cum; % [g/kWh] Vector of cumulative values
    MCONP_Total = MCON_Cum/Work_Total; % [g/kWh] CON with respect to total work of the cycle
else
    fprintf('CON signal absent\n'); % Error Message
    MCON_Total = 0;
end

%% CO2 Calculations
if (exist('CO2'))
    MCO2 = 0.00152.*CO2.*MAKH*10000; % [g/hr]
    MCO2_Cum = cumsum(MCO2)*nSampleTime/3600;
    MCO2_Total = MCO2_Cum(end); % [g] Total Tailpipe CO2 in the cycle
    % Cumulative CO2 upon work Calculation MCO2P
    MCO2P = MCO2_Cum./Work_cum; % [g/kWh] Vector of cumulative values
    MCO2P_Total = MCO2_Cum/Work_Total; % [g/kWh] CO2 with respect to total work of the cycle
else
    fprintf('CO2 signal absent\n'); % Error Message
    MCO2_Total = 0;
end

%% CO2N Calculations
if (exist('CO2N'))
    MCO2N = 0.00152.*CO2N.*MAKH*10000; % [g/hr]
    MCO2N_Cum = cumsum(MCO2N)*nSampleTime/3600;
    MCO2N_Total = MCO2N_Cum(end); % [g] Total Tailpipe CO2N in the cycle
    % Cumulative CO2N upon work Calculation MCO2NP
    MCO2NP = MCO2N_Cum./Work_cum; % [g/kWh] Vector of cumulative values
    MCO2NP_Total = MCO2N_Cum/Work_Total; % [g/kWh] CO2N with respect to total work of the cycle
else
    fprintf('CO2N signal absent\n'); % Error Message
    MCO2N_Total = 0;
end

%% HC Calculations
if (exist('HC'))
    MHC = 0.000478.*HC.*MAKH; % [g/hr]
    MHC_Cum = cumsum(MHC)*nSampleTime/3600;
    MHC_Total = MHC_Cum(end); % [g] Total Tailpipe NOx in the cycle
    % Cumulative HC upon work Calculation MHCP
    MHCP = MHC_Cum./Work_cum; % [g/kWh] Vector of cumulative values
    MHCP_Total = MHC_Cum/Work_Total; % [g/kWh] HC with respect to total work of the cycle
else
    fprintf('HC signal absent\n'); % Error Message
    MHC_Total = 0;
end

%% HCN Calculations
if (exist('HCN'))
    MHCN = 0.000478.*HCN.*MAKH; % [g/hr]
    MHCN_Cum = cumsum(MHCN)*nSampleTime/3600;
    MHCN_Total = MHCN_Cum(end); % [g] Total Tailpipe NOx in the cycle
    % Cumulative HCN upon work Calculation MHCNP
    MHCNP = MHCN_Cum./Work_cum; % [g/kWh] Vector of cumulative values
    MHCNP_Total = MHCN_Cum/Work_Total; % [g/kWh] HCN with respect to total work of the cycle
else
    fprintf('HCN signal absent\n'); % Error Message
    MHCN_Total = 0;
end

%% O2 Calculations
if (exist('O2'))
    MO2 = 0.00105.*O2.*MAKH*10000; % [g/hr]
    MO2_Cum = cumsum(MO2)*nSampleTime/3600;
    MO2_Total = MO2_Cum(end); % [g] Total Tailpipe O2 in the cycle
    % Cumulative O2 upon work Calculation MO2P
    MO2P = MO2_Cum./Work_cum; % [g/kWh] Vector of cumulative values
    MO2P_Total = MO2_Cum/Work_Total; % [g/kWh] O2 with respect to total work of the cycle
else
    fprintf('O2 signal absent\n'); % Error Message
    MO2_Total = 0;
end

%% O2N Calculations
if (exist('O2N'))
    MO2N = 0.00105.*O2N.*MAKH*10000; % [g/hr]
    MO2N_Cum = cumsum(MO2N)*nSampleTime/3600;
    MO2N_Total = MO2N_Cum(end); % [g] Total Tailpipe O2N in the cycle
    % Cumulative O2N upon work Calculation MO2NP
    MO2NP = MO2N_Cum./Work_cum; % [g/kWh] Vector of cumulative values
    MO2NP_Total = MO2N_Cum/Work_Total; % [g/kWh] O2N with respect to total work of the cycle
else
    fprintf('O2N signal absent\n'); % Error Message
    MO2N_Total = 0;
end

%% NH3 Calculations
if (exist('NH3'))
    MNH3 = 0.00588.*NH3.*MAKH; % [g/hr]
    MNH3_Cum = cumsum(MNH3)*nSampleTime/3600;
    MNH3_Total = MNH3_Cum(end); % [g] Total Tailpipe NH3 in the cycle
    % Cumulative NH3 upon work Calculation MNH3P
    MNH3P = MNH3_Cum./Work_cum; % [g/kWh] Vector of cumulative values
    MNH3P_Total = MNH3_Cum/Work_Total; % [g/kWh] NH3 with respect to total work of the cycle
else
    fprintf('NH3 signal absent\n'); % Error Message
    MNH3_Total = 0;
end

%% MHST Calculation
MHST_Cum = zeros(length(MHST),1); % Memory allocation
if (exist('MHSTEE'))
    for nIdx = 1:length(MHSTEE) % Unit is g/h
        if (nIdx==1)
            MHST_Cum(nIdx) = MHSTEE(nIdx)*nSampleTime/3600; % for the first instance
        else
            MHST_Cum(nIdx) = MHST_Cum(nIdx-1)+MHSTEE(nIdx)*nSampleTime/3600; %[g] Incremental Calculation
        end
        
    end
else
    for nIdx = 1:length(MHST)
        if (nIdx==1)
            MHST_Cum(nIdx) = MHST(nIdx)*nSampleTime/3600; % for the first instance
        else
            MHST_Cum(nIdx) = MHST_Cum(nIdx-1)+MHST(nIdx)*nSampleTime/3600; %[g] Incremental Calculation
        end
        
    end
    
end
MHST_Total = MHST_Cum(end); % [g] Total urea dosing in cycle

%% Hydrolysis limit calculation
if (exist('MHSTHYEE')&& exist('MHSTCCEE'))
    MHSTdenied = MHSTCCEE - MHSTHYEE; % Taken from Samuel's code
    MHSTdenied(MHSTdenied<0) = 0; % Converting all negative values to 0
    MHSTdenied_Cum = zeros(length(MHSTdenied),1); % Memory allocation
    for nIdx = 1:length(MHSTdenied)
        if (nIdx==1)
            MHSTdenied_Cum(nIdx) = MHSTdenied(nIdx)*nSampleTime/3600; % for the first instance
        else
            MHSTdenied_Cum(nIdx) = MHSTdenied_Cum(nIdx-1)+ MHSTdenied(nIdx)*nSampleTime/3600; %[g] Incremental Calculation
        end
        
    end
    MHSTdenied_Total = MHSTdenied_Cum(end); % [g] Total urea dosing denied in cycle
    time_MHSTdenied_perc = sum(MHSTdenied > 0) / length(MHSTdenied) * 100; % Percent time in which Dosing denied
else
    MHSTdenied_Total = NaN; % cant calculate
    time_MHSTdenied_perc = NaN; % Cant Calculate
    fprintf('MHSTHYEE and MHSTCCEE signal absent Hydrolysis Calculation will be skipped \n'); % Warning Message
end
%% MBONL Cumulative Calculation
MBONL_Cum = zeros(length(MBONL),1); % Memory allocation
for nIdx = 1:length(MBONL) % MBONL unit is kg/h
    if (nIdx==1)
        MBONL_Cum(nIdx) = MBONL(nIdx)*nSampleTime/3600; % for the first instance
    else
        MBONL_Cum(nIdx) = MBONL_Cum(nIdx-1)+ MBONL(nIdx)*nSampleTime/3600; %[kg] Incremental Calculation
    end
    
end
MBONL_Total = MBONL_Cum(end); % [kg] Total Fuellling in cycle

%% BSFC Cumulative Calculation
BSFC = MBONL_Total*1000/Work_Total; % [g/kWh] BSFC = fuelling/total work

%% NOXKONV
NOXKONV = (MNOX_Cum - MNOXN_Cum)./MNOX_Cum*100; % NOX conversion efficiency
ETA = NOXKONV(end); % Final value of NOx conversion efficiency


%% Exhaust enthalpy ExHDOT (formula Kai Kanning simplified: h_dot = MAKH * (T4 - TL)
if (exist('T4')&& exist('TL'))
    ExHdot = MAKH .* (T4 - TL); % [kg K/h] Exhaust enthalpy
    ExHdot_Cum = zeros(length(ExHdot),1); % Memory allocation
    for nIdx = 1:length(ExHdot)
        if (nIdx==1)
            ExHdot_Cum(nIdx) = ExHdot(nIdx)*nSampleTime/3600; % for the first instance
        else
            ExHdot_Cum(nIdx) = ExHdot_Cum(nIdx-1)+ ExHdot(nIdx)*nSampleTime/3600; %[kg K] Incremental Calculation
        end
        
    end
else
    fprintf('T4 or TL signal absent Skipping ExHdot calculation\n');
end
%% TM Mode distibution calculation
if exist('TMCEE')
    cTM1 = (sum(TMCEE==1)/length(TMCEE))*100; % [%] TM1 mode percent
    cTM3 = (sum(TMCEE==3)/length(TMCEE))*100; % [%] TM3 mode percent
    cTM5 = (sum(TMCEE==5)/length(TMCEE))*100; % [%] TM5 mode percent
    
elseif exist('STMCEE')
    cTM1 = (sum(STMCEE==1)/length(STMCEE))*100; % [%] TM1 mode percent
    cTM3 = (sum(STMCEE==3)/length(STMCEE))*100; % [%] TM3 mode percent
    cTM5 = (sum(STMCEE==5)/length(STMCEE))*100; % [%] TM5 mode percent
    TMCEE = STMCEE; % Assigning alternative signal
elseif exist('tmc_status')
    cTM1 = (sum(tmc_status==1)/length(tmc_status))*100; % [%] TM1 mode percent
    cTM3 = (sum(tmc_status==3)/length(tmc_status))*100; % [%] TM3 mode percent
    cTM5 = (sum(tmc_status==5)/length(tmc_status))*100; % [%] TM5 mode percent
    TMCEE = tmc_status; % Assigning alternative signal
else
    fprintf('TMCEE signal absent. Skipping TM mode distribution calculation\n'); % Error Message
    cTM1 = NaN; % cant calculate
    cTM3 = NaN; % cant calculate
    cTM5 = NaN;
end

%% Idling Calculation
if exist('EOMEE')
    Idling = (EOMEE > 6) & (EOMEE < 12); % engine is idle when EOM =8
    Idling_Total = sum(Idling)/length(Idling)*100; % [%]
elseif exist('eom_engine_state')
    EOMEE = eom_engine_state; % Mapping from MARC to MVA
    Idling = (EOMEE > 6) & (EOMEE < 12); % engine is idle when EOM =8
    Idling_Total = sum(Idling)/length(Idling)*100; % [%]
else
    fprintf('EOMEE signal absent. Skipping Idling calculation\n'); % Error Message
    Idling_Total = NaN; % Cant calculate
end

%% Coasting Calculation
if (exist('ALPHA','var')&& exist('fis_act_fm_combustion'))
    %Coasting = (ALPHA <0.1) & (EOMEE > 12); %initial formula taken from Samuel's script
    Coasting = ((fis_act_fm_combustion==0) & (ALPHA<0.1) & (NMOTW>450)); % Formula suggested by Partha
    %check
    %Coasting = ((ALPHA<0.1) & (NMOTW>450));check
    Coasting_Total = sum(Coasting) / length(Coasting) * 100; % [%]
elseif (exist('ccf_atc_fm_act')&& exist('ALPHA','var'))
    Coasting = ((ccf_atc_fm_act==0) & (ALPHA<0.1) & (NMOTW>450)); % Formula suggested by Partha
    %check
    %Coasting = ((ALPHA<0.1) & (NMOTW>450));check
    Coasting_Total = sum(Coasting) / length(Coasting) * 100; % [%]
else
    fprintf('ALPHA signal absent. Skipping coasting calculation\n'); % Error Message
    Coasting_Total = NaN; % No Calculation
end

%% Mean Temperature Calculation
if exist('T2SEE')
    T2SEE_Mean = mean(T2SEE); % [deg C]
else
    fprintf('T2SEE signal absent. Skipping Mean calculation\n'); % Error Message
    T2SEE_Mean = NaN; % No Calculation
end

if exist('T31')
    T31_Mean = mean(T31); % [deg C]
else
    fprintf('T31 signal absent. Skipping Mean calculation\n'); % Error Message
    T31_Mean = NaN; % No Calculation
end

if exist('T32')
    T32_Mean = mean(T32); % [deg C]
else
    fprintf('T32 signal absent. Skipping Mean calculation\n'); % Error Message
    T32_Mean = NaN; % No Calculation
end

if exist('T4')
    T4_Mean = mean(T4); % [deg C]
else
    fprintf('T4 signal absent. Skipping Mean calculation\n'); % Error Message
    T4_Mean = NaN; % No Calculation
end

if exist('TAB')
    TAB_Mean = mean(TAB); % [deg C]
else
    fprintf('TAB signal absent. Skipping Mean calculation\n'); % Error Message
    TAB_Mean = NaN; % No Calculation
end

if exist('T7VEE')
    T7VEE_Mean = mean(T7VEE); % [deg C]
elseif exist('is4_t_doc_in')
    T7VEE = is4_t_doc_in; % MARC to MVA Mapping
    T7VEE_Mean = mean(T7VEE); % [deg C]
else
    fprintf('T7VEE signal absent. Skipping Mean calculation\n'); % Error Message
    T7VEE_Mean = NaN; % No Calculation
end

if ~exist('T7NEE')
    if exist('is4_t_doc_out')
        T7NEE = is4_t_doc_out; % MARC to MVA Mapping
    end
end

if exist('T9VEE')
    T9VEE_Mean = mean(T9VEE); % [deg C]
elseif exist('is4_t_scr_cat_in')
    T9VEE = is4_t_scr_cat_in; % MARC to MVA Mapping
    T9VEE_Mean = mean(T9VEE); % [deg C]
else
    fprintf('T9VEE signal absent. Skipping Mean calculation\n'); % Error Message
    T9VEE_Mean = NaN; % No Calculation
end

if exist('T9NEE')
    T9NEE_Mean = mean(T9NEE); % [deg C]
elseif exist('is4_t_scr_cat_out')
    T9NEE = is4_t_scr_cat_out; % MARC to MVA Mapping
    T9NEE_Mean = mean(T9NEE); % [deg C]
else
    fprintf('T9NEE signal absent. Skipping Mean calculation\n'); % Error Message
    T9NEE_Mean = NaN; % No Calculation
end

%% Clearing unwanted variables

clear nIdx nTestbenchSwitch nNoxHumidityCorrection nNOxShift nTtauConstant nAirFuelRatioStoich

sOutputFilename = [sInputFilename(1:end-4),'_PEMSNOX.mat']; % Filename for the output file
clear sInputFilename
save(sOutputFilename,'-regexp','-regexp', '^(?!(sOutputFilename|cRequiredSignals)$).');



end