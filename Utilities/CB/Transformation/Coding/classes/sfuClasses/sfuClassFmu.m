classdef sfuClassFmu < cbtClassSilverSfu
    
	properties (Access = private)
        
        % config parameters must be confirmed with:
        oThisSfuParam = parClassFmu.empty;
        
    end % private properties
    
    % ====================================================================
    
    properties (Constant, Access = private)
        
        % expected extension of module file
        sThisModuleFileExt = '.fmu';
        
    end % private constant properties
    
    % =====================================================================
    
    methods
        
        function obj = sfuClassFmu(oCONST,oMP,xSetup)
            
            % create from super class
            obj@cbtClassSilverSfu(oCONST,oMP,'',xSetup);
            obj.oThisSfuParam = parClassFmu(oCONST);
            obj.assignSfuParameter(str2double(obj.xSetup.initOrder),...
                obj.oThisSfuParam,obj.sThisModuleFileExt);
            
            % -------------------------------------------------------------
            
            % set path of fmu file
            obj.oSfuParam.FmuFile = obj.getModuleFilePath;
            
            % set renaming path
            obj.oSfuParam.OutRenameFile = obj.createOutRenameFile;
            
        end % sfuClassFmu
        
        % =================================================================

        function thisCreateSfuFiles(obj)
            
            % DEFAULT create actions
            obj.createSfuFiles;
            
            % -------------------------------------------------------------
            % INDIVIDUAL create actions
            
            % filepath of SFU sil file
            sSfuSilFilepath = fullfile(obj.CONST.sSfuFolder,...
                obj.sSfuSilFile);

            % create xml object
            oXml = xmlClassModifier(sSfuSilFilepath);
            
            % get modules
            cModules = oXml.getComplex('module');
            sModule = cModules{1};

            % add remote process line
            sRemoteCluster = '<remote-module-cluster>_</remote-module-cluster>';
            sModule = sprintf('%s  %s\n',sModule,sRemoteCluster);
            cModules{1} = sModule;

            % set modified sil line
            oXml.setComplex('module',cModules);
            
            % rewrite xml file
            oXml.writeFile(sSfuSilFilepath);
            
        end % thisCreateSfuFiles
        
    end % methods
    
    % =====================================================================
    
    methods (Access = private)
        
    end % private methods
    
end