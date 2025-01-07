function [sMP]= mec_transferGlobalParameters(varargin)
% MEC_TRANSFERGLOBALPARAMETERS generate parameters from mec module to make
% them available in other module
%
% Syntax:
%
% Inputs:
%   sMP - structure containing vehicle parameters
%
% Outputs:
%   sMP - structure containing vehicle parameters
% 
% Example: transferGlobalParameters()
%
% See also: 
%
% Author: Fabian Beck, TP/EAD, Daimler AG
%  Phone: 
% MailTo: fabian.fb.beck@daimler.com
%   Date: 2016-06-28

% read sMP structure from base workspace
sMP = evalin('base','sMP');         % get sMP parameter struct

% create temp mec structure containing all mec parameters
mec= sMP.phys.mec;

% total vehicle mass including trailer
mec.mec_massVehicle_kg = mec.mass.startGCW_kg  ; % mass

% get axle and wheel parameters of vehicle
% isDriven# either 0 if not a driven axle or 1 if driven axle
isDriven1   = mec.axle1.isDriven;
isDriven2   = mec.axle2.isDriven;
isDriven3   = mec.axle3.isDriven;
isDriven4   = mec.axle4.isDriven;

% isRear# either 0 if not a rear axle or 1 if driven axle
isRear1     = mec.axle1.isRearAxle;
isRear2     = mec.axle2.isRearAxle;
isRear3     = mec.axle3.isRearAxle;
isRear4     = mec.axle4.isRearAxle;

% get wheel parameters of vehicle
fRollC1     = mec.wheel1.fRollCoeff;
fRollC2     = mec.wheel2.fRollCoeff;
fRollC3     = mec.wheel3.fRollCoeff;
fRollC4     = mec.wheel4.fRollCoeff;

% get axle and wheel parameters of trailer
rDynTrailer = [mec.trailerWheel1.rDyn_m mec.trailerWheel2.rDyn_m mec.trailerWheel3.rDyn_m];
fRollC_T1   = mec.trailerWheel1.fRollCoeff;
fRollC_T2   = mec.trailerWheel2.fRollCoeff;
fRollC_T3   = mec.trailerWheel3.fRollCoeff;
rDynTrailer = rDynTrailer([fRollC_T1 fRollC_T2 fRollC_T3] > 0);

% copy of logic in file axleConfiguration_150526.mo
if (isRear1==0 && isDriven1==0) && (isRear2==1 && isDriven2==1) && (isRear3==0 && isDriven3==3) && (isRear4==0 && isDriven4==3) %4x2 Configuration
    mec.mec_iDiffAxle       =   mec.axle2.iDiff;
    mec.mec_rWheelDriven    =   mec.wheel2.rDyn_m;
    mec.mec_axleConfig      =   [4 2];
elseif (isRear1==0 && isDriven1==1) && (isRear2==1 && isDriven2==1) && (isRear3==0 && isDriven3==3) && (isRear4==0 && isDriven4==3) %4x4 Configuration
    mec.mec_iDiffAxle       =   mec.axle1.iDiff;
    mec.mec_rWheelDriven    =   mec.wheel1.rDyn_m;
    mec.mec_axleConfig      =   [4 4];
elseif (isRear1==0 && isDriven1==0) && (isRear2==1 && isDriven2==0) && (isRear3==1 && isDriven3==1) && (isRear4==0 && isDriven4==3) %6x2/2 VLA && 6x2/4 VLA Configuration
    mec.mec_iDiffAxle       =   mec.axle3.iDiff;
    mec.mec_rWheelDriven    =   mec.wheel3.rDyn_m;
    mec.mec_axleConfig      =   [6 2];
elseif (isRear1==0 && isDriven1==0) && (isRear2==1 && isDriven2==1) && (isRear3==1 && isDriven3==0) && (isRear4==0 && isDriven4==3) %6x2 ENA und 6x2 DNA Configuration
    mec.mec_iDiffAxle       =   mec.axle2.iDiff;
    mec.mec_rWheelDriven    =   mec.wheel2.rDyn_m;
    mec.mec_axleConfig      =   [6 2];
elseif (isRear1==0 && isDriven1==0) && (isRear2==1 && isDriven2==1) && (isRear3==1 && isDriven3==1) && (isRear4==0 && isDriven4==3) %6x4 Configuration
    mec.mec_iDiffAxle       =   mec.axle2.iDiff;
    mec.mec_rWheelDriven    =   mec.wheel2.rDyn_m;
    mec.mec_axleConfig      =   [6 4];
elseif (isRear1==0 && isDriven1==1) && (isRear2==1 && isDriven2==1) && (isRear3==1 && isDriven3==1) && (isRear4==0 && isDriven4==3) %6x6 Configuration
    mec.mec_iDiffAxle       =   mec.axle1.iDiff;
    mec.mec_rWheelDriven    =   mec.wheel1.rDyn_m;
    mec.mec_axleConfig      =   [6 6];
elseif (isRear1==0 && isDriven1==0) && (isRear2==1 && isDriven2==0) && (isRear3==1 && isDriven3==1) && (isRear4==1 && isDriven4==0) %8x2/4 VLA/DNA Configuration
    mec.mec_iDiffAxle       =   mec.axle3.iDiff;
    mec.mec_rWheelDriven    =   mec.wheel3.rDyn_m;
    mec.mec_axleConfig      =   [8 2];
elseif (isRear1==0 && isDriven1==0) && (isRear2==0 && isDriven2==0) && (isRear3==1 && isDriven3==1) && (isRear4==1 && isDriven4==0) %8x2/4 ENA Configuration
    mec.mec_iDiffAxle       =   mec.axle3.iDiff;
    mec.mec_rWheelDriven    =   mec.wheel3.rDyn_m;
    mec.mec_axleConfig      =   [8 2];
elseif (isRear1==0 && isDriven1==0) && (isRear2==1 && isDriven2==1) && (isRear3==1 && isDriven3==1) && (isRear4==1 && isDriven4==0) %8x4 ENA Configuration
    mec.mec_iDiffAxle       =   mec.axle2.iDiff;
    mec.mec_rWheelDriven    =   mec.wheel2.rDyn_m;
    mec.mec_axleConfig      =   [8 4];
elseif (isRear1==0 && isDriven1==0) && (isRear2==0 && isDriven2==0) && (isRear3==1 && isDriven3==1) && (isRear4==1 && isDriven4==1) %8x4/4 Configuration
    mec.mec_iDiffAxle       =   mec.axle3.iDiff;
    mec.mec_rWheelDriven    =   mec.wheel3.rDyn_m;
    mec.mec_axleConfig      = 	[8 4];
elseif (isRear1==0 && isDriven1==1) && (isRear2==0 && isDriven2==0) && (isRear3==1 && isDriven3==1) && (isRear4==1 && isDriven4==1) %8x6/4 Configuration Variante 1
    mec.mec_iDiffAxle       =   mec.axle1.iDiff;
    mec.mec_rWheelDriven    =   mec.wheel1.rDyn_m;
    mec.mec_axleConfig      =   [8 6];
elseif (isRear1==0 && isDriven1==0) && (isRear2==0 && isDriven2==1) && (isRear3==1 && isDriven3==1) && (isRear4==1 && isDriven4==1) %8x6/4 Configuration Variante 2
    mec.mec_iDiffAxle       =   mec.axle2.iDiff;
    mec.mec_rWheelDriven    =   mec.wheel2.rDyn_m;
    mec.mec_axleConfig      =   [8 6];
elseif (isRear1==0 && isDriven1==1) && (isRear2==0 && isDriven2==1) && (isRear3==1 && isDriven3==1) && (isRear4==1 && isDriven4==1) %8x8/4 Configuration
    mec.mec_iDiffAxle       =   mec.axle1.iDiff;
    mec.mec_rWheelDriven    =   mec.wheel1.rDyn_m;
    mec.mec_axleConfig      =   [8 8];
else %Dummy or not matching Configurations
    mec.mec_iDiffAxle       =   mec.axle1.iDiff;
    mec.mec_rWheelDriven    =   mec.wheel1.rDyn_m;
    mec.mec_axleConfig      =   [0 0];
end

% Info from D. Wilke: if axle 1 and 2 are not driven, then axle 2 is the 
% 'front axle' because the wheels of this axle are sensed by ABS. If axle 2 is driven 
% while axle 1 is not driven then axle 1 is the 'front axle'.
if (isDriven1==0) && (isDriven2==0) 
    mec.mec_rWheelFrontAxle = mec.wheel2.rDyn_m;
elseif (isDriven1==0) && (isDriven2==1)
    mec.mec_rWheelFrontAxle = mec.wheel1.rDyn_m;
else
    mec.mec_rWheelFrontAxle = 0;
    warning('No valid vehicle configuration selected. Dynamic front wheel radius is set to 0.');
end

rDynTrailer = setdiff(rDynTrailer,0); % unique reduction of all rDyn values (without disabled axles)
if isempty(rDynTrailer)
    rDynTrailer = 0;
end
if length(rDynTrailer) > 1
    error('Different dynamic wheel radius are not supported for the trailer');
end
mec.mec_rWheelTrailer = rDynTrailer(1);

% source for global parameters: EBS/PNE - conv. to mm 
mec.mec_rWheelTrailer = mec.mec_rWheelTrailer * 1000;
mec.mec_rWheelFrontAxle = mec.mec_rWheelFrontAxle * 1000;
mec.mec_rWheelDriven = mec.mec_rWheelDriven * 1000;

% source for global parameters: Vector of Dynamic wheel radius Tractor/Trailer axles - conv. to mm
mec.wheels_rdynTractor = [mec.wheel1.rDyn_m, mec.wheel2.rDyn_m, mec.wheel3.rDyn_m, mec.wheel4.rDyn_m].*1000;
mec.wheels_rdynTrailer = [mec.trailerWheel1.rDyn_m, mec.trailerWheel2.rDyn_m, mec.trailerWheel3.rDyn_m].*1000;
% source for global parameters: driver - fRollCoeff of complete roadtrain (vehicle + trailer)
% --> obsolete
mec.mec_fRollCoeffOverall = sum([mec.massLoad.mass_distribution(1,1:4) .* [fRollC1 fRollC2 fRollC3 fRollC4] mec.massLoad.mass_distribution(1,5:7) .* ...
    [fRollC_T1 fRollC_T2 fRollC_T3]])/sum(mec.massLoad.mass_distribution(1,:));

% source for global parameters: mechanical inertias (for driving performance)
%mec.mec_JEng_kgm2          			= mec.eng.JCrankShaft_kgm2 + mec.eng.JFlyWheel_kgm2;
mec.mec_JEng_kgm2          			= mec.eng.JCrankShaft_kgm2;
%mec.mec_JTxWorstCase_kgm2           = mec.tx.JTxInShft_kgm2 + mec.tx.JTxMainShft_kgm2 + mec.tx.JTxOutShft_kgm2 + mec.tx.JTxCntShft_kgm2 + mec.tx.JTxRngCarrier_kgm2;
mec.mec_JTxWorstCase_kgm2           = 0.1;
% (worst case for transmission, low effort)
mec.mec_JShafts_kgm2    = mec.shtF.JPropShaft_kgm2 + mec.shtR.JPropShaft_kgm2;
mec.mec_JAxles_kgm2     = mec.axle1.JSideShft_kgm2 + mec.axle2.JSideShft_kgm2 + mec.axle3.JSideShft_kgm2 + mec.axle4.JSideShft_kgm2 ...
    + mec.trailerAxle1.JSideShft_kgm2 + mec.trailerAxle2.JSideShft_kgm2 + mec.trailerAxle3.JSideShft_kgm2;
mec.mec_JWheels_kgm2    = 2* (mec.wheel1.JWheel_kgm2 + mec.wheel2.JWheel_kgm2 + mec.wheel3.JWheel_kgm2 + mec.wheel4.JWheel_kgm2 ...
    + mec.trailerWheel1.JWheel_kgm2 + mec.trailerWheel2.JWheel_kgm2 + mec.trailerWheel3.JWheel_kgm2);

% write global parameters back into sMP-structure
sMP.phys.mec= mec;

% just add mec_iDiffAxle, mec_rWheelDriven, mec_axleConfig to .mec structure,
% clear all other vars ...
clear isDriven1 isRear1 iDiff1 rDyn1 fRollC1 fRollC_T1;
clear isDriven2 isRear2 iDiff2 rDyn2 fRollC2 fRollC_T2;
clear isDriven3 isRear3 iDiff3 rDyn3 fRollC3 fRollC_T3;
clear isDriven4 isRear4 iDiff4 rDyn4 fRollC4;
clear rDynTrailer mec

% write sMP structure back to base workspace
assignin('base', 'sMP', sMP); 