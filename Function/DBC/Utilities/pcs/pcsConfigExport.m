function pcsConfigExport(sFileConfig,~,~,nExecution)
% PCSCONFIGEXPORT exports the modules of a specified configuration for 
% DIVe CodeBased 
%   Part of platform DIVe CodeBased specfic functions (pcs).
%
% Syntax:
%   pcsConfigExport(sFileConfig,~,~,nExecution)
%
% Inputs:
%	sFileConfig - string with filepath of last saved configuration
%	(sPathContent) - string with path to content folder of DIVe basic
%                  configurator (holds context level of DIVe export)
%       => outdated, is not needed any more but is passed from the calling
%       function!
%	(xData) - structure of DIVe Basic Configuration (according xlsx)
%       => outdated, is not needed any more but is passed from the calling
%       function!
%	nExecution - integer (1x1) with execution flag:
%       0: save and open
%       1: save, open and run
%       2: create SiL runtime
%
% Outputs:
%
% Example: 
%   pcsConfigExport(sFileConfig,~,~,nExecution)
%
%
% See also: dsv, umsMsg
%
% Author: Elias Rohrer, TE/PTC, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2024-02-27

% start up message
fprintf('\n==========================================');
fprintf('\nDIVe CB - Executing Transformation scripts.\nPlease Wait ...\n');

% translate run type
switch nExecution
    
    case 0  % open in Silver GUI
        nRunType = 0;
    case 1  % run in Silver GUI
        nRunType = 1;
    case 2  % only transform configuration
        nRunType = 3;
    otherwise
        fprintf('\nUnknown execution type parsed from dbc: Using transformation instead.\n');
        nRunType = 3;
    
end

% get debug flag from environment
bDebug = getenv('debug');

% run transformation
if bDebug == '1'
    bSuccess = dsv(sFileConfig,nRunType,'','debugMode',true);
else
    bSuccess = dsv(sFileConfig,nRunType,'');
end

% check retun value
if ~bSuccess
    umsMsg('Configurator',2,'Error in DIVe CB transformation!\n');
    umsMsg('Configurator',2,'See Matlab Command Window\n');
    umsMsg('Configurator',1,'----------------------------------------');
end

return
