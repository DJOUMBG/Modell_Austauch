classdef parClassCosim < parSuperclassMethods
    
    properties % MUST NOT BE PRIVATE AND CONSTANT !
        
        % -----------------------------------------------------------------
        % DEFINE CONFIG PARAMETER NAMES OF SFU:
        ConnectTimeout = 'ConnectTimeout';
        OpenSimulink = 'OpenSimulink';
        MaxCosimStepsize = 'MaxCosimStepsize';
        CosimModelName = 'CosimModelName';
        CosimModelFile = 'CosimModelFile';
        CosimFolder = 'CosimFolder';
        MasterDir = 'MasterDir';
        Matlab64Exe = 'Matlab64Exe';
        % -----------------------------------------------------------------
        
    end % properties
    
    % =====================================================================
    
    properties (Constant, Access = private) % MUST BE PRIVATE !
        
        % -----------------------------------------------------------------
        % DEFINE NAME OF SFU TEMPLATE:
        sThisSfuName = 'template_SFU_cosim';
        
        % -----------------------------------------------------------------
        
    end % constant private properties
    
    % =====================================================================
    
    methods
    
        function obj = parClassCosim(oCONST)
            
            % create SFU parameter object
            obj@parSuperclassMethods(oCONST);
            obj.setSfuName(obj.sThisSfuName);
            
            % -------------------------------------------------------------
            % CREATE SIL LINES FOR MODULES OF SFU:
            
            % matlab arguments
            sMatlabArgs = '-nosplash -nodesktop -minimize -r';
            
            % matlab call
            sMatlabCall = sprintf(['${%s} %s cd(%s${%s}%s);addpath(genpath(fullfile(%s%s%s)));',...
                'InitSlave(%s${%s}%s,%s${%s}%s,%s${%s}%s);'],...
                obj.Matlab64Exe,...
                sMatlabArgs,...
                qtm,obj.MasterDir,qtm,...
                qtm,obj.CONST.sSilverSupportFromMaster,qtm,...
                qtm,obj.CosimFolder,qtm,...
                qtm,obj.CosimModelFile,qtm,...
                qtm,obj.OpenSimulink,qtm);
            
            % cosim sil line
            sCosimSilLine = sprintf('CoSimMaster.dll -a %s%s%s -c ${%s} -t ${%s} -n ${%s}',...
            	obj.CONST.sQuotReplaceString,...
                sMatlabCall,...
                obj.CONST.sQuotReplaceString,...
            	obj.MaxCosimStepsize,...
                obj.ConnectTimeout,...
            	obj.CosimModelName);
            
            % collect all module sil lines
            cSilLines = {sCosimSilLine};
            
            % -------------------------------------------------------------
            
            % set defined module sil lines
            obj.setModuleSilLines(cSilLines);
            
        end % parClassCosim
        
    end % methods
    
end