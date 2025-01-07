function sMsg = runMatlab(sRun,varargin)
% RUNMATLAB issue Matlab command in a new Matlab instance, while aligning version specific startup
% options.
%
% Syntax:
%   runMatlab(sRun,varargin)
%
% Inputs:
%              sRun - string with run command
%          sRelease - [optional] value string of key "release" with Matlab release to start
%          sLogfile - [optional] value string of key "logfile" with filepath of logfile for new Matlab instance
%        sPathStart - [optional] value string of key "startpath" with path of Matlab startup path
%            bBatch - [optional] value boolean of key "batch" if batch mode should be used (>=R2019b)
%              wait - [optional] value boolean of key "wait" if wait option should be applied
%         noDesktop - [optional] value boolean of key "noDesktop" to start only command line (still
%                     allows for Simulink ussage
%        automation - [optional] value boolean of key "automation" if matlab automation server
%                     should be used
%   releaseInstance - [optional] value boolean of key "releaseInstance" dos shell should be release
%                     for further use (apply & at end of call)
%
% Outputs:
%
% Example: 
%   runMatlab('disp(''Hello World''),quit')
%   runMatlab('disp(''Hello World''),quit','release','R2016a')
%   runMatlab('disp(''Hello World''),quit','release','R2016a','logfile',fullfile(pwd,'Example.log'))
%   runMatlab('pwd,disp(''Hello World''),quit','release','R2016a','logfile',fullfile(pwd,'Example.log'),'startpath','c:\temp\')
% 
% See also: run, exit, getMatlabInstallations, versionAliasMatlab 
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-8485-3325
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2022-06-22

% check input
xArg = parseArgs({'release','R2016a',[];...
                  'batch',false,[];... % available since R2019b
                  'noDesktop',false,[];...
                  'automation',false,[];...
                  'releaseInstance',false,[];...
                  'wait',false,[];...
                  'logfile','runMatlab.log',[];...
                  'startpath','',[]},... % available since R2019b
                  varargin{:});
xArg.version = versionAliasMatlab(xArg.release);

% determine Matlab version executable
cVersion = getMatlabInstallation;
%   cVersionAll - cell (nx6) with string of MATLAB installation instances
%               m = 1: string with filepath of executable
%                   2: string with installation path
%                   3: string with release
%                   4: string with version
%                   5: string with bit variant (32 or 64; based on
%                      assumption 32bit in doubt)
%                   6: string with installation folder
bVersion = strcmpi(xArg.release,cVersion(:,3));

% base start options
sBase = '-nosplash';
if xArg.noDesktop
    sBase = [sBase ' -nodesktop'];
end
if xArg.automation
    sBase = [sBase ' -automation'];
end
if xArg.wait
    sBase = [sBase ' -wait'];
end

% run call of matlab version
if isempty(xArg.startpath)
    sRunFull = sprintf('-r "%s"',sRun);
elseif verLessThanOther(xArg.version,'9.7')
    sRunFull = sprintf('-r "cd(''%s'');%s"',xArg.startpath,sRun);
else
    if xArg.batch
        sRunFull = sprintf('-sd "%s" -batch "%s"',xArg.startpath,sRun);
    else
        sRunFull = sprintf('-sd "%s" -r "%s"',xArg.startpath,sRun);
    end
end
if ~isempty(xArg.logfile)
    sRunFull = [sRunFull sprintf(' -logfile "%s"',xArg.logfile)];    
end

if xArg.releaseInstance
    sRunFull = [sRunFull '&'];
end

% system call
sCall = sprintf('"%s" %s %s',cVersion{bVersion,1},sBase,sRunFull);
[nStatus,sMsg] = system(sCall);
if nStatus
    fprintf(2,'Error in runMatlab: %s\nFrom Call: %s\n',sMsg,sCall);
end
return

% ==================================================================================================