function slcSimulinkSystemClose(sOption)
% SLCSIMULINKSYSTEMCLOSE close Simulink systems according option.
% Part of Simulink custom package slc.
%
% Syntax:
%   slcSimulinkSystemClose(sOption)
%
% Inputs:
%   sOption - string with one of the following options
%               all: [default] close all open system without saving
%               lib: close all open library system without saving
%
% Outputs:
%
% Example: 
%   slcSimulinkSystemClose('all')
%   slcSimulinkSystemClose('lib')
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2016-02-01

% input check
if nargin < 1
    sOption = 'all';
end

% close according option
switch lower(sOption)
    case 'all'
        % close all Simulink systems
        bdclose('all');
        
    case 'lib'
        % get all open libraries
        cLib = find_system('SearchDepth',0,'LibraryType','BlockLibrary');
        
        % close libs
        close_system(cLib,0);
        
    otherwise
        fprintf(2,'Error - pmsSimulinkSystemClose:unknownOption');
end
return