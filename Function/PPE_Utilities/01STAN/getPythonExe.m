function sFileExe = getPythonExe(sVersion)
% GETPYTHONEXE determine python version from a) standard path, b) PYTHON_HOME env variable or c)
% windows path
%
% Syntax:
%   sFileExe = getPythonExe(sVersion)
%
% Inputs:
%   sVersion - string with version info e.g. '3.9.4'
%
% Outputs:
%   sFileExe - string with filepath of python executable 
%
% Example: 
%   sFileExe = getPythonExe('3.9.4')
%   sFileExe = getPythonExe('any')
%
%
% Subfunctions: checkPythonExe, getPythonPath

% Private functions:
% Other m-files required:
% MAT-files required:
%
% See also: getPythonExe
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-8485-3325
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2022-07-21

% specify needed python version
if nargin<1
    sVersion = '3.9.4';
end
 
% default location of winpython installation from IT shop
sFileExe = 'C:\apps\winPython3940\python-3.9.4.amd64\python.exe';
if exist(sFileExe,'file')==2
    cPython = {sFileExe};
else
    cPython = {''};
end

% get python installation directory
if isempty(cPython{1})
    cPython = {fullfile(getenv('PYTHON_HOME'),'python.exe')};
end

% python from Silver installation
if isempty(cPython{1})
    cPython = getPythonFromSilver;
end

% check Windows path as backup
if isempty(cPython{1})
    cPython = getPythonPath;
    cPython = {fullfile(cPython{1},'python.exe')};
end

% verify executable existence and version
cPythonExe = checkPythonExe(cPython,sVersion);
if isempty(cPythonExe)
    error('getPythonExe:none','Could not autodetect any python version %s\n',sVersion); 
end
sFileExe = cPython{1};
return

% ==================================================================================================

function cPythonExe = checkPythonExe(cPythonExe,sVersion)
% CHECKPYTHONEXE checks python path candidates for executable and version
%
% Syntax:
%   cPythonExe = checkPythonExe(cPythonExe,sVersion)
%
% Inputs:
%  cPythonExe - cell (1xn) with filepathes of python exe
%    sVersion - string with version identifier e.g. '3.9.4'
%
% Outputs:
%   cPythonExe - cell (1xn) with strings of filepathes to python executables of matching version
%
% Example: 
%   cPythonExe = checkPythonExe(cPath,sVersion)

bExe = false(size(cPythonExe));
bVersion = false(size(cPythonExe));
for nIdxPath = 1:numel(cPythonExe)
    if exist(cPythonExe{nIdxPath},'file') == 2
        bExe(nIdxPath) = true;
        [nStatus,sMsg] = system([cPythonExe{nIdxPath} ' --version']); %#ok<ASGLU>
        if strcmp(sVersion,regexp(sMsg,'[0-9\.]+','match','once')) || ...
                strcmp(sVersion,'any')
            bVersion(nIdxPath) = true;
        end
    end   
end
cPythonExe = cPythonExe(bExe & bVersion);
return

% ==================================================================================================

function cPython = getPythonFromSilver
% GETPYTHONFROMSILVER get the Python executable of the silver installation.
%
% Syntax:
%   cPython = getPythonFromSilver
%
% Inputs:
%
% Outputs:
%   cPython - cell (mx1) with filepathes of the python executable
%
% Example: 
%   cPython = getPythonFromSilver

% init output
cPython = {};

% check for silver installations
[nStatus,sMsg] = system('where silver.exe'); %#ok<ASGLU>
if isempty(regexp(sMsg,'silver.exe'))
    return
end

% refine python path from silver path
cSilver = strsplitOwn(sMsg,char(10)); %#ok<CHARTEN>
cSilver = cellfun(@(x)x(1:end-15),cSilver,'UniformOutput',false); % remove \bin\silver.exe
cPython = cellfun(@(x)fullfile(x,'common','ext-tools','python3','python.exe'),cSilver,'UniformOutput',false); 
return
% ==================================================================================================

function cPython = getPythonPath
% GETPYTHONPATH get Windows path references to python installations
%
% Syntax:
%   cPython = getPythonPath
%
% Outputs:
%   cPython - cell (1xn) of strings with python pathes
%
% Example: 
%   cPython = getPythonPath

sPath = getenv('PATH');
cPath = strsplitOwn(sPath,pathsep);
bPython = ~cellfun(@isempty,regexpi(cPath,'python','once'));
cPython = cPath(bPython);
return