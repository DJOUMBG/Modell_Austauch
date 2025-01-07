classdef sfuClassSfcn < cbtClassSilverSfu
    
	properties (Access = private)
        
        % config parameters must be confirmed with:
        oThisSfuParam = parClassSfcn.empty; % or parClassSfcnGt.empty
        
    end % private properties

    % =====================================================================

    properties (Constant, Access = private)
        
        % expected extension of module file
        sThisModuleFileExt = '.mex';
        
    end % private constant properties
    
    % =====================================================================
    
    methods
        
        function obj = sfuClassSfcn(oCONST,oMP,xSetup,bGtSfcnModule)
            
            % >>> OPTION: Argument für create Sfu, um env Modul korrekt zu
            % behandeln (bzw. bdry)
            
            % check variable input
            if nargin < 4
                bGtSfcnModule = false;
            end
            
            % create from super class
            obj@cbtClassSilverSfu(oCONST,oMP,'',xSetup);
            
            % get SFU parameter object
            if bGtSfcnModule
                obj.oThisSfuParam = parClassSfcnGt(oCONST);
            else
                obj.oThisSfuParam = parClassSfcn(oCONST);
            end
            
            % assign values
            obj.assignSfuParameter(str2double(obj.xSetup.initOrder),...
                obj.oThisSfuParam,obj.sThisModuleFileExt);
            
            % -------------------------------------------------------------
            
            % set path of mex file
            obj.oSfuParam.MexFile = obj.getModuleFilePath;
            
            % create parameter mat file
            obj.createParamFile;
            
            % create port alias file
            obj.createPortAliasFile;
            
            % set renaming path
            obj.oSfuParam.OutRenameFile = obj.createOutRenameFile;
            
        end % sfuClassSfcn
        
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
                
                % get sil line
                cSilLines = oXml.getComplex('sil-line');
                sSilLine = cSilLines{1};
                
                % add folder x86
                sSilLine = sprintf('%s%s%s','x86','\',sSilLine);
                cSilLines{1} = sSilLine;
                
                % set modified sil line
                oXml.setComplex('sil-line',cSilLines);
                
                % ---------------------------------------------------------
                
                % get modules
                cModules = oXml.getComplex('module');
                sModule = cModules{1};
                
                % add remote process line
                sRemoteCluster = '<remote-module-cluster>_</remote-module-cluster>';
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
    
    methods (Access = protected)
        
        function createParamFile(obj)
            
            % run through all parameters
            for nPar=1:numel(obj.xSetup.Parameter)
                
                % get name from sMP structure
                sSmpName = obj.xSetup.Parameter(nPar).smpVariable;
                
                % get final name and value of pameter
                if ~isempty(sSmpName)
                    
                    % get parameter name
                    sParName = strrep(sSmpName,'.','_');
                    
                    % get parameter value
                    try
                        % get value from sMP structure
                        paramValue = evalin('base',sSmpName); %#ok<NASGU>
                    catch
                        % get value from parameter module structure
                        paramValue = obj.xSetup.Parameter(nPar).value; %#ok<NASGU>
                    end
                    
                    % evaluate parameter in local workspace
                    % !!! attention paramValue variable name has also to be changed here !!!
                    try
                        eval(sprintf('%s=paramValue;',sParName));
                    catch
                        fprintf(2,'\tCan not assign "%s" in sfunction parameter file.\n',...
                            sParName);
                    end
                    
                end
                
            end % obj.xSetup.Parameter
            
            % get all ports
             xPorts = [obj.xSetup.Inport,obj.xSetup.Outport];
            
            % run through all ports
            for nPort=1:numel(xPorts)
                
                % get name from sMP structure
                sSmpName = xPorts(nPort).smpVariable;
                
                % get final name and value of port
                if ~isempty(sSmpName)
                    
                    % get port name
                    sParName = strrep(sSmpName,'.','_');
                    
                    % get port value
                    try
                        % get value from sMP structure
                        paramValue = evalin('base',sSmpName); %#ok<NASGU>
                    catch
                        % get value from port module structure
                        paramValue = xPorts(nPort).value; %#ok<NASGU>
                    end
                    
                    % evaluate parameter in local workspace
                    % !!! attention paramValue variable name has also to be changed here !!!
                    try
                        eval(sprintf('%s=paramValue;',sParName));
                    catch
                        fprintf(2,'\tCan not assign "%s" in sfunction parameter file.\n',...
                            sParName);
                    end
                    
                end
                
            end % xPorts
            
            % -------------------------------------------------------------
            
            % create name of parameter file
            obj.oSfuParam.ParamFile = [obj.xSetup.species,'.mat'];
            
            % create filepath of parameter file
            sParamFilepath = fullfile(obj.CONST.sMasterFolder,...
                obj.oSfuParam.ParamFile);
            
            % save parameters in mat file
            save(sParamFilepath,'sMP_*','-v7');
            
        end % createParamFile
        
        % =================================================================
        
        function createPortAliasFile(obj)
            
            % init string content of routning file
            sRoutingTxt = '';

            % -------------------------------------------------------------
            
            % inports
            xInport = obj.xSetup.getOnlyIndexStruct('Inport');
            xInport = sortStructByField(xInport,'index',true,true);
            for nIn=1:numel(xInport)
                sOffsetIndex = num2str(str2double(xInport(nIn).index) - 1);
                sRoutingTxt = obj.createCreateRoutingLine(sRoutingTxt,'u','[0]',...
                    sOffsetIndex,xInport(nIn).name);
            end
            
            % outports
            xOutport = obj.xSetup.getOnlyIndexStruct('Outport');
            xOutport = sortStructByField(xOutport,'index',true,true);
            for nOut=1:numel(xOutport)
                sOffsetIndex = num2str(str2double(xOutport(nOut).index) - 1);
                sRoutingTxt = obj.createCreateRoutingLine(sRoutingTxt,'y','[0]',...
                    sOffsetIndex,xOutport(nOut).name);
            end
            
            % config parameter
            % !!! => Wird das nur dadurch festgelegt: silCheckSfcnModelIsStd
            if silCheckSfcnModelIsStd(obj.xSetup.context,obj.xSetup.family,obj.xSetup.modelSet)
                sRoutingTxt = sprintf('%sp[0] = sMP_ctrl_%s_user_config\n',...
                    sRoutingTxt,obj.xSetup.species);
            end
            
            % get only structure with index
            xDataParams = obj.xSetup.getOnlyIndexStruct('Parameter');
            xIoParams = obj.xSetup.getOnlyIndexStruct('ParameterIO');
            xParameter = [xDataParams,xIoParams];
            
            % parameters
            xParameter = sortStructByField(xParameter,'index',true,true);
            for nPar=1:numel(xParameter)
                sOffsetIndex = num2str(str2double(xParameter(nPar).index) - 1);
                sSmpParamName = strrep(xParameter(nPar).smpVariable,'.','_');
                sRoutingTxt = obj.createCreateRoutingLine(sRoutingTxt,'p','',...
                    sOffsetIndex,sSmpParamName);
            end

            % -------------------------------------------------------------
            
            % create name of parameter file
            obj.oSfuParam.PortAliasFile = sprintf('%s_%s_%s_routing.txt',...
                obj.xSetup.species,obj.xSetup.family,obj.xSetup.type);
            
            % create filepath of parameter file
            sPortAliasFilepath = fullfile(obj.CONST.sMasterFolder,...
                obj.oSfuParam.PortAliasFile);
            
            % write port alias file
            fleFileWrite(sPortAliasFilepath,sRoutingTxt);
            
        end % createPortAliasFile
        
    end % protected methods
    
    % =====================================================================
    
    methods (Static, Access = protected)
        
        function sTxt = createCreateRoutingLine(sTxt,sPrefix,sSuffix,sIndex,sName)
        	sTxt = sprintf('%s%s[%s]%s = %s\n',sTxt,sPrefix,sIndex,sSuffix,sName);
        end % createCreateRoutingLine
        
    end% protected static methods
    
end