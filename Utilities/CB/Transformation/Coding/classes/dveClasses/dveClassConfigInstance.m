classdef dveClassConfigInstance < handle
    
    properties (SetAccess = private, GetAccess = public)
        
        % reduced structured data of configuration
        xConfigData = struct([]);
        
        % list of model instances
        oModelInst = dveClassModelInstance.empty;
        
        % list of setup instances
        oSetupInst = dveClassSetupInstance.empty;
        
    end % properties
    
    % =====================================================================
    
    properties (Access = private)
        
        % transformation constant object
        CONST = cbtClassTrafoCONST.empty;
        
        % DIVe sMP structure
        sMP = struct([]);
        
        % structured list of model setups
        xSetupList = struct([]);
        
        % structured list of modules
        xModuleList = struct([]);
        
    end % private properties
    
    % =====================================================================
    
    properties (Constant, Access = private)
        
    end % constant private properties
    
    % =====================================================================
    
    methods
        
        function obj = dveClassConfigInstance(oCONST,sMP)
            
            % assign constant object
            obj.CONST = oCONST;
            
            % check input sMP structure
            if isstruct(sMP) && ~isempty(sMP)
                obj.sMP = sMP;
            else
                error('DIVe sMP structure must be a non empty struct.');
            end
            
            % -------------------------------------------------------------
            
            % get reduced structured config data
            obj.xConfigData = obj.getReducedConfigData;
            
            % get structured setup list
            obj.xSetupList = obj.getSetupList;
            
            % get structured module list
            obj.xModuleList = obj.getModuleList;
            
            % -------------------------------------------------------------
            
            % create model instance list
            obj.createModelInstanceList;
            
            % create setup instance list
            obj.createSetupInstanceList;
            
        end % dveClassConfigInstance
        
    end % methods
    
    % =====================================================================
    
    methods (Access = private)
        
        function createModelInstanceList(obj)
            
            % create model instance list
            for nSet=1:numel(obj.xSetupList)
                
                % current setup structure
                xSetup = obj.xSetupList(nSet);
                
                % get corresponding module structure
                xModule = obj.getModuleOfSetup(xSetup);
                
                % get corresponding simulation value structure
                xSimValue = obj.getSimValuesOfSetup(xSetup);
                
                % create instance of class model instance
                oModel = dveClassModelInstance(xSetup,xModule,xSimValue);
                
                % append instance in list
                obj.oModelInst = [obj.oModelInst,oModel];
                
            end % setup list
            
        end % createModelInstanceList
        
        % =================================================================
        
        function createSetupInstanceList(obj)
            
            for nModel=1:numel(obj.oModelInst)
                
                % user info
                fprintf(1,'dve: Get setup structure of "%s"\n',...
                    obj.oModelInst(nModel).sSetupName);
                
                % create setup class instance
                oSetup = dveClassSetupInstance(obj.CONST,obj.oModelInst(nModel),nModel);
                
                % append object in setup list
                obj.oSetupInst = [obj.oSetupInst,oSetup];
                
            end % oModelInst
            
        end % createSetupInstanceList
        
        % =================================================================
        % GET METHODS:
        % =================================================================
        
        function xConfigData = getReducedConfigData(obj)
            
            % get configuration structure
            xConfiguration = obj.getConfigurationFromSmp(obj.sMP);
            
            % delete filed ModuleSetup
            if isfield(xConfiguration,'ModuleSetup')
                xConfiguration = rmfield(xConfiguration,'ModuleSetup');
            end
            
            % assign reduced structure
            xConfigData = xConfiguration;
            
        end % getReducedConfigData
        
        % =================================================================
        
        function xSetupList = getSetupList(obj)
            
            % get configuration structure
            xConfiguration = obj.getConfigurationFromSmp(obj.sMP);
            
            % get field ModuleSetup
            checkFieldname(xConfiguration,'ModuleSetup');
            xSetupList = xConfiguration.('ModuleSetup');
            
            % check Module field
            checkFieldname(xSetupList,'Module');
            
        end % getSetupList
        
        % =================================================================
        
        function xModuleList = getModuleList(obj)
            
            % get xml structure
            xXml = obj.getXmlFromSmp(obj.sMP);
            
            % get field Module
            checkFieldname(xXml,'Module');
            xModuleList = xXml.('Module');
            
            % check context field
            checkFieldname(xModuleList,'context');
            
            % check species field
            checkFieldname(xModuleList,'species');
            
        end % getModuleList
        
        % =================================================================
        
        function xModule = getModuleOfSetup(obj,xSetup)
            
            % get context and species
            [sContext,sSpecies] = obj.getContextAndSpecies(xSetup);
            
            % search in module list for current setup
            xModulesFound = struct([]);
            for nMod=1:numel(obj.xModuleList)
                
                % current module
                xModule = obj.xModuleList(nMod);
                
                % search for equal species and context
                if    strcmp(strtrim(xModule.('species')),sSpecies) ...
                   && strcmp(strtrim(xModule.('context')),sContext)
                    xModulesFound = [xModulesFound,xModule]; %#ok<AGROW>
                end
                
            end % module list
            
            % -------------------------------------------------------------
            
            if numel(xModulesFound) == 1
                xModule = xModulesFound;
            elseif isempty(xModulesFound)
                error('No module was found in module list for setup "%s.%s"',...
                    sContext,sSpecies);
            else
                error('More than one module was found in module list for setup "%s.%s"',...
                    sContext,sSpecies);
            end
            
        end % getModuleOfSetup
        
        % =================================================================
        
        function xSimValue = getSimValuesOfSetup(obj,xSetup)
            
            % get context and species
            [sContext,sSpecies] = obj.getContextAndSpecies(xSetup);
            
            % get context structure from sMP
            if isfield(obj.sMP,sContext)
                xContext = obj.sMP.(sContext);
            else
                xContext = struct([]);
                fprintf(2,'dve: WARNING: Context "%s" is present in ModuleSetup but not in sMP structure!\n',...
                    sContext);
            end
            
            % get species structure from sMP
            if isfield(xContext,sSpecies)
                xSpecies = xContext.(sSpecies);
            else
                xSpecies = struct([]);
                fprintf(2,'dve: WARNING: Species "%s" is present in ModuleSetup but not in sMP structure!\n',...
                    sSpecies);
            end
            
            % -------------------------------------------------------------
            
            % add inport field if not exist
            xSpecies.('in') = setNormStructField(xSpecies,'in');
            
            % add outport field if not exist
            xSpecies.('out') = setNormStructField(xSpecies,'out');
            
            % assign simulation value structure
            xSimValue = xSpecies;
            
        end % getSimValuesOfSetup
        
    end % private methods
    
    % =====================================================================
    
    methods (Static, Access = private)
        
        function xConfiguration = getConfigurationFromSmp(sMP)
            
            % get cfg
            checkFieldname(sMP,'cfg');
            xCfg = sMP.('cfg');
            
            % get Configuration
            checkFieldname(xCfg,'Configuration');
            xConfiguration = xCfg.('Configuration');
            
        end % getConfigurationFromSmp
        
        % =================================================================
        
        function xXml = getXmlFromSmp(sMP)
            
            % get cfg
            checkFieldname(sMP,'cfg');
            xCfg = sMP.('cfg');
            
            % get xml
            checkFieldname(xCfg,'xml');
            xXml = xCfg.('xml');
            
        end % getXmlFromSmp
        
        % =================================================================
        
        function [sContext,sSpecies] = getContextAndSpecies(xSetup)
            
            % get xSetupModule
            checkFieldname(xSetup,'Module');
            xSetupModule = xSetup.('Module');
            
            % get context
            checkFieldname(xSetupModule,'context');
            sContext = strtrim(xSetupModule.('context'));
            
            % get species
            checkFieldname(xSetupModule,'species');
            sSpecies = strtrim(xSetupModule.('species'));
            
        end % getContextAndSpecies
        
    end % static private methods
    
end % dveClassConfigInstance