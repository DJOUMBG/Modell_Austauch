function xData = dpsLoadStandardFile(sFile)
% DPSLOADSTANDARDFILE load DIVe standard data file.
% Part of DIVe Platform Standard functions.
%
% Syntax:
%   xData = dpsLoadStandardFile(sFile)
%
% Inputs:
%   sFile - string with file or filepath of script to load  
%
% Outputs:
%   xData - structure with fields of singular parameters in data file 
%
% Example: 
%   xData = dpsLoadStandardFile(sFile)
%
% Subfunctions: dpsLoadStandardMscript, dpsLoadStandardMatfile
%
% See also: run, load, fileparts 
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2014-10-24

% get parts of file path
[sPath,sFileName,sExtension] = fileparts(sFile);  %#ok<ASGLU>

% get path if not passed
if isempty(sPath)
    sFileCheck = which(sFile);
    if isempty(sFileCheck)
        error('dpsLoadStandardFile:unknownFile',['The specfied file is '...
            'not on the current MATLAB path: %s'],sExtension)
    end
    [sPath,sFileName,sExtension] = fileparts(sFileCheck);  %#ok<ASGLU>
else
    sFileCheck = sFile;
end

switch sExtension
    case '.m'
        xData = dpsLoadStandardMscript(sFileCheck);
    case '.mat'
        xData = dpsLoadStandardMatfile(sFileCheck);
    otherwise
        error('dpsLoadStandardFile:invalidFileType',['The specfied file is '...
            'not of a valid DIVe standard data file: %s'],sExtension)
end
return

% =========================================================================

function xData = dpsLoadStandardMscript(sFile)
% DPSLOADSTANDARDMSCRIPT get DIVe standard data from a m-script into a
% MATLAB structure. DIVe standard data in m-scripts are assignments of
% values, vectors or matrices to a single MATLAB variable - structure are
% not allowed.
%
% Syntax:
%   xData = dpsLoadStandardMscript(sFile)
%
% Inputs:
%   sFile - string with file or filepath of script to load 
%
% Outputs:
%   xData - structure with fields of singular parameters in script file 
%
% Example: 
%   xData = dpsLoadStandardMscript(sFile)

% reset file cache to account for changes in file
[sPath,sName] = fileparts(sFile); %#ok<ASGLU>
clear(sName,'sPath','sName');

% execute m-script with parameter declarations
run(sFile);

% remove input variable from current function workspace
clear('sFile');

% get all variables in current function workspace
cParameter = who;

% create output structure
xData = struct;
for nIdxParameter = 1:numel(cParameter)
    xData.(cParameter{nIdxParameter}) = eval(cParameter{nIdxParameter});
end
return

% =========================================================================

function xData = dpsLoadStandardMatfile(sFile)
% DPSLOADSTANDARDMATFILE get DIVe standard data from a mat-file into a MATLAB
% structure. DIVe standard data mat files contain only plain variables,
% vectors or matrices, but no structures, cells or objects.
%
% Syntax:
%   xData = dpsLoadStandardMatfile(sFile)
%
% Inputs:
%   sFile - string with file or filepath of script to load 
%
% Outputs:
%   xData - structure with fields of singular parameters in script file 
%
% Example: 
%   xData = dpsLoadStandardMatfile(sFile)

xData = load(sFile,'-mat');
return
