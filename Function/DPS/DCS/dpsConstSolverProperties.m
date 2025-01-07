function xSolver = dpsConstSolverProperties
% DPSCONSTSOLVERPROPERTIES creates a structure with predefined DIVe client
% solver names, which have been agreed and aligned in the DIVe CoreTeam.
%
% Syntax:
%   xSolver = dpsConstSolverProperties
%
% Inputs:
%
% Outputs:
%   xSolver - structure with fields: 
%     .Simulink - struct with parameters for Simulink
%     .Silver   - struct with parameters for Silver
%       .parameter - struct with parameter name/value pairs
%         .name - string
%         .value - string
%
% Example: 
%   xSolver = dpsConstSolverProperties
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2015-07-25

nIdx = 1;
xSolver(nIdx).name = 'FixedStep01';
nPar = 1;
% xSolver(nIdx).Simulink.parameter(nPar).name = 'Type'; % no real mdl value
% xSolver(nIdx).Simulink.parameter(nPar).value = 'Fixed-step';
% nPar = nPar + 1;
xSolver(nIdx).Simulink.parameter(nPar).name = 'Solver';
xSolver(nIdx).Simulink.parameter(nPar).value = 'ode1';
nPar = nPar + 1;
xSolver(nIdx).Simulink.parameter(nPar).name = 'SolverName';
xSolver(nIdx).Simulink.parameter(nPar).value = 'ode1';
nPar = nPar + 1;
xSolver(nIdx).Simulink.parameter(nPar).name = 'SolverMode';
xSolver(nIdx).Simulink.parameter(nPar).value = 'SingleTasking';
nPar = 1;
xSolver(nIdx).Silver.parameter(nPar).name = 'Solver';
xSolver(nIdx).Silver.parameter(nPar).value = 'ode1';
nPar = nPar + 1;
xSolver(nIdx).Silver.parameter(nPar).name = 'SolverName';
xSolver(nIdx).Silver.parameter(nPar).value = 'ode1';

nIdx = nIdx + 1;
xSolver(nIdx).name = 'FixedStep02';
nPar = 1;
% xSolver(nIdx).Simulink.parameter(nPar).name = 'Type'; % no real mdl value
% xSolver(nIdx).Simulink.parameter(nPar).value = 'Fixed-step';
% nPar = nPar + 1;
xSolver(nIdx).Simulink.parameter(nPar).name = 'Solver';
xSolver(nIdx).Simulink.parameter(nPar).value = 'ode2';
nPar = nPar + 1;
xSolver(nIdx).Simulink.parameter(nPar).name = 'SolverName';
xSolver(nIdx).Simulink.parameter(nPar).value = 'ode2';
nPar = nPar + 1;
xSolver(nIdx).Simulink.parameter(nPar).name = 'SolverMode';
xSolver(nIdx).Simulink.parameter(nPar).value = 'SingleTasking';
nPar = 1;
xSolver(nIdx).Silver.parameter(nPar).name = 'Solver';
xSolver(nIdx).Silver.parameter(nPar).value = 'ode3';
nPar = nPar + 1;
xSolver(nIdx).Silver.parameter(nPar).name = 'SolverName';
xSolver(nIdx).Silver.parameter(nPar).value = 'ode3';

nIdx = nIdx + 1;
xSolver(nIdx).name = 'VariableStep01';
nPar = 1;
% xSolver(nIdx).Simulink.parameter(nPar).name = 'Type'; % no real mdl value
% xSolver(nIdx).Simulink.parameter(nPar).value = 'Variable-step';
% nPar = nPar + 1;
xSolver(nIdx).Simulink.parameter(nPar).name = 'Solver';
xSolver(nIdx).Simulink.parameter(nPar).value = 'ode23';
nPar = nPar + 1;
xSolver(nIdx).Simulink.parameter(nPar).name = 'SolverName';
xSolver(nIdx).Simulink.parameter(nPar).value = 'ode23';
nPar = nPar + 1;
xSolver(nIdx).Simulink.parameter(nPar).name = 'SolverMode';
xSolver(nIdx).Simulink.parameter(nPar).value = 'SingleTasking';
nPar = 1;
xSolver(nIdx).Silver.parameter(nPar).name = 'Solver';
xSolver(nIdx).Silver.parameter(nPar).value = 'CVode';
nPar = nPar + 1;
xSolver(nIdx).Silver.parameter(nPar).name = 'SolverName';
xSolver(nIdx).Silver.parameter(nPar).value = 'cvode';

nIdx = nIdx + 1;
xSolver(nIdx).name = 'VariableStep02stiff';
nPar = 1;
% xSolver(nIdx).Simulink.parameter(nPar).name = 'Type'; % no real mdl value
% xSolver(nIdx).Simulink.parameter(nPar).value = 'Variable-step';
% nPar = nPar + 1;
xSolver(nIdx).Simulink.parameter(nPar).name = 'Solver';
xSolver(nIdx).Simulink.parameter(nPar).value = 'ode23tb';
nPar = nPar + 1;
xSolver(nIdx).Simulink.parameter(nPar).name = 'SolverName';
xSolver(nIdx).Simulink.parameter(nPar).value = 'ode23tb';
nPar = nPar + 1;
xSolver(nIdx).Simulink.parameter(nPar).name = 'SolverMode';
xSolver(nIdx).Simulink.parameter(nPar).value = 'SingleTasking';
nPar = 1;
xSolver(nIdx).Silver.parameter(nPar).name = 'Solver';
xSolver(nIdx).Silver.parameter(nPar).value = 'CVode';
nPar = nPar + 1;
xSolver(nIdx).Silver.parameter(nPar).name = 'SolverName';
xSolver(nIdx).Silver.parameter(nPar).value = 'cvode';

nIdx = nIdx + 1;
xSolver(nIdx).name = 'ModuleInternal';
xSolver(nIdx).Simulink.parameter = struct('name',{},'value',{});
xSolver(nIdx).Silver.parameter = struct('name',{},'value',{});
return
