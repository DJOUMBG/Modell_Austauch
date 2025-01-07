classdef dveClassSmp < handle
    
    properties (SetAccess = private, GetAccess = public)
        
        % DIVe sMP structure
        sMP = struct([]);
        
        % DIVe configuration xml
        xConfigXml = struct([]);
        
        % DIVe configuration setup list
        xSetupXml = struct([]);
        
        % DIVe module xml list
        xModuleXml = struct([]);
        
    end % properties
    
    % =====================================================================
    
    properties (Access = private)
        
        % assign transformation constants
        CONST = cbtClassTrafoCONST.empty;
        
    end % private properties
    
    % =====================================================================
    
    properties (Constant, Access = private)
        
        % default DIVe input name
        sStdInputName = 'in';
        
        % default DIVe output name
        sStdOutputName = 'out';
        
        % default DIVe initIO name
        sStdInitIoName = 'initIO';
        
    end % private constant properties
    
    % =====================================================================
    
    methods
        
        function obj = dveClassSmp(oCONST,sMP)
            
            % assign constant object
            obj.CONST = oCONST;
            
            % check input arguments
            if ~isstruct(sMP)
                error('Given sMP variable is not from type struct.');
            end
            
            % update sMP structure
            obj.updateObject(sMP);
            
        end % (constructor)
        
        % =================================================================
        
        function updateObject(obj,sMP)
            
            % assign sMP structure
            obj.sMP = sMP;
            
            % get config xml
            checkFieldname(obj.sMP,'cfg');
            checkFieldname(obj.sMP.('cfg'),'Configuration');
            obj.xConfigXml = obj.sMP.('cfg').('Configuration');
            
            % get module xml list
            checkFieldname(obj.sMP,'cfg');
            checkFieldname(obj.sMP.('cfg'),'xml');
            checkFieldname(obj.sMP.('cfg').('xml'),'Module');
            obj.xModuleXml = obj.sMP.('cfg').('xml').('Module');
            
            % get setup list
            checkFieldname(obj.xConfigXml,'ModuleSetup');
            obj.xSetupXml = obj.xConfigXml.('ModuleSetup');
            
        end % updateObject
        
        % =================================================================
        
        function testMethod(obj)
            
            % user info
            fprintf('Run test methods for sMP structure:\n');
            
            % test config methods
            obj.getLogData;
            obj.getInitOrderStruct;
            obj.getStepSizeData;
            obj.getInitIoData;
            obj.getSignalRouting;
            obj.getRangeCheckData;
            
            % get context names
            cContextNames = obj.getContextNames;
            
            % get species names
            for nCtx=1:numel(cContextNames)
                
                % get species names
                cSpeciesNames = obj.getSpeciesNames(cContextNames{nCtx});
                
                % get module data of species
                for nSpc=1:numel(cSpeciesNames)
                    
                    % user info
                    fprintf(1,'Run test methods for "%s.%s" ...\n',...
                        cContextNames{nCtx},cSpeciesNames{nSpc});
                    
                    % test module methods
                    obj.getModuleStruct(cContextNames{nCtx},cSpeciesNames{nSpc});
                    obj.getSetupStruct(cContextNames{nCtx},cSpeciesNames{nSpc});
                    obj.getFmuData(cContextNames{nCtx},cSpeciesNames{nSpc});
                    obj.getSfcnData(cContextNames{nCtx},cSpeciesNames{nSpc});
                    
                end % cSpeciesNames
                
            end % cContextNames
            
            % user info
            fprintf('Finished test methods for sMP structure.\n');
            
        end % testMethod

    end % public methods
    
    % =================================================================
    % SFU INTERFACE METHODS:
    %   [xParameter,xIoParameter] = obj.getFmuData(sContext,sSpecies)
    %   [xInput,xOutput,xParameter] = obj.getSfcnData(sContext,sSpecies)
    %   xSignalList = obj.getSignalRouting
    %   xPort = obj.getInitIoData
    %   xSignalList = obj.getRangeCheckData
    %   [cMergedSignalList,xLogParamater,sLogType,vLogStepSize] = obj.getLoggingData(cLogParamDef)
    % =================================================================
    
	methods
        
        function [xParameter,xIoParameter] = getFmuData(obj,sContext,sSpecies)
            
            % get parameter with index
            xIdxParamList = obj.getParamAttribList(sContext,sSpecies);
            
            % split between initIO and other parameter
            [xIoParameter,xParameter] = obj.getStructOfFieldValue(...
                xIdxParamList,'class',obj.sStdInitIoName);
            
            % sort tables
            xParameter = obj.sortStructByField(xParameter,'variable',true);
            xIoParameter = obj.sortStructByField(xIoParameter,'variable',true);
            
        end % getFmuData
        
        % =================================================================
        
        function [xInput,xOutput,xParameter] = getSfcnData(obj,sContext,sSpecies)
            
            % get inports with index
            xInput = obj.getPortAttribList(sContext,sSpecies,obj.sStdInputName);
            
            % get outports with index
            xOutput = obj.getPortAttribList(sContext,sSpecies,obj.sStdOutputName);
            
            % get parameter with index
            xParameter = obj.getParamAttribList(sContext,sSpecies);
            
            % sort structures
            xInput = obj.sortStructByField(xInput,'index');
            xOutput = obj.sortStructByField(xOutput,'index');
            xParameter = obj.sortStructByField(xParameter,'index');
            
        end % getSfcnData
        
        % =================================================================
        
        function xSignalList = getSignalRouting(obj)
            
            % init list
            xSignalList = struct([]);
            
            % check field interface
            if isfield(obj.xConfigXml,'Interface')
                
                % check field signals
                if isfield(obj.xConfigXml.('Interface'),'Signal')
                    
                    % check source and destination
                    if isfield(obj.xConfigXml.('Interface').('Signal'),'source') && ...
                            isfield(obj.xConfigXml.('Interface').('Signal'),'destination')
                        
                        % assign dignal list
                        xSignalList = obj.xConfigXml.('Interface').('Signal');
                        
                    end % source and destination
                    
                end % signal
                
            end % interface
            
        end % getSignalRouting
        
        % =================================================================
        
        function xPort = getInitIoData(obj)
            
            % init output
            xPort = struct([]);
            
            % get sorted init order structure
            xInitOrder = obj.getInitOrderStruct;
            
            % get port structures of each species
            for nSpec=1:numel(xInitOrder)
                
                % get inports
                [~,xInport] = obj.getPortAttribList(...
                    xInitOrder(nSpec).context,...
                    xInitOrder(nSpec).species,obj.sStdInputName);
                
                % get outports
                [~,xOutport] = obj.getPortAttribList(...
                    xInitOrder(nSpec).context,...
                    xInitOrder(nSpec).species,obj.sStdOutputName);
                
                % append inports and outports in port list
                xPort = [xPort,xInport,xOutport]; %#ok<AGROW>
                
            end % xInitOrder
            
        end % getInitIoData
        
        % =================================================================
        
        function xSignalList = getRangeCheckData(obj)
            
            % get all signals from port description
            xPort = obj.getInitIoData;
            
            % unique port list to signal list
            [~,nIdxList] = unique(obj.getFieldValues(xPort,'name'),'stable');
            xSignalList = xPort(nIdxList);
            
        end % getRangeCheckData
        
        % =================================================================
        
        function [cMergedSignalList,xLogParamater,sLogType,vLogStepSize] = getLoggingData(obj,cLogParamDef)
            
            % get log data
            [sLogType,vLogStepSize] = obj.getLogData;
            
            % log signal lists
            cConfigSignalList = obj.getSignalListFromConfig;
            cModulesSignalList = obj.getSignalListFromModules;
            
            % merge signal list
            cMergedSignalList = unique(...
                [cConfigSignalList;cModulesSignalList],'stable');
            
            % -------------------------------------------------------------
            
            % init structure list
            xLogParamater = struct([]);
            
            % get parameters to be logged definied by context and species
            for nMod=1:size(cLogParamDef,1)
                
                % get context and species
                sContext = cLogParamDef{nMod,1};
                sSpecies = cLogParamDef{nMod,2};
                
                % check context
                if not(obj.checkContext(sContext))
                    continue;
                end
                
                % check species
                if not(obj.checkSpecies(sContext,sSpecies))
                    continue;
                end
                
                % get full parameter list of species
                [~,xSpeciesParam] = obj.getParamAttribList(sContext,sSpecies);
                
                % append in list of parameter
                xLogParamater = [xLogParamater,xSpeciesParam]; %#ok<AGROW>
                
            end % cLogParamDef
            
        end % getLoggingData
        
        % =================================================================
        
    end % SFU interface methods
    
    % =====================================================================
    % sMP structure METHODS:
    %   bIsContext = obj.checkContext(sContext)
    %   bIsSpecies = obj.checkSpecies(sContext,sSpecies)
    %   cContextNames = obj.getContextNames
    %   cSpeciesNames = obj.getSpeciesNames(sContext)
    %   xSpecies = obj.getSpeciesStruct(sContext,sSpecies)
    %   cSubspecies = obj.getSubspecies(sContext,sSpecies)
    %   cInputs = obj.getInputs(sContext,sSpecies)
    %   cOutputs = obj.getOutputs(sContext,sSpecies)
    %   cParams = obj.getParams(sContext,sSpecies)
    %   cSubParams = obj.getSubparams(sContext,sSpecies,sSubspecies)
    %   sSmpName = obj.getSmpName(sContext,sSpecies,sSubspecies,sName)
    %   [sContext,sSpecies,sName,sSubspecies] = obj.splitSmpName(sSmpName)
    % =====================================================================
    
    methods (Access = private)
        
        function bIsContext = checkContext(obj,sContext)
        % check if given context names is present in sMP structure
            
            % check context in sMP structure
            if ismember(sContext,obj.getContextNames)
                bIsContext = true;
            else
                bIsContext = false;
            end
            
        end % checkContext
        
        % =================================================================
        
        function bIsSpecies = checkSpecies(obj,sContext,sSpecies)
        % check if given species names is present in given context of sMP 
        % structure
            
            % check context in sMP structure
            if obj.checkContext(sContext)
                
                % check species in context
                if ismember(sSpecies,obj.getSpeciesNames(sContext))
                    bIsSpecies = true;
                else
                    bIsSpecies = false;
                end
                
            else
                bIsSpecies = false;
            end
            
        end % checkSpecies
        
        % =================================================================
        
        function cContextNames = getContextNames(obj)
        % get list of all DIVe context names in sMP structure
        
            % get all fieldnames
            cSmpFields = fieldnames(obj.sMP);
            
            % get valid member array
            bMembers = ismember(cSmpFields,obj.CONST.cStdContextList);
            
            % filter names
            cContextNames = cSmpFields(bMembers);
            
        end % getContextNames
        
        % =================================================================
        
        function cSpeciesNames = getSpeciesNames(obj,sContext)
        % get list of all DIVe species names in given context in sMP
        % structure
        
            if obj.checkContext(sContext)
                cSpeciesNames = fieldnames(obj.sMP.(sContext));
            else
                cSpeciesNames = {};
            end
            
        end % getSpeciesNames
        
        % =================================================================
                
        function xSpecies = getSpeciesStruct(obj,sContext,sSpecies)
        % get structure of given context.species in sMP structure
            
            % init species struct
            xSpecies = struct([]);
            
            % check species
            if not(obj.checkSpecies(sContext,sSpecies))
                fprintf(2,'\tWARNING: Species "%s" does not exist in sMP structure.\n',...
                    sSpecies);
                return;
            end
            
            % get structure of species
            xSpecies = obj.sMP.(sContext).(sSpecies);
            
        end % getSpeciesStruct
        
        % =================================================================
        
        function cSubspecies = getSubspecies(obj,sContext,sSpecies)
        % get list of all subspecies names in given context.species of sMP
        % structure
            
            % init subspecies list
            cSubspecies = {};
            
            % get struct of given species
            xSpecies = obj.getSpeciesStruct(sContext,sSpecies);
            
            % get all fieldnames of species
            cSpeciesFields = fieldnames(xSpecies);
            
            % check fields
            for nField=1:numel(cSpeciesFields)
                
                % this fieldname
                sField = cSpeciesFields{nField};
                
                % subspecies if field is structure
                if isstruct(xSpecies.(sField))
                    
                    % subspecies if field is not input or output
                    if not(strcmp(sField,obj.sStdInputName)) && ...
                            not(strcmp(sField,obj.sStdOutputName))
                        
                        % append as subspecies name
                        cSubspecies = [cSubspecies,sField]; %#ok<AGROW>
                        
                    end % not in or out
                    
                end % isstruct
                
            end % cSpeciesFields
            
        end % getSubspecies
        
        % =================================================================
        
        function cInputs = getInputs(obj,sContext,sSpecies)
      	% get list of all input signal names in given context.species of
      	% sMP structure
            
            cInputs = obj.getSubparams(sContext,sSpecies,obj.sStdInputName);
            
        end % getInputs
        
        % =================================================================
        
        function cOutputs = getOutputs(obj,sContext,sSpecies)
        % get list of all output signal names in given context.species of
        % sMP structure
            
            cOutputs = obj.getSubparams(sContext,sSpecies,obj.sStdOutputName);
            
        end % getOutputs
        
        % =================================================================
        
        function cParams = getParams(obj,sContext,sSpecies)
        % get list of all parameter names out of subspecies in given 
        % context.species of sMP structure
            
            % get struct of given species
            xSpecies = obj.getSpeciesStruct(sContext,sSpecies);
            
            % get fields to ignore (structures)
            cIgnoreFields = [obj.getSubspecies(sContext,sSpecies),...
                obj.sStdInputName,obj.sStdOutputName];
            
            % get all fieldnames of species
            cSpeciesFields = fieldnames(xSpecies);
            
            % get not ignore members
            bIsParam = not(ismember(cSpeciesFields,cIgnoreFields));
            
            % filter params
            cParams = cSpeciesFields(bIsParam);
            
        end

        % =================================================================
        
        function cSubParams = getSubparams(obj,sContext,sSpecies,sSubspecies)
        % get list of all parameter names in given subspecies in given
        % context.species of sMP structure
            
            % get struct of given species
            xSpecies = obj.getSpeciesStruct(sContext,sSpecies);
            
            % check field inputs in species
            if isfield(xSpecies,sSubspecies)
                cSubParams = fieldnames(xSpecies.(sSubspecies));
            else
                cSubParams = {};
            end
            
        end % getSubparams

        % =================================================================
        
        function sSmpName = getSmpName(~,sContext,sSpecies,sName,sSubspecies)
        % concatenated sMP structure of given name considering
        % context.species and subspecies
            
            % optional argument subspecies
            if nargin  < 5
                sSubspecies = '';
            end
            
            % create sMP name
            if isempty(sSubspecies)
                sSmpName = sprintf('sMP.%s.%s.%s',...
                    sContext,sSpecies,sName);
            else
                sSmpName = sprintf('sMP.%s.%s.%s.%s',...
                    sContext,sSpecies,sSubspecies,sName);
            end
            
        end % getSmpName
        
        % =================================================================
        
        function [sContext,sSpecies,sSubspecies,sName] = splitSmpName(~,sSmpName)
        % split sMP structure variable:
        % sMP.{sContext}.{sSpecies}.{sSubspecies}.{sName}
        % sMP.{sContext}.{sSpecies}.{sName}
            
            % split sMP variable by dot
            cSplit = strsplit(sSmpName,'.');
            
            % check number of structure levels
            if (numel(cSplit) > 5) || numel(cSplit) < 4
                error('No valid sMP variable structure: "%s".',sSmpName);
            end
            
            % get subspecies and name
            if numel(cSplit) == 5
                sSubspecies = cSplit{4};
                sName = cSplit{5};
            else
                sSubspecies = '';
                sName = cSplit{4};
            end
            
            % get context and species
            sContext = cSplit{2};
            sSpecies = cSplit{3};
            
        end % splitSmpName

    end % sMP structure methods

    % =====================================================================
    % configuration data METHODS:
    %   xModule = obj.getModuleStruct(sContext,sSpecies)
    %   xSetup = obj.getSetupStruct(sContext,sSpecies)
    %   [sLogType,vLogStepSize] = obj.getLogData
    %   xInitOrder = obj.getInitOrderStruct
    %   [vSimStepSize,vLogStepSize,cModuleStepSizeList] = obj.getStepSizeData
    %   cSignalList = obj.getSignalListFromConfig
    %   cSignalList = obj.getSignalListFromModules
    % =====================================================================
    
    methods (Access = private)
        
        function xModule = getModuleStruct(obj,sContext,sSpecies)
        % get module xml structure of given context.species
            
            % init module struct
            xModule = struct([]);
            
            % search in list
            for nMod=1:numel(obj.xModuleXml)
                
                % search for context name
                if strcmpi(strtrim(obj.xModuleXml(nMod).('context')),sContext)
                    
                    % search for species name
                    if strcmpi(strtrim(obj.xModuleXml(nMod).('species')),sSpecies)
                        xModule = [xModule,obj.xModuleXml(nMod)]; %#ok<AGROW>
                    end
                    
                end
                
            end % obj.xModuleXml
            
            % check number of modules
            if isempty(xModule)
                error('"%s.%s" does not exist in module xml list.',...
                	sContext,sSpecies);
            elseif numel(xModule) > 1
                error('More than one "%s.%s" was found in module xml list.',...
                	sContext,sSpecies);
            end
            
        end % getModuleStruct
        
        % =================================================================
        
        function xSetup = getSetupStruct(obj,sContext,sSpecies)
        % get setup xml structure of given context.species
           
            % init setup struct
            xSetup = struct([]);
            
            % search in list
            for nSet=1:numel(obj.xSetupXml)
                
                % search for context name
                if strcmpi(strtrim(obj.xSetupXml(nSet).('Module').('context')),sContext)
                    
                    % search for species name
                    if strcmpi(strtrim(obj.xSetupXml(nSet).('Module').('species')),sSpecies)
                        xSetup = [xSetup,obj.xSetupXml(nSet)]; %#ok<AGROW>
                    end
                    
                end
                
            end % obj.xSetupXml
            
            % check number of setups
            if isempty(xSetup)
                error('"%s.%s" does not exist in setup list.',...
                	sContext,sSpecies);
            elseif numel(xSetup) > 1
                error('More than one "%s.%s" was found in setup list.',...
                	sContext,sSpecies);
            end
            
        end % getSetupStruct
        
        % =================================================================
        
        function [sLogType,vLogStepSize] = getLogData(obj)
            
            % get loggin type
            try
                sLogType = obj.xConfigXml.('Interface').('LogSetup').('sampleType');
            catch
                sLogType = '';
            end
            
            % get logging step size
            try
                
                % get step size from config
                vLogStepSize = obj.xConfigXml.('Interface').('LogSetup').('sampleTime');
                
                % convert to number
                vLogStepSize = obj.convert2Number(vLogStepSize);
                
            catch
                vLogStepSize = [];
            end
            
        end % getLogData
        
        % =================================================================
        
        function xInitOrder = getInitOrderStruct(obj)
            
            % init list
            xInitOrder = struct([]);
            
            % get context names
            cContextNames = obj.getContextNames;
            
            % handle each context
            for nCtx=1:numel(cContextNames)
                
                % current context
                sContext = cContextNames{nCtx};
                
                % get species names
                cSpeciesNames = obj.getSpeciesNames(sContext);
                
                % handle each species
                for nSpc=1:numel(cSpeciesNames)
                    
                    % current species
                    sSpecies = cSpeciesNames{nSpc};
                    
                    % get setup struct of species
                    nInitOrder = obj.getInitOrderOfModule(sContext,sSpecies);
                    
                    % this init order structure
                    % -----------------------------------------------------
                    xThisInitOrder.('context') = sContext;
                    xThisInitOrder.('species') = sSpecies;
                    xThisInitOrder.('initOrder') = nInitOrder;
                    % -----------------------------------------------------
                    
                    % append init order in list
                    xInitOrder = [xInitOrder,xThisInitOrder]; %#ok<AGROW>
                    
                end % cSpeciesNames
                
            end % cContextNames
            
            % sort list by initOrder
            xInitOrder = obj.sortStructByField(xInitOrder,'initOrder');
            
        end % getInitOrderList
        
        % =================================================================
        
        function [vSimStepSize,vLogStepSize,cModuleStepSizeList] = getStepSizeData(obj)
            
            % init list
            cModuleStepSizeList = {};
            
            % get simulation step size
            try
                
                % get main step size
                vSimStepSize = obj.xConfigXml.('MasterSolver').('maxCosimStepsize');
                
                % convert to number
                vSimStepSize = obj.convert2Number(vSimStepSize);
                
            catch
                vSimStepSize = [];
            end
            
            % get logging step size
            [~,vLogStepSize] = obj.getLogData;
            
            % get context names
            cContextNames = obj.getContextNames;
            
            % handle each context
            for nCtx=1:numel(cContextNames)
                
                % current context
                sContext = cContextNames{nCtx};
                
                % get species names
                cSpeciesNames = obj.getSpeciesNames(sContext);
                
                % handle each species
                for nSpc=1:numel(cSpeciesNames)
                    
                    % current species
                    sSpecies = cSpeciesNames{nSpc};
                    
                    % get setup struct of species
                    vStepSize = obj.getStepSizeOfModule(sContext,sSpecies);
                    
                    % append init order in list
                    cModuleStepSizeList = [cModuleStepSizeList;...
                        {sContext,sSpecies,vStepSize}]; %#ok<AGROW>
                    
                end % cSpeciesNames
                
            end % cContextNames
            
        end % getStepSizeData
        
        % =================================================================
        
        function cSignalList = getSignalListFromConfig(obj)
            
            % init list
            cSignalList = {};
            
            % get signal list to be logged from configuration
            if isfield(obj.xConfigXml,'Interface')
                
                if isfield(obj.xConfigXml.('Interface'),'Logging')
                    
                    % get log signal list from config xml
                    cSignalList = obj.getFieldValues(...
                        obj.xConfigXml.('Interface').('Logging'),'name');
                    
                end % Logging
                
            end % Interface
            
        end % getLoggingSignalList
        
        % =================================================================
        
        function cSignalList = getSignalListFromModules(obj)
            
            % init list
            cSignalList = {};
            
            % get file list with logging signals
            if isfield(obj.sMP,'cfg') && isfield(obj.sMP.('cfg'),'cLogAdd')
                cAddLogFileList = obj.sMP.('cfg').('cLogAdd');
            else
                cAddLogFileList = {};
            end
            
            % check if files exists
            for nFile=1:numel(cAddLogFileList)
                
                % create fullpath of file
                sLogFilepath = fullfile(obj.CONST.sWorkspaceFolder,...
                    cAddLogFileList{nFile});
                
                % check if file exists
                if ~chkFileExists(sLogFilepath)
                    
                    % display warning if file not exists
                    fprintf(2,'\tWARNING: Module log file "%s" was not found.\n',...
                        sLogFilepath);
                    
                else
                    
                    % read file content
                    sTxt = fleFileRead(sLogFilepath);
                    
                    % create list from file content
                    cSignalList = strStringListClean(strStringToLines(sTxt));
                    
                end % file exist
                
            end % log file list
            
        end % getSignalListFromModules
        
    end % configuration data methods
    
    % =====================================================================
    % module xml METHODS:
    %   [xIdxPortList,xRawPortList] = obj.getPortAttribList(sContext,sSpecies,sPortType)
    %   [xIdxParamList,xRawParamList] = obj.getParamAttribList(sContext,sSpecies)
    %   xInport = obj.getInportStruct(sContext,sSpecies,sInputName)
    %   xOutport = obj.getOutportStruct(sContext,sSpecies,sOutputName)
    %   xParam = obj.getParamStruct(sContext,sSpecies,sClassName,sParamName)
    %   xInportList = obj.getInportList(sContext,sSpecies)
    %   xOutportList = obj.getOutportList(sContext,sSpecies)
    %   xParamList = obj.getParamList(sContext,sSpecies)
    %   nInitOrder = obj.getInitOrderOfModule(sContext,sSpecies)
    %   vStepSize = obj.getStepSizeOfModule(sContext,sSpecies)
    % =====================================================================
    
    methods (Access = private)
        
        function [xIdxPortList,xRawPortList] = getPortAttribList(obj,sContext,sSpecies,sPortType)
            
            % init lists
            xIdxPortList = struct([]);
            xRawPortList = struct([]);
            
            % get port names
            if strcmp(sPortType,obj.sStdInputName)
                cPortNames = obj.getInputs(sContext,sSpecies);
            elseif strcmp(sPortType,obj.sStdOutputName)
                cPortNames = obj.getOutputs(sContext,sSpecies);
            else
                return;
            end
            
            % get port attribute structure lists
            for nPort=1:numel(cPortNames)
                
                % get attribute structures of port
                [xPortIdx,xPortRaw] = obj.getPortAttrib(...
                    sContext,sSpecies,sPortType,cPortNames{nPort});
                
                % append structure in list
                xIdxPortList = [xIdxPortList,xPortIdx]; %#ok<AGROW>
                xRawPortList = [xRawPortList,xPortRaw]; %#ok<AGROW>
                
            end % cPortNames
            
        end % getPortAttribList
        
        % =================================================================
        
        function [xIdxParamList,xRawParamList] = getParamAttribList(obj,sContext,sSpecies)
            
            % init lists
            xIdxParamList = struct([]);
            xRawParamList = struct([]);
            
            % -------------------------------------------------------------
            
            % get parameter names without subspecies
            cParamNames = obj.getParams(sContext,sSpecies);
            
            % get parameter attribute structure lists
            for nParam=1:numel(cParamNames)
                
                % get attribute structures of parameter
                [xParamIdx,xParamRaw] = obj.getParamAttrib(...
                    sContext,sSpecies,'',cParamNames{nParam});
                
                % append structure in list
                xIdxParamList = [xIdxParamList,xParamIdx]; %#ok<AGROW>
                xRawParamList = [xRawParamList,xParamRaw]; %#ok<AGROW>
                
            end % cParamNames
            
            % -------------------------------------------------------------
            
            % get subspecies names
            cSubspecies = obj.getSubspecies(sContext,sSpecies);
            
            % get parameter of subspecies
            for nSub=1:numel(cSubspecies)
                
                % get parameter names of subspecies
                cSubParamNames = obj.getSubparams(sContext,sSpecies,...
                    cSubspecies{nSub});
                
                % get parameter attribute structure lists
                for nParam=1:numel(cSubParamNames)
                    
                    % get attribute structures of parameter
                    [xParamIdx,xParamRaw] = obj.getParamAttrib(...
                        sContext,sSpecies,cSubspecies{nSub},...
                        cSubParamNames{nParam});

                    % append structure in list
                    xIdxParamList = [xIdxParamList,xParamIdx]; %#ok<AGROW>
                    xRawParamList = [xRawParamList,xParamRaw]; %#ok<AGROW>
                    
                end % cSubParamNames
                
            end % cSubspecies
            
            % -------------------------------------------------------------
            
            % get initIO parameters for inputs
            cInputNames = obj.getInputs(sContext,sSpecies);
            
            % get initIO input params
            for nIn=1:numel(cInputNames)
                
                % get attribute structures of parameter
                [xParamIdx,xParamRaw] = obj.getParamAttrib(...
                    sContext,sSpecies,obj.sStdInputName,...
                    cInputNames{nIn},obj.sStdInitIoName);

                % append structure in list
                xIdxParamList = [xIdxParamList,xParamIdx]; %#ok<AGROW>
                xRawParamList = [xRawParamList,xParamRaw]; %#ok<AGROW>
                
            end % cInputNames
            
            % -------------------------------------------------------------
            
            % get initIO parameters for outputs
            cOutputNames = obj.getOutputs(sContext,sSpecies);
            
            % get initIO output params
            for nOut=1:numel(cOutputNames)
                
                % get attribute structures of parameter
                [xParamIdx,xParamRaw] = obj.getParamAttrib(...
                    sContext,sSpecies,obj.sStdOutputName,...
                    cOutputNames{nOut},obj.sStdInitIoName);

                % append structure in list
                xIdxParamList = [xIdxParamList,xParamIdx]; %#ok<AGROW>
                xRawParamList = [xRawParamList,xParamRaw]; %#ok<AGROW>
                
            end % cOutputNames
            
        end % getOutportAttribList
        
        % =================================================================
        
        function xInport = getInportStruct(obj,sContext,sSpecies,sInputName)
            
            % get inport structure list from module xml
            xInportList = obj.getInportList(sContext,sSpecies);
            
            % get specifies input
            xInport = obj.getStructOfFieldValue(xInportList,'name',sInputName);
            
        end % getInportStruct
        
        % =================================================================
        
        function xOutport = getOutportStruct(obj,sContext,sSpecies,sOutputName)
            
            % get inport structure list from module xml
            xOutportList = obj.getOutportList(sContext,sSpecies);
            
            % get specifies input
            xOutport = obj.getStructOfFieldValue(xOutportList,'name',sOutputName);
            
        end % getOutportStruct
        
        % =================================================================
        
        function xParam = getParamStruct(obj,sContext,sSpecies,sClassName,sParamName)
            
            % get inport structure list from module xml
            xParamList = obj.getParamList(sContext,sSpecies,sClassName);
            
            % get specifies input
            xParam = obj.getStructOfFieldValue(xParamList,'name',sParamName);
            
        end % getParamStruct
        
        % =================================================================
        
        function xInportList = getInportList(obj,sContext,sSpecies)
        % get xml input structure from module of given context.species
            
            % get module struct
            xModule = obj.getModuleStruct(sContext,sSpecies);
            
            % get inport struct
            try
                xInportList = xModule.('Interface').('Inport');
            catch
                xInportList = struct([]);
            end
            
        end % getInportList
        
        % =================================================================
        
        function xOutportList = getOutportList(obj,sContext,sSpecies)
        % get xml output structure from module of given context.species
            
            % get module struct
            xModule = obj.getModuleStruct(sContext,sSpecies);
            
            % get outport struct
            try
                xOutportList = xModule.('Interface').('Outport');
            catch
                xOutportList = struct([]);
            end
            
        end % getOutportList
        
        % =================================================================
        
        function xParamList = getParamList(obj,sContext,sSpecies,sClass)
        % get xml parameter structure from module of given context.species
            
            % check class
            if nargin < 4
                sClass = '';
            end
        
            % get module struct
            xModule = obj.getModuleStruct(sContext,sSpecies);
            
            % get parameter struct
            try
                xParamList = xModule.('Interface').('Parameter');
            catch
                xParamList = struct([]);
            end
            
            % get parameters of given class
            if not(isempty(sClass))
                xParamList = obj.getStructOfFieldValue(xParamList,...
                    'className',sClass);
            end
            
        end % getParamList
        
        % =================================================================
        
        function nInitOrder = getInitOrderOfModule(obj,sContext,sSpecies)
            
            % get setup struct of module
            xSetup = obj.getSetupStruct(sContext,sSpecies);
            
            % get init order of module
            try
                
                % get init order
                nInitOrder = xSetup.('initOrder');
                
                % convert to number
                nInitOrder = obj.convert2Number(nInitOrder);
                
            catch
                nInitOrder = [];
            end
            
        end % getInitOrderOfModule
        
        % =================================================================
        
        function vStepSize = getStepSizeOfModule(obj,sContext,sSpecies)
            
            % get module struct of module
            xModule = obj.getModuleStruct(sContext,sSpecies);
            
            % get step size of module
            try
                
                % get init order
                vStepSize = xModule.('maxCosimStepsize');
                
                % convert to number
                vStepSize = obj.convert2Number(vStepSize);
                
            catch
                vStepSize = [];
            end
            
        end % getStepSizeOfModule
        
    end % module xml methods
    
    % =====================================================================
    % port / parameter property METHODS:
    %   [xPortIdx,xPortRaw] = obj.getPortAttrib(sContext,sSpecies,sPortType,sName)
    %   [xParamIdx,xParamRaw] = obj.getParamAttrib(sContext,sSpecies,sSubspecies,sName,sClass)
    %   sValue = obj.getValue(sContext,sSpecies,sSubspecies,sName)
    %   sClassName = obj.getClassName(xParam,sName)
    %   nIndex = obj.getIndex(xPort,sName)
    %   sDescript = obj.getDescription(xPort)
    %   sUnit = obj.getUnit(xPort)
    %   sClass = obj.getDataClass(xPort)
    %   [sSna,sMaxRange,sMinRange] = obj.getSignalRange(xPort)
    % =====================================================================
    
    methods (Access = private)
        
        function [xPortIdx,xPortRaw] = getPortAttrib(obj,sContext,sSpecies,sPortType,sName)
            
            % get sMP structure name
            sVariableName = obj.getSmpName(sContext,sSpecies,sName,sPortType);
            
            % get port value
          	vValue = obj.getValue(sContext,sSpecies,sPortType,sName);
            
            % get port structure
            if strcmp(sPortType,obj.sStdInputName)
                xPort = obj.getInportStruct(sContext,sSpecies,sName);
            elseif strcmp(sPortType,obj.sStdOutputName)
                xPort = obj.getOutportStruct(sContext,sSpecies,sName);
            else
                xPortIdx = struct([]);
                xPortRaw = struct([]);
                return;
            end
            
            % check for not present in module xml
            if not(isempty(xPort))
                
                % get index of port
                nIndex = obj.getIndex(xPort,sVariableName);

                % get port unit
                sUnit = obj.getUnit(xPort);
                
                % get port comment description
                sComment = obj.getDescription(xPort);
                
                % get port range limits
                [sSna,sMaxRange,sMinRange] = obj.getSignalRange(xPort);
                
            else
                nIndex = [];
                sUnit = '';
                sComment = '';
                sSna = '';
                sMaxRange = '';
                sMinRange = '';
            end
            
            % -------------------------------------------------------------
            xPortRaw.('variable') = sVariableName;
            xPortRaw.('name') = sName;
            xPortRaw.('type') = sPortType;
            xPortRaw.('value') = vValue;
            xPortRaw.('species') = sSpecies;
            xPortRaw.('index') = nIndex;
            xPortRaw.('unit') = sUnit;
            xPortRaw.('comment') = sComment;
            xPortRaw.('sna') = sSna;
            xPortRaw.('maxValue') = sMaxRange;
            xPortRaw.('minValue') = sMinRange;
            % -------------------------------------------------------------
            
            % check index
            if not(isempty(nIndex))
              	xPortIdx = xPortRaw;
            else
                xPortIdx = struct([]);
            end
            
        end % getPortAttrib
        
        % =================================================================
        
        function [xParamIdx,xParamRaw] = getParamAttrib(obj,sContext,sSpecies,sSubspecies,sName,sClass)
            
            % get class name
            if nargin < 6
                sClass = sSubspecies;
            end
            
            % get sMP structure name
            sVariableName = obj.getSmpName(sContext,sSpecies,sName,sSubspecies);
            
            % get parameter value
          	vValue = obj.getValue(sContext,sSpecies,sSubspecies,sName);
            
            % get subspecies flag
            if isempty(sSubspecies) || ...
                    strcmp(sSubspecies,obj.sStdInputName) || ...
                    strcmp(sSubspecies,obj.sStdOutputName)
                bIsSubspecies = false;
            else
                bIsSubspecies = true;
            end
            
            % get parameter structure
            xParam = obj.getParamStruct(sContext,sSpecies,sClass,sName);
            
            % check for not present in module xml
            if not(isempty(xParam))
            
                % get class name of parameter
                sDataClass = obj.getDataClass(xParam);
                
                % get index of parameter
                nIndex = obj.getIndex(xParam,sVariableName);

                % get parameter unit
                sUnit = obj.getUnit(xParam);
                
                % get parameter comment description
                sComment = obj.getDescription(xParam); 
                
            else
                sDataClass = '';
                nIndex = [];
                sUnit = '';
                sComment = '';
            end

            % ---------------------------------------------------------
            xParamRaw.('variable') = sVariableName;
            xParamRaw.('name') = sName;
            xParamRaw.('value') = vValue;
            xParamRaw.('isSubspecies') = bIsSubspecies;
            xParamRaw.('class') = sDataClass;
            xParamRaw.('species') = sSpecies;
            xParamRaw.('index') = nIndex;
            xParamRaw.('unit') = sUnit;
            xParamRaw.('comment') = sComment;
            % ---------------------------------------------------------

            % check index
            if not(isempty(nIndex))
                xParamIdx = xParamRaw;
            else
                xParamIdx = struct([]);
            end
            
        end % getParamAttrib
        
        % =================================================================
        
        function sValue = getValue(obj,sContext,sSpecies,sSubspecies,sName)
            
            % get value from sMP structure
            if not(isempty(sSubspecies))
                sValue = obj.sMP.(sContext).(sSpecies).(sSubspecies).(sName);
            else
                sValue = obj.sMP.(sContext).(sSpecies).(sName);
            end
            
        end % getValue
        
        % =================================================================
        
        function sClassName = getClassName(~,xParam,sName)
            
            % init output
            sClassName = '';
            
            % get class name from structure
            if isfield(xParam,'className')
                sClassName = strtrim(xParam.('className'));
            else
                fprintf(2,'\tWARNING: No className found for "%s".\n',...
                    sName);
            end
            
        end % getClassName
        
        % =================================================================
        
        function nIndex = getIndex(obj,xPort,sName)
            
            % get indices
            try
                
                % get index value list from structure
                cIndices = obj.getFieldValues(xPort,'index');
                
                % format from string to number
                nIndex = str2double(cIndices);
                
                % delete NaN values
                nIndex = nIndex(not(isnan(nIndex)));
                
            catch
                nIndex = [];
            end
            
            % check and format to number
            if numel(nIndex) > 1
                fprintf(2,'\tWARNING: More than one indices defined for "%s" in module xml!\n',...
                    sName);
                nIndex = nIndex(end);
            end
            
        end % getIndex
        
        % =================================================================
        
        function sDescript = getDescription(~,xPort)
            
            % init output
            sDescript = '';
            
            % get description from parameter
            if isfield(xPort,'description')
                sDescript = strtrim(xPort.('description'));
                return;
            end
            
            % get manual description from port
            if isfield(xPort,'manualDescription')
                sManualDescript = strtrim(xPort.('manualDescription'));
                if not(isempty(sManualDescript))
                    sDescript = sManualDescript;
                    return;
                end
            end
            
            % get auto description from port
            if isfield(xPort,'autoDescription')
                sAutoDescript = strtrim(xPort.('autoDescription'));
                if not(isempty(sAutoDescript))
                    sDescript = sAutoDescript;
                    return;
                end
            end
            
        end % getDescription
        
        % =================================================================
        
        function sUnit = getUnit(~,xPort)
            
            % init output
            sUnit = '';
            
            % get unit
            if isfield(xPort,'unit')
                sUnit = strtrim(xPort.('unit'));
            end
            
        end % getUnit
        
        % =================================================================
        
        function sClass = getDataClass(~,xPort)
            
            % init output
            sClass = '';
            
            % get unit
            if isfield(xPort,'className')
                sClass = strtrim(xPort.('className'));
            end
            
        end % getDataClass
        
        % =================================================================
        
        function [sSna,sMaxRange,sMinRange] = getSignalRange(~,xPort)
            
            % init outputs
            sSna = '';
            sMaxRange = '';
            sMinRange = '';
            
            % get sna
            if isfield(xPort,'sna')
                sSna = strtrim(xPort.('sna'));
            end
            
            % get max physical range
            if isfield(xPort,'maxPhysicalRange')
                sMaxRange = strtrim(xPort.('maxPhysicalRange'));
            end
            
            % get min physical range
            if isfield(xPort,'minPhysicalRange')
                sMinRange = strtrim(xPort.('minPhysicalRange'));
            end
            
        end % getSignalRange
        
    end % port / parameter property methods
    
    % =====================================================================
    
    methods (Access = private)
        
        function [xStruct,xInvStruct] = getStructOfFieldValue(obj,xStructList,sField,sValue)
        % get structures with matching values in given field of structure
        % list
            
            % get values of specified field
            cValues = obj.getFieldValues(xStructList,sField);

            % get indices in structure of specified field value
            [nPosIdx,nInvPosIdx] = obj.getPosIndexInList(cValues,sValue);

            % get structure
            xStruct = xStructList(nPosIdx);
            xInvStruct = xStructList(nInvPosIdx);
            
        end % getStructOfFieldValue
        
        % =================================================================
        
        function xStruct = sortStructByField(obj,xStruct,sFieldName,bAlphabetic)
            
            % check input
            if nargin < 4
                bAlphabetic = false;
            end
            
            % check for empty structure
            if isempty(xStruct)
                return;
            end
            
            % get values of field of interest
            cFieldvalues = obj.getFieldValues(xStruct,sFieldName);
            
            if isempty(cFieldvalues)
                return;
            end
            
            % sort index array
            if bAlphabetic
                [~,nSortIdx] = sortrows(lower(cFieldvalues));
            else
                [~,nSortIdx] = sortrows(cFieldvalues);
            end
            
            % sort structure by index array
            xStruct = xStruct(nSortIdx);
            
        end % sortStructByField
        
    end % private methods
    
    % =====================================================================
    
    methods (Static, Access = private)
        
        function cFieldvalues = getFieldValues(xStruct,sField)
        % get list of values of given field in structure list
            
            if isfield(xStruct,sField)
                cFieldvalues = {xStruct(:).(sField)}';
            else
                cFieldvalues = {};
            end
            
        end % getFieldValues
        
        % =================================================================
        
        function [nPosIdx,nInvPosIdx] = getPosIndexInList(cList,sName)
        % get index array of matching names in given name list
            
            if not(isempty(cList))
                nPosList = 1:numel(cList);
                bIsPos = ismember(cList,sName);
                nPosIdx = nPosList(bIsPos);
                nInvPosIdx = nPosList(not(bIsPos));
            else
                nPosIdx = [];
                nInvPosIdx = [];
            end
            
        end % getPosIndexInList

        % =================================================================
        
        function vValue = convert2Number(sValue)
        % converts given value to number if not is numeric
            
            if isnumeric(sValue)
                vValue = sValue;
            elseif ischar(sValue)
                vValue = str2double(sValue);
                if isnan(vValue)
                    vValue = [];
                end
            elseif islogical(sValue)
                vValue = double(sValue);
            else
                vValue = [];
            end
            
        end % convert2Number
        
    end % private static methods
    
end % dveClassSmp
