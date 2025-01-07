classdef parClassFmu < parSuperclassMethods
    
    properties % MUST NOT BE PRIVATE AND CONSTANT !
        
        % -----------------------------------------------------------------
        % DEFINE CONFIG PARAMETER NAMES OF SFU:
        FmuFile = 'FmuFile';
        OutRenameFile = 'OutRenameFile';
        % -----------------------------------------------------------------
        
    end % properties
    
    % =====================================================================
    
    properties (Constant, Access = private) % MUST BE PRIVATE !
        
        % -----------------------------------------------------------------
        % DEFINE NAME OF SFU TEMPLATE:
        sThisSfuName = 'template_SFU_fmu';
        
        % -----------------------------------------------------------------
        
    end % constant private properties
    
    % =====================================================================
    
    methods
    
        function obj = parClassFmu(oCONST)
            
            % create SFU parameter object
            obj@parSuperclassMethods(oCONST);
            obj.setSfuName(obj.sThisSfuName);
            
            % -------------------------------------------------------------
            % CREATE SIL LINES FOR MODULES OF SFU:
            
            % sfunction sil line
            sSfcnSilLine = sprintf('Fmu20.dll -m ${%s}',...
            	obj.FmuFile);
            
            % collect all module sil lines
            cSilLines = {sSfcnSilLine};
            
            % -------------------------------------------------------------
            
            % set defined module sil lines
            obj.setModuleSilLines(cSilLines);
            
        end % parClassFmu
        
    end % methods
    
end