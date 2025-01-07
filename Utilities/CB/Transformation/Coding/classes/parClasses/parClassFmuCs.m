classdef parClassFmuCs < parSuperclassMethods
    
    properties % MUST NOT BE PRIVATE AND CONSTANT !
        
        % -----------------------------------------------------------------
        % DEFINE CONFIG PARAMETER NAMES OF SFU:
        FmuFile = 'FmuFile';
        DymFile = 'DymFile';
        IoDymFile =  'IoDymFile';
        OutRenameFile = 'OutRenameFile';
        % -----------------------------------------------------------------
        
    end % properties
    
    % =====================================================================
    
    properties (Constant, Access = private) % MUST BE PRIVATE !
        
        % -----------------------------------------------------------------
        % DEFINE NAME OF SFU TEMPLATE:
        sThisSfuName = 'template_SFU_fmuCs';
        
        % -----------------------------------------------------------------
        
    end % constant private properties
    
    % =====================================================================
    
    methods
    
        function obj = parClassFmuCs(oCONST)
            
            % create SFU parameter object
            obj@parSuperclassMethods(oCONST);
            obj.setSfuName(obj.sThisSfuName);
            
            % -------------------------------------------------------------
            % CREATE SIL LINES FOR MODULES OF SFU:
            
            % sfunction sil line
            sSfcnSilLine = sprintf('Fmu20cs.dll -m ${%s} ${%s} ${%s}',...
            	obj.FmuFile,...
                obj.DymFile,...
                obj.IoDymFile);
            
            % collect all module sil lines
            cSilLines = {sSfcnSilLine};
            
            % -------------------------------------------------------------
            
            % set defined module sil lines
            obj.setModuleSilLines(cSilLines);
            
        end % parClassFmuCs
        
    end % methods
    
end