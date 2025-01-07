function sVariant = dbcFcnDataVariantGet(xConfiguration,sSpecies,sClassName)
% DBCFCNDATAVARIANTGET get the dataset variant of a specified species and
% its className from a DIVe Configuration structure.
%
% Syntax:
%   sVariant = dbcFcnDataVariantGet(xConfiguration,sSpecies,sClassName)
%
% Inputs:
%   xConfiguration - structure with fields according a DIVe Configuration 
%         sSpecies - string with species name of requested dataset variant
%       sClassName - string with dataset className of requested dataset variant
%
% Outputs:
%   sVariant - string requested dataset variant ('none' if empty)
%
% Example: 
%   sVariant = dbcFcnDataVariantGet(xConfiguration,sSpecies,sClassName)
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2016-08-09


% initialize output
sVariant = 'none';

% get list of currently configured module species
cSpecies = cell(1,numel(xConfiguration.ModuleSetup));
for nIdxSetup = 1:numel(xConfiguration.ModuleSetup)
    cSpecies{nIdxSetup} = xConfiguration.ModuleSetup(nIdxSetup).Module.species; %#ok<AGROW>
end

% check existence of species in current configuration
bSetup = strcmp(sSpecies,cSpecies);
if any(bSetup) % a ModuleSetup with defined species exists
    % check existence of defined className in Module datasets
    cClassName = {xConfiguration.ModuleSetup(bSetup).DataSet.className};
    bSet = strcmp(sClassName,cClassName);
    if any(bSet)
        sVariant = xConfiguration.ModuleSetup(bSetup).DataSet(bSet).variant;
    end
end % if species of dataset exists in current configuration
return
