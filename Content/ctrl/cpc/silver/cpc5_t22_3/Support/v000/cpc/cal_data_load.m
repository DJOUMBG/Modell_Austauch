function [cal, mdl] = cal_data_load(sPathRunDir, mdl, EEP) %#ok<*NASGU>

% Init output
cal = [];

% Check for supported transmissions by CAL
% Igonore automatic transmissions like Allison, Voith, ZF
% see cal_lib.c
if exist('EEP', 'var')
    switch EEP.ptconf_p_Trans.TransType_u8
        
        % Automatic transmissions
        case {17, 18, 19, 20, 21}
            % Probably also possible dependent on sw_p_VehConf.EnAg_u1
            % But this parameter is set only in main par file, and not
            % defined by configured transmission dataset
            return % ignore
            
        % GEARS_2
        case 100 % RE440-2K
            
        % GEARS_6
        case 101 % RE440EVO-6K 
            
        % GEARS_6
        case 6  % G70-6S
        case 7  % G71-6S
        case 8  % G90-6S
        case 14 % GO190-6S
        case 15 % GO210-6S
        case 16 % GO230-6S
        case 23 % Allison 3000 P/PR - 6 gears PTCAN
        case 24 % Allison 3200 P/PR - 6 gears PTCAN
        case 25 % Allison 3000 SP P/PR - 6 gears PTCAN
        case 52 % G85-6S
        case 54 % G85NGR-6S
        case 80 % GO120-6S
        case 81 % ESO-6106A
            
        % GEARS_7
        case 51 % M130-7S Fuso manual
            
        % GEARS_8
        case 5  % G140-8K
        case 9  % GO240-8K or GO250-8K
        case 26 % UG100E
            
        % GEARS_9
        case 13 % G141-9S
        case 22 % ZF 9S - 1115
        case 53 % G131-9S
            
        % GEARS_12_OVERDRIVE
        case 1  % G230-12K
        case 3  % G330-12K
        case 48 % G340-12K
        case 50 % G320-12K
            
        % GEARS_12_DIRECTDRIVE
        case 0  % G211-12K
        case 2  % G281-12K
        case 47 % G291-12K
        case 49 % G271-12K
            
        % GEARS_16
        case 4  % G280-16K
        case 10 % G260-16S
        case 11 % G230-16S
        case 12 % G231-16S
            
        otherwise % maybe already supported, but not listed here yet
            warning('%s: unknown and unsupported transmission type', mfilename)
            
    end
else
    EEP = [];
end

% Definition of file names
CAL_FILE_CDS = 'cpc_cds.hex'; % Calibration Data Set file
CAL_FILE_DEF = 'cpc_init_def.txt'; % CAL parameter definition
CAL_FILE_VAL = 'cpc_init_val.txt'; % stored CAL parameter
CAL_DEBUG_DEF = 'cpc_init_debug.txt'; % CAL parameter definition for debug file
CAL_DEBUG_VAL = 'cpc_init_debug.csv'; % logged CAL parameter vs. time
CPC_TYPE = upper(mdl.CPC_TYPE);

% Detect used model type
if exist([CPC_TYPE '.DLL'], 'file')
    bTypeDLL = 1;
    SIM_FILE = 'cpc_sim.sil'; % Silver model for initialisation
else
    bTypeDLL = 0;
    SIM_FILE = 'cpc_sim.slx'; % Simulink model for initialisation
end

% Get current directory to change back to after running this function
sDir0 = pwd;

% Path of CAL Module
sDirCAL = fullfile(fileparts(mfilename('fullpath')), 'CAL');

% Prepare files to run CPC Module
copyfile(fullfile(sDirCAL, CAL_FILE_DEF), fullfile(sPathRunDir, CAL_FILE_DEF))
copyfile(fullfile(sDirCAL, CAL_DEBUG_DEF), fullfile(sPathRunDir, CAL_DEBUG_DEF))
copyfile(fullfile(sDirCAL, SIM_FILE), fullfile(sPathRunDir, SIM_FILE))
cd(sPathRunDir)

% Check CDS file format
xFileCDS = dir(CAL_FILE_CDS);
if xFileCDS.bytes ~= 1254901
    warning('Have you selected ..._TEST.hex file? Byte Size of 1.254.901 is expected');
end

% Run CPC for 10s
if nargout
    fprintf(1, 'CPC is running for 10s to get shift parameter ...\n');
else
    fprintf(1, 'CPC is running for 10s for some basic checks ...\n');
end
if bTypeDLL
    % Run Silver (full licence needed)
    sCmd = ['silversim -c -E 10 ' SIM_FILE];
    [status, cmdout] = dos(sCmd);
    if status
        disp(cmdout)
        error('CPC could not run in Silver with ''%s'' for some reason.\nTake a look above for details', sCmd) 
    end
    % Delete DLL from run directory again, only needed for CAL initialization
    % ---> 
    % DIVe Functions that create versionID in overall configuration XML
    % file don't like pdb created files in the Content folder 
    % --> versionID will be empty
    % --> DIve Perforce Upload Checks prevent uploading configuration XML
    % with empty versionID, therefore keep file in run directory. 
    % Although Silver is using DLL file directly from Content folder anyway, 
    % therefore it doesn't help here at the moment
    bKeepDLL = 1;
    if ~bKeepDLL
        delete([CPC_TYPE '.*']) % .dll and .pdb
    end
else
    % Define user config string for S-Function
    user_config = [ ...
        '-a cpc_eep.par' ...
        ' -b cpc_defaults.txt' ...
        ' -d ' CAL_FILE_CDS ...
        ' -f ' CAL_FILE_DEF ...
        ' -g ' CAL_FILE_VAL ...
        ' -h ' CAL_DEBUG_VAL ...
        ' -i ' CAL_DEBUG_DEF ...
        ' -j 10 -W 0 -X 0 -Y 0 -Z 5555' ...
        ];
    
    % Get Bus definition variable
    run([CPC_TYPE '_SFUN_PreLoadFcn'])
    a2l_1 = evalin('base', 'a2l_1');
    
    % Model is created by DIVe Script dmdModuleTest,
    % but any Callback, Inputs and Outputs are removed,
    % so no update is needed, if new In-/Outputs are defined
    
    % Clear S-Function: clear persistent variables from previous run
    clear([CPC_TYPE '_SFUN'])
    
    % Disable warnings
    xWarn = {};
    xWarn{end+1} = warning('off', 'Simulink:Engine:InputNotConnected');
    xWarn{end+1} = warning('off', 'Simulink:Engine:OutputNotConnected');
    % Run CPC for 10s
    sim(SIM_FILE, 'SrcWorkspace', 'current');
    % Reset warning states
    for n = 1:length(xWarn)
        warning(xWarn{n}.state, xWarn{n}.identifier)
    end
    % Close System, otherwise it may be still loaded in next simulation
    close_system(SIM_FILE)
    % Clear S-Function
    clear([CPC_TYPE '_SFUN'])
end

% Read info from Run
% cal1 = read_silver_par_file(CAL_FILE_VAL); % read Silver output file, only as info. Not used, because output is not always correct
cal = read_csv_par(CAL_DEBUG_VAL); % read Silver debug output file
try
    CDS_NAME = cpc_cds_name(EEP, cal); % get CDS Name
    fprintf('%s selected\n', CDS_NAME);
catch
    CDS_NAME = '';
end
% Show CDS Part Number
show_CDS_PartNo(cal)
% Check, if AG ModulState ok
checkModulState(cal, CDS_NAME) 
% Check other parameter
cal = checkPar(cal);

% Check if ptconf_g_RetSpd_u8 is in output variables
if isfield(cal, 'ptconf_g_RetSpd_u8')
    % Provide the retarder speed sample points for the function rcm2cpc
    mdl.r_rpm = cal.ptconf_g_RetSpd_u8;
    % Remove this output from CAL structure,
    % because it has nothing to do with Calibration Dataset for shifts
    cal = rmfield(cal, 'ptconf_g_RetSpd_u8');
end

% Disable CAL Module for complete CPC
cal.cal_m_EnCal_u8 = 0;
if nargout && isfield(EEP, 'ag_p_VehConf') && sum(EEP.ag_p_VehConf.SftPrgAv_u8 == 255) < 2
    % Only output this warning, if CAL is assigned in output (nargout > 0)
    warning('CPC will not bot be able to switch shift parameter between driving programs during simulation, because CAL module disabled');
end

% Clear folder of created files and change back to previous path
delete(SIM_FILE, CAL_FILE_DEF, CAL_FILE_VAL, CAL_DEBUG_DEF, CAL_DEBUG_VAL)
cd(sDir0)


function checkModulState(cal, CDS_NAME)
if cal.cal_o_AgModulState_u8 ~= 1
    sDef = {
        0 'Initialization'
        1 'finished without error'
        3 'finished with checksum error'
        9 'finished with variant error'
        16 'input value range error - module checks once again'
        21 'finished with input value range error'
        33 'finished with structure version not compatible error'
        64 'checksum calculation in progress'
        69 'finished with checksum calculation not ready error'
        };
    switch cal.cal_o_AgModulState_u8
        case 33
            error('Structure Version %d not compatible to CAL module', cal.cal_o_AgStructVersNr_u32);
        case 9
            if isempty(CDS_NAME)
                error('Engine-Emission-Transmission-Retarder-DrivingProgram variant not supported in CDS %d...%d', ...
                    cal.cal_o_AgStructVersNr_u32, cal.cal_o_AgActGrpNr_u32);
            else
                error('Combination %s not supported', CDS_NAME);
            end
        otherwise
            idx = find([sDef{:,1}] == cal.cal_o_AgModulState_u8);
            error('CAL: %s', sDef{idx,2}) %#ok<FNDSB>
    end
end


function [X] = checkPar(X)
% Check variables from initialization and remove variables again

% PTCONF
sVar = 'ptconf_g_SysStat_u8';
if isfield(X, sVar)
    if X.(sVar) == 2
        warning('CPC-PTCONF: variables initialized and errors detected (a set of variables has substitution or SNA values)')
    end
    X = rmfield(X, sVar);
end

sVar = 'ptconf_g_ErrPtcEepDatPos_u8';
if isfield(X, sVar)
    if X.(sVar) ~= 0
        try  %#ok<TRYNC>
            getErrPtcEepDatPos(X.(sVar));
        end
    end
    X = rmfield(X, sVar);
end

% ITPM
sVar = 'itpm_m_VehParCheck_u8';
if isfield(X, sVar)
    if X.(sVar) ~= 0
        warning('CPC-ITPM: VehParCheck failed')
    end
    X = rmfield(X, sVar);
end

sVar = 'itpm_m_VehParCheckDiag_u16';
if isfield(X, sVar)
    cVehParCheckDiag = {
        'Eng'
        'Clutch'
        'Trans'
        'Ret'
        'Pmr'
        'TransCase'
        'ShftTireStff'
        'Axle'
        'WheelNum'
        'DynWheelRad'
        'VehMass'
        'Vehicle'
        'Emot'
        };
    idx = find(fliplr(dec2bin(X.(sVar))) == '0');
    for k = idx
        fprintf(1, 'Please check %s\n', cVehParCheckDiag{k});
    end
    X = rmfield(X, sVar);
end


function show_CDS_PartNo(cal)
% Show CDS Part Number
try %#ok<TRYNC>
    sParNo = 'A0000000000-000';
    y = 2;
    for x = 1:13
        sVar = sprintf('cal_g_AgMbs%d_u8', x);
        sParNo(y) = char(cal.(sVar));
        y  = y + 1;
        if x == 10 % Part number Index after position 10
            y = y + 1;    
        end
    end
    sDate = sprintf('Y20%02d - W%02d', cal.cal_g_AgYear_u8, cal.cal_g_AgWeek_u8);
    fprintf('CDS Part number: %s (%s)\n', sParNo, sDate);
end