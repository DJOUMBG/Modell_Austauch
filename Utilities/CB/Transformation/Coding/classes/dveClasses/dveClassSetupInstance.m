classdef dveClassSetupInstance < handle
    
    properties (SetAccess = private, GetAccess = public)
        
        % name of module setup in DIVe config
        name = '';
        
        % context of module
        context = '';
        
        % species of module
        species = '';
        
        % family of module
        family = '';
        
        % type of module
        type = '';
        
        % variant of module setup
        variant = '';
        
        % model set of module setup
        modelSet = '';
        
        % execution tool of model set
        executionTool = '';
        
        % authoring tool of model set
        authoringTool = '';
        
        % co-simulation type of model set
        cosimType = '';
        
        % file extension of model set execution file
        fileExt = '';
        
        % bit version of model set
        bitVersion = '';
        
        % init order of module in DIVe config
        initOrder = '';
        
        % max step size of module
        maxStepSize = '';
        
        % user config string of model set
        user_config = '';
        
        % position of model setup in DIVe sMP structure
        smpPos = [];
        
        % -----------------------------------------------------------------
        
        % execution file structure of model set
        MainFile = struct([]);
        
        % structure list with all model files of model set
        ModelFile = struct([]);
        
        % structure list with all DataSets of module
        DataSet = struct([]);
        
        % structure list with all SupportSets of module
        SupportSet = struct([]);
        
        % structure list with all inports of module 
        Inport = struct([]);
        
        % structure list with all outports of module 
        Outport = struct([]);
        
        % structure list of all parameters of module
        Parameter = struct([]);
        
        % structure list of all initIO parameters of module
        ParameterIO = struct([]);
        
    end % properties
    
    % =====================================================================
    
    properties (Access = private)
        
        % transformation constant object
        CONST = cbtClassTrafoCONST.empty;
        
        % given object of model instance
        oModelInst = dveClassModelInstance.empty;
        
    end % private properties
    
    % =====================================================================
    
    properties (Constant, Access = private)
        
        % default structure ModelFile
        xDefault_ModelFile = struct(...
            'name','',...
            'isMain','',...
            'copyToRunDirectory','',...
            'filepath','',...
            'relFilepath','');
        
        % default structure DataSet
        xDefault_DataSet = struct(...
            'className','',...
            'classType','',...
          	'isSubspecies','',...
            'variant','',...
            'level','');
        
        % default structure SupportSet
        xDefault_SupportSet = struct(...
            'name','',...
            'level','');
        
        % default structure ports (Inport, Outport)
        xDefault_Port = struct(...
            'name','',...
            'value',[],...
            'smpVariable','',...
            'minPhysicalRange','',...
            'maxPhysicalRange','',...
            'sna','',...
            'index','');
        
        % default structure Parameter
        xDefault_Parameter = struct(...
            'name','',...
            'value',[],...
            'smpVariable','',...
            'className','',...
            'classType','',...
          	'isSubspecies','',...
            'size','',...
            'index','');
        
    end % constant private properties
    
    % =====================================================================
    
    methods
        
        function obj = dveClassSetupInstance(oCONST,oModelInst,nSmpPos)
            
            % assign constant object
            obj.CONST = oCONST;
            
            % assign input arguments
            obj.oModelInst = oModelInst;
            obj.smpPos = nSmpPos;
            
            % -------------------------------------------------------------
            
            % get general attributs
            obj.getGeneralAttributes;
            
            % get ModelFiels
            obj.getModelFiles;
            
            % get MainFile
            obj.getMainFile;
            
            % get DataSets
            obj.getDataSets;
            
            % get SupportSets
            obj.getSupportSets;
            
            % -------------------------------------------------------------
            
            % get Inports
            obj.getPorts('in','Inport');
            
            % get Outports
            obj.getPorts('out','Outport');
            
            % get Parameters
            obj.getParameters;
            
        end % dveClassSetupInstance
        
        % =================================================================
        
        function xStruct = getOnlyIndexStruct(obj,sPropName)
            
            % init output
            xStruct = struct([]);
            
            % check property name
            if isprop(obj,sPropName)
                
                % get structure
                xFullStruct = obj.(sPropName);
                
                % check for field "index"
                if isfield(xFullStruct,'index')
                    
                    % run though channels
                    for nCh=1:numel(xFullStruct)
                        
                        % check for valid index value
                        if ~isempty(xFullStruct(nCh).('index'))
                            xStruct = [xStruct,xFullStruct(nCh)]; %#ok<AGROW>
                        end
                        
                    end % xFullStruct
                    
                end
                
            else
                error('"%s" is not a readable property of "%s".',...
                    sPropName,class(obj));
            end
            
        end % getOnlyIndexStruct
        
    end % methods
    
    % =====================================================================
    
    methods (Access = private)
        
        function getGeneralAttributes(obj)
            
            % assignment attributes
            obj.name = obj.getValueOfField(obj.oModelInst.xModelSet,'name','UNKNOWN',true);
            obj.context = obj.getValueOfField(obj.oModelInst.xModelSet,'context','UNKNOWN',true);
            obj.species = obj.getValueOfField(obj.oModelInst.xModelSet,'species','UNKNOWN',true);
            obj.family = obj.getValueOfField(obj.oModelInst.xModelSet,'family','UNKNOWN',true);
            obj.type = obj.getValueOfField(obj.oModelInst.xModelSet,'type','UNKNOWN',true);
            obj.variant = obj.getValueOfField(obj.oModelInst.xModelSet,'variant','UNKNOWN',true);
            obj.executionTool  = obj.getValueOfField(obj.oModelInst.xModelSet,'executionTool','UNKNOWN',true);
            obj.authoringTool = obj.getValueOfField(obj.oModelInst.xModelSet,'authoringTool','UNKNOWN',true);
            obj.initOrder  = obj.getValueOfField(obj.oModelInst.xModelSet,'initOrder','UNKNOWN',true);
            obj.maxStepSize = obj.getValueOfField(obj.oModelInst.xModelSet,'maxCosimStepsize','UNKNOWN',true);
            
            % check model set: e.g. sfcn as open
            sModelSet = obj.getValueOfField(obj.oModelInst.xModelSet,'modelSet','UNKNOWN',true);
            obj.modelSet = obj.getCheckedModelSet(sModelSet);
            
            % co-simulation execution attributes
            [obj.cosimType,obj.fileExt,obj.bitVersion] = obj.getCosimExecAttributes;
            
            % user config string
            obj.user_config = obj.getUserConfigString;
            
        end % getGeneralAttributes
        
        % =================================================================
        
        function getModelFiles(obj)
            
            % create path to model set folder
            sModelSetFolderpath = fullfile(...
                obj.CONST.sContentFolder,...
                obj.context,...
                obj.species,...
                obj.family,...
                obj.type,...
                'Module',...
                obj.variant,...
                obj.modelSet);
            
            % create relative path (from Content folder) to model set
            % folder
            sModelSetRelpath = fleRelativePathGet(obj.CONST.sContentFolder,sModelSetFolderpath);
            
            % check if files exists
            if ~chkFolderExists(sModelSetFolderpath)
                fprintf(2,'\tWARNING: Model set folder "%s" does not exist in given DIVe Content.\n',...
                    sModelSetFolderpath);
            end
            
            % -------------------------------------------------------------
            
            % get model files from model instance class
            xModelFiles = obj.getValueOfField(obj.oModelInst.xModelSet,'ModelFile',struct([]),true);
            
            % run through all model files
            for nFile=1:numel(xModelFiles)
                
                % get name of model file
                sModelFile = obj.getValueOfField(xModelFiles(nFile),'name','UNKNOWN',true);
                
                % create paths to model file
                sFilepath = fullfile(sModelSetFolderpath,sModelFile);
                sRelFilepath = fullfile(sModelSetRelpath,sModelFile);
                
                % check if mode file exists
                if ~chkFileExists(sFilepath)
                    fprintf(2,'\tWARNING: Model file "%s" does not exist in given DIVe Content.\n',...
                        sFilepath);
                end
                
                % ---------------------------------------------------------
                
                % init structure
                xThisModelFile = obj.xDefault_ModelFile;
                
                % assing data
                xThisModelFile.('name') = sModelFile;
                xThisModelFile.('isMain') = obj.getValueOfField(...
                    xModelFiles(nFile),'isMain','UNKNOWN',true);
                xThisModelFile.('copyToRunDirectory') = obj.getValueOfField(...
                    xModelFiles(nFile),'copyToRunDirectory','UNKNOWN',true);
                xThisModelFile.('filepath') = sFilepath;
                xThisModelFile.('relFilepath') = sRelFilepath;
                
                % append structure
                obj.ModelFile = [obj.ModelFile,xThisModelFile];
                
            end % xModelFiles
            
        end % getModelFiles
        
        % =================================================================
        
        function getMainFile(obj)
            
            % init structure
            xPreMainFiles = struct([]);

            % search for main file
            if ~isempty(obj.fileExt)

                for nFile=1:numel(obj.ModelFile)

                    % get fileparts of model file
                    [~,~,sExt] = fileparts(obj.ModelFile(nFile).('filepath'));

                    % check file extension
                    if strncmpi(sExt,obj.fileExt,numel(obj.fileExt))
                        xPreMainFiles = [xPreMainFiles,obj.ModelFile(nFile)]; %#ok<AGROW>
                    end

                end

            else
                xPreMainFiles = obj.ModelFile;
            end

            % check for more than one files
            xMainFiles = struct([]);

            if numel(xPreMainFiles) > 1

                for nFile=1:numel(xPreMainFiles)

                    % check for definition of main file
                    if strcmp(xPreMainFiles(nFile).('isMain'),'1')
                        xMainFiles = [xMainFiles,xPreMainFiles(nFile)]; %#ok<AGROW>
                    end

                end

            else
                xMainFiles = xPreMainFiles;
            end
            
            % check for not defined main file
            if isempty(xMainFiles)
                error('There is no model cosim file with extension "%s" for model set "%s" in species "%s".',...
                    obj.fileExt,obj.modelSet,obj.species);
            elseif numel(xMainFiles) > 1
                error('There is more than one model cosim main file with extension "%s" for model set "%s" in species "%s".',...
                    obj.fileExt,obj.modelSet,obj.species);
            end
            
            % assing main file structure
            obj.MainFile = xMainFiles(1);
            
        end % getMainFile
        
        % =================================================================
        
        function getDataSets(obj)
            
            % get DataSet list from model instance
            xDataSetList = obj.oModelInst.xDataSets;
            
            % run through all DataSets
            for nSet=1:numel(xDataSetList)
                
                % init structure
                xThisDataSet = obj.xDefault_DataSet;
                
                % assign data
                xThisDataSet.('className') = obj.getValueOfField(...
                    xDataSetList(nSet),'className','UNKNOWN',true);
                xThisDataSet.('classType') = obj.getValueOfField(...
                    xDataSetList(nSet),'classType','UNKNOWN',true);
                xThisDataSet.('isSubspecies') = obj.getValueOfField(...
                    xDataSetList(nSet),'isSubspecies','UNKNOWN',true);
                xThisDataSet.('variant') = obj.getValueOfField(...
                    xDataSetList(nSet),'variant','UNKNOWN',true);
                xThisDataSet.('level') = obj.getValueOfField(...
                    xDataSetList(nSet),'level','UNKNOWN',true);
                
                % append structure
                obj.DataSet = [obj.DataSet,xThisDataSet];
                
            end % xDataSetList
            
        end % getDataSets
        
        % =================================================================
        
        function getSupportSets(obj)
            
            % get SupportSet list from model instance
            xSupportSetList = obj.oModelInst.xSupportSets;
            
            % run through all SupportSets
            for nSet=1:numel(xSupportSetList)
                
                % init structure
                xThisSupportSet = obj.xDefault_SupportSet;
                
                % assign data
                xThisSupportSet.('name') = obj.getValueOfField(...
                    xSupportSetList(nSet),'name','UNKNOWN',true);
                xThisSupportSet.('level') = obj.getValueOfField(...
                    xSupportSetList(nSet),'level','UNKNOWN',true);
                
                % append structure
                obj.SupportSet = [obj.SupportSet,xThisSupportSet];
                
            end % xSupportSetList
            
        end % getSupportSets
        
        % =================================================================
        
        function getPorts(obj,sSubName,sStructName)
            
            % get port values from sMP structure
            xPortVals = obj.oModelInst.xSimValue.(sSubName);
            
            % get port structure list from module
            xPortList = obj.oModelInst.xInterface.(sStructName);
            
            % run through ports
            for nPort=1:numel(xPortList)
                
                % current port
                xPortStruct = xPortList(nPort);
                sPortName = obj.getValueOfField(xPortStruct,'name','',true);
                sIndex = obj.getValueOfField(xPortStruct,'index','',true);
                
                % init port value
                valueOfPort = [];
                
                % check port name in value structure
                if ~isfield(xPortVals,sPortName)
                    if ~isempty(sIndex)
                        fprintf(1,'\tWARNING: %s "%s" of species "%s" was defined in module xml but was not found in sMP structure!\n',...
                            sStructName,sPortName,obj.species);
                    end
                else
                    % get value from structure
                    valueOfPort = xPortVals.(sPortName);
                    % remove field
                    xPortVals = rmfield(xPortVals,sPortName);
                end
                
                % ---------------------------------------------------------
                
                % init structure
                xThisPort = obj.xDefault_Port;
                
                % assign data
                xThisPort.('name') = sPortName;
                xThisPort.('value') = valueOfPort;
                xThisPort.('smpVariable') = sprintf('sMP.%s.%s.%s.%s',...
                    obj.context,obj.species,sSubName,sPortName);
                xThisPort.('minPhysicalRange') = obj.getValueOfField(...
                    xPortStruct,'minPhysicalRange','');
                xThisPort.('maxPhysicalRange') = obj.getValueOfField(...
                    xPortStruct,'maxPhysicalRange','');
                xThisPort.('sna') = obj.getValueOfField(...
                    xPortStruct,'sna','');
                xThisPort.('index') = sIndex;
                
                % append structure
                obj.(sStructName) = [obj.(sStructName),xThisPort];
                
            end % xPortList
            
            % -------------------------------------------------------------
            
            % get remaining ports
            cRemainPortNames = fieldnames(xPortVals);
            
            % run through remaining ports
            for nField=1:numel(cRemainPortNames)
                
                % current port name
                sPortName = cRemainPortNames{nField};
                
                % init structure
                xThisPort = obj.xDefault_Port;
                
                % assign data
                xThisPort.('name') = sPortName;
                xThisPort.('value') = xPortVals.(sPortName);
                xThisPort.('smpVariable') = sprintf('sMP.%s.%s.%s.%s',...
                    obj.context,obj.species,sSubName,sPortName);
                
                % append structure
                obj.(sStructName) = [obj.(sStructName),xThisPort];
                
            end % cRemainInNames
            
        end % getPorts
                
        % =================================================================
        
        function getParameters(obj)
            
            % get param values from sMP structure
            xParamVals = obj.oModelInst.xSimValue;
            
            % get parameter structure list from module
            xParamList = obj.oModelInst.xInterface.Parameter;
            
            % run through parameters
            for nParam=1:numel(xParamList)
                
                % current parameter
                xParamStruct = xParamList(nParam);
                sParamName = obj.getValueOfField(xParamStruct,'name','',true);
                sClassName = obj.getValueOfField(xParamStruct,'className','',true);
                sIndex = obj.getValueOfField(xParamStruct,'index','',true);
                
                % get parameter attributes from DataSet
                [sClassType,sSubspecies] = obj.getMatchingClassAttributes(...
                    sClassName,obj.DataSet);
                
                % ---------------------------------------------------------
                
                % init structure
                xThisParameter = obj.xDefault_Parameter;
                
                % assign general data
                xThisParameter.('name') = sParamName;
                xThisParameter.('className') = sClassName;
                xThisParameter.('classType') = sClassType;
                xThisParameter.('size') = obj.getValueOfField(...
                    xParamStruct,'size','');
                xThisParameter.('index') = sIndex;
                
                % get value of parameter and remove field in xParamVals if
                % it was found there
                if strcmp(sClassName,'initIO')
                    
                    % get initIO parameter value
                    [xParamVals,valueOfParam,sSmpVariable] = obj.getInitIOParamValue(...
                        sParamName,sIndex,xParamVals,obj.context,obj.species);
                    
                    % assign specific values
                    xThisParameter.('value') = valueOfParam;
                    xThisParameter.('smpVariable') = sSmpVariable;
                    
                    % append structure
                    obj.ParameterIO = [obj.ParameterIO,xThisParameter];
                    
                else
                    
                    % get DataClass parameter value
                    [xParamVals,valueOfParam,sSmpVariable] = obj.getDataClassParamValue(...
                        sParamName,sClassName,sSubspecies,sIndex,xParamVals,obj.context,obj.species);
                    
                    % assign specific values
                    xThisParameter.('value') = valueOfParam;
                    xThisParameter.('smpVariable') = sSmpVariable;
                    
                    % append structure
                    obj.Parameter = [obj.Parameter,xThisParameter];
                    
                end
                
            end % xParamList
            
            % -------------------------------------------------------------
            
            % get remaining parameters
            cRemainFieldNames = fieldnames(xParamVals);
            
            % run through remaining parameters
            for nField=1:numel(cRemainFieldNames)
                
                % current parameter name
                sFieldName = cRemainFieldNames{nField};
                
                % check if is subspecies
                if isstruct(xParamVals.(sFieldName))
                    
                    % assign sub structure and class name
                    xSubParamVals = xParamVals.(sFieldName);
                    sClassName = sFieldName;
                    cSubParamList = fieldnames(xSubParamVals);
                    
                    % get class type
                    sClassType = obj.getMatchingClassAttributes(sClassName,obj.DataSet);
                    
                    % run through parameters
                    for nParam=1:numel(cSubParamList)
                        
                        % get sub param name and value
                        sSubParamName = cSubParamList{nParam};
                        valueOfSubParam = xSubParamVals.(sSubParamName);
                        
                    	% init structure
                        xThisParameter = obj.xDefault_Parameter;

                        % assign data
                        xThisParameter.('name') = sSubParamName;
                        xThisParameter.('value') = valueOfSubParam;
                        xThisParameter.('smpVariable') = sprintf('sMP.%s.%s.%s.%s',...
                            obj.context,obj.species,sClassName,sSubParamName);
                        xThisParameter.('className') = sClassName;
                        xThisParameter.('classType') = sClassType;
                        
                        % append structure
                        obj.Parameter = [obj.Parameter,xThisParameter];
                        
                    end
                    
                else
                    
                    % get param name and value
                    sParamName = sFieldName;
                    valueOfParam = xParamVals.(sParamName);

                    % init structure
                    xThisParameter = obj.xDefault_Parameter;

                    % assign data
                    xThisParameter.('name') = sParamName;
                    xThisParameter.('value') = valueOfParam;
                    xThisParameter.('smpVariable') = sprintf('sMP.%s.%s.%s',...
                        obj.context,obj.species,sParamName);
                    
                    % append structure
                    obj.Parameter = [obj.Parameter,xThisParameter];
                    
                end
                               
            end % cRemainPortNames
            
        end % getParameters
        
        % =================================================================
        % GET METHODS:
        % =================================================================
        
        function sModelSet = getCheckedModelSet(obj,sModelSet)
            
            % get inteface values
            xInport = obj.oModelInst.xInterface.Inport;
            xOutport = obj.oModelInst.xInterface.Outport;
            xParameter = obj.oModelInst.xInterface.Parameter;
            
            % check model set
            if strncmpi(sModelSet,'sfcn',numel('sfcn'))

                % always handle sfunctions from context "ctrl" and family "sil" as
                % sfunctions >>> see old transformation
                if strncmpi(obj.context,'ctrl',numel('ctrl')) ...
                   && strncmpi(obj.family,'sil',numel('sil'))
                    return;
                end

                % init parameter lists
                cAllParamList = {};
                cIndexParamList = {};
                cInOutParams = {};

                % collect parameters
                for nPar=1:numel(xParameter)

                    % get parameter name
                    sParamName = xParameter(nPar).('name');

                    % append parameter to all list
                    cAllParamList = [cAllParamList;{sParamName}]; %#ok<AGROW>

                    % append paremeter to index list
                    if ~isempty(xParameter(nPar).('index'))
                        cIndexParamList = [cIndexParamList;{sParamName}]; %#ok<AGROW>
                    end

                end % parameters

                % collect in params
                for nPort=1:numel(xInport)

                    % get port name
                    sPortName = xInport(nPort).('name');

                    % append port to IO param list
                    if ~isempty(xInport(nPort).('index'))
                        cInOutParams = [cInOutParams;{sPortName}]; %#ok<AGROW>
                    end

                end % inports

                % collect out params
                for nPort=1:numel(xOutport)

                    % get port name
                    sPortName = xOutport(nPort).('name');

                    % append port to IO param list
                    if ~isempty(xOutport(nPort).('index'))
                        cInOutParams = [cInOutParams;{sPortName}]; %#ok<AGROW>
                    end

                end % outports

                % unique lists
                cAllParamList = unique(cAllParamList,'stable');
                cIndexParamList = unique(cIndexParamList,'stable');
                cInOutParams = unique(cInOutParams,'stable');

                % compare parameter list
                if isequal(numel(cIndexParamList),0) ...
                   && ~isempty(setdiff(cAllParamList,cInOutParams))

                    % sfunction will handled as open Simulink model
                    sModelSet = 'open';
                    fprintf(2,'\tWARNING: Sfunction for "%s" will be handled as open due to incorrect parameter definition.\n',...
                        obj.name);

                end

            end % check model set is sfcn
            
        end % getCheckedModelSet
        
        % =================================================================
        
        function [sCosimType,sFileExtStart,sBitVersion] = getCosimExecAttributes(obj)
            
            % init error flag
            bValid = true;

            % default bit version
            sBitVersion = '64';

            % check model sets
            if strncmpi(obj.modelSet,'silver_dll',numel('silver_dll'))

                % is Silver dll
                sCosimType = 'dll';
                sFileExtStart = '.dll';

                % check bit version
                if strncmpi(obj.modelSet,'silver_dll_w32',numel('silver_dll_w32')) ...
                   && ~strncmpi(obj.modelSet,'silver_dll_w3264',numel('silver_dll_w3264'))
                    sBitVersion = '32';
                end

            elseif strncmpi(obj.modelSet,'sfcn',numel('sfcn'))

                % is sfunction
                sCosimType = 'sfcn';
                sFileExtStart = '.mex';

                % check bit version
                if strncmpi(obj.modelSet,'sfcn_w32',numel('sfcn_w32')) ...
                   && ~strncmpi(obj.modelSet,'sfcn_w3264',numel('sfcn_w3264'))
                    sBitVersion = '32';
                end

            elseif strncmpi(obj.modelSet,'fmu',numel('fmu'))

                % is fmu
                sCosimType = 'fmu';
                sFileExtStart = '.fmu';

            elseif strncmpi(obj.modelSet,'open',numel('open')) ...
                   && strncmpi(obj.executionTool,'Simulink',numel('Simulink'))

               % is open Simulink
                sCosimType = 'Simulink';
                sFileExtStart = '';

                % check bit version
                if strncmpi(obj.executionTool,'Simulink_w32',numel('Simulink_w32')) ...
                   && ~strncmpi(obj.executionTool,'Simulink_w3264',numel('Simulink_w3264'))
                    sBitVersion = '32';
                end

            elseif strncmpi(obj.modelSet,'open',numel('open')) ...
                   && strncmpi(obj.executionTool,'Silver',numel('Silver'))

                % is open Silver (SFU)
                sCosimType = 'Silver';
                sFileExtStart = '';

            else
                sCosimType = obj.executionTool;
                sFileExtStart = '';
                sBitVersion = '';
                bValid = false;
            end
            
            % check for any unknown model set
            if ~bValid
                fprintf(2,'\tWARNING: DIVe CB can not run "%s" as "%s" for "%s".\n',...
                    obj.executionTool,obj.modelSet,obj.name);
            end
            
        end % getCosimExecAttributes
        
        % =================================================================
        
        function sUserConfigString = getUserConfigString(obj)
            
            % get sim values
            xSimValue = obj.oModelInst.xSimValue;
            
            % init user config string
            sUserConfigString = '';
            
            % check if user_config parameter exists
            if isfield(xSimValue,'user_config')
                sUserConfigString = strtrim(xSimValue.('user_config'));
            end
            
            % return if no user config string is defined
            if isempty(sUserConfigString)
                return;
            end
            
            % split config string
            [cNames,cValues] = silConfigStringSplit(sUserConfigString);
            
            % get quotation character => !!! Gilt das wirklich nur dafür ???
            if strcmp(obj.modelSet,'fmu20') && strcmp(obj.context,'ctrl')
                sFmuQuotes = '"';
            else
                sFmuQuotes = '';
            end
            
            % modify user config
            sUserConfigString = '';
            for nCfg=1:length(cNames)

                % current name value pair
                sName = cNames{nCfg};
                sValue = cValues{nCfg};

                % check for path string in value of config parameter
                if strcontain(sValue,'/') || strcontain(sValue,'\\')

                    % trim value
                    sValue = strtrim(sValue);

                    % create relative path to path value from master folder
                    if ~isempty(obj.CONST.sMasterFolder)
                        sRelPathValue = fleRelativePathGet(obj.CONST.sMasterFolder,sValue);
                    else
                        sRelPathValue = sValue;
                    end

                    % replace os file seperator with Silvers file seperator
                    % !!! => Wird das wirklich benötigt? => Silver kann auch mit \ umgehen !: 
                    % sRelPathValue = strrep(sRelPathValue,filesep,'\\');

                    % create user config 
                    sUserConfigString = sprintf('%s%s%s%s%s',...
                        sUserConfigString,sName,sFmuQuotes,sRelPathValue,sFmuQuotes);

                else
                    % create user config string for non path values
                    sUserConfigString = sprintf('%s%s%s',...
                        sUserConfigString,sName,sValue);
                end

            end
            
        end % getUserConfigString
        
        % =================================================================
        % ADDITIONAL METHODS:
        % =================================================================
        
        function value = getValueOfField(obj,xStruct,sField,emptyOption,bCheck)
            
            % check input arguments
            if nargin < 5
                bCheck = false;
            end
            
            % check for field and return value
            if isfield(xStruct,sField)
                
                % get field value
                value = xStruct.(sField);
                
                % check for character array to be trimmed
                if ischar(value)
                    value = strtrim(value);
                end
                
                % check for empty value and assign empty option
                if isempty(value)
                    value = emptyOption;
                end
                
            else
                
                % assign empty option if field does not exist
                value = emptyOption;
                
                % optional check output
                if bCheck
                    fprintf(2,'\tAttribute "%s" is missing for "%s".\n',...
                        sField,obj.oModelInst.sSetupName);
                end
                
            end
            
        end % getValueOfField
        
    end % private methods
    
    % =====================================================================
    
    methods (Static, Access = private)
        
        function xPort = getMatchingPort(sPortName,xPortList)
            
            % init ouput
            xPort = struct([]);
            
            % check field name
            if isfield(xPortList,'name')
                
                % run through structure list
                for nPort=1:numel(xPortList)
                    
                    % check for equal signal name
                    if strcmp(strtrim(xPortList(nPort).('name')),sPortName)
                        xPort = xPortList(nPort);
                        break;
                    end
                    
                end % xPortList
                
            end % if fields
            
        end % getMatchingPort
        
        % =================================================================
        
        function xParam = getMatchingParam(sParamName,sClassName,xParamList)
            
            % init ouput
            xParam = struct([]);
            
            % check field name
            if isfield(xParamList,'name') && isfield(xParamList,'className')
                
                % run through structure list
                for nPar=1:numel(xParamList)
                    
                    % check for equal parameter name
                    if strcmp(strtrim(xParamList(nPar).('name')),sParamName)
                       
                        % check class name
                        if ~isempty(sClassName) && ...
                           strcmp(strtrim(xParamList(nPar).('className')),sClassName)
                            xParam = xParamList(nPar);
                        else
                            xParam = xParamList(nPar);
                            break;
                        end
                        
                    end % check parameter name
                    
                end % xParamList
                
            end % if fields
            
        end % getMatchingParam
        
        % =================================================================
        
        function [sClassType,sSubspecies] = getMatchingClassAttributes(sClassName,xDataSet)
            
            % init output
            sClassType = '';
            sSubspecies = '';
            
            % run through all data sets
            for nSet=1:numel(xDataSet)
                if strcmp(xDataSet(nSet).('className'),sClassName)
                    sClassType = xDataSet(nSet).('classType');
                    sSubspecies = xDataSet(nSet).('isSubspecies');
                    return;
                end
            end
            
        end % getMatchingClassAttributes
     	
        % =================================================================
        
        function [xParamVals,valueOfParam,sSmpVariable] = getInitIOParamValue(sParamName,sIndex,xParamVals,sContext,sSpecies)
            
            % init value
            valueOfParam = [];
            sSmpVariable = sprintf('MISSING IO param %s',sParamName);
            
            % get values from in and outs
            xInVals = xParamVals.('in');
            xOutVals = xParamVals.('out');

            % check parameter in in or out structure
            if isfield(xInVals,sParamName)
                
                % get value from structure
                valueOfParam = xInVals.(sParamName);
                
                % get sMP valiable structure
                sSmpVariable = sprintf('sMP.%s.%s.%s.%s',sContext,sSpecies,...
                    'in',sParamName);
                
                % remove field
                xInVals = rmfield(xInVals,sParamName);
                xParamVals.('in') = xInVals;
                
            elseif isfield(xOutVals,sParamName)
                
                % get value from structure
                valueOfParam = xOutVals.(sParamName);
                
                % get sMP valiable structure
                sSmpVariable = sprintf('sMP.%s.%s.%s.%s',sContext,sSpecies,...
                    'out',sParamName);
                
                % remove field
                xOutVals = rmfield(xOutVals,sParamName);
                xParamVals.('out') = xOutVals;
                
            else
                
                % warning if init IO parameter has index and was not found
                if ~isempty(sIndex)
                    fprintf(1,'\tWARNING: initIO parameter "%s" of species "%s" was defined in module xml but was not found in sMP structure!\n',...
                        sParamName,sSpecies);
                end
                
            end
            
        end % getInitIOParamValue
        
        % =================================================================
        
        function [xParamVals,valueOfParam,sSmpVariable] = getDataClassParamValue(sParamName,sClassName,sSubspecies,sIndex,xParamVals,sContext,sSpecies)
            
            % init value
            valueOfParam = [];
            sSmpVariable = '';
            
            % check for subspecies
            if strcmp(sSubspecies,'1')
                
                % pre define structure in sMP
                sSmpVariable = sprintf('sMP.%s.%s.%s.%s',sContext,sSpecies,...
                    sClassName,sParamName);
                
                % check subspecies field
                if ~isfield(xParamVals,sClassName) && ...
                   ~isstruct(xParamVals.(sClassName))
                    
                    % wraning if subspecies is not appear correctly in sMP
                    % structure
                    fprintf(1,'\tWARNING: Subspecies class name "%s" of species "%s" was defined in module xml but was not found in sMP structure!\n',...
                        sClassName,sSpecies);
                    
                else

                    % get structure of subspecies
                    xSubParamVals = xParamVals.(sClassName);

                    % check parameter name in value structure
                    if ~isfield(xSubParamVals,sParamName)
                        
                        % warning if parameter has index and was not found
                        if ~isempty(sIndex)
                            fprintf(1,'\tWARNING: Parameter "%s" in class "%s" of species "%s" was defined in module xml but was not found in sMP structure!\n',...
                                sParamName,sClassName,sSpecies);
                        end
                        
                    else
                        
                        % get value from structure
                        valueOfParam = xSubParamVals.(sParamName);
                        
                        % remove field
                        xSubParamVals = rmfield(xSubParamVals,sParamName);
                        xParamVals.(sClassName) = xSubParamVals;
                        
                    end

                end

            else
                
                % pre define structure in sMP
                sSmpVariable = sprintf('sMP.%s.%s.%s',sContext,sSpecies,...
                    sParamName);
                
                % check parameter name in value structure
                if ~isfield(xParamVals,sParamName)
                    
                    % warning if parameter has index and was not found
                    if ~isempty(sIndex)
                        fprintf(1,'\tWARNING: Parameter "%s" of species "%s" was defined in module xml but was not found in sMP structure!\n',...
                            sParamName,sSpecies);
                    end
                    
                else
                    
                    % get value from structure
                    valueOfParam = xParamVals.(sParamName);
                    
                    % remove field
                    xParamVals = rmfield(xParamVals,sParamName);
                    
                end

            end
            
        end % getDataClassParamValue
      	
    end % static private methods
    
end % dveClassSetupInstance