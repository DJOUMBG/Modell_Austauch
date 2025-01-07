function [eep] = read_drumroll_par_file(sFile)
% READ_DRUMROLL_PAR_FILE read par file from Drumroll App into eep structure needed for CPC-SIL
% Format is from NAFTA
%
%
% Syntax:  [eep] = read_drumroll_par_file(sFile)
%
% Inputs:
%    sFile - [''] par file (String)
%
% Outputs:
%    eep - [.] eep structure
%
% Example:
%    IPPC_EEP = read_drumroll_par_file('IPPC Rel3 FE1 Captive logging enabled 660.par');
%    CPC3_EEP = read_drumroll_par_file('HR3640_CPC3EVO_20160615_ENG_REV0.par');
%
%
% See also: fcGetCDI
%
% Author: ploch37
% Date:   30-Aug-2016

% SVN: (is set automatically, if Keywords - Property enabled)
%   $Rev:: 3526                                                 $
%   $Author:: PLOCH37                                           $
%   $Date:: 2020-12-14 18:49:59 +0100 (Mo, 14. Dez 2020)        $
%   $URL: file:///J:/TG/FCplatform/500_newLDYN_SimPlatform/DIVeLDYN_svn/trunk/ldDevProj/case/c000/Content/ctrl/cpc/Support/v0/CPC/read_drumroll_par_file.m $


%% init output
eep = [];

%% check file format
h = fopen(sFile); % open file
l = fgetl(h); % read first line
fclose(h); % close file
switch l(1:9)
    case {'S,ECU,CPC', 'S,ECU,ECP'}
        sECU = 'CPC';
    case 'S,ECU,IPP'
        sECU = 'IPPC';
    otherwise
        error('unknown file format')
end
xCDI0 = fcGetCDI(sECU);

%% read file
% read data from file
h = fopen(sFile); % open file
C = textscan(h, '%*s %s %*s %f', 'HeaderLines', 8, 'Delimiter', ','); % read data, for example P,ptconf_p_Veh_VehClass_u8,B,50
fclose(h); % close file
sPar = C{1}; % Parametername
dValue = C{2}; % Value
if strcmp(sECU, 'CPC')
    for k = 1:length(sPar)
        idx = find(sPar{k} == '_');
        sPar{k}(idx(3)) = '.'; % '.' instead of '_'
    end
end
flg = 0;    % flag to detect type of signal: 0 - scalar | 1 - vector | 2 - matrix
flg2 = 0;   % flag to updated counters for while loop
k = 1;      % initializing the while loop

% Put data into eep struct and transform from physical to raw value
while k <= length(sPar)
    
    % Init values
    dValueRaw = [];
    xCDI = [];
    
    % short name
    idx = find(sPar{k} == '_');
    switch sECU
        case 'CPC' % for example: P,ptconf_p_Veh_VehClass_u8,B,50
            idx_start = 1; % Start of Signal name
            idx_unit = idx(3) + 1; % Start u8 / u16 / u160 / ...
            unit = sPar{k}(idx_unit:end);
        case 'IPPC' % for example: P,VCD_016_cdi_p_LogConf.LogEn_u1,B,1
            idx_start = idx(2) + 1; % Start of Signal name
            idx_unit = idx(5) + 1; % Start u8 / u16 / u160 / ...
            unit = sPar{k}(idx_unit:end);
    end
    
    
    switch unit
        case {'u1', 'u2', 'u4', 'u8', 's8', 'u16', 's16', 'u32', 's32'} % Scalar Signals
          
            flg = 0;
            flg2 = 0;
            sParShort = sPar{k}(idx_start:end);
            
            % Get physical value
            dValuePhys = dValue(k);
            
        case {'u10', 'u40', 'u80', 's80', 'u160', 's160', 'u320'} % Vector Signals
            
            flg = 1;
            flg2 = 1;
            sParShort = sPar{k}(idx_start:end-1);
            sParCmp0 = sPar{k}(idx_start:idx_unit-2);
            ctr = 1; % counter
            sParCmp1 = sPar{k+ctr}(idx_start:idx_unit-2);
            while strcmp(sParCmp0,sParCmp1) == 1
                ctr = ctr + 1;
                if (k+ctr) > length(sPar) % File at the end
                    break
                end
                idx1 = find(sPar{k+ctr} == '_');
                if (length(idx) ~= length(idx1)) || any(idx ~= idx1)
                    break
                else
                    sParCmp1 = sPar{k+ctr}(idx_start:idx_unit-2);
                end
            end
            % Get physical values
            dValuePhys = dValue(k:k-1+ctr)';
            
        case {'u100', 'u800', 'u1600', 's1600'} % Matrix Signals
            
            flg = 2;
            flg2 = 1;
            sParShort = sPar{k}(idx_start:end-2);
            sParCmp0 = sPar{k}(idx_start:idx_unit-2);
            nPosRow = length(sPar{k});
            nRow0 = 0;
            r_idx = 1;
            c_idx = 1;
            ctr = 1;
            sParCmp1 = sPar{k+ctr}(idx_start:idx_unit-2);
            while strcmp(sParCmp0,sParCmp1) == 1
                % Matrix size detection
                nRow1 = str2double(sPar{k+ctr}(nPosRow:end));
                if nRow0 + 1 == nRow1
                    % next row element
                    r_idx = r_idx + 1;
                else
                    % next column element
                    c_idx = c_idx + 1;
                    if c_idx == 11 % change (from u899 to u8100) or (from u16915 to u16100)
                        nPosRow = nPosRow + 1;
                    end
                    % first row element
                    r_idx = 1;
                end
                nRow0 = nRow1;
                % Next Element
                ctr = ctr + 1;
                if (k+ctr) > length(sPar) % File at the end
                    break
                end
                idx1 = find(sPar{k+ctr} == '_');
                if (length(idx) ~= length(idx1)) || any(idx ~= idx1)
                    break
                else
                    sParCmp1 = sPar{k+ctr}(idx_start:idx_unit-2);
                end
            end
            
            % Get physical values
            dValuePhys = reshape(dValue(k:k-1+c_idx*r_idx), [r_idx, c_idx]);
            
        otherwise
            sParShort = sPar{k};
            fprintf(1, 'Unknown Type: %s\n', sParShort);
            flg2 = 0;
    end
    
    % Put data into eep struct
    try
        [xCDI, dValueRaw] = fcGetCDI(xCDI0, sParShort, 'raw', dValuePhys); %#ok<ASGLU>
        % Usage of eval, because parameter in struct like
        % ptconf_p_Veh.VehClass_u8 for example
        eval(['eep.' sParShort ' = dValueRaw;']);
    catch
        fprintf(1, 'Parameter %s not found?\n', sParShort);
    end
    
    % Updating counters
    if flg2 == 1
        k = k + ctr;
    else
        k = k + 1;
    end
end

