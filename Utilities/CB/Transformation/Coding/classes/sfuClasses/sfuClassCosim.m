classdef sfuClassCosim < cbtClassSilverSfu
    
    properties (Access = private)
        
        % config parameters must be confirmed with:
        oThisSfuParam = parClassCosim.empty;
        
    end % private properties
    
    % ====================================================================
    
    properties (Constant, Access = private)
        
        % extension of module file
        sThisModuleFileExt = '.slx';
        
        % -----------------------------------------------------------------
        
        % name of cosim workspace save file
        sCosimWorkspaceFile = 'WSForSlave.mat';
        
        % default timeout (wait time before connection from Silver to
        % Simulink will terminated
        sDefaultTimeout = '200';
        
        % default option to open Simulink GUI (true) or not (otherwise)
        sDefaultSimulinkGui = 'false';
        
    end % private constant properties
    
    % =====================================================================
    
    properties (Access = private)
        
        % sMP structure data
        sMP = struct([]);
        
        % fullpath of cosim folder
        sCosimFolderpath = '';

    end % private properties
    
    % =====================================================================
    
    methods
        
        function obj = sfuClassCosim(oCONST,oMP,sMP,xConfig,xCosimSetups)
            
            % >>> OPTION: Argument für create Sfu, um env Modul korrekt zu
            % behandeln (bzw. bdry)
            
            % create from super class
            % >>> with Simulink Cosim: 2. argument must be a not empty string!
            obj@cbtClassSilverSfu(oCONST,oMP,'CosimModel',xCosimSetups);
            obj.oThisSfuParam = parClassCosim(oCONST);
            obj.assignSfuParameter(obj.CONST.nCreateOrderCosim,...
                obj.oThisSfuParam,obj.sThisModuleFileExt);
            
            % -------------------------------------------------------------
            
            % assign matlab path
            obj.oSfuParam.Matlab64Exe = silGetConfigParamResolve(...
                obj.CONST.sStdConfigParamMatlabPath);
            
            % assign run directory path
            obj.oSfuParam.MasterDir = silGetConfigParamResolve(...
                obj.CONST.sStdConfigParamMasterDir);
            
            % assign default timeout
            obj.oSfuParam.ConnectTimeout = obj.sDefaultTimeout;
            
            % assign default Simulink GUI open flag
            obj.oSfuParam.OpenSimulink = obj.sDefaultSimulinkGui;
            
            % create cosim folder
            obj.createCosimFolder;
            
            % set cosim model name
            obj.oSfuParam.CosimModelName = obj.CONST.sCosimName;
            
            % set cosim model file
            obj.oSfuParam.CosimModelFile = [obj.CONST.sCosimName,obj.sModuleFileExt];
            
            % set max cosim stepsize 
            obj.setMaxCosimStepSize(xConfig);
            
            % create Simulink cosim instance
            obj.sMP = obj.createSimulinkCosimInstance(sMP);
            
        end % sfuClassCosim
        
        % =================================================================

        function sMP = thisCreateSfuFiles(obj)
            
            % DEFAULT create actions
            obj.createSfuFiles;
            
            % -------------------------------------------------------------
            % INDIVIDUAL create actions
            
            % return updated sMP structure
            sMP = obj.sMP;
            
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
        
        function createCosimFolder(obj)
            
            % full path of cosim folder
            obj.sCosimFolderpath = ...
                fullfile(obj.CONST.sSilMainFolder,obj.CONST.sCosimName);
            
            % relative path of cosim folder from master folder
            obj.oSfuParam.CosimFolder = ...
                fleRelativePathGet(obj.CONST.sMasterFolder,obj.sCosimFolderpath);
            
            % create folder in main folder
            fleCreateFolder(obj.sCosimFolderpath);
            
        end % createCosimFolder
        
        % =================================================================
        
        function setMaxCosimStepSize(obj,xConfig)
            
            % check field of max cosim stepsize
            if isfield(xConfig,'MasterSolver') && ...
                    isfield(xConfig.('MasterSolver'),'maxCosimStepsize')
                
                % assign max cosim step size
                obj.oSfuParam.MaxCosimStepsize = ...
                    xConfig.('MasterSolver').('maxCosimStepsize');
                
            else
                
                % error handling
                error('Field "maxCosimStepsize" does not exist in configuration.');
                
            end
            
        end % getMaxCosimStepSize
        
        % =================================================================
        
        function sMP = createSimulinkCosimInstance(obj,sMP)
            
            % init setup number list
            nSetupNumberList = obj.getCosimSpeciesNumbers(sMP,obj.xSetup);

            % return if list is empty
            if isempty(nSetupNumberList)
                return;
            end
            
            % save current run and Matlab paths
            sCurDir = pwd;
            sCurMatlabPaths = path;
            
            % add paths for Simulink cosim instance creation
            addpath(genpath(obj.CONST.sUtilitiesFolder));
            
            % call create script
            fprintf(1,'\tCreate Simulink cosim model ...\n');
            sMP = silCreateSlave(sMP,obj.CONST.sContentFolder,1,...
                obj.sCosimFolderpath,nSetupNumberList,obj.oSfuParam.CosimModelName);
            fprintf(1,'\tSimulink cosim model saved.\n');
            
            % store workspace of cosim instance
            eval(sprintf('save(''%s'',''-regexp'',''\\<(?!sMP\\>)\\w*'')',...
                fullfile(obj.sCosimFolderpath,obj.sCosimWorkspaceFile)));
            
            % restore paths
            rmpath(genpath(obj.CONST.sUtilitiesFolder));
            cd(sCurDir);
            addpath(sCurMatlabPaths);
            
        end % createSimulinkCosimInstance
        
    end % private methods
    
    % =====================================================================
    
    methods (Static, Access = private)
        
        function nSmpNumbers = getCosimSpeciesNumbers(sMP,xCosimSetup)
            
            % init output
            nSmpNumbers = [];
            
            % get module setup from sMP structure
            xModuleSetup = sMP.cfg.Configuration.ModuleSetup;
            
            % run through all cosim setups
            for nSet=1:numel(xCosimSetup)
                
                % get setup name
                sSetupName = xCosimSetup(nSet).name;
                
                % search for setup name in sMP structure
                nThisPos = [];
                for nModSet=1:numel(xModuleSetup)
                    
                    % compare names
                    if strcmp(xModuleSetup(nModSet).name,sSetupName)
                        nThisPos = nModSet;
                        break;
                    end
                    
                end
                
                % check for sMP pos
                if isempty(nThisPos)
                    error('sfu: No module setup for "%s" was found in sMP structure.',...
                        sSetupName);
                else
                    nSmpNumbers = [nSmpNumbers,nThisPos]; %#ok<AGROW>
                end
                
                % display adding of module in cosim slave
                fprintf(1,'\tAdd module "%s".\n',sSetupName);
                
            end
            
        end % getCosimSpeciesNumbers
        
    end % static private methods
    
end