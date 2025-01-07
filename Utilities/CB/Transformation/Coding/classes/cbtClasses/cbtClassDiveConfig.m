classdef cbtClassDiveConfig < handle
% CBTCLASSDIVECONFIG
    
   	properties (SetAccess = private, GetAccess = public)
        
        % xml config load structure
        xDcsConfig = struct([]);
        
        % structured data of configuration xml
        xConfigXml = struct([]);
        
        % structured data of module xml
        xModuleXmlList = struct([]);
        
        % sMP structure of configuration xml
        xMP = struct([]);
        
        % setup structure list of configuration xml
        xSetupList = dveClassSetupInstance.empty;
        
        % list of post scripts to be executed after simulation
        cPostScripts = {};
        
    end % properties
    
    % =====================================================================
    
    properties (Access = private)
        
        % transformation constant object
        CONST = cbtClassTrafoCONST.empty;
        
    end % private properties
    
    % =====================================================================
    
    methods 
        
        function obj = cbtClassDiveConfig(oCONST)
            
            % assign constant object
            obj.CONST = oCONST;
            
            % load xml structures
            fprintf(1,'\ncbt: Load config xml structure.\n');
            obj.getXmlStructures;
            
            % init DIVe configuration
            fprintf(1,'\ncbt: Init DIVe configuration and modules.\n');
            obj.initConfigAndSmpStructure;
            
            % get setup structure list
            fprintf(1,'\ncbt: Create setup structure list.\n');
            obj.getSetupStructList;
            
        end % cbtClassDiveConfig
        
        % =================================================================
        
        function updateSmp(obj,sMP)
            obj.xMP = sMP;
        end % updateSmp
        
    end % methods
    
    % =====================================================================
    
    methods (Access = private)
        
        function getXmlStructures(obj)
            
            % load configuration and xmls of used Modules
            xDcsConfig = dcsConfigLoad(obj.CONST.sDiveConfigXmlFile,obj.CONST.sContentFolder,...
                'dcsConfigLoad',false,false);
            
            % check path lengths
            cFileViolation = dpsPathLengthCheck(xDcsConfig,obj.CONST.sContentFolder,...
                obj.CONST.nMaxPathLength);
            
            % user info with invalid path length
            if ~isempty(cFileViolation)
                fprintf(2,'\tWARNING: Maximum filepath length (%i) exceeded for the following files:\n',...
                    obj.CONST.nMaxPathLength);
                % print paths
                for nFile=1:numel(cFileViolation)
                    fprintf(1,'\t\t%s\n',cFileViolation{nFile});
                end
            end
            
            % -------------------------------------------------------------
            
            % check fields
            checkFieldname(xDcsConfig,'Configuration');
            checkFieldname(xDcsConfig.('Configuration'),'ModuleSetup');
            checkFieldname(xDcsConfig.('Configuration').('ModuleSetup'),'name');
            checkFieldname(xDcsConfig,'xml');
            checkFieldname(xDcsConfig.('xml'),'Module');

            % sort module setups alphabetically
            % => NICHT SORTIEREN, DA SONST INKONSISTENT ZU .xml.Module
%             [~,nSort] = sort({xDcsConfig.('Configuration').ModuleSetup.name});
%             xDcsConfig.('Configuration').ModuleSetup ...
%                 = xDcsConfig.('Configuration').ModuleSetup(nSort);
            
            % assign xml structure
            obj.xDcsConfig = xDcsConfig;
            obj.xConfigXml = xDcsConfig.('Configuration');
            obj.xModuleXmlList = xDcsConfig.('xml').('Module');
            
            % get original xml structure
            xTree.('Configuration') = xDcsConfig.('Configuration');
            
            % save configuration xml in SiL folder
            dsxWrite(obj.CONST.sSilConfigXmlFile,xTree);
            pause(0.1);
            
        end % getXmlStructures
        
        % =================================================================
        
        function initConfigAndSmpStructure(obj)
            
            % get model block paths for module loop
            cModelBlockPaths = obj.getModelBlockPaths(obj.xConfigXml,...
                obj.xModuleXmlList,obj.CONST.sContentFolder);
            
            % get sMP structure if already exists
            try
                sMP = evalin('base','sMP');
            catch
                sMP.cfg = struct([]);
            end
            
            % intialize sMP structure with xml config data
            sMP.cfg = obj.xDcsConfig;
            
            % add field for additional Module intern (A2LAccess) signals to
            % be merged into platform logging
            sMP.cfg.cLogAdd = {}; 
            
            % transfer sMP structure to base workspace
            assignin('base','sMP',sMP);
            
            % start Module initialization
            [~,obj.cPostScripts] = dpsModuleLoop(obj.xConfigXml,obj.xModuleXmlList,...
                obj.CONST.sContentFolder,obj.CONST.sMasterFolder,cModelBlockPaths,0);

            % get updated sMP (added DataSets of Modules)
            obj.xMP = evalin('base','sMP');
            
            % check signals for mulitple module sources
            fprintf(1,'\ncbt: Check module outputs.\n');
            try
                
                % load config xml structure from final location
                xExtConfig = dsxRead(obj.CONST.sSilConfigXmlFile,0,0);
                
                % check outports
                dpsOutportValueCheck(obj.xMP,xExtConfig);
                
            catch
                fprintf(1,'\tCan not check module outputs for some reasons.\n');
            end
            
        end % initConfigAndSmpStructure
        
        % =================================================================
        
        function getSetupStructList(obj)
            
            % create config class instance
            oConfig = dveClassConfigInstance(obj.CONST,obj.xMP);
            
            % assign setup structure list
            obj.xSetupList = oConfig.oSetupInst;
            
        end % getSetupStructList
        
    end % private methods
    
    % =====================================================================
    
    methods (Static, Access = private)
        
        function cModelBlockPaths = getModelBlockPaths(xConfigXml,xModuleXmlList,sPathContent)
            
            % init values
            cModelBlockPaths = {}; % cell for holding block paths
            
            % close all simulink systems unconditionally
            bdclose all;
            
            % create model block paths and sMP structure
            for nModuleIdx = 1:length(xConfigXml.ModuleSetup)
                
                % user info
                fprintf(1,'\tProcessing "%s" to create model block paths and sMP structure.\n',...
                    xConfigXml.ModuleSetup(nModuleIdx).name);
                
                % get DIVe levels
                sModelSet = xConfigXml.ModuleSetup(nModuleIdx).Module.modelSet;
                
                % check for open ModelSets
                cModelSetType = {xModuleXmlList(nModuleIdx).Implementation.ModelSet.type};
                bOpenIdx = strcmp('open',cModelSetType);
                
                % get execution tool
                if any(bOpenIdx)
                    sExecutionTool = xModuleXmlList(nModuleIdx).Implementation.ModelSet(bOpenIdx).executionTool;
                else
                    sExecutionTool = xModuleXmlList(nModuleIdx).Implementation.ModelSet(1).executionTool;
                end
                
                % prepare Simulink models
                if strcmp('open',sModelSet) && ~isempty(strfind(sExecutionTool,'Simulink'))
                    
                    %get index of open Model set
                    bIsOpen = strcmp('open',{xModuleXmlList(nModuleIdx).Implementation.ModelSet.type});
                    
                    %get main model file
                    bIsMain = strcmp('1',{xModuleXmlList(nModuleIdx).Implementation.ModelSet(bIsOpen).ModelFile.isMain});
                    
                    %get model file name
                    sFileMain = xModuleXmlList(nModuleIdx).Implementation.ModelSet(bIsOpen).ModelFile(bIsMain).name;
                    
                    %resolve the path of Model
                    sModelFilePath = fullfile(sPathContent,xModuleXmlList(nModuleIdx).context,...
                        xModuleXmlList(nModuleIdx).species,xModuleXmlList(nModuleIdx).family,...
                        xModuleXmlList(nModuleIdx).type,'Module',xModuleXmlList(nModuleIdx).name,'open',sFileMain);
                    [~,sModelName,~] = fileparts(sModelFilePath);
                    
                    % load model
                    load_system(sModelFilePath);
                    cModelBlockPaths = [cModelBlockPaths gcb(sModelName)]; %#ok<AGROW>
                    close_system(sModelFilePath);
                    
                else
                    
                    cModelBlockPaths = [cModelBlockPaths {''}]; %#ok<AGROW>
                    
                end
            end
            
        end % getModelBlockPaths
        
    end % static private methods
    
end