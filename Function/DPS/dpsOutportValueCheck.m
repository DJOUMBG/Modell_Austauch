function dpsOutportValueCheck(sMP,xExtConfig)
% DPSOUTPORTVALUECHECK checks whether an output signal is written by 
% multiple species and displays a warning if it is not the source species
% defined in the signal list for this signal.
%
% Syntax:
%   dpsOutportValueCheck(sMP,xExtConfig)
%
% Inputs:
%	sMP - structure with fields:
%       DIVe sMP structure with fields of the outputs of all species.
%   xExtConfig - structure with fields: 
%       Config xml structure with interface extension.
%
% Outputs: (Display warnings)
%
% Example: 
%   dpsOutportValueCheck(sMP,xExtConfig)
%
%
% Subfunctions: checkOutputSources, displayWarning, getOutputList, 
%   getSignalStruct, getSourceList
%
%
% See also: dpsInportValueCheck
%
% Author: Elias Rohrer, TE/PTC-H, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2024-08-08

% get output structure
xSignal = getSignalStruct(xExtConfig);

% check structure
if isempty(xSignal)
    fprintf(1,'\tExtended DIVe configuration xml file does not have a part "Signal" or is empty.\n');
    return;
end

% get model setup name to species translation table
cTranslation = getModelSpeciesTranslation(xExtConfig);

% get source list
cSourceList = getSourceList(xSignal,cTranslation);

% get output list
cOutputList = getOutputList(sMP);

% check output sources of species
checkOutputSources(cSourceList,cOutputList);

return % dpsOutputValueCheck

% =========================================================================

function xSignal = getSignalStruct(xExtConfig)
% GETSIGNALSTRUCT returns only the signals structure of config xml
% structure in section <Interface>.
%
% Syntax:
%   xSignal = getSignalStruct(xExtConfig)
%
% Inputs:
%   xExtConfig - structure with fields: 
%       Config xml structure with interface extension.
%
% Outputs:
%   xSignal - structure with fields: 
%       Section <Signal> of config xml with interface extension
%

% init signale structure
xSignal = struct([]);

% get signale structure of configuration
if isfield(xExtConfig,'Configuration')
    
    if isfield(xExtConfig.('Configuration'),'Interface')
        
        if isfield(xExtConfig.('Configuration').('Interface'),'Signal')
            
            if isfield(xExtConfig.('Configuration').('Interface').('Signal'),'name') && ...
                    isfield(xExtConfig.('Configuration').('Interface').('Signal'),'modelRefSource')
                
                % get signal struct from config xml
                xSignal = xExtConfig.('Configuration').('Interface').('Signal');
                
            end % name %% modelRefSource
            
        end % Signal
        
    end % Interface
    
end % Configuration

return % getSignalStruct

% =========================================================================

function cTranslation = getModelSpeciesTranslation(xExtConfig)
% GETMODELSPECIESTRANSLATION returns a translation table with assignment of
% module setup name (column 1) to module species name (column 2).
%
% Syntax:
%   cTranslation = getModelSpeciesTranslation(xExtConfig)
%
% Inputs:
%   xExtConfig - structure with fields: 
%       Config xml structure with interface extension.
%
% Outputs:
%   cTranslation - cell (mx2)
%       Translation from module setup name to module species
%           Column 1: module setup name
%           Column 2: module species name
%

% init translation table
cTranslation = {};

% get signale structure of configuration
if isfield(xExtConfig,'Configuration')
    
    if isfield(xExtConfig.('Configuration'),'ModuleSetup')
        
        % get setup list
     	xSetupList = xExtConfig.('Configuration').('ModuleSetup');
        
        if isfield(xSetupList,'name') && isfield(xSetupList,'Module')
            
            % check setup list
            for nIdxSetup=1:numel(xSetupList)
                
                if isfield(xSetupList(nIdxSetup).('Module'),'species')
                    
                    % get setup name
                    sSetupName = strtrim(xSetupList(nIdxSetup).('name'));
                    
                    % get species name
                    sSpeciesName = strtrim(xSetupList(nIdxSetup).('Module')(1).('species'));
                    
                    % check empty values
                    if not(isempty(sSetupName)) && not(isempty(sSpeciesName))

                       % create row in translation table
                        cTranslation = [cTranslation;{sSetupName,sSpeciesName}]; %#ok<AGROW>

                    end % empty check
                    
                end % species
                
            end % xSetupList
            
        end % name and Module
        
    end % ModuleSetup
    
end % Configuration

return % getModelSpeciesTranslation

% =========================================================================

function cSourceList = getSourceList(xSignal,cTranslation)
% GETSOURCELIST returns a table with output signals in column one and its
% source species in column two.
%
% Syntax:
%   cSourceList = getSourceList(xSignal,cTranslation)
%
% Inputs:
%   xSignal - structure with fields: 
%       Section <Signal> of config xml with interface extension
%   cTranslation - cell (mx2)
%       Translation from module setup name to module species
%           Column 1: module setup name
%           Column 2: module species name
%
% Outputs:
%   cSourceList - cell (mx2):
%       Table with signal to source assignment.
%           Column 1: output signal name
%           Column 2: source species
%

% init list
cSourceList = {};

% search in list
for nIdxSignal=1:numel(xSignal)
    
    % get name and source
    sSignalName = strtrim(xSignal(nIdxSignal).('name'));
    sSetupSource = strtrim(xSignal(nIdxSignal).('modelRefSource'));
    
    % find species name of setup source
    bIsSpecies = ismember(cTranslation(:,1),sSetupSource);
    
    % get translated species name
    cSpecies = cTranslation(bIsSpecies,2);
    
    % assign species source if found
    if numel(cSpecies) > 0
        sSpeciesSource = cSpecies{1};
    else
        sSpeciesSource = sSetupSource;
    end
    
    % append in list
    cSourceList = [cSourceList;{sSignalName,sSpeciesSource};]; %#ok<AGROW>
    
end % xSignal
    
return % getSourceList

% =========================================================================

function cOutputList = getOutputList(sMP)
% GETOUTPUTLIST returns a table with output signals in column one and its
% species in column two. It contains a assignment of all output signals
% from sMP structure to its species. Function ignores species "pltm"
% because this species can overwrite outputs.
%
% Syntax:
%   cOutputList = getOutputList(sMP)
%
%	sMP - structure with fields:
%       DIVe sMP structure with fields of the outputs of all species.
%
% Outputs:
%   cOutputList - cell (nx2):
%       Table with signal to source assignment.
%           Column 1: output signal name
%           Column 2: source species 
%

% init list
cOutputList = {};

% list of relevant context, ATTENTION: ignore outputs of pltm
cContext = {'ctrl','phys','human','bdry'};

% context
for nIdxContext=1:numel(cContext)
    
    % current context name
    sContext = cContext{nIdxContext};
    
    % check context name
    if isfield(sMP,sContext)
        
        % get all species names of context
        cSpecies = fieldnames(sMP.(cContext{nIdxContext}));
        
        % species
        for nIdxSpecies=1:numel(cSpecies)
            
            % current species name
            sSpecies = cSpecies{nIdxSpecies};
            
            % get inport names and values
            if isfield(sMP.(sContext).(sSpecies),'out')
                
                % get names and values of inports
                cOutputNames = fieldnames(sMP.(sContext).(sSpecies).('out'));
                
                % output list of species
                cSpeciesList = {};
                cSpeciesList(1:numel(cOutputNames)) = {sSpecies};
                cSpeciesOutputList = [cOutputNames,cSpeciesList'];
                
                % append in full list
                cOutputList = [cOutputList;cSpeciesOutputList]; %#ok<AGROW>
                
            end % out
            
        end % cSpecies
        
    end % isfield(sMP,sContext)
    
end % cContext

return % getOutputList

% =========================================================================

function checkOutputSources(cSourceList,cOutputList)
% CHECKOUTPUTSOURCES checks if a output signal is written by other species
% then its source species.
%
% Syntax:
%   checkOutputSources(cSourceList,cOutputList)
%
% Inputs:
%   cSourceList - cell (mx2):
%       Table with signal to source assignment from config xml structure.
%           Column 1: output signal name
%           Column 2: source species
%   cOutputList - cell (nx2):
%       Table with signal to source assignment from sMP structure.
%           Column 1: output signal name
%           Column 2: source species  
%

% check each signal
for nIdxSignal=1:size(cSourceList,1)
    
    % get name and source
    sName = cSourceList{nIdxSignal,1};
    sSource = cSourceList{nIdxSignal,2};
    
    % find logical indices of signal in output list
    bIsSignal = ismember(cOutputList(:,1),sName);
    
    % get all species sources of output
    cSpeciesSource = cOutputList(bIsSignal,2);
    
    % find logical indices of species that are not source
    bNotIsSource = not(ismember(cSpeciesSource,sSource));
    
    % get list of species that are not true source of signal
    cNotSourceSpecies = unique(cSpeciesSource(bNotIsSource),'stable');
    
    % display warning if multiple source species of output signal
    if not(isempty(cNotSourceSpecies))
        displayWarning(sName,sSource,cNotSourceSpecies);
    end
    
end % cSourceList

return % checkOutputSources

% =========================================================================

function displayWarning(sName,sSource,cNotSourceSpecies)
% DISPLAYWARNING displays warnings if output signal is written by other
% species then its source species.
%
% Syntax:
%   displayWarning(sName,sSource,cNotSourceSpecies)
%
% Inputs:
%	sName - string:
%       Name of output signal.
%	sSource - string:
%       Name of defined source of output signal.
%	cNotSourceSpecies - cell (mx1) 
%       List of other species that are also write this output signal.
%

% init species string
sSpeciesString = '';

% get all species
for nIdxSpecies=1:numel(cNotSourceSpecies)
    
    % create string of species
    if nIdxSpecies < numel(cNotSourceSpecies)
        sSpeciesString = sprintf('%s, ',cNotSourceSpecies{nIdxSpecies});
    else
        sSpeciesString = sprintf('%s',cNotSourceSpecies{nIdxSpecies});
    end
    
end % cNotSourceSpecies

% display warning
if not(isempty(sSpeciesString))
    fprintf(2,'\tWARNING: Source of signal "%s" is "%s" but it is also output of: %s\n',...
        sName,sSource,sSpeciesString);
end

return % diplayWarning
