classdef parClassStdRangeCheck < parSuperclassMethods
    
    properties % MUST NOT BE PRIVATE AND CONSTANT !
        
        % -----------------------------------------------------------------
        % DEFINE CONFIG PARAMETER NAMES OF SFU:
        RangeCheckFile = 'RangeCheckFile';
        CheckStartTime = 'CheckStartTime';
        % -----------------------------------------------------------------
        
    end % properties
    
    % =====================================================================
    
    properties (Constant, Access = private) % MUST BE PRIVATE !
        
        % -----------------------------------------------------------------
        % DEFINE NAME OF SFU TEMPLATE:
        sThisSfuName = 'template_SFU_stdRangeCheck';
        
        % -----------------------------------------------------------------
        
    end % constant private properties
    
    % =====================================================================
    
    methods
    
        function obj = parClassStdRangeCheck(oCONST)
            
            % create SFU parameter object
            obj@parSuperclassMethods(oCONST);
            obj.setSfuName(obj.sThisSfuName);
            
            % -------------------------------------------------------------
            % CREATE SIL LINES FOR MODULES OF SFU:
            
            % Python script sil line
            sPyScriptLine = sprintf('Python.dll ${%s} -a %s${%s}%s -V 3',...
                obj.RangeCheckFile,...
                obj.CONST.sQuotReplaceString,...
                obj.CheckStartTime,...
                obj.CONST.sQuotReplaceString);
            
            % collect all module sil lines
            cSilLines = {sPyScriptLine};
            
            % -------------------------------------------------------------
            
            % set defined module sil lines
            obj.setModuleSilLines(cSilLines);
            
        end % parClassStdRangeCheck
        
    end % methods
    
end