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

% calculate key performance
if xRun.start == -1 % error in initialization
    vStopVec = dateVecSubtract(datevec(xRun.end),datevec(xRun.init));
    vInitVec = dateVecSubtract(datevec(xRun.end),datevec(xRun.init));
else
    vStopVec = dateVecSubtract(datevec(xRun.end),datevec(xRun.start));
    vInitVec = dateVecSubtract(datevec(xRun.start),datevec(xRun.init));
end
vVec2Sec = [31536000 2592000 86400 3600 60 1]';
vStop = vStopVec * vVec2Sec;
vInit = vInitVec * vVec2Sec;
vFRealTime = vStop/vEnd(1);

% display message on command line
if xRun.start == -1 % error in initialization
    umsMsg('DIVe',1,['Simulation failed likely during initialization. ' ...
                     'Initialization took %4.2fs.\n'],vInit);
else
    umsMsg('DIVe',1,['Simulation needed %4.2fs for %4.2fs simulated '...
        'time and initialization of %4.2fs.\n'],vStop,vEnd(1),vInit);
    umsMsg('DIVe',1,'Simulation performance was realtime = %4.2f * simulated time \n',vFRealTime);
end
if vStopVec(3) > 0
    umsMsg('DIVe',1,'Total time: %id %02i:%02i:%02.0fh\n',vStopVec(3:6));
else
    umsMsg('DIVe',1,'Total time: %02i:%02i:%02.0fh\n',vStopVec(4:6));
end
umsMsg('DIVe',1,['Current time is: ' datestr(now)]);
return

% =========================================================================

function vDuration = dateVecSubtract(vDate1,vDate2)
% DATEVECSUBTRACT subtraction of datevecs to determine simulation periods.
% Accounts for different days in months, but not for leap years.
%
% Syntax:
%   vDuration = dateVecSubtract(vDate1,vDate2)
%
% Inputs:
%   vDate1 - vector (1x6) with datevec of end time point
%   vDate2 - vector (1x6) with datevec of start time point
%
% Outputs:
%   vDuration - vector (1x6) with datevec of duration
%
% Example: 
%   vDuration = dateVecSubtract([2019 2 28 17 2 15],[2019 3 1 6 1 1])

vDuration = vDate1 - vDate2;

% compensate negative rollover
vNeg = [0 12 30 24 60 60];
vMonth = [31 28 31 30 31 30 31 31 30 31 30 31];
for nIdxPos = numel(vDuration):-1:2
    if vDuration(nIdxPos) < 0
        if nIdxPos == 3 % turnover negative days to month
            vDuration(nIdxPos) = vDuration(nIdxPos) + vMonth(vDate2(nIdxPos-1));
            vDuration(nIdxPos-1) = vDuration(nIdxPos-1) - 1;
        else % standard turnover (no leap year correction)
            vDuration(nIdxPos) = vDuration(nIdxPos) + vNeg(nIdxPos);
            vDuration(nIdxPos-1) = vDuration(nIdxPos-1) - 1;
        end
    end
end
return

