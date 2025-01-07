classdef dveClassConfig < handle
    
    properties (SetAccess = protected, GetAccess = public)
        
        % configuration data structure
        xConfig = struct(...
            'sName','',...
            'vStepSize',0.01,...
            'vTimeEnd',inf,...
            'sLogType','mdf',...
            'sLogStepSize',0.01,...
            'xIoSignals',struct([]),...         % see obj.xStdIoSignalStruct
            'xRbuSignals',struct([]),...        % see obj.xStdRbuSignalStruct
            'cLogSignals',[],...
            'xLogParams',struct([]),...         % see obj.xStdLogParamStruct
            'xRangeCheckSignals',struct([]),... % see obj.xStdRangeCheckStruct
            'xModuleStepSizes',struct([]));     % see obj.xStdModuleStepSize
        
        % setup data object list
        oSetups = dveClassConfig.empty;
        
    end
    
    % =====================================================================
    
    properties (Access = private)
        
        % transformation constants
        CONST = cbtClassTrafoCONST.empty;
        
        % sMP structure
        sMP = struct([]);
        
        % configuration xml struct from sMP
        xConfigXml = struct([]);
        
        % module setup xml struct list from sMP
        xSetupXml = struct([]);
        
        % module xml struct list from sMP
        xModuleXml = struct([]);
        
    end % private properties
    
    % =====================================================================
    
    properties (Constant, Access = private)
        
        % default structure of init IO signal
        % (see obj.xConfig.xIoSignals)
        xStdIoSignalStruct = struct(...
            'variable','',...
            'name','',...
            'value',[]);
        
        % default structure of rbu routing signal
        % (see obj.xConfig.xRbuSignals)
        xStdRbuSignalStruct = struct(...
            'source','',...
            'destination',[]);
        
        % default structure of log parameter 
        % (see obj.xConfig.xLogParams)
        xStdLogParamStruct = struct(...
            'variable','',...
            'name','',...
            'value',[],...
            'isSubspecies',false,...
            'class','',...
            'species','',...
            'index',[],...
            'unit','',...
            'comment','');
        
        % default structure of range check signals
        % (see obj.xConfig.xRangeCheckSignals)
        xStdRangeCheckStruct = struct(...
            'variable','',...
            'name','',...
            'sna',[],...
            'maxValue',[],...
            'minValue',[]);
        
        % default structure of module step sizes
        xStdModuleStepSize = struct(...
            'species','',...
            'stepSize',[]);
        
    end % private constant properties
    
    % =====================================================================
    
    methods
        
        function obj = dveClassConfig(oCONST,sMP)
            
            % assign input arguments
            obj.CONST = oCONST;
            obj.sMP = sMP;
            
            % get xml structures from sMP
            obj.getXmlStructures;
            
        end % (constructor)
        
    end % public methods
    
    % =====================================================================
    
    methods (Access = private)
        
        function getXmlStructures(obj)
            
            % get cfg
            checkFieldname(obj.sMP,'cfg');
            xCfg = obj.sMP.('cfg');
            
            % get Configuration
            checkFieldname(xCfg,'Configuration');
            xConfiguration = xCfg.('Configuration');
            
            % get ModuleSetup xml list
            if isfield(xConfiguration,'ModuleSetup')
                obj.xSetupXml = xConfiguration.('ModuleSetup');
                obj.xConfigXml = rmfield(xConfiguration,'ModuleSetup');
            else
                obj.xSetupXml = struct([]);
                obj.xConfigXml = xConfiguration;
            end
            
            % get Modul xml list
            try
                obj.xModuleXml = xCfg.('xml').('Module');
            catch
                obj.xModuleXml = struct([]);
            end
            
        end % getXmlSubStructures
        
        % =================================================================
        
        function getConfigAttributes(obj)
            
            % get name 
            if isfield(obj.xConfigXml,'name')
                obj.xConfig.sName = obj.xConfigXml.('name');
            end
            
            % get and convert configuration step size
            try
                vStepSize = obj.convert2Number(...
                    obj.xConfigXml.MasterSolver.maxCosimStepsize);
                if not(isempty(vStepSize))
                    obj.xConfig.vStepSize = vStepSize;
                else
                    fprintf(2,'\t%s. Using default %d s instead.',...
                        'No valid step size was given in configuration',...
                        obj.xConfig.vStepSize);
                end
            catch
            end
            
            % get and convert simulation end time
            
            
        end % getConfigAttributes
        
    end % private methods
    
    % =====================================================================
    
    methods (Static, Access = private)
        
        function vValue = convert2Number(sValue)
            sValue = strtrim(sValue);
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
        
    end % static private methods
    
end % dveClassConfig
