function [s] = cpc_cds_def(n, sPar)
% CPC_CDS_DEF Get definition name of parameter needed for CDS selection
%
%
% Syntax:  [s] = cpc_cds_def(n, sPar)
%
% Inputs:
%       n - [-] Parameter value
%    sPar - [''] Parameter type, short name
%
% Outputs:
%    s - [''] Parameter definition name
%
% Example:
%    s = cpc_cds_def(1, 'VehClass');
%    s = cpc_cds_def(1, 'SftProg');
%    s = cpc_cds_def(5, 'EngType');
%    s = cpc_cds_def(0, 'TransType');
%    s = cpc_cds_def(3, 'CustType');
%
%
% Author: ploch37
% Date:   04-Oct-2018

%% ------------- BEGIN CODE --------------
s = ''; % init output
switch sPar
    
    case 'VehClass'
        switch n
            case {1, 2}
                s = 'SFTP';
            case {3}
                s = 'NGA';
            case {4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}
                s = 'EVOBUS';
            case {17}
                s = 'BUS'; 
            case {50, 51}
                s = 'FREIGHTLINER';
            case {60, 61, 62}
                s = 'FUSO';
            case {30, 31}
                s = 'BRAZIL';
        end
        
    case 'SftProg'
        sDef = {
            0, 'Power'
            1, 'Economy'
            2, 'HeavyDuty'
            3, 'Fleet'
            4, 'Offroad'
            5, 'Municipal'
            6, 'Fire'
            7, 'EcoPlus'
            8, 'ViabPower'
            9, 'ViabEconomy'
            10, 'ViabOffroad'
            100, 'Standard'
            };
        s = sDef{[sDef{:,1}] == n, 2};

    case 'EngType'
        sDef = {
            2,  'OM926'
            3,  'OM936'
            4,  'OM470'
            5,  'OM471'
            6,  'OM473'
            15, 'OM472'
            20, 'OM924'
            21, 'OM926'
            23, 'OM460'
            100, 'Remy'
            };
        s = sDef{[sDef{:,1}] == n, 2};
        
    case 'CombustionClass'
        switch n
            case {3, 50}
                s = 'EU3';
            case {4, 5, 51}
                s = 'EU5';
            case {6, 52}
                s = 'EU6';
            case {7, 10, 11, 13}
                s = 'EPA';
            case {24, 100, 102}
                s = 'TIER';
            case {70, 71}
                s = 'JP';
        end
        
        
    case 'TransType'
        switch n
            case {100}
                s = '2D';
            case {6, 7, 8, 14, 15, 16, 23, 24, 25, 52, 54, 80, 81}
                s = '6D';
            case {51}
                s = '7D';
            case {5, 9, 26}
                s = '8D';
            case {13, 22, 53}
                s = '9D';
            case {1, 3, 48, 50}
                s = '12OD';
            case {0, 2, 47, 49}
                s = '12DD';
            case {4, 10, 11, 12}
                s = '16D';
        end
        
    case 'CustType'
        sDef = {
            0, ''
            1, 'Development'
            2, 'Euro_FE0'
            3, 'Euro_FE1'
            4, 'EPA_FE0_captive'
            5, 'EPA_FE1_captive'
            6, 'EPA_FE0_noncaptive'
            7, 'EPA_FE1_noncaptive'
            8, 'twoaxle_short'
            9, 'twoaxle_long'
            10, 'threeaxle_short'
            11, 'threeaxle_long'
            13, 'Rigid truck'
            14, 'NAFTA_TCO'
            255, ''
            };
        s = sDef{[sDef{:,1}] == n, 2};
        
    case 'RetType'
        if n > 0 && n <= 39 
            s = 'Ret1';
        else
            s = 'Ret0';
        end
end
s = upper(s);