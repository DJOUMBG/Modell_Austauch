function sFilePath = slcFileLibraryGet(hSystem)
% SLCFILELIBRARYGET get the library filepath of a specified Simulink
% block/subsystem.
%
% Syntax:
%   sFilePath = slcFileLibraryGet(hSystem)
%
% Inputs:
%   hSystem - handle of Simulink block or string with Simulink block path
%
% Outputs:
%   sFilePath - string with filepath of the library mdl-file
%
% Example: 
%   sFilePath = slcFileLibraryGet(hSystem)
%
% See also: ismdl, pathparts
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2016-07-15

% check input
if ~ismdl(hSystem)
    error('slcFileLibraryGet:invalidSimulinkBlockHandle',...
        'The specified handle or blockpath does not belong to a loaded Simulink block!')
end

% get Simulink information
sReference = get_param(hSystem,'ReferenceBlock');
if isempty(sReference)
    sReference = get_param(hSystem,'AncestorBlock');
end
sBlockDiagramType = get_param(bdroot(hSystem),'BlockDiagramType');
if isempty(sReference) 
    % the specified system has no other library reference
    if strcmp(sBlockDiagramType,'library')
        % the specified system is in a library diagram -> get location of this library mdl
        sFilePath = get_param(bdroot(hSystem),'FileName');
    else
       % the specified system does not belong to a library at all
       sFilePath = '';
       warning('slcFileLibraryGet:blockIsNoLibrary',...
           'slcFileLibraryGet: The specified system is not in a library.')
    end
else
    % the specified system is a library reference from another mdl
    sFilePath = get_param(bdroot(sReference),'FileName');
end
return