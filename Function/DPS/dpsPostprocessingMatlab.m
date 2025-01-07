function nStatus = dpsPostprocessingMatlab(cPostExec,sPathResult)
% DPSPOSTPROCESSINGMATLAB execute DIVe post processing functions of pltm.post Modules in a Matlab
% Simulink environment
%
% Syntax:
%   nStatus = dpsPostprocessingMatlab(cPostExec,sPathResult)
%
% Inputs:
%     cPostExec - cell (mx1) of char vectors with filepathes of file to execute
%   sPathResult - string with path of simulation result directory
%
% Outputs:
%   nStatus - integer (1x1) with execution health state (0: successful, 1: error occurred)
%
% Example: 
%   nStatus = dpsPostprocessingMatlab(cPostExec,sPathResult)
%
%
% Subfunctions: dppMatlabFeval, dppPythonCall, dppPythonFeval
%
% See also: getPythonExe, pathparts
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-8485-3325
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2023-02-02

% init output
nStatus = 0;

% store path for correct cleanup
sPathCurrent = pwd;

try
    for nIdxFile = 1:numel(cPostExec) % loop files
        [sPath,sName,sExt] = fileparts(cPostExec{nIdxFile});
        switch lower(sExt)
            case {'.m','.p'}
                % evaluate Matlab script/function in own try/catch loop
                dppMatlabFeval(sPath,sName,sPathResult);
            case '.py'
                % call python according Matlab
                nStatus = dppPythonFeval(cPostExec{nIdxFile},sPathCurrent);
            otherwise
                fprintf(2,['dpsPostprocessingMatlab:unknownFileType - '...
                    'There is no implementation for this kind of file: %s\n'],cPostExec{nIdxFile});
                nStatus = 1;
        end
    end
catch MEall %#ok<NASGU>
    % thorough error reporting
    fprintf(2,'FAILURE in postprocessing via pltm.post - post processing execution stopped.\n');
    nStatus = 1;
end

% restore path
cd(sPathCurrent);
return

% ==================================================================================================

function dppMatlabFeval(sPath,sName,sPathResult)
% DPPMATLABFEVAL evaluate specified Matlab function in specified directory, while current path is in
% specified result folder.
%
% Syntax:
%   dppMatlabFeval(sPath,sName,sPathResult)
%
% Inputs:
%         sPath - string with path of Matlab function to execute
%         sName - string with name of Matlab function to execute
%   sPathResult - string with path of simulation results
%
% Example: 
%   dppMatlabFeval(sPath,sName,sPathResult)

cd(sPathResult);
try
    addpath(sPath); % add DataSet variant path for supporting m-files
    feval(sName,sPathResult);
    rmpath(sPath);
catch MEsingle
    % clean path
    rmpath(sPath);
    
    % report root cause and stack
    cPath = pathparts(sPath);
    fprintf(2,'ERROR during execution of pltm.post DataSet "%s" with file: %s\n',...
        cPath{end},fullfile(sPath,[sName '.m']));
    mExceptionDisp(MEsingle,1);
    
    % rethrow error to prevent further execution
    rethrow(MEsingle);
end
return

% ==================================================================================================

function nStatus = dppPythonFeval(sFilePost,sPathResult)
% DPPPYTHONFEVAL execute the specified post-processing python script/function with the result folder
% as argument.
%
% Syntax:
%   nStatus = dppPythonFeval(sFilePost,sPathResult)
%
% Inputs:
%     sFilePost - string with filepath of python postprocessing script to execute
%   sPathResult - string with result directory to be used as argument
%
% Outputs:
%   nStatus - integer (1x1) of system call end state (0: success, 1: error)
%
% Example: 
%   nStatus = dppPythonFeval(sFilePost,sPathResult)

sPythonExe = getPythonExe('any');
nStatus = dppPythonCall(sPythonExe,sFilePost,sPathResult);
return

% ==================================================================================================

function nStatus = dppPythonCall(sPythonExe,sFilePost,sPathResult)
% DPPPYTHONCALL call python postprocessing function/script with result directory as argument and
% handle 
%
% Syntax:
%   nStatus = dppPythonCall(sPythonExe,sFilePost,sPathResult)
%
% Inputs:
%    sPythonExe - string with filepath of python executable
%     sFilePost - string with filepath of python postprocessing file to execute
%   sPathResult - string with path of simulation result folder
%
% Outputs:
%   nStatus - integer (1x1) of system call end state (0: success, 1: error)
%
% Example: 
%   nStatus = dppPythonCall(sPythonExe,sFilePost,sPathResult)

sCall = sprintf('"%s" "%s" "%s"',sPythonExe,sFilePost,sPathResult);
fprintf(1,'Python postprocessing function from Matlab with call: %s\n',sCall)
[nStatus,sMsg] = system(sCall,'-echo');
if nStatus
    fprintf(2,'dpsPostprocessingMatlab: Python postprocessing function "%s" failed with message:\n%s\n',sFilePost,sMsg);
else
    fprintf(1,'dpsPostprocessingMatlab: Python postprocessing function "%s" ended successful.\n',sFilePost);
    fprintf(1,'Python echo output:\n%s\n',sMsg);
end
return

