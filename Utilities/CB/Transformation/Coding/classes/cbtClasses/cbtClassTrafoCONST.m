classdef cbtClassTrafoCONST < handle
    
    % =====================================================================
    % PRIVATE CONSTANT PROPERTIES:
    % =====================================================================
    
    properties (Constant, Access = private)
        
        % default name of SiLs folder in workspace
        sStdSilFolderName = 'SiLs';
        
        % default name of results folder in Sil location
        sStdResultFolderName = 'results';
        
    end % private constant properties
    
    % =====================================================================
    % PUBLIC CONSTANT PROPERTIES:
    % =====================================================================
    
    properties (Constant)
        
        % -----------------------------------------------------------------
        % DIVe names:
        % -----------------------------------------------------------------
        
        % name of initIo Data class
        sStdInitIoClassName = 'initIO';
        
        % name of Module folder
        sStdFolderNameModule = 'Module';
        
        % name of Data folder
        sStdFolderNameData = 'Data';
        
        % name 
        sStdFolderNameSupport = 'Support';
        
        % list of valid context names
        cStdContextList = {'ctrl','phys','human','bdry','pltm'};
        
        % -----------------------------------------------------------------
        % Silver setup names:
        % -----------------------------------------------------------------
        
        % name of config parameter of final config name (main folder of final SiL)
        sStdConfigParamConfigName = 'DIVe_ConfigName';
        
        % name of config parameter of final Master folder (= run directory of final SiL)
        sStdConfigParamMasterDir = 'DIVe_MasterDir';
        
        % name of config parameter of matlab.exe path in final SiL file
        sStdConfigParamMatlabPath = 'DIVe_Matlab64Exe';
        
        % name of config parameter of content path in final SiL file
        sStdConfigParamDiveContentPath = 'DIVe_ContentPath'; 
        
        % name of Simulink cosim instance
        sCosimName = 'SimulinkCosim';
        
        % name of Simulink cosim instance of DIVe species "env"
        sCosimNameEnv = 'SimulinkCosimEnv';
        
        % default prefix of SiL simulation log file
        sSilSimLogFilePrefix = 'SilSimLog__';
        
        % default Silver SFU extension
        sStdSilverSfuExt = '.sil';
        
        % default Silver SFU config and init file extension
        sStdSilverIniExt = '.ini';
        
        % default name of rename output signal property
        sStdOutRenameProp = 'OutRenameFile';
        
        % -----------------------------------------------------------------
        % Silver setup SFU order:
        % -----------------------------------------------------------------
        
        % default create order of SFU_ENV module: must be very first
        nCreateOrderEnv = -1;
        
        % default create order of SFU_SUPPORT: must be first
        nCreateOrderSupport = 0;
        
        % default create order of SFU_SimulinkCosim: must be last
        nCreateOrderCosim = 1e6 + 1;
        
        % default create order of SFU_LOGGING: must be last
        nCreateOrderLogging = 1e6 + 2;
        
        % default create order of SFU_POST: must be last
        nCreateOrderPost = 1e6 + 3;
        
        % default create order of SFU_SimulinkCosim: must be last
        nCreateOrderRangeCheck = 1e6 + 4;
        
        % -----------------------------------------------------------------
        % Default patterns:
        % -----------------------------------------------------------------
        
        % replace key pattern
        sReplaceNameString = '$$$';
        
        % config ini replace string
        sConfigIniReplaceString = '$$$paramsIniConfigPath$$$';
        
        % double quotation mark replace string
        sQuotReplaceString = '%%%';
        
        % seperator of Python arguments
        sPyArgSeperatorString = '&&&';
        
        % windows batch script comment string
        sWinBatchCommentString = ':: ';
        
        % -----------------------------------------------------------------
        % Default values:
        % -----------------------------------------------------------------
        
        % maximum characters of path lengths
        nMaxPathLength = 255;
        
        % value precision: maximum number of significant digits in num2str
        % or mat2str (e.g. initIO.txt, *.dym, ParameterList.txt)
        nValuePrecision = 15;
        
        % default log type
        sStdLogType = 'mdf';
        
        % default log time
        sStdLogTime = '0.1';
        
        % default simulation step size
        sStdSimStepSize = '0.1';
        
        % default simulation end time
        sStdSimEndTime = '36000';
        
    end % public constant properties
    
    % =====================================================================
    % READ-ONLY PROPERTIES:
    % =====================================================================
    
    properties (SetAccess = private, GetAccess = public)
        
        % filepath of DIVe configuration xml file
        sDiveConfigXmlFile = '';
        
        % folderpath of DIVe workspace root folder
        sWorkspaceFolder = '';
        
        % folderpath of DIVe SiLs
        sSilsFolder = '';
        
        % folderpath of Sil root folder (main)
        sSilMainFolder = '';
        
        % folderpath of SiLs result folder
        sResultFolder = '';
        
        % name of Silver setup
        sSilverSetupName = '';
        
        % flag if using short name (true) or full name with date and time
        % (false) for sSilverSetupName
        bShortName = false;
        
    end % properties
    
    % =====================================================================
    % INIT DEPENDENT PROPERTIES:
    % =====================================================================
    
    properties (Dependent)
        
        % name of DIVe config
        sDiveConfigName = '';
        
        % -----------------------------------------------------------------
        % DIVe workspace paths:
        % -----------------------------------------------------------------
        
        % folderpath of DIVe Content
        sContentFolder = '';
        
        % folderpath of DIVe Function
        sFunctionFolder = '';
        
        % folderpath of DIVe Utilities
        sUtilitiesFolder = '';
        
        % folderpath of Silver support scripts
        sSilverSupportFolder = '';
        
        % folderpath of additional python scripts !!! => outdated, when
        % defining full paths of python scripts
        sPyScriptFolder = '';
        
        % -----------------------------------------------------------------
        % Additional transformation paths:
        % -----------------------------------------------------------------
        
        % filepath of Python posthook file
        sPythonPosthookFile = '';
        
        % filepath of Python create Silver SFU file
        sPythonCreateSfuFile = '';
        
        % folderpath of template main folder
        sSilverTemplateMainFolder = '';
        
        % folderpath of template master folder
        sSilverTemplateMasterFolder = '';
        
        % folderpath of template SFU folder
        sSilverTemplateSfuFolder = '';
        
        % folderpath of template config param folder
        sSilverTemplateConfigParamFolder = '';
        
        % filepath of SFU template version file
        sSfuTemplateVersionFile = '';
        
        % -----------------------------------------------------------------
        % Environment paths:
        % -----------------------------------------------------------------
        
        % folderpath of Silver home (installation path)
        sSilverHome = '';
        
        % filepath of Silvers Python 3 executable
        sPythonExe = '';
        
        % filepath of used Matlab executable
        sMatlabExe = '';
        
        % list of filepaths to be added with subfolders to Matlab path
        cCbtMatlabPaths = '';
        
        % path string to be added to Matlab path
        sCbtMatlabAddPathString = '';
        
        % -----------------------------------------------------------------
        % Silver setup folders:
        % -----------------------------------------------------------------
        
        % folderpath of master folder (= run directory)
        sMasterFolder = '';
        
        % folderpath of rbu folder (rest bus unit content)
        sRbuFolder = '';
        
        % folderpath of log folder
        sLogFolder = '';
        
        % folderpath of SFU folder
        sSfuFolder = '';
        
        % folderpath of config param folder
        sConfigParamFolder = '';
        
        % folderpath of init param folder
        sInitParamFolder = '';
        
        % relative path from Master folder to result folder
        sResultFromMaster = '';
        
        % relative path from Master folder to Content folder
        sContentFromMaster = '';
        
        % relative path from Master folder to SilverSupport folder
        sSilverSupportFromMaster = '';
        
        % relative path from main folder to result folder
        sResultFromMain = '';
        
        % relative path from main folder to SFUs folder
        sSfuFolderFromMain = '';
        
        % relative path from master folder to config param folder
        sConfigParamFromMaster = '';
        
        % init param from main folder
        sInitParamFromMain = '';
        
        % -----------------------------------------------------------------
        % Silver setup file paths:
        % -----------------------------------------------------------------
        
        % filepath of main Sil file
        sMainSilFile = '';
        
        % filepath of restored DIVe configuration xml
        sSilConfigXmlFile = '';
        
        % filepath of create Sil batch file
        sCreateSilFile = '';
        
        % filepath of run Sil batch file
        sRunSilFile = '';
        
        % filepath of debug command file
        sDebugCmdFile = '';
        
        % filepath of log file
        sLogFile = '';
        
        % filepath of config source file
        sConfigSourceFile = '';
        
        % filepath of sMP structure file
        sSmpFile = '';
        
        % filepath of setup structure list file
        sSetupListFile = '';
        
        % filepath of DIVe ONE com data file
        sDiveOneComDataFile = '';
        
    end % dependent properties
    
    % =====================================================================
    % DEPENDENT GET METHODS:
    % =====================================================================
    
    methods % DEPENDENT
        
        function sDiveConfigName = get.sDiveConfigName(obj)
            [~,sDiveConfigName] = fileparts(obj.sDiveConfigXmlFile);
        end
        
        % =================================================================
        % DIVe workspace paths:
        % =================================================================
        
        function sContentFolder = get.sContentFolder(obj)
            sContentFolder = fullfile(obj.sWorkspaceFolder,'Content');
            obj.checkFolder(sContentFolder);
            obj.checkHasFolders(sContentFolder);
        end
        
        % =================================================================
        
        function sFunctionFolder = get.sFunctionFolder(obj)
            sFunctionFolder = fullfile(obj.sWorkspaceFolder,'Function');
            obj.checkFolder(sFunctionFolder);
            obj.checkHasFolders(sFunctionFolder);
        end
        
        % =================================================================
        
        function sUtilitiesFolder = get.sUtilitiesFolder(obj)
            sUtilitiesFolder = fullfile(obj.sWorkspaceFolder,'Utilities');
            obj.checkFolder(sUtilitiesFolder);
            obj.checkHasFolders(sUtilitiesFolder);
        end
        
        % =================================================================
        
        function sSilverSupportFolder = get.sSilverSupportFolder(obj)
            sSilverSupportFolder = fullfile(obj.sUtilitiesFolder,...
                'CB\SilverSupport');
            obj.checkFolder(sSilverSupportFolder);
        end
        
        % =================================================================
        
        function sPyScriptFolder = get.sPyScriptFolder(obj)
            sPyScriptFolder = fullfile(obj.sUtilitiesFolder,...
                'CB\Transformation\Coding\pyInterface');
            obj.checkFolder(sPyScriptFolder);
        end
        
        % =================================================================
        % Additional transformation paths:
        % =================================================================
        
        function sPythonPosthookFile = get.sPythonPosthookFile(obj)
            sPythonPosthookFile = fullfile(obj.sUtilitiesFolder,...
                'CB\Transformation\Coding\pyInterface\pytPosthookCall.py');
            obj.checkFile(sPythonPosthookFile);
        end
        
        % =================================================================
        
        function sPythonCreateSfuFile = get.sPythonCreateSfuFile(obj)
            sPythonCreateSfuFile = fullfile(obj.sUtilitiesFolder,...
                'CB\Transformation\Coding\pyInterface\createSilverSFU.py');
            obj.checkFile(sPythonCreateSfuFile);
        end
        
        % =================================================================
        
        function sSfuTemplateVersionFile = get.sSfuTemplateVersionFile(obj)
            sSfuTemplateVersionFile = fullfile(obj.sSilverTemplateMainFolder,...
                'TEMPLATE_VERSION.txt');
            obj.checkFile(sSfuTemplateVersionFile);
        end
        
        % =================================================================
        
        function sSilverTemplateMainFolder = get.sSilverTemplateMainFolder(obj)
            sSilverTemplateMainFolder = fullfile(obj.sUtilitiesFolder,...
                'CB\Transformation\Coding\data\SFU_Templates');
            obj.checkFolder(sSilverTemplateMainFolder);
        end
        
        % =================================================================
        
        function sSilverTemplateMasterFolder = get.sSilverTemplateMasterFolder(obj)
            sSilverTemplateMasterFolder = fullfile(obj.sSilverTemplateMainFolder,...
                'Master');
            obj.checkFolder(sSilverTemplateMasterFolder);
        end
        
        % =================================================================
        
        function sSilverTemplateSfuFolder = get.sSilverTemplateSfuFolder(obj)
            sSilverTemplateSfuFolder = fullfile(obj.sSilverTemplateMainFolder,...
                'SFUs');
            obj.checkFolder(sSilverTemplateSfuFolder);
        end
        
        % =================================================================
        
        function sSilverTemplateConfigParamFolder = get.sSilverTemplateConfigParamFolder(obj)
            sSilverTemplateConfigParamFolder = fullfile(obj.sSilverTemplateSfuFolder,...
                'configParams');
            obj.checkFolder(sSilverTemplateConfigParamFolder);
        end
        
        % =================================================================
        % Environment paths:
        % =================================================================
                
        function sSilverHome = get.sSilverHome(obj)
            
            % check environment variable
            sSilverHome = fullfile(getenv('SILVER_HOME'));
            if isempty(strtrim(sSilverHome))
                error('Environment variable "SILVER_HOME" does not exist or is empty.');
            end
            
            % check folder
            obj.checkAbsPath(sSilverHome);
            obj.checkFolder(sSilverHome);
            obj.checkHasFolders(sSilverHome);
            
        end
        
        % =================================================================
        
        function sPythonExe = get.sPythonExe(obj)
            sPythonExe = fullfile(obj.sSilverHome,...
                'common\ext-tools\python3\python.exe');
            obj.checkFile(sPythonExe);
        end
        
        % =================================================================
        
        function sMatlabExe = get.sMatlabExe(obj)
            sMatlabExe = fullfile(matlabroot,'bin','matlab.exe');
            obj.checkFile(sMatlabExe);
        end
        
        % =================================================================
        
        function cCbtMatlabPaths = get.cCbtMatlabPaths(obj)
            
            % init list
            cCbtMatlabPaths = {};
            
            % set paths
            cCbtMatlabPaths = [cCbtMatlabPaths;...
                fullfile(obj.sWorkspaceFolder,...
                'Function')];
            cCbtMatlabPaths = [cCbtMatlabPaths;...
                fullfile(obj.sWorkspaceFolder,...
                'Utilities\CB\Transformation\Coding\classes')];
            cCbtMatlabPaths = [cCbtMatlabPaths;...
                fullfile(obj.sWorkspaceFolder,...
                'Utilities\CB\Transformation\Coding\functions')];
            
            % check paths
            for nPath=numel(cCbtMatlabPaths)
                obj.checkFolder(cCbtMatlabPaths{nPath});
            end
            
        end
        
        % =================================================================
        
        function sCbtMatlabAddPathString = get.sCbtMatlabAddPathString(obj)
            sCbtMatlabAddPathString = '';
            for nPath=1:numel(obj.cCbtMatlabPaths)
                sCbtMatlabAddPathString = [sCbtMatlabAddPathString,...
                    genpath(obj.cCbtMatlabPaths{nPath})]; %#ok<AGROW>
            end
        end
        
        % =================================================================
        % Silver setup folders:
        % =================================================================
        
        function sMasterFolder = get.sMasterFolder(obj)
            sMasterFolder = fullfile(obj.sSilMainFolder,'Master');
            fleCreateFolder(sMasterFolder);
        end
        
        % =================================================================
        
        function sRbuFolder = get.sRbuFolder(obj)
            sRbuFolder = fullfile(obj.sMasterFolder,'rbu');
            fleCreateFolder(sRbuFolder);
        end
        
        % =================================================================
        
        function sLogFolder = get.sLogFolder(obj)
            sLogFolder = fullfile(obj.sSilMainFolder,'logs');
            fleCreateFolder(sLogFolder);
        end
        
        % =================================================================
        
        function sSfuFolder = get.sSfuFolder(obj)
            sSfuFolder = fullfile(obj.sSilMainFolder,'SFUs');
            fleCreateFolder(sSfuFolder);
        end
        
        % =================================================================
        
        function sConfigParamFolder = get.sConfigParamFolder(obj)
            sConfigParamFolder = fullfile(obj.sSfuFolder,'configParams');
            fleCreateFolder(sConfigParamFolder);
        end
        
        % =================================================================
        
        function sInitParamFolder = get.sInitParamFolder(obj)
            sInitParamFolder = fullfile(obj.sSfuFolder,'initParams');
            fleCreateFolder(sInitParamFolder);
        end
        
        % =================================================================
        
        function sResultFromMaster = get.sResultFromMaster(obj)
            sResultFromMaster = fleRelativePathGet(obj.sMasterFolder,...
                obj.sResultFolder);
        end
        
        % =================================================================
        
        function sContentFromMaster = get.sContentFromMaster(obj)
            sContentFromMaster = fleRelativePathGet(obj.sMasterFolder,...
                obj.sContentFolder);
        end
        
        % =================================================================
        
        function sSilverSupportFromMaster = get.sSilverSupportFromMaster(obj)
            sSilverSupportFromMaster = fleRelativePathGet(obj.sMasterFolder,...
                obj.sSilverSupportFolder);
        end
        
        % =================================================================
        
        function sResultFromMain = get.sResultFromMain(obj)
            sResultFromMain = fleRelativePathGet(obj.sSilMainFolder,...
                obj.sResultFolder);
        end
        
        % =================================================================
        
        function sSfuFolderFromMain = get.sSfuFolderFromMain(obj)
            sSfuFolderFromMain = fleRelativePathGet(obj.sSilMainFolder,...
                obj.sSfuFolder);
        end
        
        % =================================================================
        
        function sConfigParamFromMaster = get.sConfigParamFromMaster(obj)
            sConfigParamFromMaster = fleRelativePathGet(obj.sMasterFolder,...
                obj.sConfigParamFolder);
        end
        
        % =================================================================
        
        function sInitParamFromMain = get.sInitParamFromMain(obj)
            sInitParamFromMain = fleRelativePathGet(obj.sSilMainFolder,...
                obj.sInitParamFolder);
        end

        % =================================================================
        % Silver setup file paths:
        % =================================================================
        
        function sMainSilFile = get.sMainSilFile(obj)
            sMainSilFile = fullfile(obj.sSilMainFolder,...
                [obj.sSilverSetupName,obj.sStdSilverSfuExt]);
        end
        
        % =================================================================
        
        function sSilConfigXmlFile = get.sSilConfigXmlFile(obj)
            [~,sConfigName,sConfigExt] = fileparts(obj.sDiveConfigXmlFile);
            sSilConfigXmlFile = fullfile(obj.sSilMainFolder,[sConfigName,sConfigExt]);
        end
        
        % =================================================================
        
        function sCreateSilFile = get.sCreateSilFile(obj)
            sCreateSilFile = fullfile(obj.sSilMainFolder,'createSil.bat');
        end
        
        % =================================================================
        
        function sRunSilFile = get.sRunSilFile(obj)
            sRunSilFile = fullfile(obj.sSilMainFolder,'runSilSim.bat');
        end
        
        % =================================================================
        
        function sDebugCmdFile = get.sDebugCmdFile(obj)
            sDebugCmdFile = fullfile(obj.sSilMainFolder,'debugRestart.m');
        end
        
        % =================================================================
        
        function sLogFile = get.sLogFile(obj)
            sLogFile = fullfile(obj.sLogFolder,'CB_transformation_Matlab.log');
        end
        
        % =================================================================
        
        function sConfigSourceFile = get.sConfigSourceFile(obj)
            sConfigSourceFile = fullfile(obj.sResultFolder,'ConfigurationSource.txt');
        end
        
        % =================================================================
        
        function sSmpFile = get.sSmpFile(obj)
            sSmpFile = fullfile(obj.sMasterFolder,'sMP.mat');
        end
        
        % =================================================================
        
        function sSetupListFile = get.sSetupListFile(obj)
            sSetupListFile = fullfile(obj.sMasterFolder,'SetupList.mat');
        end
        
        % =================================================================
        
        function sDiveOneComDataFile = get.sDiveOneComDataFile(obj)
            sDiveOneComDataFile = fullfile(obj.sMasterFolder,'diveOneComData.txt');
        end
        
    end % dependent methods
    
    % =====================================================================
    % PUBLIC METHODS:
    % =====================================================================
    
    methods
        
        function obj = cbtClassTrafoCONST(sWorkspaceFolder,sDiveConfigXmlFile,bShortName,sResultFolderpath)
            
            % check input arguments
            if nargin < 4
                sResultFolderpath = '';
            else
                sResultFolderpath = fullfile(char(sResultFolderpath));
            end
            
            % assign input arguments
            obj.sDiveConfigXmlFile = fullfile(char(sDiveConfigXmlFile));
            obj.bShortName = logical(bShortName);
            
            % check config xml file
            obj.checkFile(obj.sDiveConfigXmlFile);
            
            % get basic paths
            obj.getBasicPaths(sWorkspaceFolder,sResultFolderpath);
            
            % -------------------------------------------------------------
            
            % run dependent properties
            evalc('obj');
            pause(0.1);
            
        end % (constructor)
        
        % =================================================================
        % PUBLIC GET METHODS:
        % =================================================================
        
        function sMainSilFilename = getMainSilFilename(obj)
            [~,sName,sExt] = fileparts(obj.sMainSilFile);
            sMainSilFilename = [sName,sExt];
        end % getMainSilFilename
        
    end % public methods
    
    % =====================================================================
    % PRIVATE METHODS:
    % =====================================================================
    
    methods (Access = private)
        
        function getBasicPaths(obj,sWorkspaceFolder,sResultFolderpath)
            
            if isempty(sResultFolderpath)
                
                % check and assign given workspace folder
                obj.checkWorkspaceFolder(sWorkspaceFolder);
                
                % create SiLs folder
                obj.sSilsFolder = fullfile(obj.sWorkspaceFolder,...
                    obj.sStdSilFolderName);
                if ~chkFolderExists(obj.sSilsFolder)
                    fleCreateFolder(obj.sSilsFolder);
                end
                
                % get Silver setup name
                obj.getSilverSetupName;
                
                % create main folder
                obj.sSilMainFolder = fullfile(obj.sSilsFolder,...
                    obj.sSilverSetupName);
                fleCreateFolder(obj.sSilMainFolder);
                
                % create result folder
                obj.sResultFolder = fullfile(obj.sSilMainFolder,...
                    obj.sStdResultFolderName);
                fleCreateFolder(obj.sResultFolder);
                
            else
                
                % check results folder
                obj.checkAbsPath(sResultFolderpath);
                [~,sResultFolderName] = fileparts(sResultFolderpath);
                if not(strcmp(sResultFolderName,obj.sStdResultFolderName))
                    error('Name of resuls folder must be "%s" but it is "%s".',...
                        obj.sStdResultFolderName,sResultFolderName);
                end
                obj.sResultFolder = sResultFolderpath;
                
                % check and assign main folder
                obj.sSilMainFolder = fileparts(obj.sResultFolder);
                if strcmp(obj.sSilMainFolder,obj.sResultFolder)
                    error('Given results folder "%s" contains to less folder levels.',...
                        sResultFolderpath);
                end
                
                % check and assign Silver setup name
                [~,obj.sSilverSetupName] = fileparts(obj.sSilMainFolder);
                if isempty(obj.sSilverSetupName)
                    error('Given results folder "%s" contains to less folder levels.',...
                        sResultFolderpath);
                end
                
                % check and assign SiLs folder
                obj.sSilsFolder = fileparts(obj.sSilMainFolder);
                if strcmp(obj.sSilsFolder,obj.sSilMainFolder)
                    error('Given results folder "%s" contains to less folder levels.',...
                        sResultFolderpath);
                end
                
                % check sil folder name
                [~,sSilFolderName] = fileparts(obj.sSilsFolder);
                if not(strcmp(sSilFolderName,obj.sStdSilFolderName))
                    error('Name of SiLs folder must be "%s" but it is "%s".',...
                        obj.sStdSilFolderName,sSilFolderName);
                end
                
                % check and assign workspace folder
                sWorkspaceFolder = fileparts(obj.sSilsFolder);
                if strcmp(sWorkspaceFolder,obj.sSilsFolder)
                    error('Given results folder "%s" contains to less folder levels.',...
                        sResultFolderpath);
                end
                obj.checkWorkspaceFolder(sWorkspaceFolder);
                
                % delete older versions of main folder
                if chkFolderExists(obj.sSilMainFolder)
                    [~] = rmdir(obj.sSilMainFolder,'s');
                    pause(0.5);
                end
                
                % create result folder and all higher level folders
                fleCreateFolder(obj.sResultFolder);
                
            end 
            
        end % getBasicPaths
        
        % =================================================================
        
        function checkWorkspaceFolder(obj,sWorkspaceFolder)
            
            % convert folder variable
            sWorkspaceFolder = fullfile(char(sWorkspaceFolder));
            
            % check folder
            obj.checkAbsPath(sWorkspaceFolder);
            obj.checkFolder(sWorkspaceFolder);
            obj.checkHasFolders(sWorkspaceFolder);
            
            % assign folder
            obj.sWorkspaceFolder = sWorkspaceFolder;
            
        end % checkWorkspaceFolder
        
        % =================================================================
        
    	function getSilverSetupName(obj)
            
            % create final sil name
            if ~obj.bShortName
                
                % init flag
                bNewNameFound = false;
                
                % init number of tries
                nNumberOfTries = 0;
                
                % try to get name with date and time
                while not(bNewNameFound)
                    
                    % get possible date combined name
                    sNewSetupName = obj.getSilNameByDate(obj.sDiveConfigName);
                    
                    % use name if not already exist
                    if ~chkFolderExists(fullfile(obj.sSilsFolder,sNewSetupName))
                        bNewNameFound = true;
                    else
                        % wait time to end process of other instance
                        pause(1.1 + randi([0,9])*10^-1);
                    end
                    
                    % raise number of tries
                    nNumberOfTries = nNumberOfTries + 1;
                    
                    % check number of tries
                    if nNumberOfTries > 20
                        error('Cannot create Silver setup name. More than 20 tries.');
                    end
                    
                end
                
            else
                % create short name from config name
                sNewSetupName = obj.sDiveConfigName;
                
                % delete older version of setup
                if chkFolderExists(fullfile(obj.sSilsFolder,sNewSetupName))
                    rmdir(fullfile(obj.sSilsFolder,sNewSetupName),'s');
                    pause(0.5);
                end
            end
            
            % assign values
            obj.sSilverSetupName = sNewSetupName;
            
        end % getSilverSetupName
        
    end % private methods
    
    % =====================================================================
    % PRIVATE STATIC METHODS:
    % =====================================================================
    
    methods (Static, Access = private)
        
        function checkAbsPath(sPath)
            % check if is fullpath
            if ~fleIsAbsPath(sPath)
                error('Path "%s" must be absolute.',sPath);
            end
        end % checkAbsPath
        
        % =================================================================
        
        function checkFile(sFile)
            % check file exists
            if ~chkFileExists(sFile)
                error('File "%s" does not exist.',sFile);
            end
        end % checkFile
        
        % =================================================================
        
        function checkFolder(sFolder)
            % check folder exists
            if ~chkFolderExists(sFolder)
                error('Folder "%s" does not exist.',sFolder);
            end
        end % checkFolder
        
        % =================================================================
        
        function checkHasFolders(sFolder)
            % check folder contains folders
            if isempty(fleFoldersGet(sFolder))
                error('Folder "%s" must contain folders.',sFolder);
            end
        end % checkHasFolders
        
        % =================================================================
        
        function sSilName = getSilNameByDate(sConfigName)
            
            % get date string and user
            sDateString = datestr(now,'yymmdd_HHMMSS');
            sUserName = lower(getenvOwn('username'));
            
            % create combined name
            sSilName = sprintf('%s_%s_%s',sDateString,sConfigName,sUserName);
            
        end % getSilNameByDate
        
    end % private static methods
    
end % cbtClassTrafoCONST
