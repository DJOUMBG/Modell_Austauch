function [bSuccess,sCmdout] = runDiveCbTrafo(sConfigXmlFile,nExecutionType,sWorkspaceRoot,bShortName)
% RUNDIVECBTRAFO runs the DIVe CB transfromation process with Python for
% given configuration xml file, execution type and DIVe workspace folder.
%
% Syntax:
%   runDiveCbTrafo(sConfigXmlFile,nExecutionType,sWorkspaceRoot)
%   runDiveCbTrafo(sConfigXmlFile,nExecutionType,sWorkspaceRoot,bShortName)
%   bSuccess = runDiveCbTrafo(__)
%   [bSuccess,sCmdout] = runDiveCbTrafo(__)
%
% Inputs:
%   sConfigXmlFile - string: filepath of DIVe configuration xml file 
%   nExecutionType - integer (1x1): execution type of configuration:
%       0: open Silver GUI stopped
%       1: run simulation with Silver GUI
%       2: only transform configuration
%       3: island transformation (outdated)
%       4: run silent simulation (regression)
%   sWorkspaceRoot - string: folderpath of DIVe workspace root folder 
%       bShortName - bool: flag to use short name (only config name) as final SiL folder 
%
% Outputs:
%   bSuccess - boolean (1x1): flag of success
%       true (1): transformation / simulation successfully executed
%    sCmdout - string: (outdated)
%
%
% Author: Elias Rohrer, TT/XCI, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2023-10-22


%% check input arguments

if nargin < 4
    bShortName = false;
end

if ~exist(sConfigXmlFile,'file')
    error('Configuration xml file "%s" does not exist.',sConfigXmlFile);
end

if nExecutionType < 0 || nExecutionType > 4
    error('Execution type "%d" does not exist.',nExecutionType);
end

if ~exist(sWorkspaceRoot,'dir')
    error('Workspace folder "%s" does not exist.',sWorkspaceRoot);
end


%% check transfomation script

% Content folder path
sStartCbFile = fullfile(sWorkspaceRoot,'startDIVeCodeBased.m');
if ~exist(sStartCbFile,'file')
    error('Start DIVe CodeBased file "%s" does not exist.',sStartCbFile);
end

% translate execution type
switch nExecutionType
    
    case 0 % 0: open Silver GUI stopped
        nStartType = 0;
    case 1 % 1: run simulation with Silver GUI
        nStartType = 1;
    case 2 % 2: only transform configuration
        nStartType = 3;
    case 3 % 3: island transformation (outdated)
        fprintf('Execution type "island" is no longer supported. Use "transform only" instead.\n');
        nStartType = 3;
    case 4 % 4: run silent simulation (regression)
        nStartType = 2;
    otherwise
        fprintf('Unknown execution type. Use "transform only" instead.\n');
        nStartType = 3;
    
end

% clear previous sMP variable
bSmpExist = evalin('base',...
    sprintf('exist(%ssMP%s,%svar%s);',...
    char(39),char(39),char(39),char(39)));
if bSmpExist
    evalin('base',sprintf('clear(%ssMP%s);',char(39),char(39)));
end
pause(0.1);


%% call transformation script

% add workspace root path
addpath(sWorkspaceRoot);

% run transformation script
[~,bSuccess] = startDIVeCodeBased(sConfigXmlFile,nStartType,...
    '','shortName',bShortName);

% outdated variable
sCmdout = '';

% remove workspace root path
rmpath(sWorkspaceRoot);

end