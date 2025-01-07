% DIVeLDYN solver settings
% 
% solverCfg.Solver - Solver name
% solverCfg.SolverType - Solver type 
% solverCfg.SolverMode - Tasking mode for periodic sample times
% solverCfg.FixedStep - Fixed-step size (fundamental sample time)
% solverCfg.StartTime - Simulation start time
% solverCfg.StopTime - Simulation stop time
%
% default solver settings for all simulations

solverCfg.SolverType = 'Fixed-step';
solverCfg.Solver = 'ode1';
solverCfg.SolverMode = 'SingleTasking';
solverCfg.FixedStep = '0.001';
solverCfg.StartTime = '0.0';
solverCfg.StopTime = 'inf';