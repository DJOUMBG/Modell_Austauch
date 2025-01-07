function executeMatlabPostScript(sScriptFilepath,sResultPath,sLogFile)
% EXECUTEMATLABPOSTSCRIPT executes the given matlab post processing
% function with result paths as its argument and writes the command window
% output into the given log file.
% If there is any error the function terminates with returncode 1, if there
% is no error it terminates with 0.
%   This function can be used to call matlab post processing functions from
%   command window, Python or any other system call and capture its output.
% 
%
% Syntax:
%   executeMatlabPostScript(sScriptFilepath,sResultPath,sLogFile)
%
% Inputs:
%   sScriptFilepath - string: filepath of post processing matlab function 
%       sResultPath - string: result folder, argument of the matlab function 
%          sLogFile - string: filepath of the log file, where the output is written 
%
% Outputs:
%
% Example: 
%   executeMatlabPostScript(sScriptFilepath,sResultPath,sLogFile)
%
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2023-03-22

%% create log diary

% check if log file already exists
if exist(sLogFile,'file')
    % delete older log file
    delete(sLogFile);
end

% create new log file
diary(sLogFile);
oCloseDiary = onCleanup(@() diary('off'));


%% execute post processing script
try
    
    % check result folder
    if ~exist(sResultPath,'dir')
        error('Result folder "%s" does not exist.',sResultPath);
    end
    
    % check post scirpt file
    if ~exist(sScriptFilepath,'file')
        error('Path of script "%s" does not exist.',sScriptFilepath);
    end
    
    % get paths
    [sScriptPath,sScriptName,~] = fileparts(sScriptFilepath);
    
    % execute post processing script
    addpath(sScriptPath);
    feval(sScriptName,sResultPath);
    rmpath(sScriptPath);
    
    % return success code
    diary('off');
    quit(0);
    
catch ME
    
    % display error message
    fprintf(2,'Error during execution of pltm.post script "%s":\n%s',...
        sScriptFilepath,ME.message);
    
    % return error code
    diary('off');
    quit(1);
    
end

return