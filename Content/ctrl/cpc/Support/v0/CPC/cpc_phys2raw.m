function [y] = cpc_phys2raw(x, bInverse)  %#ok<*ASGLU>
% CPC_PHYS2RAW converts physical values into ECU raw values
% cpc_cdi_table.m is needed
%
%
% Syntax:  [y] = cpc_phys2raw(x, bInverse)
%
% Inputs:
%           x - [.] input structure
%    bInverse - [0,1] convert raw2phys (optional, default:0)
%
% Outputs:
%    y - [.] output structure
%
% Example: 
%    y = cpc_phys2raw(x);
%    y = cpc_phys2raw(sMP.ctrl.cpc.init);
%    y = cpc_phys2raw(read_csv_par('cpc_debug.csv'));
%    CreateCANapeParFile('cpc_test.par', cpc_phys2raw(read_csv_par('cpc_debug.csv')), 'eCPC')
%
%
% Other m-files required: cpc_cdi_table.m
%
% See also: fcGetCDI, read_csv_par, CreateCANapeParFile, read_par_file
%
% Author: PLOCH37
% Date:   16-Mar-2021

%% Destination of conversion
if exist('bInverse', 'var') && bInverse
    sDestination = 'phys';
else
    sDestination = 'raw';
end

%% Convert
xCDI0 = fcGetCDI('CPC'); % get CDI table information
cPID = fieldnames(x); % PIDs, for example ptconf_p_Trans
for k = 1:length(cPID)
    sPID = cPID{k};
    if ~isstruct(x.(sPID)) % Signal, not a parameter
        sSig = sPID;
        dValuePhys = x.(sSig);
        try
            [xCDI, dValueRaw] = fcGetCDI(xCDI0, sSig, sDestination, dValuePhys);
            y.(sSig) = dValueRaw;
        catch
            fprintf(1, 'Parameter or Signal %s not found?\n', sSig);
        end
    else % Parameter
        cPar = fieldnames(x.(sPID)); % Parameter, for exmple GearRatio_s16 in ptconf_p_Trans.GearRatio_s16
        for n = 1:length(cPar)
            sPar = cPar{n};
            sSig = [sPID '.' sPar];
            dValuePhys = x.(sPID).(sPar);
            try
                [xCDI, dValueRaw] = fcGetCDI(xCDI0, sSig, sDestination, dValuePhys);
                y.(sPID).(sPar) = dValueRaw;
            catch
                fprintf(1, 'Parameter or Signal %s not found?\n', sSig);
            end
            
        end
    end
end