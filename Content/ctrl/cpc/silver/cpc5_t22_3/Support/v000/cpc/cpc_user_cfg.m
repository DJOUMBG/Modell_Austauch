function [user_config] = cpc_user_cfg(x)
% CPC_USER_CFG create user_config for CPC
% user_config used in Simulink mask for S-Function in Matlab/Simulink, 
% but also as parameter defintion for DLL in Silver
%
% -a	: Parameter File; required: yes; default: 0;
% -b	: Init Value File; required: yes; default: 0;
% -c	: Par Default File; required: yes; default: 0;
% -d	: Calibration Data Set; required: yes; default: 0;
% -e	: CDStxtFileOutput; required: yes; default: 0;
% -f	: Names of signals to save after simulation; required: yes; default: 0;
% -g	: Target file to save signals after simulation; required: yes; default: 0;
% -h	: Debugging Output File; required: yes; default: 0;
% -i	: Debugging Definition File; required: yes; default: 0;
% -j	: Debugging Step Size; required: yes; default: 0;
%
%
% Syntax:  [user_config] = cpc_user_cfg(x)
%
% Inputs:
%              x - [.] cpc struct
%
% Outputs:
%    user_config - [''] user config string
%
% Example: 
%    cpc.user_config = cpc_user_cfg(cpc);
%    sMP.ctrl.cpc.user_config = cpc_user_cfg(sMP.ctrl.cpc);

% Author: PLOCH37
% Date:   22-Sep-2022

%% ------------- BEGIN CODE --------------

% Optional CAL par file
if isempty(x.CAL)
    sCAL = '';
else
    sCAL = '-c cpc_cal.par ';
end

% Debug output file (mf4, mdf or csv)
if isfield(x.debug, 'filetype')
    sDebugOut = ['-h cpc_debug.' x.debug.filetype ' '];
else
    sDebugOut = ['-h cpc_debug.csv '];
end

% Debug step size
sDebugStep = sprintf('-j %g ', x.debug.step_size);

% User Config String for S-Function or DLL
user_config = [
    '-a cpc_eep.par ' ...
    '-b cpc_defaults.txt ' ...
    sCAL ...
    '-d cpc_cds.hex ' ...
    '-f cpc_out_def.txt ' ...
    '-g cpc_out_val.txt ' ...
    sDebugOut ...
    '-i cpc_debug.txt ' ...
    sDebugStep ...
    '-W 0 -X 0 -Y 0 -Z 5555'];
% disp(user_config)
