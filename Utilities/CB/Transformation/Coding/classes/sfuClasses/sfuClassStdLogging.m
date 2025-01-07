classdef sfuClassStdLogging < cbtClassSilverSfu
    
    properties (Access = private)
        
        % config parameters must be confirmed with:
        oThisSfuParam = parClassStdLogging.empty;
        
    end % private properties
    
    % =====================================================================
    
    properties (Constant, Access = private)
        
        % standard file name of log signal list
        sStdSignalListFileName = 'pltmLogSilver.txt';
        
        % standard file name of parameter log list
        sStdParameterListFileName = 'ParameterList.txt';
        
        % Python script to read parameter list
        sReadParamListScript = 'DIVeReadParamList.py';
        
        % Python script to rename result log file
        sRenameResultLogScript = 'DIVeRenameLog.py';
        
        % list of species which parameters has to be logged
        cSpeciesParamLogList = {'mec3d'};
        
        % standard name of time signal
        sStdTimeSignalName = 'time';
        
    end % private constant properties
    
    % =====================================================================
    
    methods
        
        function obj = sfuClassStdLogging(oCONST,oMP,sLogType,xMP,xConfig,xSetupList)
            
            % create from super class
            obj@cbtClassSilverSfu(oCONST,oMP,'SFU_Logging');
            
            % get param object depended on log type
            if strcmpi(sLogType,'mdf')
                obj.oThisSfuParam = parClassStdLogging(oCONST,'mdf');
            elseif strcmpi(sLogType,'mat')
                obj.oThisSfuParam = parClassStdLogging(oCONST,'mat');
            elseif strcmpi(sLogType,'csv')
                obj.oThisSfuParam = parClassStdLogging(oCONST,'csv');
            else
                error('Unknown writer type "%s".',sLogType);
            end
            
            % assign parameter
            obj.assignSfuParameter(obj.CONST.nCreateOrderLogging,...
                obj.oThisSfuParam);
            
            % -------------------------------------------------------------
            
            % assign name of sil configuration
            obj.oSfuParam.ConfigurationName = silGetConfigParamResolve(...
                obj.CONST.sStdConfigParamConfigName);
            
            % create log signal list file
            obj.createLogSignalFile(xConfig,xMP);
            
            % create log parameter list file
            obj.createLogParamFile(xSetupList);
            
        end % sfuClassStdLogging
        
        % =================================================================
        
        % INDIVIDUAL create method
        function thisCreateSfuFiles(obj,sLogTime,sSimStepSize)
            
            % DEFAULT create actions
            obj.createSfuFiles;
            
            % -------------------------------------------------------------
            % INDIVIDUAL create actions
            
            % convert sample times to double
            vLogTime = str2double(sLogTime);
            vSimStepSize = str2double(sSimStepSize);
            
            % get multiplier
            if vLogTime < vSimStepSize
                fprintf(2,'\tWARNING: Log sample time is lower than simulation step size, used step size instead.\n');
                nMultiplier = 1;
            else
                % take lower step size
                nMultiplier = floor(vLogTime / vSimStepSize);
                vNewLogTime = nMultiplier * vSimStepSize;
                fprintf(1,'\tTook %s s as resulting log sample time.\n',...
                    num2str(vNewLogTime));
            end
            
            % filepath of SFU sil file
            sSfuSilFilepath = fullfile(obj.CONST.sSfuFolder,...
                obj.sSfuSilFile);
            
            % create xml object
            oXml = xmlClassModifier(sSfuSilFilepath);
            
            % activate macro step multiplier => ATTENTION!: Only if writer
            % is first module in SFU
            if oXml.isComplex('multiply-macro-step')
                oXml.setComplex('multiply-macro-step',{'true'});
            else
                fprintf(2,'\tWARNING: No xml complex to activate macro step multiplier was found in SFU "%s".\n',...
                    sSfuSilFilepath);
            end
            
            % set macro step multiplier value => ATTENTION!: Only if writer
            % is first module in SFU
            if oXml.isComplex('macro-step-multiplier')
                oXml.setComplex('macro-step-multiplier',{num2str(nMultiplier)});
            else
                fprintf(2,'\tWARNING: No xml complex to set macro step multiplier value was found in SFU "%s".\n',...
                    sSfuSilFilepath);
            end
            
            % write modified sil file
            oXml.writeFile(sSfuSilFilepath);
            
        end % thisCreateSfuFiles
        
    end % methods
    
    % =====================================================================
    
    methods (Access = private)
        
        function createLogSignalFile(obj,xConfig,xMP)
            
            % get signal list to be logged from configuration
            cSignalListConfig = obj.getSignalListFromConfig(xConfig);
            
            % get file list with signal lists from module internal logging
            cSignalListModules = obj.getSignalListFromModules(xMP,...
                obj.CONST.sWorkspaceFolder);
            
            % merge signal list
            cMergedLogSignalList = unique(...
                [cSignalListConfig;cSignalListModules],'stable');
            
            % name of log signal list file
            obj.oSfuParam.LogSignalListFile = obj.sStdSignalListFileName;
            
            % filepath of log signal list file
            sLogSignalListFilepath = fullfile(obj.CONST.sMasterFolder,...
                obj.oSfuParam.LogSignalListFile);
            
            % add time as signal when list is empty
            if isempty(cMergedLogSignalList)
                cMergedLogSignalList = {obj.sStdTimeSignalName};
            end
            
            % create text string from signal list
            sLogSignalListTxt = strLinesToString(cMergedLogSignalList);
            
            % write signal list to file
            fleFileWrite(sLogSignalListFilepath,sLogSignalListTxt,'w');
            
        end % createLogSignalFile
        
        % =================================================================
        
        function createLogParamFile(obj,xSetupList)
            
            % name of log paremeter list file
            obj.oSfuParam.LogParamListFile = obj.sStdParameterListFileName;
            
            % filepath of log signal list file
            sLogParamListFilepath = fullfile(obj.CONST.sMasterFolder,...
                obj.oSfuParam.LogParamListFile);
            
            % get assignment text of all parameters of given species
            sLogParamListTxt = obj.getTextStringOfParamAssign(xSetupList,...
                obj.cSpeciesParamLogList,obj.CONST.nValuePrecision);
            
            % write signal list to file
            fleFileWrite(sLogParamListFilepath,sLogParamListTxt,'w');
            
        end % createLogParamFile
        
    end % private methods
    
    % =====================================================================
    
    methods (Static, Access = private)
        
        function cSignalList = getSignalListFromConfig(xConfig)
            
            % get signal list to be logged from configuration
            if isfield(xConfig,'Interface') && ...
                    isfield(xConfig.('Interface'),'Logging') && ...
                    isfield(xConfig.('Interface').('Logging'),'name')
                
                cSignalList = {xConfig.('Interface').('Logging').('name')}';
                
            else
                
                cSignalList = {};
                
            end
            
        end % getSignalListFromConfig
        
        % =================================================================
        
        function cSignalList = getSignalListFromModules(xMP,sWorkspaceFolder)
            
            % init signal list
            cSignalList = {};
            
            % get file list with logging signals
            if isfield(xMP,'cfg') && isfield(xMP.('cfg'),'cLogAdd')
                cAddLogFileList = xMP.('cfg').('cLogAdd');
            else
                cAddLogFileList = {};
            end
            
            % check if files exists
            for nFile=1:numel(cAddLogFileList)
                
                % create fullpath of file
                sLogFilepath = fullfile(sWorkspaceFolder,cAddLogFileList{nFile});
                
                % check if file exists
                if ~chkFileExists(sLogFilepath)
                    
                    % display warning if file not exists
                    fprintf(2,'\tWARNING: Module log file "%s" not found.\n',...
                        sLogFilepath);
                    
                else
                    
                    % read file content
                    sTxt = fleFileRead(sLogFilepath);
                    
                    % create list from file content
                    cSignalList = strStringListClean(strStringToLines(sTxt));
                    
                end
                
            end % log file list
            
        end % getSignalListFromModules
        
        % =================================================================
        
        function sTxtStr = getTextStringOfParamAssign(xSetupList,cSpeciesParamLogList,nPrecision)
            
            % init output
            sTxtStr = '';
            
            % run through setups
            for nSet=1:numel(xSetupList)
                
                % current setup
                xSetup = xSetupList(nSet);
                sSpecies = xSetup.species;
                
                % skip setup if species is not member of species list
                if ismember(sSpecies,cSpeciesParamLogList)
                    
                    % get parameter from species
                    xParams = xSetup.Parameter;
                    
                    % parameter list
                    for nPar=1:numel(xParams)
                        
                        % get parameter value
                        paramValue = xParams(nPar).value;
                        
                        % check for muneric parameter
                        if isnumeric(paramValue)
                            
                            % create parameter value string of vector
                            sParamString = mat2str(paramValue,nPrecision);
                            
                            % check for subspecies class name
                            if ~isempty(xParams(nPar).isSubspecies)
                                sParamNameStruct = sprintf('%s_%s',...
                                    xParams(nPar).className,...
                                    xParams(nPar).name);
                            else
                                sParamNameStruct = xParams(nPar).name;
                            end

                            % create assignment string
                            sTxtStr = sprintf('%s%s_p_%s = %s;\n',sTxtStr,...
                                sSpecies,sParamNameStruct,sParamString);

                        end % is numeric

                    end % xParamList
                    
                end % is species
                
            end % xSetupList
            
        end % getTextStringOfParamAssign
         
    end % static private methods
    
end