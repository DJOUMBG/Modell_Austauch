function ldDIVeConfigurator2LDYN(sFilePath,bRun)
% LDDIVECONFIGURATOR2LDYN preliminary test implementation for start of LDYN
% simulation buildup from DIVe Basic Configurator.
% Part of platform DIVe LDYN specfic functions (pls).
%
% Syntax:
%   ldDIVeConfigurator2LDYN(sFilePath,bRun)
%
% Inputs:
%   sFilePath - string with full filepath of DIVe configuration file
%        bRun - boolean (1x1) if model should be run/started automatically
%
% Example: 
%   ldDIVeConfigurator2LDYN('C:\test\bla.xml',true)

% just dummy message for implementation check - please remove code or
% complete function
fprintf(1,'LDYN should open/run(%i) the configuration: %s\n',bRun,sFilePath);
fprintf(1,'Please update this file for full functionality: %s\n',mfilename('fullpath'));
return
