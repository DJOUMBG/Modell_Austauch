% noTfc

% ___Data___________
torqueDistribution = [0 100];

% state transfercase {0=HIGH/onroad;1=LOW/offroad; 3=none}
stTrfGrBoxHi = 3.0;

iTfc = [1.0 1.0];

JTfc_kgm2    = 0.5;


% Dataset: no_losses

% //   losses
tfcLoss_dim   =    [2, 2];  % // dimension loss map
tfcLoss_x_speedTfcIn_rpm = [-1e10 1e10];
tfcLoss_y_torqueTfcIn_Nm = [-1e10; 1e10];
tfcLoss_map_torqueTfcIn_Nm = [0 0; 0 0];
