classdef dveClassModelInstance < handle
    
    properties (SetAccess = private, GetAccess = public)
        
        % name of module setup
        sSetupName = '';
        
        % merged structured data of ModelSet and general module data
        xModelSet = struct([]);
        
        % list of merged structured data of DataSets
        xDataSets = struct([]);
        
        % list of merged structured data of SupportSets
        xSupportSets = struct([]);
        
        % structured interface description of module
        % .Inport
        % .Outport
        % .Parameter
        xInterface = struct([]);
        
        % simulation value structure
        % .in
        % .out
        % .{...}
        xSimValue = struct([]);
        
    end % properties
    
    % =====================================================================
    
    properties (Access = private)
        
        % model setup structure
        xSetup = struct([]);
        
        % module structure
        xModule = struct([]);
        
        % model set list of module
        xModuleModelSetList = struct([]);
        
    end % private properties
    
    % =====================================================================
    
    properties (Constant, Access = private)
        
    end % constant private properties
    
    % =====================================================================
    
    methods
        
        function obj = dveClassModelInstance(xSetup,xModule,xSimValue)
            
            % assing input arguments
            obj.xSetup = xSetup;
            obj.xModule = xModule;
            obj.xSimValue = xSimValue;
            
            % -------------------------------------------------------------
            
            % get setup name
            obj.sSetupName = obj.getSetupName;
            
            % get interface structure from module
            obj.xInterface = obj.getInterfaceOfModule;
            
            % get structured model set list from module
            obj.xModuleModelSetList = obj.getModelSetList;
            
            % -------------------------------------------------------------
            
            % merge structured model set data
            obj.mergeModelSet;
            
            % merge structured data set data
            obj.mergeDataSet;
            
            % merge structured support set data
            obj.mergeSupportSet;
            
        end % dveClassModelInstance
        
    end % methods
    
    % =====================================================================
    
    methods (Access = private)
        
        function mergeModelSet(obj)
            
            % get model set structure from setup
            xSetupModelSet = obj.getSetupModelSet;
            
            % get corresponding model set from module
            xModuleModelSet = obj.getModuleModelSet(xSetupModelSet);
            
            % get general module data
            xGeneralModuleData = obj.getModuleData;
            
            % -------------------------------------------------------------
            
            % get merged structure
            xModelSet = mergeStructures(xSetupModelSet,xModuleModelSet);
            xModelSet = mergeStructures(xModelSet,xGeneralModuleData);
                
          	% assing merged ModelSet structure
            obj.xModelSet = xModelSet;
            
        end % mergeModelSet
        
        % =================================================================
        
        function mergeDataSet(obj)
            
            % get data set list from setup
            xSetupDataSetList = obj.getSetupDataSetList;
            
            % get data set list from module
            xModuleDataSetList = obj.getModuleDataSetList;
            
            % check corresponding length of DataSet lists
            if numel(xSetupDataSetList) ~= numel(xModuleDataSetList)
                error('Number of DataSets in configuration differs from number in Module of "%s".',...
                    oobj.sSetupName);
            end
            
            % -------------------------------------------------------------
            
            % DataSets in setup
            for nSet=1:numel(xSetupDataSetList)
                
                % current DataSet in setup
                xSetupDataSet = xSetupDataSetList(nSet);
                
                % init DataSet in module
                xModuleDataSet = struct([]);
                
                % search for corresponding DataSet in module
                for nMod=1:numel(xModuleDataSetList)
                    
                    % current DataSet in module
                    xCurModuleDataSet = xModuleDataSetList(nMod);
                    
                    % check for corresponding DataSet
                    if obj.checkEqualDataSet(xSetupDataSet,xCurModuleDataSet)
                        xModuleDataSet = xCurModuleDataSet;
                        break;
                    end
                    
                end % xModuleDataSetList
                
                % check if module DataSet was found
                if isempty(xModuleDataSet)
                    error('Could not found corresponding DataSet "%s" in module of "%s".',...
                        xSetupDataSet.('className'),obj.sSetupName);
                end
                
                % ---------------------------------------------------------
                
                % get merged structure
                xDataSet = mergeStructures(xSetupDataSet,xModuleDataSet);
                
                % append merged DataSet structure
                obj.xDataSets = appendNormStructure(obj.xDataSets,xDataSet);
                
            end % xSetupDataSetList
            
        end % mergeDataSet
        
        % =================================================================
        
        function mergeSupportSet(obj)
            
            % get support set list from setup
            xSetupSupportSetList = obj.getSetupSupportSetList;
            
            % get support set list from module
            xModuleSupportSetList = obj.getModuleSupportSetList;
            
            % check corresponding length of SupportSet lists
            if numel(xSetupSupportSetList) ~= numel(xModuleSupportSetList)
                error('Number of SupportSets in configuration differs from number in Module of "%s".',...
                    obj.sSetupName);
            end
            
            % -------------------------------------------------------------
            
            % SupportSets in setup
            for nSet=1:numel(xSetupSupportSetList)
                
                % current SupportSet in setup
                xSetupSupportSet = xSetupSupportSetList(nSet);
                
                % init SupportSet in module
                xModuleSupportSet = struct([]);
                
                % search for corresponding SupportSet in module
                for nMod=1:numel(xModuleSupportSetList)
                    
                    % current SupportSet in module
                    xCurModuleSupportSet = xModuleSupportSetList(nMod);
                    
                    % check for corresponding SupportSet
                    if obj.checkEqualSupportSet(xSetupSupportSet,xCurModuleSupportSet)
                        xModuleSupportSet = xCurModuleSupportSet;
                        break;
                    end
                    
                end % xModuleSupportSetList
                
                % check if module SupportSet was found
                if isempty(xModuleSupportSet)
                    error('Could not found corresponding SupportSet "%s" in module of "%s".',...
                        xSetupSupportSet.('name'),obj.sSetupName);
                end
                
                % ---------------------------------------------------------
                
                % get merged structure
                xSupportSet = mergeStructures(xSetupSupportSet,xModuleSupportSet);
                
                % append merged SupportSet structure
                obj.xSupportSets = appendNormStructure(obj.xSupportSets,xSupportSet);
                
            end % xSetupSupportSetList
            
        end % mergeSupportSet
        
        % =================================================================
        % GET METHODS:
        % =================================================================
        
        function sSetupName = getSetupName(obj)
            
            % get name of module setup
            checkFieldname(obj.xSetup,'name');
            sSetupName = obj.xSetup.('name');
            
        end % getSetupName
        
        % =================================================================
        
        function xInterface = getInterfaceOfModule(obj)
            
            % check field Implementation
            checkFieldname(obj.xModule,'Interface');
            xModuleInterface = obj.xModule.('Interface');
            
            % set field Inport
            xInterface.('Inport') = setNormStructField(xModuleInterface,'Inport');
            
            % set field Outport
            xInterface.('Outport') = setNormStructField(xModuleInterface,'Outport');
            
            % set field Parameter
            xInterface.('Parameter') = setNormStructField(xModuleInterface,'Parameter');
            
        end % getInterfaceOfModule
        
    	% =================================================================
        
        function xModuleModelSetList = getModelSetList(obj)
            
            % check field Implementation
            checkFieldname(obj.xModule,'Implementation');
            xImplementation = obj.xModule.('Implementation');
            
            % get field ModelSet
            if isfield(xImplementation,'ModelSet')
                xModuleModelSetList = xImplementation.('ModelSet');
            else
                error('No model sets for setup of "%s".',...
                    obj.sSetupName);
            end
            
            % check context field
            checkFieldname(xModuleModelSetList,'type');
            
        end % getModelSetList
        
        % =================================================================
        
        function xSetupModelSet = getSetupModelSet(obj)
            
            % get xSetupModule
            checkFieldname(obj.xSetup,'Module');
            xSetupModelSet = obj.xSetup.('Module');
            
            % get all fieldnames of setup
            cSetupFields = fieldnames(obj.xSetup);
            
            % get all non structured fields of setup and append in setup
            % model set structure
            for nField=1:numel(cSetupFields)
                
                % field name
                sFieldname = cSetupFields{nField};
                
                % field value
                fieldValue = obj.xSetup.(sFieldname);
                
                % append field if no is struct
                if ~isstruct(fieldValue)
                    xSetupModelSet.(sFieldname) = fieldValue;
                end
                
            end % fields
            
            % check field modelSet
            checkFieldname(xSetupModelSet,'modelSet');
            
        end % getSetupModelSet
        
    	% =================================================================
        
        function xModuleModelSet = getModuleModelSet(obj,xSetupModelSet)
            
            % get model set name
            sModelSetName = xSetupModelSet.('modelSet');
            
            % search for corresponding model set
            xModelSetsFound = struct([]);
            for nSet=1:numel(obj.xModuleModelSetList)
                
                % current model set
                xCurModuleModelSet = obj.xModuleModelSetList(nSet);
                
                % search for equal model set
                if strcmp(strtrim(xCurModuleModelSet.('type')),sModelSetName)
                    xModelSetsFound = [xModelSetsFound,xCurModuleModelSet]; %#ok<AGROW>
                end
                
            end % model sets
            
            % -------------------------------------------------------------
            
            if numel(xModelSetsFound) == 1
                xModuleModelSet = xModelSetsFound;
            elseif isempty(xModelSetsFound)
                error('No model set "%s" was found in module for species "%s".',...
                    obj.xModuleData.('species'));
            else
                error('More than one model set "%s" was found in module for species "%s".',...
                    obj.xModuleData.('species'));
            end
            
            % -------------------------------------------------------------
            
            % remove field type (=ModelSet) field to prevent confusions
            % with DIVe type
            if isfield(xModuleModelSet,'type')
                xModuleModelSet = rmfield(xModuleModelSet,'type');
            end
            
        end % getModuleModelSet
        
        % =================================================================
        
      	function xModuleData = getModuleData(obj)
            
            % pre assing module data
            xModuleData = obj.xModule;
            
            % get all fieldnames of module
            cModuleFields = fieldnames(xModuleData);
            
            % remove all structured fields
            for nField=1:numel(cModuleFields)
                
                % field name
                sFieldname = cModuleFields{nField};
                
                % field value
                fieldValue = xModuleData.(sFieldname);
                
                % append field if not is struct
                if isstruct(fieldValue)
                    xModuleData = rmfield(xModuleData,sFieldname);
                end
                
            end % fields
            
            % remove field name (=variant) field to prevent confusions
            % with module setup name
            if isfield(xModuleData,'name')
                xModuleData = rmfield(xModuleData,'name');
            end
            
        end % getModuleData
        
        % =================================================================
                
        function xSetupDataSetList = getSetupDataSetList(obj)
            
            % get DataSet field
            xSetupDataSetList = setNormStructField(obj.xSetup,'DataSet');
            
            % check name field
            if ~isempty(xSetupDataSetList)
                checkFieldname(xSetupDataSetList,'className');
                checkFieldname(xSetupDataSetList,'classType');
                checkFieldname(xSetupDataSetList,'level');
            end
            
        end % getSetupDataSetList
        
        % =================================================================
        
        function xModuleDataSetList = getModuleDataSetList(obj)
            
            % check field Implementation
            checkFieldname(obj.xModule,'Interface');
            xInterface = obj.xModule.('Interface');
            
            % get field DataSet (also obsolete InitIO DataSet)
            xModuleDataSetList = setNormStructField(xInterface,'DataSet');
            xModuleDataSetInitIo = setNormStructField(xInterface,'DataSetInitIO');
            xModuleDataSetList = [xModuleDataSetInitIo,xModuleDataSetList];
            
            % check name field
            if ~isempty(xModuleDataSetList)
                checkFieldname(xModuleDataSetList,'className');
                checkFieldname(xModuleDataSetList,'classType');
                checkFieldname(xModuleDataSetList,'level');
            end
            
        end % getModuleDataSetList
        
     	% =================================================================
        
        function xSetupSupportSetList = getSetupSupportSetList(obj)
            
            % get SupportSet field
            xSetupSupportSetList = setNormStructField(obj.xSetup,'SupportSet');
            
            % check fields
            if ~isempty(xSetupSupportSetList)
                checkFieldname(xSetupSupportSetList,'name');
                checkFieldname(xSetupSupportSetList,'level');
            end
            
        end % getSetupSupportSetList
        
        % =================================================================
        
        function xModuleSupportSetList = getModuleSupportSetList(obj)
            
            % check field Implementation
            checkFieldname(obj.xModule,'Implementation');
            xImplementation = obj.xModule.('Implementation');
            
            % get field SupportSet
            xModuleSupportSetList = setNormStructField(xImplementation,'SupportSet');
            
            % check fields
            if ~isempty(xModuleSupportSetList)
                checkFieldname(xModuleSupportSetList,'name');
                checkFieldname(xModuleSupportSetList,'level');
            end
            
        end % getModuleSupportSetList
        
    end % private methods
    
    % =====================================================================
    
    methods (Static, Access = private)
        
        function bIsEqual = checkEqualDataSet(xDataSetA,xDataSetB)
            
            if    strcmp(strtrim(xDataSetA.('className')),strtrim(xDataSetB.('className'))) ...
               && strcmp(strtrim(xDataSetA.('classType')),strtrim(xDataSetB.('classType'))) ...
               && strcmp(strtrim(xDataSetA.('level')),strtrim(xDataSetB.('level')))
                bIsEqual = true;
            else
                bIsEqual = false; 
            end
            
        end % checkEqualDataSet
        
        % =================================================================
        
        function bIsEqual = checkEqualSupportSet(xSupportSetA,xSupportSetB)
            
            if    strcmp(strtrim(xSupportSetA.('name')),strtrim(xSupportSetB.('name'))) ...
               && strcmp(strtrim(xSupportSetA.('level')),strtrim(xSupportSetB.('level')))
                bIsEqual = true;
            else
                bIsEqual = false;
            end
            
        end % checkEqualDataSet
        
    end % static private methods
    
end % dveClassModelInstance