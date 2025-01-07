% Select and load main par file dependent on Vehicle Class and Type
% sParUser = 'myParFile'; % override default par file selection by user defined name (without .par extension)
cpc_par_load;

% Change Parameter based on vehicle config
cpc_data_load; 

% Overwrite EEP with parameter needed for simulation
cpc_eep4sim; 

% Check parameter
cpc_check_par;