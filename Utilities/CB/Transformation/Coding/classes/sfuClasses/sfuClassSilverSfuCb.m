classdef sfuClassSilverSfuCb < cbtClassSilverSfu
    
	properties (Access = private)
        
        % config parameters must be confirmed with:
            % no parameter object neccessary
        
    end % private properties
    
    % =====================================================================
    
    methods
        
        function obj = sfuClassSilverSfuCb(oCONST,oMP,xSetup)
            
            % create from super class
            obj@cbtClassSilverSfu(oCONST,oMP,'',xSetup);
            obj.assignSfuParameter(str2double(obj.xSetup.initOrder));
            
        end % sfuClassSilverSfuCb
        
        % =================================================================

        function thisCreateSfuFiles(obj)
            
            % DEFAULT create actions
            % FOR NON DIVE SILVER SFU NO createSfuFiles IS NOT NEEDED !
            
            % -------------------------------------------------------------
            % INDIVIDUAL create actions
            
            % copy actions for non DIVe SFU files
            obj.handleNonDiveSfuFiles;
            
        end % thisCreateSfuFiles
        
    end % methods
    
    % =====================================================================
    
    methods (Access = private)
        
        function handleNonDiveSfuFiles(obj)
            
            % get SFU files from DataSets: sil, config, param file
            [cSilFileList,cConfigFileList,cParamFileList] = ...
                obj.getSfuFilesFromDataSets(obj.xSetup,obj.CONST.sContentFolder);
            
            % copy Silver files and get file names
            cNewSilFileList = obj.copySilverFilesToSilverEnv(cSilFileList,...
                cConfigFileList,cParamFileList);
            
            % update working directory in sil files
            for nSilFile=1:numel(cNewSilFileList)
            	obj.setWorkingDirInSilFile(cNewSilFileList{nSilFile});
            end
            
            % check for default create string
            if numel(cNewSilFileList) == 1
                % if standard non DIVe SFU
                obj.setStdCreateString(cNewSilFileList{1},cParamFileList);
            elseif numel(cNewSilFileList) > 1
                % if multiple sil sfu files without ini files (e.g. GUI)
                obj.setNonStdCreateString(cNewSilFileList);
            end
            
        end % handleNonDiveSfuFiles
        
        % =================================================================
        
        function cNewSilFileList = copySilverFilesToSilverEnv(obj,cSilFileList,cConfigFileList,cParamFileList)
            
            % copy sil files
            cNewSilFileList = {};
            for nSilFile=1:numel(cSilFileList)
                
                % get file parts of sfu sil file
                [~,sName,sExt] = fileparts(cSilFileList{nSilFile});
                
                % new filepath
                sNewSilFilepath = fullfile(obj.CONST.sSfuFolder,[sName,sExt]);
                
                % copy sfu sil file to sil environment
                copyfile(cSilFileList{nSilFile},sNewSilFilepath);
                
                % append to new sil list
                cNewSilFileList = [cNewSilFileList;{sNewSilFilepath}]; %#ok<AGROW>
                
            end % sil files
            
            % copy config files
            for nConfigFile=1:numel(cConfigFileList)
                
                % get file parts of config file
                [~,sName,sExt] = fileparts(cConfigFileList{nConfigFile});
                
                % copy config file to sil environment
                copyfile(cConfigFileList{nConfigFile},...
                    fullfile(obj.CONST.sConfigParamFolder,[sName,sExt]));
                
            end % config files
            
            % copy ini param files
            for nIniFile=1:numel(cParamFileList)
                
                % get file parts of ini param file
                [~,sName,sExt] = fileparts(cParamFileList{nIniFile});
                
                % copy ini param file to sil environment
                copyfile(cParamFileList{nIniFile},...
                    fullfile(obj.CONST.sInitParamFolder,[sName,sExt]));
                
            end % ini param files
            
        end % copySilverFilesToSilverEnv
        
        % =================================================================
        
        function setWorkingDirInSilFile(obj,sSfuSilFilepath)
            
            % relative path to master folder from SFU folder
            sRelMasterFolder = fleRelativePathGet(obj.CONST.sSfuFolder,...
                obj.CONST.sMasterFolder);
            
            % create xml object
            oXml = xmlClassModifier(sSfuSilFilepath);
            
            % get complex key from Silver versions
            if oXml.isComplex('working-dir')
                sComplexKey = 'working-dir';
            else
                sComplexKey = '';
            end
            
            % replace modules complex
            if ~isempty(sComplexKey)
                oXml.setComplex('working-dir',{sRelMasterFolder});
            else
                fprintf(2,'sfu: WARNING: No complex "working-dir" was found in SFU "%s".\n',...
                    sSfuSilFilepath);
            end
            
            % write modified sil file
            oXml.writeFile(sSfuSilFilepath);
            
        end % setWorkingDirInSilFile
        
        % =================================================================
        
        function setStdCreateString(obj,sSilFilepath,cParamFilepathList)
            
            % get sil file
            [~,sName,sExt] = fileparts(sSilFilepath);
            obj.sSfuSilFile = [sName,sExt];
            
            % get ini param files
            cIniFiles = {};
            for nFile=1:numel(cParamFilepathList)
                [~,sName,sExt] = fileparts(cParamFilepathList{nFile});
                cIniFiles = [cIniFiles;{[sName,sExt]}]; %#ok<AGROW>
            end
            obj.cIniFileList = cIniFiles;
            
            % call default method
            obj.setCreateString;
            
        end % setStdCreateString
        
        % =================================================================
        
        function setNonStdCreateString(obj,cSilFilepathList)
            
            % init create string
            sSfuLines = '';
            
            for nSilFile=1:numel(cSilFilepathList)
                
                % get fileparts from sil file
                [~,sName,sExt] = fileparts(cSilFilepathList{nSilFile});
                
                % relative path of SFU from main folder
                sSfuSilRelFilepath = fullfile(obj.CONST.sSfuFolderFromMain,...
                    [sName,sExt]);
                
                % create sfu create line
                sSfuLines = sprintf('%s--sfu %s ^\n',sSfuLines,sSfuSilRelFilepath);
                
            end
            
            % assign create string
            obj.sCreateString = sSfuLines;
            
        end % setNonStdCreateString
        
    end % private methods
    
    % =====================================================================
    
    methods (Static, Access = private)
        
        function [cSilFileList,cConfigFileList,cParamFileList] = getSfuFilesFromDataSets(xSetup,sContentFolder)
            
            % species folder
            sSpeciesFolder = fullfile(sContentFolder,xSetup.context,xSetup.species);
            
            % family folder
            sFamilyFolder = fullfile(sSpeciesFolder,xSetup.family);
            
            % type folder
            sTypeFolder = fullfile(sFamilyFolder,xSetup.type);
            
            % init file list
            cSilFileList = {};
            cConfigFileList = {};
            cParamFileList = {};
            
            % run through DataSets
            for nDatSet=1:numel(xSetup.DataSet)
                
                % DataSet parameter
                sLevel = xSetup.DataSet(nDatSet).level;
                sClassType = xSetup.DataSet(nDatSet).classType;
                sVariant = xSetup.DataSet(nDatSet).variant;
                
                % create level dependend path prefix
                switch sLevel
                    case 'species'
                        sFolderPrefix = sSpeciesFolder;
                    case 'family'
                        sFolderPrefix = sFamilyFolder;
                    case 'type'
                        sFolderPrefix = sTypeFolder;
                end
                
                % create folder path of DataSet variant folder
                sVariantFolder = fullfile(sFolderPrefix,...
                    'Data',sClassType,sVariant);
                
                % check folder path
                if ~chkFolderExists(sVariantFolder)
                   	error('DataSet variant folder "%s" does not exist to search for Silver files.',...
                        sVariantFolder);
                end
                
                % ---------------------------------------------------------
                
                % get SFU files from folder
                cCurSilFiles = fleFilesGet(sVariantFolder,{'.sil'});
                cCurSilFiles = fleFullpathCreate(sVariantFolder,cCurSilFiles);
                cCurIniFiles = fleFilesGet(sVariantFolder,{'.ini'});
                cCurIniFiles = fleFullpathCreate(sVariantFolder,cCurIniFiles);
                
                % seperate config files from param files
                if ~isempty(cCurSilFiles)
                    % append config files
                    cConfigFileList = [cConfigFileList;cCurIniFiles]; %#ok<AGROW>
                else
                    % append param files
                    cParamFileList = [cParamFileList;cCurIniFiles]; %#ok<AGROW>
                end
                
                % append sil files
                cSilFileList = [cSilFileList;cCurSilFiles]; %#ok<AGROW>
                
            end % DataSet
            
            % -------------------------------------------------------------
            
            % *** DESCRIPTION ***
            % valid cases:
            %   -> one sil file & no/several config file & no/several param files
            %   -> several sil files & no/several config file & NO param files
            %
            % warning cases:
            %   -> no sil file
            %
            % unvalid cases:
            %   -> several sil files & several param files
            
            % check unvalid combinations of non DIVe SFU files
            if isempty(cSilFileList)
                % overwrite oaram file as empty, because of no belonging sil file 
                cParamFileList = {};
                fprintf(2,'WARNING: No sil file was found as non DIVe SFU for species "%s"\n',...
                    xSetup.species);
            elseif numel(cSilFileList) > 1 && ~isempty(cParamFileList)
                error('More than one sil file and ini file was found as non DIVe SFU for species "%s"',...
                    xSetup.species);
            end
            
        end % getSfuFilesFromDataSets
        
    end % static private methods
    
end