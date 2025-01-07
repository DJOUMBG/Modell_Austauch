classdef parSuperclassMethods < handle
    
    properties (Access = private)    % MUST BE PRIVATE !
        
        % name of SFU
        sSfuName = '';
        
        % sil lines of modules in SFU
        cModuleSilLines = {};
        
        % config parameter of SFU
        cConfigParams = {};
        
    end % private properties
    
    % =====================================================================
    
    properties (Access = protected)
        
        % transformation constant object
        CONST = cbtClassTrafoCONST.empty;
        
    end % protected properties
    
    % =====================================================================
    
    methods
        
        function obj = parSuperclassMethods(oCONST)
            
            % assign constant object
            obj.CONST = oCONST;
            
            % get config params from subclass
            obj.setConfigParams;
            
        end % parSuperclassMethods
        
        % =================================================================
        
        function sSfuName = getSfuName(obj)
            sSfuName = obj.sSfuName;
        end % getSfuName
        
        % =================================================================
        
        function cModuleSilLines = getModuleSilLines(obj)
            cModuleSilLines = obj.cModuleSilLines;
        end % getModuleSilLines
        
        % =================================================================
        
        function cConfigParams = getConfigParams(obj)
            cConfigParams = obj.cConfigParams;
        end % getConfigParams
        
    end % methods
    
    % =====================================================================
    
    methods (Access = protected)
        
        function setSfuName(obj,sSfuName)
            obj.sSfuName = sSfuName;
        end % setSfuName
        
        % =================================================================
        
        function setModuleSilLines(obj,cModuleSilLines)
            obj.cModuleSilLines = cModuleSilLines;
        end % setModuleSilLines
        
    end % protected methods
    
    % =====================================================================
    
    methods (Access = private)
        
        function setConfigParams(obj)
            
            % get properties of suf param class
            cPropNames = properties(obj);

            % init config parameter list
            obj.cConfigParams = {};

            % run through all properties
            for nProp=1:numel(cPropNames)
                obj.cConfigParams = [obj.cConfigParams;...
                    obj.(cPropNames{nProp})];
            end
            
        end % getConfigParams
        
    end % private methods
    
end