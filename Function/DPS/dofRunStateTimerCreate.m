function hStateTimer = dofRunStateTimerCreate(hClock,sEndpoint,sToken,sSimId,sPathRun,sHost,hSlope)
% DOFRUNSTATETIMERCREATE creates a timer to provide feedback of current simulation time to DIVeONE.
%
% Syntax:
%   dofRunStateTimerCreate(hClock,sEndpoint,sToken,sSimId)
%
% Inputs:
%      hClock - handle or string with Simulink block (clock, output: current simulation time) 
%   sEndpoint - string with simulation endpoint of DIVeONE instance
%      sToken - string with DIVeONE token
%      sSimId - string with DIVeONE simulation ID
%    sPathRun - string with runtime folder of this simulation
%       sHost - string with name of executing host/computer
%      hSlope - handle or string with Simulink block (road slope lookup of env Module for vehicle 
%               simulation, input: current vehicle postion)
%
% Outputs:
%      hClock - handle (1x1) 
% Example: 
%   dofRunStateTimerCreate(hClock,sEndpoint,sToken,sSimId)

% transform input into structure for storage and handling
xTimer.clock = hClock;
xTimer.diveOneSimulationEndpoint = sEndpoint;
xTimer.diveOneToken = sToken;
xTimer.diveOneSimulationId = sSimId;
xTimer.pathRun = sPathRun;
xTimer.host = sHost;
xTimer.slope = hSlope;

% timer definition
hStateTimer = timer(...
    'Name','dofRunStateTimer',...
    'TimerFcn',@RunStateTimerFcn,...
    'StartDelay',30,...
    'BusyMode','queue',...
    'ExecutionMode','fixedRate',...
    'Period',30,...
    'TasksToExecute',Inf,...
    'UserData',xTimer,...
    'Tag','dofRunStateTimer');

% start timer
start(hStateTimer);
dofSimulationStateUpdate(xTimer,'nState',2,'sNote','Simulation start ...');
return

% ==================================================================================================

function RunStateTimerFcn(hTimer,varargin)
% RUNSTATETIMERFCN determines the current simulation time of the referenced Simulink model and
% reports it as heartbeat to DIVeONE Simulation overview.
%
% Syntax:
%   RunStateTimerFcn(hTimer,varargin)
%
% Inputs:
%     hTimer - handle (1x1) 
%   varargin - 
%
% Outputs:
%
% Example: 
%   RunStateTimerFcn(hTimer,varargin)

% get data from timer
xTimer = get(hTimer,'UserData');

% try to retrieve current Simulink simulation time
try
    oRun = get_param(xTimer.clock,'RunTimeObject');
    if isempty(oRun)
        vTime = [];
    else
        vTime = get(oRun.OutputPort(1),'DataAsDouble');
    end
catch ME
    vTime = [];
    fprintf(1,'RunStateTimer Error: %s\n',ME.message);
end
        
% try to retrieve current Simulink vehicle position
try
    oRunSlope = get_param(xTimer.slope,'RunTimeObject');
    if isempty(oRunSlope)
        vPosition = [];
    else
        vPosition = get(oRunSlope.InputPort(1),'DataAsDouble');
    end
catch ME
    vPosition = [];
    fprintf(1,'RunStateTimer Error on position: %s\n',ME.message);
end

% retrieve sMP structure data for advanced feedback
sMP = evalin('base','sMP');
vTimeEnd = [];
if isfield(sMP,'cfg') && isfield(sMP.cfg,'Configuration') && ...
        isfield(sMP.cfg.Configuration,'MasterSolver') && ...
        isfield(sMP.cfg.Configuration.MasterSolver,'timeEnd')
    sTimeEnd = sMP.cfg.Configuration.MasterSolver.timeEnd;
    if ~strcmpi('inf',sTimeEnd)
        vTimeEnd = str2double(sTimeEnd);
    end
end
vTrackEnd = [];
if isfield(sMP,'bdry') && isfield(sMP.bdry,'env') && ...
        isfield(sMP.bdry.env,'road') && ...
        isfield(sMP.bdry.env.road,'m_Way') 
    vTrackEnd = sMP.bdry.env.road.m_Way(end);
end
vDateStart = [];
if isfield(sMP,'cfg') && isfield(sMP.cfg,'run') && ...
        isfield(sMP.cfg.run,'start') 
    vDateStart = sMP.cfg.run(end).start;
end

% generate mouseover notice for DIVeONE with heartbeat and estimate
vPercent = 0;
if isnumeric(vTime) && ~isempty(vTime)
    if isnumeric(vPosition) && ~isempty(vPosition)
        if isempty(vTrackEnd)
            sNote = sprintf('heartbeat: %2.0fm, %2.0fs',vPosition,vTime);
        else % end of track known
            vPercent = vPosition/vTrackEnd*100;
            sNote = sprintf('heartbeat: %4.1f%% [%s|%s, %2.0fs]',vPercent,distance(vPosition),distance(vTrackEnd),vTime);
        end
    else
        if isempty(vTimeEnd)
            sNote = sprintf('heartbeat: %2.0fs',vTime);
        else % end time known
            vPercent = vTime/vTimeEnd*100;
            sNote = sprintf('heartbeat: %4.1f%% [%2.0fs|%2.0fs]',vPercent,vTime,vTimeEnd);
        end
    end
else
    sNote = 'heartbeat - runtime object not (yet?) available';
end
if vPercent > 2 && ~isempty(vDateStart)
    vEstimate = vDateStart + (now - vDateStart)/vPercent*100;
    sEstimate = datestr(vEstimate,'HH:MM yyyy-mm-dd');
    sNote = [sNote ', est. end ' sEstimate];
end
% status update for DIVeONE simulation overview
dofSimulationStateUpdate(xTimer,'nState',2,'sNote',sNote);

% check for cancel state of simulation in DIVeONE
if ~dofSimulationContinue(xTimer)
    % set cancel request in Simulink
    fprintf(1,'Simulation cancel request via DIVeONE Simulation Overview detected at simulation time %4.1fs.\n',vTime);
    cBlock = find_system(bdroot(gcs),'LookUnderMasks','all','SearchDepth',2,'Tag','Simulation_Cancel');
    if isempty(cBlock)
        fprintf(1,'Cancelation block was not found\n')
    else
        set_param(cBlock{1},'Value','1');
    end
end
return

 % =================================================================================================
 
function sDistance = distance(vDistance)
% DISTANCE format distance according value
%
% Syntax:
%   sDistance = distance(vDistance)
%
% Inputs:
%   vDistance - double value (1x1) of distance in meters
%
% Outputs:
%   sDistance - string with appropriate formatted value and unit
%
% Example: 
%   sDistance = distance(123)


if vDistance < 10
    sDistance = sprintf('%2.1fm',vDistance);
elseif vDistance < 1000
    sDistance = sprintf('%2.0fm',vDistance);
elseif vDistance < 1e4
    sDistance = sprintf('%2.1fkm',vDistance*0.001);
else
    sDistance = sprintf('%2.0fkm',vDistance*0.001);
end
return
