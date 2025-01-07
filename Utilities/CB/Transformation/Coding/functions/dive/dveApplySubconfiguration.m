function xConfig = dveApplySubconfiguration(xConfig,xSubConfig)

% run through setups in subconfig
for nSetSub=1:numel(xSubConfig.Subconfiguration.SpeciesSetup)
    
    % current set
    xSpeciesSet = xSubConfig.Subconfiguration.SpeciesSetup(nSetSub);
    
    % get species name
    sSpecies = xSpeciesSet.species;
    
    % element number of setup with species in configuration
    nSpeciesPos = 0;
    
    % search for existing species in configuration setups
    for nSetCfg=1:numel(xConfig.Configuration.ModuleSetup)
        
        % current set
        xSetup = xConfig.Configuration.ModuleSetup(nSetCfg);
        
        % check for species
        if strcmp(xSetup.species,sSpecies)
            nSpeciesPos = nSetCfg;
            break;
        end
        
    end
    
    % check if species was found
    if nSpeciesPos
        xConfig.Configuration.ModuleSetup(nSpeciesPos) = xSpeciesSet;
    else
        xConfig.Configuration.ModuleSetup(end+1) = xSpeciesSet;
    end

end