classdef parClassStdPost < parSuperclassMethods
    
    properties % MUST NOT BE PRIVATE AND CONSTANT !
        
        % -----------------------------------------------------------------
        % DEFINE CONFIG PARAMETER NAMES OF SFU:
        PostScriptListFile = 'PostScriptListFile';
        Matlab64Exe = 'Matlab64Exe';
        % -----------------------------------------------------------------
        
    end % properties
    
    % =====================================================================
    
    properties (Constant, Access = private) % MUST BE PRIVATE !
        
        % -----------------------------------------------------------------
        % DEFINE NAME OF SFU TEMPLATE:
        sThisSfuName = 'template_SFU_stdPost';
        
        % -----------------------------------------------------------------
        % DEFINE PYTHON SUPPORT SCRIPTS:
        %   => !!! Must be present in folder obj.CONST.sSilverSupportFromMaster
        
        % run post processing script
        sRunPostProcScript = 'DIVeRunPost.py';
        
        % -----------------------------------------------------------------
        
    end % constant private properties
    
    % =====================================================================
    
    methods
    
        function obj = parClassStdPost(oCONST)
            
            % create SFU parameter object
            obj@parSuperclassMethods(oCONST);
            obj.setSfuName(obj.sThisSfuName);
            
            % -------------------------------------------------------------
            % CREATE SIL LINES FOR MODULES OF SFU:
            
            % Python script sil line
            sPyScriptLine = sprintf('Python.dll %s -a %s${%s} %s %s${%s}%s%s -V 3',...
                fullfile(obj.CONST.sSilverSupportFromMaster,obj.sRunPostProcScript),...
                obj.CONST.sQuotReplaceString,...
                obj.PostScriptListFile,...
                obj.CONST.sResultFromMaster,...
                qtm,obj.Matlab64Exe,qtm,...
                obj.CONST.sQuotReplaceString);
            
            % collect all module sil lines
            cSilLines = {sPyScriptLine};
            
            % -------------------------------------------------------------
            
            % set defined module sil lines
            obj.setModuleSilLines(cSilLines);
            
        end % parClassStdPost
        
    end % methods
    
end