function [] = nlxCall_cpc_family(varargin)

% Get sMP structure from base workspace and set paths of parameter slots
sMP = evalin('base','sMP');

% Add CPC Support Set path
addpath(fullfile(fileparts(mfilename('fullpath')), 'cpc'))

% Version
[ver.release, ver.version, ver.desc] = cpc_info;
sMP.ctrl.cpc.version = sprintf('%s / %s / %s', ver.release, ver.version, ver.desc);

% Update sMP structure in base workspace
assignin('base','sMP',sMP);

