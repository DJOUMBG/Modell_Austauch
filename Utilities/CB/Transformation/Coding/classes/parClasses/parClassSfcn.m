classdef parClassSfcn < parSuperclassMethods
    
    properties % MUST NOT BE PRIVATE AND CONSTANT !
        
        % -----------------------------------------------------------------
        % DEFINE CONFIG PARAMETER NAMES OF SFU:
        MexFile = 'MexFile';
        ParamFile = 'ParamFile';
        PortAliasFile = 'PortAliasFile';
        OutRenameFile = 'OutRenameFile';
        % -----------------------------------------------------------------
        
    end % properties
    
    % =====================================================================
    
    properties (Constant, Access = private) % MUST BE PRIVATE !
        
        % -----------------------------------------------------------------
        % DEFINE NAME OF SFU TEMPLATE:
        sThisSfuName = 'template_SFU_sfcn';
        
        % -----------------------------------------------------------------
        
    end % constant private properties
    
    % =====================================================================
    
    methods
    
        function obj = parClassSfcn(oCONST)
            
            % create SFU parameter object
            obj@parSuperclassMethods(oCONST);
            obj.setSfuName(obj.sThisSfuName);
            
            % -------------------------------------------------------------
            % CREATE SIL LINES FOR MODULES OF SFU:
            
            % sfunction sil line
            sSfcnSilLine = sprintf('SFunction.dll ${%s} -p ${%s} -q -a ${%s}',...
            	obj.MexFile,...
            	obj.ParamFile,...
            	obj.PortAliasFile);
            
            % collect all module sil lines
            cSilLines = {sSfcnSilLine};
            
            % -------------------------------------------------------------
            
            % set defined module sil lines
            obj.setModuleSilLines(cSilLines);
            
        end % parClassSfcn
        
    end % methods
    
end