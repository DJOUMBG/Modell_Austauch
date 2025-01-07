function dpsInportValueCheck(sMP)
% DPSINPORTVALUECHECK check if inports were defined by more than one module
% with different default values.
%
% Syntax:
%   dpsInportValueCheck(sMP)
%
% Inputs:
%   sMP - structure: sMP structure 
%
% Outputs:
%   (warning, if same inport names have different values)
%
% Example: 
%   dpsInportValueCheck(sMP)
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2023-10-05

%% collect all inport values

% list of relevant context
cContext = {'ctrl','phys','human','bdry','pltm'};

% context
for nIdxContext = 1:numel(cContext)
    
    % current context name
    sContext = cContext{nIdxContext};
    
    % check context name
    if isfield(sMP,sContext)
        
        % get all species names of context
        cSpecies = fieldnames(sMP.(cContext{nIdxContext}));
        
        % species
        for nIdxSpecies = 1:numel(cSpecies)
            
            % current species name
            sSpecies = cSpecies{nIdxSpecies};
            
            % get all parameters
            xPar = sMP.(sContext).(sSpecies);
            
            % get inport names and values
            if isfield(xPar,'in')
                
                % get names and values of inports
                cThisInportNames = fieldnames(xPar.in);
                
                % inport names
                for nIdxInport=1:numel(cThisInportNames)
                    
                    % current inport name and value
                    sInportName = cThisInportNames{nIdxInport};
                    vInportValue = xPar.in.(sInportName);
                    
                    if exist('xInportStruct','var') && isfield(xInportStruct,sInportName)
                        
                        % append structure parameters
                        xInportStruct.(sInportName).value = ...
                            [xInportStruct.(sInportName).value;vInportValue];
                        xInportStruct.(sInportName).species = ...
                            [xInportStruct.(sInportName).species;{sSpecies}];
                        
                    else
                        
                        % add structure field
                        xInportStruct.(sInportName).value = vInportValue;
                        xInportStruct.(sInportName).species = {sSpecies};
                        
                    end % check inport name
                end % inport names
            end % field "in"
        end % species
    end % is context
end % context


%% search for different definied inport values

% inport names
cAllInportNames = fieldnames(xInportStruct);

% check all inports
for nIdxInport=1:numel(cAllInportNames)
    
    % current inport name
    sInportName = cAllInportNames{nIdxInport};
    vValueList = xInportStruct.(sInportName).value;
    cSpeciesList = xInportStruct.(sInportName).species;
    
    % multiple definied values
    if numel(vValueList) > 1
        % check equality of values
        if ~all(vValueList(1) == vValueList)
            
            % warning message
            fprintf(2,'Inport "%s" is defined with different default values:\n',...
                sInportName);
            
            % display value of inport per species
            for nIdxSpecies=1:numel(cSpeciesList)
                
                % current species and value
                sSpecies = cSpeciesList{nIdxSpecies};
                vValue = vValueList(nIdxSpecies);
                
                %  message
                fprintf(2,'\tIn species "%s": %s\n',sSpecies,num2str(vValue));
                
            end % species
        end % check equality
    end % check multi definition
end % inport
return
