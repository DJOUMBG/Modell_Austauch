classdef sfuClassDll < cbtClassSilverSfu
    
	properties (Access = private)
        
        % config parameters must be confirmed with:
        oThisSfuParam = parClassDll.empty;
        
    end % private properties
    
    % ====================================================================
    
    properties (Constant, Access = private)
        
        % expected extension of module file
        sThisModuleFileExt = '.dll';
        
    end % private constant properties
    
    % =====================================================================
    
    methods
        
        function obj = sfuClassDll(oCONST,oMP,xSetup)
            
            % create from super class
            obj@cbtClassSilverSfu(oCONST,oMP,'',xSetup);
            obj.oThisSfuParam = parClassDll(oCONST);
            obj.assignSfuParameter(str2double(obj.xSetup.initOrder),...
                obj.oThisSfuParam,obj.sThisModuleFileExt);
            
            % -------------------------------------------------------------
            
            % set path of dll file
            obj.oSfuParam.DllFile = obj.getModuleFilePath;
            
            % set user config string
            obj.oSfuParam.UserConfigString = obj.xSetup.user_config;
            
            % set renaming path
            obj.oSfuParam.OutRenameFile = obj.createOutRenameFile;
            
        end % sfuClassDll
        
        % =================================================================

        function thisCreateSfuFiles(obj)
            
            % DEFAULT create actions
            obj.createSfuFiles;
            
            % -------------------------------------------------------------
            % INDIVIDUAL create actions
            
            % modify sil file for 32Bit support
            if strcmp(obj.xSetup.bitVersion,'32') 
            
                % filepath of SFU sil file
                sSfuSilFilepath = fullfile(obj.CONST.sSfuFolder,...
                    obj.sSfuSilFile);

                % create xml object
                oXml = xmlClassModifier(sSfuSilFilepath);
                
                % ---------------------------------------------------------
                
                % get modules
                cModules = oXml.getComplex('module');
                sModule = cModules{1};
                
                % add remote process line
                sRemoteCluster = sprintf('%s%s%s','<remote-module-cluster>',...
                    [upper(obj.sSpecies),'_CLUSTER'],'</remote-module-cluster>');
                sModule = sprintf('%s  %s\n',sModule,sRemoteCluster);
                cModules{1} = sModule;
                
                % set modified sil line
                oXml.setComplex('module',cModules);
                
                % ---------------------------------------------------------
                
                % rewrite xml file
                oXml.writeFile(sSfuSilFilepath);
                
            end % 32bit version
            
        end % thisCreateSfuFiles
        
    end % methods
    
    % =====================================================================
    
    methods (Access = private)
        
    end % private methods
    
end