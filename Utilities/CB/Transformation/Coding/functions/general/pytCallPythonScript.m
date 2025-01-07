function [bSuccess,sOutput] = pytCallPythonScript(sPythonExe,sScriptFilepath,bEcho,cArgs)
% PYTCALLPYTHONSCRIPT calls given python script with given python exe and
% argument list.
%
% Syntax:
%   [bSuccess,sOutput] = pytCallPythonScript(sPythonExe,sScriptFilepath,bEcho,cArgs)
%   [bSuccess,sOutput] = pytCallPythonScript(sPythonExe,sScriptFilepath,bEcho)
%
% Inputs:
%        sPythonExe - string: filepath of python exe file 
%   sScriptFilepath - string: filepath of python script 
%             bEcho - boolean (1x1): flag to output python call directly to console (true) or not (false) 
%             cArgs - cell (1xm) [optional]: cell-Array of argument values, may be different data types 
%
% Outputs:
%   bSuccess - boolean (1x1): flag if execution of python succeeded (true) or not (false) 
%    sOutput - string: output of python during execution 
%
% Example: 
%   [bSuccess,sOutput] = pytCallPythonScript(sPythonExe,sScriptFilepath,bEcho,cArgs)
%
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2023-04-19

%% check arguments

% check number of arguments
if nargin < 3
    error('pytCallPythonScript:NotEnoughArgs',...
        'Not enough input arguments.');
end

% check for optional arguments
if nargin < 4
    cArgs = {};
end

% check python exe exists
if ~chkFileExists(sPythonExe)
    error('pytCallPythonScript:PythonExeNotExist',...
        'Python exe file "%s" does not exist.',sPythonExe);
end

% check script exists
if ~chkFileExists(sScriptFilepath)
    error('pytCallPythonScript:ScriptNotExist',...
        'Python script file "%s" does not exist.',sScriptFilepath);
end

% check for py extension
[~,~,sExt] = fileparts(sScriptFilepath);
if ~strcmp(sExt,'.py');
    error('pytCallPythonScript:WrongFileExt',...
        'Script file "%s" is not a python script.',sScriptFilepath);
end

% format paths
sPythonExe = strrep(sPythonExe,'"','');
sPythonExe = sprintf('"%s"',sPythonExe);

sScriptFilepath = strrep(sScriptFilepath,'"','');
sScriptFilepath = sprintf('"%s"',sScriptFilepath);


%% create string from argument list

nPrec = 18;

sArgString = '';

for nArg=1:numel(cArgs)
    arg = cArgs{nArg};
    % check data type
    if isa(arg,'char')
        if ~checkPyCharArgFormat(arg)
            error('pytCallPythonScript:CharArgSpaces',...
                'A char argument for Python contains illegal double quotasion marks: "');
        end
        sArgString = sprintf('%s "%s"',sArgString,arg);
    elseif isnumeric(arg) || islogical(arg)
        sArgString = sprintf('%s "%s"',sArgString,num2str(arg,nPrec));
    else
        error('pytCallPythonScript:WrongArgType',...
        'An argument for Python is from unsupported type "%s".',class(arg));
    end
end


%% call python with arguments

% create full command
sCmd = sprintf('%s %s %s',sPythonExe,sScriptFilepath,sArgString);

% get current Matlab directory
sCurDir = pwd;

% call
if bEcho
    [nReturncode,sOutput] = system(sCmd,'-echo');
else
    [nReturncode,sOutput] = system(sCmd);
end

% change back to current Matlab directory
cd(sCurDir);

% check return code
if nReturncode ~= 0
    bSuccess = false;
else
    bSuccess = true;
end

return

% =========================================================================

function bValid = checkPyCharArgFormat(sArg)

if strcontain(sArg,'"')
    bValid = false;
else
    bValid = true;
end

return
