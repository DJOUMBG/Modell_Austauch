function [vStop,vInit,vFRealTime] = dpsSimTimeDisp(xRun,vEnd)
% DPSSIMTIMEDISP display time information on simulation duration and
% performance on commandline.
%
% Syntax:
%   [vStop,vInit,vFRealTime] = dpsSimTimeDisp(xRun,vEnd)
%
% Inputs:
%   xRun - structure (1x1) with fields:
%     .init  - value (1x1) with timestamp of initialization (now)
%     .start - value (1x1) with timestamp of simulation start (now)
%     .end   - value (1x1) with timestamp of simulation end (now) 
%   vEnd - value (1x1) with simulated time in seconds
%
% Outputs:
%        vStop - value (1x1) with simulation duration in seconds
%        vInit - value (1x1) with simulation initialization in seconds
%   vFRealTime - value (1x1) with real time factor of simulation
% 
% Example: 
%   dpsSimTimeDisp(struct('init',{now},'start',{now+0.02},'end',{now+0.8}),120)
%   [vStop,vInit,vFRealTime] = dpsSimTimeDisp(struct('init',{now},'start',{now+0.02},'end',{now+0.8}),120)
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2015-10-07

% input check
vStopVec = datevec(xRun.end - xRun.start);
vInitVec = datevec(xRun.start - xRun.init);
vVec2Sec = [0 2592000 86400 3600 60 1]';
vStop = vStopVec * vVec2Sec;
vInit = vInitVec * vVec2Sec;
vFRealTime = vStop/vEnd;

% display message on command line
umsMsg('DIVe',1,['Simulation needed %4.2fs for %4.2fs simulated '...
           'time and initialization of %4.2fs.\n'],vStop,vEnd,vInit);
umsMsg('DIVe',1,'Simulation performance was realtime = %4.2f * simulated time \n',vFRealTime);
if vStopVec(3) > 0
    umsMsg('DIVe',1,'Total time: %4.2fd %f02.0:%f02.0:%f02.0h\n',vStopVec(3:6));
else
    umsMsg('DIVe',1,'Total time: %02.0f:%02.0f:%02.0fh\n',vStopVec(4:6));
end
umsMsg('DIVe',1,['Current time is: ' datestr(now)]);
return
