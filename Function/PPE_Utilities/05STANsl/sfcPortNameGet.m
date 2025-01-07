function sName = sfcPortNameGet(hBlock,sType,nNumber)
% SFCPORTNAMEGET get Stateflow chart port names by specifying block,
% port type and port number.
%
% Syntax:
%   sName = sfcPortNameGet(hBlock,sType,nNumber)
%
% Inputs:
%    hBlock - handle of Statflow chart block (string only here!)
%     sType - string with port type (only 'Inport' or 'Outport')
%   nNumber - integer (1x1) with port number
%
% Outputs:
%   sName - string with name of Stateflow chart port
%
% Example: 
%   sName = sfcPortNameGet(gcb,'Inport',1)
%   sName = sfcPortNameGet(gcb,'Outport',1)
%
%
% See also: sfroot
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2014-06-25

% outport init
sName = '';

% input checking
if nargin < 1
    hBlock = gcb;
end
if nargin < 2 || ~ismember(sType,{'Input','Output'})
    sType = 'Output';
end
if nargin < 3
    nNumber = 1;
end

% get statflow root object
rt = sfroot; 

% get stateflow chart object
ch = rt.find('-isa','Stateflow.Chart','-and', 'Path', hBlock);
if isempty(ch)
    return
end

% get stateflow port object
Out = ch.find('-isa','Stateflow.Data','-and', 'Scope', sType,'-and', 'Port', nNumber);
if isempty(Out)
    return
end
sName = Out(1).Name;
return
