function dpsModelSolverOptions(hSystem,sSolver,sMaxCosimStepsize,sStopTime)
% DPSMODELSOLVEROPTIONS set solver and runtime option for DIVe MB
% Simulink models. Re-used in dmdModuleTest and buildDIVeSfcn.
%
% Syntax:
%   dpsModelSolverOptions(hSystem,sSolver,sMaxCosimStepsize,sStopTime)
%
% Inputs:
%             hSystem - handle of system to set solver settings and options 
%             sSolver - string with DIVe solver option
%   sMaxCosimStepsize - string with maximum co-simulation stepsize
%           sStopTime - string with end time value of simulation
%
% Outputs:
%
% Example: 
%   dpsModelSolverOptions(hSystem,sSolver,sMaxCosimStepsize,sStopTime)
%
% See also: dpsConstSolverProperties
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2016-01-18

%% Simulink model options
cOptions = {...
           'SaveTime','on',... % Data Import/Export (evaluate simulation performance)
           'TimeSaveName','tout',... % Data Import/Export (evaluate simulation performance)
           'SignalLogging','off',... % Data Import/Export (reduce RAM impact)
           'SaveFinalState','off',... % Data Import/Export (reduce RAM impact)
           'SaveState','off',... % Data Import/Export (reduce RAM impact)
           'SaveOutput','off',... % Data Import/Export (reduce RAM impact)
           'DSMLogging','off',... % Data Import/Export (reduce RAM impact)
           'LimitDataPoints','on',... % Data Import/Export (reduce RAM impact)
           'MaxDataPoints','10',... % Data Import/Export (reduce RAM impact)
           'BlockReduction','off',... % Optimization (problem with compiler/external logging?)
           'BlockReductionOpt','off',... % Optimization (problem with compiler/external logging?)
           'BufferReuse','off',... % Optimization (problem with compiler/external logging?)
           'BooleanDataType','off',... % Optimization
           'OptimizeBlockIOStorage','off',... % Optimization >> Simulation and Code generation: Signal storage reuse
           'ExpressionFolding','off',... % Optimization >> Code Generation >> Signals (only with real time workshop)
           'LocalBlockOutputs','off',... % Optimization >> Code Generation >> Signals (only with real time workshop)
           'InitFltsAndDblsToZero','on',... % Optimization >> Code Generation >> Data initalisation (only with real time workshop)
           'MultiTaskRateTransMsg','warning',... % Diagnostics >> Sample Time
           'MultiTaskCondExecSysMsg','warning',... % Diagnostics >> Sample Time (VehEMent)
           'StrictBusMsg','Warning',... % Diagnostics >> Connetcivity >> Buses (due to dirty MCM)
           'ParameterPrecisionLossMsg','none',... Diagnostics >> Data Validity >> Parameters (due to CPC SiL)
           'CheckSSInitialOutputMsg','off',... Diagnostics >> Data Validity >> Model Initialization (new for MCM)
           'SaveWithDisabledLinksMsg','none',... % Diagnostics >> Saving
           'SaveWithParameterizedLinksMsg','none',... % Diagnostics >> Saving
           'SimParseCustomCode','off',... % Simulation Target >> Custom Code
           'SortedOrder','on',... % display order of model blocks in block diagram
           'LibraryLinkDisplay','all'}; % display library link state
set_param(hSystem,cOptions{:});

if ~verLessThanMATLAB('8.3')
     % Diagnostics >> Connectivity >> Buses (NEEDS TO CHANGE FOR R2014a!!!) 
    set_param(hSystem,'StrictBusMsg','ErrorLevel1')
end

if ~verLessThanMATLAB('9.6')
     % Changed default value in Simulink starting with R2019a - otherwise
     % ToWorkspace output vectors are aggregated in an object
    set_param(hSystem,'ReturnWorkspaceOutputs','off')
end

%% Stateflow model options
if license('test','stateflow') % check for stateflow license
    % Stateflow related model options
    cOptions = {...
                'SFSimEnableDebug','off',... % Simulation Target >> Enable debugging/animation: disable stateflow debbuging completely
                'SFSimEcho','off'}; % Simulation Target >> Echo expressions without semicolon: do not display return of code not ended with semicolon
    if verLessThanMATLAB('8.6')
        cOptionAdd = {'SFSimOverflowDetection','off'}; % Simulation Target >> Enable overflow detection (with debugging): CAUTION - may be needed for fix point models
    else
        cOptionAdd = {'IntegerOverflowMsg','off'}; % Simulation Target >> Enable overflow detection (with debugging): CAUTION - may be needed for fix point models
    end
    cOptions = [cOptions, cOptionAdd];
    set_param(hSystem,cOptions{:});
    
    % set stateflow object properties
    oStateflow = find(sfroot,'-isa','Stateflow.Machine','Name',hSystem);
    if ~isempty(oStateflow)
        oStateflow.Debug.RunTimeCheck.DataRangeChecks = 0;
        if verLessThanMATLAB('8.6')
            oStateflow.Debug.RunTimeCheck.TransitionConflicts = 0;
        end
    else
        fprintf(1,'Comment: No Stateflow statemachine defined in Simulink model!\n');
    end
end
    
%% model browser settings
cBrowser = {'ModelBrowserVisibility','on',...
           'BrowserShowLibraryLinks','on',...
           'BrowserLookUnderMasks','on'};
if verLessThanMATLAB('9.13') % fails on R2022b Update 2 
           cBrowser = [cBrowser,{'ModelBrowserWidth',250}];
end
set_param(hSystem,cBrowser{:});

%% solver settings
% get standard settings of solver
xSolver = dpsConstSolverProperties;

% create current solver settings
bSolver = strcmp(sSolver,{xSolver.name});
cSolver = cell(numel(xSolver(bSolver).Simulink.parameter),2);
for nIdxPar = 1:numel(xSolver(bSolver).Simulink.parameter)
    cSolver{nIdxPar,1} = xSolver(bSolver).Simulink.parameter(nIdxPar).name;
    cSolver{nIdxPar,2} = xSolver(bSolver).Simulink.parameter(nIdxPar).value;
end
% set stepsize to correct attribute
if numel(sSolver) >= 9 && strcmp(sSolver(1:9),'FixedStep')
    cSolver = [cSolver; {'FixedStep',sMaxCosimStepsize}];
elseif numel(sSolver) >= 12 && strcmp(sSolver(1:12),'VariableStep')
    cSolver = [cSolver; {'MaxStep',sMaxCosimStepsize}]; %num2str(vMaxCosimStepsize) 
    cSolver = [cSolver; {'MinStep','Auto'}];
    cSolver = [cSolver; {'InitialStep','Auto'}];
end
% add end time
cSolver = [cSolver; {'StopTime',sStopTime}];
cSolver = reshape(cSolver',1,[]);

% set solver paremetersd
set_param(hSystem,cSolver{:});
return
                  