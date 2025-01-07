classdef parClassDll < parSuperclassMethods
    
    properties % MUST NOT BE PRIVATE AND CONSTANT !
        
        % -----------------------------------------------------------------
        % DEFINE CONFIG PARAMETER NAMES OF SFU:
        DllFile = 'DllFile';
        UserConfigString = 'UserConfigString';
        OutRenameFile = 'OutRenameFile';
        % -----------------------------------------------------------------
        
    end % properties
    
    % =====================================================================
    
    properties (Constant, Access = private) % MUST BE PRIVATE !
        
        % -----------------------------------------------------------------
        % DEFINE NAME OF SFU TEMPLATE:
        sThisSfuName = 'template_SFU_dll';
        
        % -----------------------------------------------------------------
        
    end % constant private properties
    
    % =====================================================================
    
    methods
    
        function obj = parClassDll(oCONST)
            
            % create SFU parameter object
            obj@parSuperclassMethods(oCONST);
            obj.setSfuName(obj.sThisSfuName);
            
            % -------------------------------------------------------------
            % CREATE SIL LINES FOR MODULES OF SFU:
            
            % dll sil line
            sDllSilLine = sprintf('${%s} ${%s}',...
            	obj.DllFile,...
            	obj.UserConfigString);
            
            % collect all module sil lines
            cSilLines = {sDllSilLine};
            
            % -------------------------------------------------------------
            
            % set defined module sil lines
            obj.setModuleSilLines(cSilLines);
            
        end % parClassDll
        
    end % methods
    
end