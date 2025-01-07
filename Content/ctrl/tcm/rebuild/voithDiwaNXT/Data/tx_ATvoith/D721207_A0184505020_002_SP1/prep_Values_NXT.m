%
%  prep_Values
%
%  prep_Values übersetzt die Struktur VoithData in flache 
%  Workspacevariablen
%
%     
%
%   -----------------------------------------------------------------------
%
%   Voith Turbo GmbH & Co. KG
%   Autor:      gorashe, tmdds
%   Version:    1.0     2021-04-23
%              
%   -----------------------------------------------------------------------


DIWA_BB_ParNames_NXT =[  
'Schaltprogramm                 ';
'Versuchsdatensatz              ';
'slider                         ';
'activation_EK_off              ';
'activation_AccLimEng           ';
'FZG_mVeh                       ';
'FZG_mVeh_empty                 ';
'FZG_mVeh_load                  ';
'FZG_rDyn                       ';
'FZG_iA                         ';
'FZG_etaAxle                    ';
'ENG_Inertia                    ';
'ENG_idleSpeed                  ';
'ENG_maxSpeed                   ';
'ENG_maxTorque                  ';
'PGM_Differenzial               ';
'SM_AGH_accFzg_max_UPS          ';
'SM_AGH_n_Offset                '; 
];

DIWA_BB_ParValues_NXT =[ 
1;              % [-]
0;              % [-]
0;              % [-]
1;              % [-]
0;              % [-]
15180;          % [kg]
11170;          % [kg]
4010;           % [kg]
0.465;          % [m]
5.875;           % [-]
0.95;           % [-]
1.08            % [kgm/s2]
600;            % [rpm]
2500;           % [rpm]
1400;           % [Nm]
3;              % [-]
0.1;            % [m/s2]
100;            % [rpm]
];