classdef parClassSfcnGt < parSuperclassMethods
    
    properties % MUST NOT BE PRIVATE AND CONSTANT !
        
        % -----------------------------------------------------------------
        % DEFINE CONFIG PARAMETER NAMES OF SFU:
        MexFile = 'MexFile';
        ParamFile = 'ParamFile';
        PortAliasFile = 'PortAliasFile';
        ModuleStepSize = 'ModuleStepSize';
        GtSuiteVersion = 'GtSuiteVersion';
        OutRenameFile = 'OutRenameFile';
        % -----------------------------------------------------------------
        
    end % properties
    
    % =====================================================================
    
    properties (Constant, Access = private) % MUST BE PRIVATE !
        
        % -----------------------------------------------------------------
        % DEFINE NAME OF SFU TEMPLATE:
        sThisSfuName = 'template_SFU_sfcnGt';
        
        % -----------------------------------------------------------------
        % DEFINE PYTHON SUPPORT SCRIPTS:
        %   => !!! Must be present in folder obj.CONST.sSilverSupportFromMaster
        
        % GT file copy script
        sGtFileCopyScript = 'DIVeCopyGTFiles.py';
        
        % GT clean up script
        sGtCleanUpScript = 'DIVeCleanUpGTFiles.py';
        
        % -----------------------------------------------------------------
        
    end % constant private properties
    
    % =====================================================================
    
    methods
    
        function obj = parClassSfcnGt(oCONST)
            
            % create SFU parameter object
            obj@parSuperclassMethods(oCONST);
            obj.setSfuName(obj.sThisSfuName);
            
            % -------------------------------------------------------------
            % CREATE SIL LINES FOR MODULES OF SFU:
            
            % Python script 1 sil line
            sPyScript1Line = sprintf('Python.dll %s -a %s%s${%s}%s %s${%s}%s%s -V 3',...
                fullfile(obj.CONST.sSilverSupportFromMaster,obj.sGtFileCopyScript),...
                obj.CONST.sQuotReplaceString,...
                qtm,obj.GtSuiteVersion,qtm,...
                qtm,obj.ModuleStepSize,qtm,...
                obj.CONST.sQuotReplaceString);
            
            % sfunction sil line
            sSfcnSilLine = sprintf('SFunction.dll ${%s} -p ${%s} -q -a ${%s} -x 1',...
            	obj.MexFile,...
            	obj.ParamFile,...
            	obj.PortAliasFile);
            
            % Python script 2 sil line
            sPyScript2Line = sprintf('Python.dll %s -V 3',...
                fullfile(obj.CONST.sSilverSupportFromMaster,obj.sGtCleanUpScript));
            
            % collect all module sil lines
            cSilLines = {sPyScript1Line;sSfcnSilLine;sPyScript2Line};
            
            % -------------------------------------------------------------
            
            % set defined module sil lines
            obj.setModuleSilLines(cSilLines);
            
        end % parClassSfcnGt
        
    end % methods
    
end