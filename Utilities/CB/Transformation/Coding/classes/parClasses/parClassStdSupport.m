classdef parClassStdSupport < parSuperclassMethods
    
    properties % MUST NOT BE PRIVATE AND CONSTANT !
        
        % -----------------------------------------------------------------
        % DEFINE CONFIG PARAMETER NAMES OF SFU:
        ModSignalListFile = 'ModSignalListFile';
        IoSignalListFile = 'IoSignalListFile';
        Matlab64Exe = 'Matlab64Exe';
        % -----------------------------------------------------------------
        
    end % properties
    
    % =====================================================================
    
    properties (Constant, Access = private) % MUST BE PRIVATE !
        
        % -----------------------------------------------------------------
        % DEFINE NAME OF SFU TEMPLATE:
        sThisSfuName = 'template_SFU_stdSupport';
        
        % -----------------------------------------------------------------
        % DEFINE PYTHON SUPPORT SCRIPTS:
        %   => !!! Must be present in folder obj.CONST.sSilverSupportFromMaster
        
        % check Matlab path script
        sCheckMatlabPathScript = 'DIVeCheckMatlabPath.py';
        
        % DIVe ONE communication script
        sDiveOneComScript = 'DIVeOneCommunication.py';
        
        % -----------------------------------------------------------------
        
    end % constant private properties
    
    % =====================================================================
    
    methods
    
        function obj = parClassStdSupport(oCONST)
            
            % create SFU parameter object
            obj@parSuperclassMethods(oCONST);
            obj.setSfuName(obj.sThisSfuName);
            
            % -------------------------------------------------------------
            % CREATE SIL LINES FOR MODULES OF SFU:
            
            % modifier 1 sil line
            sModifier1Line = sprintf('modifier.dll -f ${%s}',...
                obj.ModSignalListFile);
            
            % Python script sil line to check Matlab Exe path
            sMatlabCheckPyScriptLine = sprintf('Python.dll %s -a %s%s${%s}%s%s -V 3',...
                fullfile(obj.CONST.sSilverSupportFromMaster,obj.sCheckMatlabPathScript),...
                obj.CONST.sQuotReplaceString,...
                qtm,obj.Matlab64Exe,qtm,...
                obj.CONST.sQuotReplaceString);
            
            % modifier 2 sil line
            sModifier2Line = sprintf('modifier.dll -f ${%s}',...
                obj.IoSignalListFile);
            
            % simple controller
            sSimpleControllerLine = sprintf('simplecontroller.dll -a');
            
            % Python script sil line to communicate with DIVe ONE
            sDiveOneComPyScriptLine = sprintf('Python.dll %s -V 3',...
                fullfile(obj.CONST.sSilverSupportFromMaster,obj.sDiveOneComScript));
            
            % collect all module sil lines
            cSilLines = {sModifier1Line,sMatlabCheckPyScriptLine,...
                sModifier2Line,sSimpleControllerLine,sDiveOneComPyScriptLine};
            
            % -------------------------------------------------------------
            
            % set defined module sil lines
            obj.setModuleSilLines(cSilLines);
            
        end % parClassStdSupport
        
    end % methods
    
end