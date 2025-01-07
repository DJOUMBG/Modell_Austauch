classdef cbtClassCbtMain < handle
    
    properties (SetAccess = private, GetAccess = public)
        
        % transformation constant object => MUST BE GETACCESS PUBLIC!
        CONST = cbtClassTrafoCONST.empty;
        
        % -----------------------------------------------------------------
        
        % run type of DIVe cb transformation
        eRunType = cbtEnumRunTypes.empty;
        
        % run in Matlab debug mode flag
        bDebugMode = false;
        
        % -----------------------------------------------------------------
        
        % sMP handling object
        oMP = dveClassSmp.empty;
        
        % object with DIVe configuration data and methods
        oConfig = cbtClassDiveConfig.empty;
        
        % SFU object list
        cSfuList = {};
        
        % main sil SFU object
        oMainSfu = sfuClassStdMainTemplate.empty;
        
        % object to push update messages to DIVe ONE
        oDiveOneCom = dveClassDiveOneSimState.empty;
        
        % DIVe ONE info structure
        xOneInfo = struct([]);
        
        % -----------------------------------------------------------------
        
        % save flag
        bSavedStructures = false;
        
        % success flag
        bSuccess = false;
        
    end % properties
    
    % =====================================================================
    
    methods
        
        function obj = cbtClassCbtMain(sConfigXmlFilepath,nRunType,sWorkspaceRoot,bShortName,bDebugMode,xOneInfo,sResultFolderpath)
            
            % initial user info
            fprintf(1,'Prepare DIVe CB transformation ...\n');
            
            % -------------------------------------------------------------
            % Check input arguments:
            
            % check and formatting results folder path
            if nargin < 7
                sResultFolderpath = '';
            else
                sResultFolderpath = strrep(sResultFolderpath,'"','');
                sResultFolderpath = fullfile(sResultFolderpath);
            end
            
            % formatting file path
            sConfigXmlFilepath = strrep(sConfigXmlFilepath,'"','');
            sConfigXmlFilepath = fullfile(sConfigXmlFilepath);
            
            % check if file exists
            if ~chkFileExists(sConfigXmlFilepath)
                error('Configuration xml file "%s" does not exist.',...
                    sConfigXmlFilepath);
            end
            
            % formatting folder path
            sWorkspaceRoot = strrep(sWorkspaceRoot,'"','');
            sWorkspaceRoot = fullfile(sWorkspaceRoot);
            
            % check if folder exists
            if ~chkFolderExists(sWorkspaceRoot)
                error('Workspace root folder "%s" does not exist.',...
                    sWorkspaceRoot);
            end
            
            % formatting flag
            bShortName = logical(bShortName);
            
            % -------------------------------------------------------------
            % Assign input arguments:
            
            % get constant object
            obj.CONST = cbtClassTrafoCONST(sWorkspaceRoot,...
                sConfigXmlFilepath,bShortName,sResultFolderpath);
            
            % create debug command file
            obj.createRestartDebugFile;
            
            % set runtype enumeration
            obj.eRunType = cbtEnumRunTypes.getType(nRunType);
            
            % set debug flag
            obj.bDebugMode = bDebugMode;
            
            % set DIVe ONE info structure
            obj.xOneInfo = xOneInfo;
            
            % -------------------------------------------------------------
            % Prepare transformation process:
            
            % set timer
            nStartTime = tic;
            
            % get current directory
            sStartDir = pwd;
            
            % clean up Matlab path and set DIVe CB paths
            sPreMatlabPaths = matlabPathRestoreSet(obj.CONST.sCbtMatlabAddPathString);
            
            % set all paths with py cache
            cPyCacheFolders = {obj.CONST.sPyScriptFolder};
            
            % create log file
            diary(obj.CONST.sLogFile);
            oCloseDiaryObject = onCleanup(@() diary('off'));
            
            % clean up object
            oCleanUpObject = onCleanup(@() obj.cleanUpFunction(sStartDir,sPreMatlabPaths,cPyCacheFolders,obj.CONST.sDiveOneComDataFile));
            
            % create object to push update messages to DIVe ONE
            obj.oDiveOneCom = dveClassDiveOneSimState(obj.xOneInfo,...
                obj.CONST.sSilMainFolder,obj.CONST.sResultFolder);
            
            % create config soruce file
            obj.createConfigSourceFile;
            
            % -------------------------------------------------------------
            % Run DIVe process and create Silver SFUs:
            
            try
            
            % start message
            fprintf(1,'cbt: --- Transformation started for "%s". ---\n',...
                obj.CONST.sDiveConfigXmlFile);
            fprintf(1,'\t --> Run type: %s\n',char(obj.eRunType));
            
            % start message to DIVe ONE
            obj.oDiveOneCom.pushUpdate2DiveOne(2,...
                sprintf('Transformation started with run type %s ...',...
                char(obj.eRunType)));
                
            % pre init of cbt transformation process
            obj.preInitTransformation;
            
            % create DIVe data structures
            obj.oDiveOneCom.pushUpdate2DiveOne(2,...
                'Init DIVe configuration and modules ...');
            obj.oConfig = cbtClassDiveConfig(obj.CONST);
            obj.oMP = dveClassSmp(obj.CONST,obj.oConfig.xMP);
            
            % clean up Matlab path
            matlabPathRestoreSet(obj.CONST.sCbtMatlabAddPathString);
            
            % create Silver SFUs
            obj.createSfus;
            
            % save data structures to run directory and Matlab base workspace
            obj.saveDataStructures;
            
            % -------------------------------------------------------------
            % Create Silver environment:
            
            fprintf(1,'\ncbt: Create Silver simulation environment.\n');
            obj.oDiveOneCom.pushUpdate2DiveOne(2,...
                'Create Silver simulation environment ...');
            
            % create batch file to create main SiL file
            obj.createCreateSilBatch;
            
            % create batch file to run silent simulation
            obj.createRunSilBatch;
            
            % create final sil file
            obj.createFinalSilFile;
            
            % run posthook scripts
            obj.runPosthook;
            
            % check all paths in final sil environment
            obj.pathLengthCheck;
            
            % -------------------------------------------------------------
            
            % run simulation if run type is given
            obj.runSilSimulation;
            
            % check if simulation was canceled
            if obj.oDiveOneCom.checkSimCancel4DiveOne
                error('Simulation was canceled by DIVe ONE User.');
            end
            
            % -------------------------------------------------------------
            
            % success handling
            oError = [];
            
            % catch errors
            catch ME
                
                % assign error object
                oError = ME;
                
                % save data structures to run directory and Matlab base
                % workspace, if not happend
                obj.saveDataStructures;
                
            end
            
            % error handling
            if ~isempty(oError)
                obj.bSuccess = false;
                obj.errorHandling(oError,sStartDir,sPreMatlabPaths,cPyCacheFolders);
            else
                obj.bSuccess = true;
                obj.successHandling(toc(nStartTime));
            end
            
            % clean up Matlab
            obj.cleanUpFunction(sStartDir,sPreMatlabPaths,...
                cPyCacheFolders,obj.CONST.sDiveOneComDataFile);
            
            % final message
            if obj.bSuccess
                fprintf(1,'DIVe CB transformation / simulation successfully completed.\n\n');
            else
                fprintf(2,'DIVe CB transformation / simulation ended with errors.\n\n');
            end
            
        end % cbtClassCbtMain
        
    end % methods
    
    % =====================================================================
    
    methods (Access = private)
        
        function preInitTransformation(obj)
            
            % pre init warning mode
            warning('off','verbose');
            warning('on','all');

            % set up debug mode
            if obj.bDebugMode
                warning('on','backtrace');
                dbstop if all error
            else
                warning('off','backtrace');
                dbclear if error
            end
            
            % -------------------------------------------------------------
            
            % get Matlab version
            sMatlabVersion = strtrim(['R',version('-release')]);
            
            % check Silver installation
            [~,sSilverVersion,~,sPythonVersion] = silSilverInstallationCheck;
            
            % display versions
            fprintf(1,'\ncbt: Used Matlab version: %s\n',sMatlabVersion);
            fprintf(1,'cbt: Used Silver version: %s\n',sSilverVersion);
            fprintf(1,'cbt: Used Python version: %s\n',sPythonVersion);
            
            % check template version versus installed Silver version
            oTemplates = cbtClassSfuTemplates(obj.CONST);
            oTemplates.checkTemplateVersion;
            
        end % preInitTransformation
        
        % =================================================================
        
        function createConfigSourceFile(obj)
            
            % check is DIVe ONE
            if obj.oDiveOneCom.bIsDiveOne
                return;
            end
            
            % get Perfoce info data if not is DIVe ONE
            [sConfigName,sDepotFilepath,nChangeNum] = ...
                dveGetPerforceInfoData(obj.CONST.sDiveConfigXmlFile);
            
            % create Matlab command for debugging DIVe configuration
            sTxt = sprintf('%s\n%s\n%d\n',sConfigName,sDepotFilepath,nChangeNum);
            
            % write file
            fleFileWrite(obj.CONST.sConfigSourceFile,sTxt,'w');
            
        end % createConfigSourceFile
        
        % =================================================================
        
        function createSfus(obj)
            
            % user info
            fprintf(1,'\ncbt: Create SFUs for DIVe module species.\n');
            
            % create main sil SFU
            obj.oMainSfu = sfuClassStdMainTemplate(obj.CONST,obj.oMP);
            obj.oMainSfu.thisCreateSfuFiles;
            
            % create support SFU
            [~,sSimEndTime] = obj.getSolverSetup(obj.oConfig.xConfigXml);
            oSfuSupport = sfuClassStdSupport(obj.CONST,obj.oMP,...
                obj.oConfig.xConfigXml,obj.oConfig.xSetupList,...
                obj.oDiveOneCom,sSimEndTime);
            oSfuSupport.thisCreateSfuFiles;
            obj.appendSfuList(oSfuSupport);
            
            % create range check SFU
            oSfuRangeCheck = sfuClassStdRangeCheck(obj.CONST,obj.oMP,...
                obj.oConfig.xSetupList);
            oSfuRangeCheck.thisCreateSfuFiles;
            obj.appendSfuList(oSfuRangeCheck);
            
            % create logging SFU
            oSfuLogging = obj.getLoggingSfuObject;
            obj.appendSfuList(oSfuLogging);
            
            % create post SFU
            oSfuPost = sfuClassStdPost(obj.CONST,obj.oMP,...
                    obj.oConfig.cPostScripts);
            oSfuPost.thisCreateSfuFiles;
            obj.appendSfuList(oSfuPost);
            
            % create cosim SFU
            oSfuCosim = obj.getCosimSfuObject;
            obj.appendSfuList(oSfuCosim);
            
            % create DIVe module SFUs
            for nSet=1:numel(obj.oConfig.xSetupList)
                
                % current setup
                xSetup = obj.oConfig.xSetupList(nSet);
                
                % append SFU object
                oSfuModule = obj.getModuleSfuObject(xSetup);
                obj.appendSfuList(oSfuModule);
                
            end
            
            % sort SFU list by order number
            obj.sortSfuList;
            
        end % createSfus
        
        % =================================================================
        
        function createCreateSilBatch(obj)
            
            % get simulation stepsize
            sSimStepSize = obj.getSolverSetup(obj.oConfig.xConfigXml);
            
            % format and change unit of simulation stepsize from s to ms
            vSimStepSize = str2double(sSimStepSize) * 1e3;
            
            % get SFU create line strings
            [sSfuTxt,sRangeCheckTxt] = obj.getCreateStringText;
            
            % -------------------------------------------------------------
            
            % init string collection
            sPart = {};
            
            % set create strings of SiL main file
            sPart{end+1} = sprintf('@ECHO OFF\n\n');
            sPart{end+1} = sprintf('silver ^\n');
            sPart{end+1} = sSfuTxt;
            sPart{end+1} = sprintf('--templateProject %s --targetProject %s ^\n',...
                fullfile(obj.CONST.sSfuFolderFromMain,obj.oMainSfu.sSfuSilFile),...
                obj.CONST.getMainSilFilename);
            sPart{end+1} = sprintf('-d %s -s --generateSil --noGui ^\n',...
                num2str(vSimStepSize));
            
            % set config params of SiL main file
            sPart{end+1} = sprintf('%s=%s ^\n',...
                obj.CONST.sStdConfigParamConfigName,...
                obj.CONST.sSilverSetupName);
            sPart{end+1} = sprintf('%s="%s" ^\n',...
                obj.CONST.sStdConfigParamMasterDir,...
                obj.CONST.sMasterFolder);
            sPart{end+1} = sprintf('%s="%s" ^\n',...
                obj.CONST.sStdConfigParamMatlabPath,...
                obj.CONST.sMatlabExe);
            sPart{end+1} = sprintf('%s="%s"\n',...
                obj.CONST.sStdConfigParamDiveContentPath,...
                obj.CONST.sContentFromMaster);
            
            % set additional comment lines
            sPart{end+1} = sprintf('\n%s\n',sRangeCheckTxt);
            
            % concatenate strings
            sTxt = strjoin(sPart,'');
            
            % write batch file to Sil environment
            fleFileWrite(obj.CONST.sCreateSilFile,sTxt,'w');
            
        end % createCreateSilBatch
        
        % =================================================================
        
        function createRunSilBatch(obj)
            
            % simulation end time
            [~,sSimEndTime] = obj.getSolverSetup(obj.oConfig.xConfigXml);
            
            % init string collection
            sPart = {};
            
            % set lines of runSilSim batch script
            sPart{end+1} = sprintf('@ECHO OFF\n\n');
            sPart{end+1} = sprintf('%s\n',...
                'set datetimeFormat=%date:~-4%_%date:~3,2%_%date:~0,2%_%time:~0,2%_%time:~3,2%_%time:~6,2%');
            sPart{end+1} = sprintf('set LogfileName=%s%s%s%s\n',...
                obj.CONST.sResultFromMain,filesep,...
                obj.CONST.sSilSimLogFilePrefix,'%datetimeFormat: =0%.log');
            sPart{end+1} = sprintf('if not exist "%s" mkdir %s\n',...
                obj.CONST.sResultFromMain,obj.CONST.sResultFromMain);
            sPart{end+1} = sprintf('silversim -l %s -s -E %s %s',...
                '%LogfileName%',sSimEndTime,...
                obj.CONST.getMainSilFilename);
            
            % concatenate strings
            sTxt = strjoin(sPart,'');
            
            % write batch file to Sil environment
            fleFileWrite(obj.CONST.sRunSilFile,sTxt,'w');
            
        end % createRunSilBatch
        
        % =================================================================
        
        function createFinalSilFile(obj)
            
            % save current directory
            sThisCwd = pwd;
            
            % delete previous file
            if chkFileExists(obj.CONST.sMainSilFile)
                delete(obj.CONST.sMainSilFile);
            end
            
            % get fileparts of of create file
            [sFolder,sName,sExt] = fileparts(obj.CONST.sCreateSilFile);
            sCreateFilename = [sName,sExt];
            
            % change to folder with create script
            cd(sFolder);
            
            % call create script
            [nStatus,sCmdout] = system(sCreateFilename);
            
            % change back to previous working directory
            cd(sThisCwd);
            
            % error handling
            if nStatus ~= 0
                cd(sThisCwd);
                error('cbt: Error while creation of final SiL file:\n%s\n',...
                    sCmdout);
            end
            
        end % createFinalSilFile
        
        % =================================================================
        
        function createRestartDebugFile(obj)
            
            % single apos
            sApos = '''';
            
            % create Matlab command for debugging DIVe configuration
            sTxt = sprintf('%sRecommended Matlab version for execution: "%s"\n',...
                '% ',obj.CONST.sMatlabExe);
            
            sTxt = sprintf('%scd(%s%s%s);\n',sTxt,...
                sApos,obj.CONST.sWorkspaceFolder,sApos);
            
            sTxt = sprintf('%sstartDIVeCodeBased(%s%s%s,3,%s%s,%sdebugMode%s,true);',...
                sTxt,sApos,obj.CONST.sDiveConfigXmlFile,sApos,sApos,sApos,...
                sApos,sApos);
            
            % write file
            fleFileWrite(obj.CONST.sDebugCmdFile,sTxt,'w');
            
        end % createRestartDebugFile
        
        % =================================================================
        
        function runPosthook(obj)
            
            % user info 
            fprintf(1,'cbt: Run DIVe CB Silver posthooks.\n');
            
            % get SFU name list
            cSfuNameList = obj.getSfuNameList;
            
            % create arguments list
            cPyArgs = [{obj.CONST.sPyScriptFolder},...
                {obj.CONST.sSilConfigXmlFile},...
                {obj.CONST.sMainSilFile},...
                reshape(cSfuNameList,1,numel(cSfuNameList))];
            
            % change directory to main folder
            sCurDir = pwd;
            cd(obj.CONST.sSilMainFolder);
            
            % call python script
            bSuccess = pytCallPythonScript(obj.CONST.sPythonExe,...
                obj.CONST.sPythonPosthookFile,true,cPyArgs);
            
            % restore directory
            cd(sCurDir);
            
            % check Python call
            if ~bSuccess
                error('Posthook script could not be executed.');
            end
            
        end % runPosthook
        
        % =================================================================
        
        function saveDataStructures(obj)
            
            % if object not yet exists or structures already saved
            if isempty(obj.oConfig) || obj.bSavedStructures
                return;
            end
            
            % get structures from objects
            sMP = obj.oMP.sMP;
            SetupList = obj.oConfig.xSetupList;
            
            % assign to baseworkspace
            assignin('base','sMP',sMP);
            assignin('base','SetupList',SetupList);
            
            % save sMP structure
            save(obj.CONST.sSmpFile,'sMP','-v7');
            
            % save sMP structure
            save(obj.CONST.sSetupListFile,'SetupList','-v7');
            
            % set save flag
            obj.bSavedStructures = true;
            
        end % saveDataStructures
        
        % =================================================================
        
        function pathLengthCheck(obj)
            
            % user info
            fprintf(1,'cbt: Check path lengths of files in final sil environment.\n');
            
            % check all paths in final SiL environment
            [bValid,cPathList] = cbtPathLengthOfFilesCheck(...
                obj.CONST.sSilMainFolder,obj.CONST.nMaxPathLength);
            
            % check validation of path lengths
            if ~bValid
                fprintf(2,...
                    ['cbt: WARNING: %d paths are too long in final sil environment "%s".\n',...
                     '\tSilver may not be able to open the appropriate paths.\n'],...
                    length(cPathList),obj.CONST.sSilMainFolder);
            end
            
        end % pathLengthCheck
        
        % =================================================================
        
        function runSilSimulation(obj)
            
            if isequal(obj.eRunType,cbtEnumRunTypes.Open)
                
                % user info
                fprintf(1,'\ncbt: Open Silver simulation.\n');
                obj.oDiveOneCom.pushUpdate2DiveOne(2,...
                    'Open Silver simulation ...');
                
                % create command for open in background
                sOpenCmd = sprintf('silver -s --stopped "%s" &',...
                    obj.CONST.sMainSilFile);
                
                % command to open Silver
                nStatus = system(sOpenCmd);
                
                % check start of command
                if nStatus~=0
                    error('cbt: Silver configuration could not be opened.');
                end
                
            elseif isequal(obj.eRunType,cbtEnumRunTypes.Run)
                
                % user info
                fprintf(1,'\ncbt: Run Silver simulation with GUI.\n');
                obj.oDiveOneCom.pushUpdate2DiveOne(2,...
                    'Run Silver simulation with GUI ...');
                
                % create command for run in background
                sRunCmd = sprintf('silver -s --autoStart "%s"',...
                    obj.CONST.sMainSilFile);
                    
                % modify run command if not is DIVe ONE to open new process
                % for running Silver
                if not(obj.oDiveOneCom.bIsDiveOne)
                    sRunCmd = sprintf('%s &',sRunCmd);
                end
                
                % command to run Silver
                nStatus = system(sRunCmd);
                
                % check start of command
                if nStatus~=0
                    error('cbt: Error during interactive simulation.');
                end
                
            elseif isequal(obj.eRunType,cbtEnumRunTypes.Silent)
                
                % user info
                fprintf(1,'\ncbt: Run Silver simulation in silent mode:\n\n');
                obj.oDiveOneCom.pushUpdate2DiveOne(2,...
                    'Run Silver simulation in silent mode ...');
                
                % save current directory
                sCurDir = pwd;
                
                % change to main folder of simulation
                cd(obj.CONST.sSilMainFolder);
                
                % run sil simulation batch script
                nStatus = system(obj.CONST.sRunSilFile,'-echo');
                
                % check for eny errors
                if nStatus ~= 0
                    error('cbt: Error during silent simulation.');
                end
                
                % restore current folder
                cd(sCurDir);
                
            end
            
        end % runSilSimulation
        
        % =================================================================
        
        function errorHandling(obj,ME,sStartDir,sPreMatlabPaths,cPyCacheFolders)
            
            % capture error message
            sError = ME.message;

            % capture error stack
            [sErrorStack,sErrorStackLink] = resolveErrorStack(ME);

            % create error message for log file
            sErrorMsg = sprintf('\nERROR: %s\n%s',sError,sErrorStack);

            % append error to log file
            diary('off');
            fleFileWrite(obj.CONST.sLogFile,sErrorMsg,'a');
            
            % check DIVe ONE
            if obj.oDiveOneCom.bIsDiveOne
                
                % !!! DISPLAY ERROR IN MATLAB CONSOLE !!!
                % until implementation of non link error in dsim
                fprintf(2,'%s\n',sErrorMsg);
                
                % clean up Matlab
                obj.cleanUpFunction(sStartDir,sPreMatlabPaths,...
                    cPyCacheFolders,obj.CONST.sDiveOneComDataFile);
                
                % raise error
                rethrow(ME);
                
            else
                
                % check debug mode
                if obj.bDebugMode
                    
                    % clean up Matlab
                    obj.cleanUpFunction(sStartDir,sPreMatlabPaths,...
                        cPyCacheFolders,obj.CONST.sDiveOneComDataFile);
                    
                    % raise error
                    error('\nERROR: %s\n%s',sError,sErrorStackLink);
                    
                else
                    % just show error message
                    fprintf(2,'\nERROR: %s\n%s\n',sError,sErrorStackLink);
                end
                
            end
            
        end % errorHandling
        
        % =================================================================
        
        function successHandling(obj,vDuration)
            
            % create message parts pre and post
            sPre = sprintf('\ncbt: --- Transformation finished for'); 
            sPost = sprintf('- Duration: %.3f s ---\n\n',vDuration);

            % create command to open final folder in explorer
            sCmd = fleCmdToOpenFolderInExplorer(obj.CONST.sSilMainFolder);

            % create messages with an without link
            [sLinkMsg,sRawMsg] = strMsgWithMatCmdLink(...
                sPre,sCmd,obj.CONST.sSilverSetupName,sPost);
            
            % append to log file
            diary('off');
            fleFileWrite(obj.CONST.sLogFile,sRawMsg,'a');

            % display on command window with link if not DIVe ONE
            if obj.oDiveOneCom.bIsDiveOne
                fprintf(1,'%s',sRawMsg);
            else
                fprintf(1,'%s',sLinkMsg);
            end
                    
            % clean up message
            fprintf(1,'Clean up DIVe CB transformation ...\n');
            
        end % successHandling
        
        % =================================================================
        % =================================================================
        
        function oLoggingSfuObject = getLoggingSfuObject(obj)
            
            % get logging parameters
            [sLogType,sLogTime] = obj.getLoggingSetup(obj.oConfig.xConfigXml);
            
            % get master solver parameters
            sSimStepSize = obj.getSolverSetup(obj.oConfig.xConfigXml);
            
            % create logging SFU object
            oLoggingSfuObject = sfuClassStdLogging(obj.CONST,obj.oMP,...
                sLogType,...
                obj.oConfig.xMP,...
                obj.oConfig.xConfigXml,...
                obj.oConfig.xSetupList);
            oLoggingSfuObject.thisCreateSfuFiles(sLogTime,sSimStepSize);
            
        end % getLoggingSfuObject
        
        % =================================================================
        
        function oCosimSfuObject = getCosimSfuObject(obj)
            
            % >>> für env module eigene Routine
            
            % get list of relevant cosim setups
            xCosimSetups = struct([]);
            for nSet=1:numel(obj.oConfig.xSetupList)
                xSetup = obj.oConfig.xSetupList(nSet);
                if strcmp(xSetup.cosimType,'Simulink')
                    if strcmp(xSetup.bitVersion,'64')
                        xCosimSetups = [xCosimSetups,xSetup]; %#ok<AGROW>
                    else
                        fprintf(2,'WARNING: 32bit open Simulink modules are no longer supported in DIVe CB.\n');
                    end
                end
            end
            
            % create cosim SFU object
            if ~isempty(xCosimSetups)
                
                % create SFU object
                oCosimSfuObject = sfuClassCosim(obj.CONST,obj.oMP,...
                    obj.oConfig.xMP,...
                    obj.oConfig.xConfigXml,...
                    xCosimSetups);
                sMP = oCosimSfuObject.thisCreateSfuFiles;
                
                % assign updated sMP structure
                obj.oConfig.updateSmp(sMP);
                obj.oMP.updateObject(sMP);
                
            else
                oCosimSfuObject = cbtClassSilverSfu.empty;
            end
            
        end % getCosimSfuObject
        
        % =================================================================
        
        function oModuleSfuObject = getModuleSfuObject(obj,xSetup)
            
            if strncmpi(xSetup.context,'pltm',numel('pltm')) && ...
               strncmpi(xSetup.species,'log',numel('log')) && ...
               strncmpi(xSetup.family,'common',numel('common'))
           
                % is standard SFU
                oModuleSfuObject = [];
            
            elseif strncmpi(xSetup.context,'pltm',numel('pltm')) && ...
                   strncmpi(xSetup.species,'post',numel('post')) && ...
                   strncmpi(xSetup.family,'common',numel('common'))
           
                % is standard SFU
                oModuleSfuObject = [];
                
            elseif strcmp(xSetup.cosimType,'Simulink')
               
               % is cosim SFU
                oModuleSfuObject = [];
            
            elseif strcmp(xSetup.cosimType,'sfcn')
                
                if strncmpi(xSetup.context,'phys',numel('phys')) && ...
                   strncmpi(xSetup.family,'detail',numel('detail'))
                    
                    fprintf(1,'\tWARNING: GT sfunctions from (phys.{...}.detail) are not fully supported!!\n');
                    
                    % create GT sfunction object
                    % oModuleSfuObject = sfuClassSfcn(obj.CONST,obj.oMP,...
                    %     xSetup,true);
                    % oModuleSfuObject.thisCreateSfuFiles;
                    
                    % create sfunction object
                    oModuleSfuObject = sfuClassSfcn(obj.CONST,obj.oMP,xSetup);
                    oModuleSfuObject.thisCreateSfuFiles;
                    
                else
                    
                    % create sfunction object
                    oModuleSfuObject = sfuClassSfcn(obj.CONST,obj.oMP,xSetup);
                    oModuleSfuObject.thisCreateSfuFiles;
                    
                end
                    
            elseif strcmp(xSetup.cosimType,'fmu')
                
                % check for model exchange FMUs >>> currently obsolete in DIVe
                if strncmpi(xSetup.context,'ctrl',numel('ctrl')) && ...
                   strncmpi(xSetup.family,'sil',numel('sil'))
                    
                    fprintf(2,'WARNING: Model exchange FMUs (ctrl.{...}.sil) are currently not supported!\n');
                    
                    % create model exchange FMU object
                    % oModuleSfuObject = sfuClassFmu(obj.CONST,obj.oMP,xSetup);
                    % oModuleSfuObject.thisCreateSfuFiles;
                    
                    % create cosimulation FMU object
                    oModuleSfuObject = sfuClassFmuCs(obj.CONST,obj.oMP,xSetup);
                    oModuleSfuObject.thisCreateSfuFiles;
                    
                else
                    
                    % create cosimulation FMU object
                    oModuleSfuObject = sfuClassFmuCs(obj.CONST,obj.oMP,xSetup);
                    oModuleSfuObject.thisCreateSfuFiles;
                    
                end
                
            elseif strcmp(xSetup.cosimType,'dll')
                
                % create silver dll object
                oModuleSfuObject = sfuClassDll(obj.CONST,obj.oMP,xSetup);
                oModuleSfuObject.thisCreateSfuFiles;
                
            elseif strcmp(xSetup.cosimType,'Silver')
                
                % create silver SFU object
                oModuleSfuObject = sfuClassSilverSfuCb(obj.CONST,obj.oMP,xSetup);
                oModuleSfuObject.thisCreateSfuFiles;
               
            else
                
                % ignore module
                fprintf(2,'cbt: WARNING: No valid co-simulation type "%s" for species "%s".\n\t%s\n',...
                    xSetup.cosimType,xSetup.species,...
                    '=> Module will be ignored in final SiL simulation environment!');
                
                % empty object
                oModuleSfuObject = [];
                
            end
            
        end % getModuleSfuObject
        
        % =================================================================
        
        function appendSfuList(obj,oSfuObject)
            if ~isempty(oSfuObject)
                obj.cSfuList = [obj.cSfuList;{oSfuObject}];
            end
        end % appendSfuList
        
        % =================================================================
        
        function sortSfuList(obj)
            
            % init order number list
            nOrderNumList = zeros(numel(obj.cSfuList),1);
            
            % get order number of each sfu
            for nSfu=1:numel(obj.cSfuList)
                oSfu = obj.cSfuList{nSfu};
                nOrderNumList(nSfu) = oSfu.nCreateOrderNum;
            end
            
            % get sorted index
            [~,nSortIdx] = sort(nOrderNumList);
            
            % init sorted list
            cSortedSfuList = {};
            
            % create sorted sfu list
            for nSfu=1:numel(nSortIdx)
                oSfu = obj.cSfuList{nSortIdx(nSfu)};
                cSortedSfuList = [cSortedSfuList,{oSfu}]; %#ok<AGROW>
            end
            
            % assign sorted sfu list
            obj.cSfuList = cSortedSfuList;
            
        end % sortSfuList
        
        % =================================================================
        
        function [sTxt,sRangeCheckTxt] = getCreateStringText(obj)
            
            % init text string
            sTxt = '';
            sRangeCheckTxt = '';
            
            % run through create strings of sfus
            for nSfu=1:numel(obj.cSfuList)
                
                % current SFU
                oSfu = obj.cSfuList{nSfu};
                
                if oSfu.nCreateOrderNum ~= obj.CONST.nCreateOrderRangeCheck
                    sTxt = sprintf('%s%s',sTxt,oSfu.sCreateString);
                else
                    sRangeCheckTxt = sprintf('%s%s\n%s%s',...
                        obj.CONST.sWinBatchCommentString,...
                        'Decomment and copy the following line to SFU create lines above to use this SFU in SiL:',...
                        obj.CONST.sWinBatchCommentString,...
                        oSfu.sCreateString);
                    
                end
                
            end
            
        end % getCreateStringText
        
        % =================================================================
        
        function cSfuNameList = getSfuNameList(obj)
            
            % init list
            cSfuNameList = {};
            
            % run through SFU objects
            for nSfu=1:numel(obj.cSfuList)
                
                % current SFU
                oSfu = obj.cSfuList{nSfu};
                
                % append name to list;
                cSfuNameList = [cSfuNameList;{oSfu.sName}]; %#ok<AGROW>
                
            end
            
        end
        
        % =================================================================
        
        function [sSimStepSize,sSimEndTime] = getSolverSetup(obj,xConfigXml)
            
            % init parameters
            sSimStepSize = '';
            sSimEndTime = '';
            
            % check config xml for defined solver setup
            if isfield(xConfigXml,'MasterSolver')
                
                if isfield(xConfigXml.('MasterSolver'),'maxCosimStepsize')
                    sSimStepSize = xConfigXml.('MasterSolver').('maxCosimStepsize');
                end
                
                if isfield(xConfigXml.('MasterSolver'),'timeEnd')
                    sSimEndTime = xConfigXml.('MasterSolver').('timeEnd');
                end
                
            end
            
            % assign default parameters if not exist or is nan
            if isempty(sSimStepSize) || isnan(str2double(sSimStepSize))
                sSimStepSize = obj.CONST.sStdSimStepSize;
            end
            
            % assign default parameters if not exist or is inf or is nan
            if isempty(sSimEndTime) || ...
                    isinf(str2double(sSimEndTime)) || ...
                    isnan(str2double(sSimEndTime))
                sSimEndTime = obj.CONST.sStdSimEndTime;
            end
            
        end % getSolverSetup
        
    end % private methods
    
    % =====================================================================
    
    methods (Static, Access = private)
        
        function [sLogType,sLogTime] = getLoggingSetup(xConfigXml)
            
            % init parameters
            sLogType = '';
            sLogTime = '';
            
            % check config xml for defined log setup
            if isfield(xConfigXml,'Interface')
                
                if isfield(xConfigXml.('Interface'),'LogSetup')
                    
                    if isfield(xConfigXml.('Interface').('LogSetup'),'sampleType')
                        sLogType = xConfigXml.('Interface').('LogSetup').('sampleType');
                    end
                    
                    if isfield(xConfigXml.('Interface').('LogSetup'),'sampleTime')
                        sLogTime = xConfigXml.('Interface').('LogSetup').('sampleTime');
                    end
                    
                end
                
            end
            
            % assign default parameters if not exist
            if isempty(sLogType)
                sLogType = obj.CONST.sStdLogType;
            end
            
            if isempty(sLogTime)
                sLogTime = obj.CONST.sStdLogTime;
            end
            
            % -------------------------------------------------------------
            
            % convert log type from other formats
            if strncmpi(sLogType,'ToASCII',numel('ToASCII'))
                sLogType = 'csv';
            elseif strncmpi(sLogType,'ToWorkspace',numel('ToWorkspace'))
                sLogType = 'mat';
            elseif strncmpi(sLogType,'Simulink',numel('Simulink'))
                sLogType = 'mat';
            elseif strncmpi(sLogType,'LDYN',numel('LDYN'))
                sLogType = 'mat';
            end
            
        end % getLoggingSetup
        
        % =================================================================
        
        function cleanUpFunction(sStartDir,sPreMatlabPaths,cPyCacheFolders,sDiveOneComDataFile)
            
            % delete DIVe ONE com data file if exists
            %   reason: if restart of simulation communication with DIVe
            %   ONE is also established again
            if chkFileExists(sDiveOneComDataFile)
                delete(sDiveOneComDataFile);
            end
            
            % delete all pyc and log files and its folders
            for nFolder=1:numel(cPyCacheFolders)
                deleteAllPycAndLog(cPyCacheFolders{nFolder});
            end
            
            % change back to first working directory
            cd(sStartDir);
            
            % restore user definied matlab paths
            matlabPathRestoreSet(sPreMatlabPaths);
            
        end % cleanUpFunction
        
    end % static private methods
    
end