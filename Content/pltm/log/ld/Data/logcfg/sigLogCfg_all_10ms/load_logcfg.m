% DIVeLDYN signal logging configuration
%
%	sigLogCfg.decimation	- signal logging decimation factor (default = 1)
%								[] or 1 - no decimation (log all values)
%									 >1	- logging is decimated by the specified factor (log every Nth value)
%										  Mind interference with sample time!
%
%	sigLogCfg.lastvalue		- signal logging last value factor (default = [])
%								[]	- log all values
%								>1	- log the last N values
%
%	sigLogCfg.sampletime 	- signal logging sample time factor (default = -1)
%								-1	- inherited (signal resolution is used for logging)
%								 0	- continuous (interpolation method: zero-order hold), hold each value for one sample interval
%								>0	- discrete (interpolation method: linear), log a value each x seconds
%									  Do not specify a sample time for frame-based signals and conditional subsystems! Mind interference with decimation!
%
%	sigLogCfg.sig 			- signal logging configuration:
%								cell array nx2, <signalName / 'all'>, <ModuleSpecies / 'all'>
% Example:
% sigLogCfg.sig = {
%     'drv_AccPdl_pos', 'drv'
%     'all', 'cpc'};
% sigLogCfg.sig = {'all','all'};
%
% note: the following signals have to be always enabled
%       {'drv_simulationEnd_sta','drv'};...
%       {'drv_simulationSuccLvl_sta','drv'};...
%       {'drv_track_enable_sta','drv'};...
%
% Default (minimum) logging dataset for all simulations
sigLogCfg.decimation=1;
sigLogCfg.lastvalue=[];
sigLogCfg.sampletime=0.02;
sigLogCfg.sig = [
{'all','all'};...
];