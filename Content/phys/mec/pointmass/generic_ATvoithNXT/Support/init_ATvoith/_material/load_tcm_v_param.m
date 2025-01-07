%% Set Shifting Program
SP = 5;
disp(['Shifting Program loaded: SP' num2str(SP)]);
%% Load data files according to the selected shifting programme (SP3/SP5(SORT)/SP6)
warning('off','MATLAB:RMDIR:RemovedFromPath');
try
    rmdir('Voith_Data\','s');
        catch
            disp('Can''t remove directory \Voith_Data\ !');
end
try 
    delete('DIWA_BB_ParNames.mat','DIWA_BB_ParValues.mat');
        catch
            disp('Can''t remove DIWA Parameter Files');
end
warning('on','MATLAB:RMDIR:RemovedFromPath');

switch SP
    case 3
        copyfile('DIWA_BB_ParNames_SP3Fix.mat','DIWA_BB_ParNames.mat');
        copyfile('DIWA_BB_ParValues_SP3Fix.mat','DIWA_BB_ParValues.mat');
        copyfile('Voith_Data_SP3Fix\','Voith_Data\');    
    case 5
        copyfile('DIWA_BB_ParNames_SP5.mat','DIWA_BB_ParNames.mat');
        copyfile('DIWA_BB_ParValues_SP5.mat','DIWA_BB_ParValues.mat');
        copyfile('Voith_Data_SP5\','Voith_Data\');


    case 6
        copyfile('DIWA_BB_ParNames_SP6.mat','DIWA_BB_ParNames.mat');
        copyfile('DIWA_BB_ParValues_SP6.mat','DIWA_BB_ParValues.mat');
        copyfile('Voith_Data_SP6\','Voith_Data\');
end

load DIWA_BB_ParNames.mat
load DIWA_BB_ParValues.mat

% retarder inititalization
x_ret_GW_rpm =   [200 300 400 500 600 700 800 900 1000 1100 1200 1300 1400 1500 1600 1700 1800 1900 2000 2100 2200 2300 2400 2500 2600 2700 2800 2900 3000 3100 3200 3300 3400 3500];
%MP665 SP5
y_ret_M_max  =   [70 180 300 430 580 750 975 1224 1553 1800 1800 1800 1800 1800 1790 1685 1592 1508 1500 1500 1500 1500 1500 1500 1500 1500 1500 1500 1500 1500 1500 1500 1500 1500];

% dummy parameters needed for later initialization of the transmission
% control with global parameters

mVeh = [];
rDyn = [];
axleiDiff = [];
eng_idleSpeed = [];
eng_maxSpeed = [];
eng_maxTorque = [];
rhoAir = [];
fRFzg = [];
etaAxle = [];

