classdef cbtClassSilverSfu < handle
    
    properties (SetAccess = protected, GetAccess = public)
        
        % module SFU type (if it is DIVe module SFU)
        % bIsModuleSfu = true;
        
        % species header of SFU
        sSpecies = '';
        
        % name of SFU
        sName = '';
        
        % module file extension
        sModuleFileExt = '';
        
        % setup structure of module
        xSetup = struct([]);
        
        % SFU parameter object
        oSfuParam = parSuperclassMethods.empty;
        
        % SFU template name
        sSfuTemplateName = '';
        
        % sil file of SFU
        sSfuSilFile = '';
        
        % param config file of SFU
        sParamConfigFile = '';
        
        % ini files list of SFU
        cIniFileList = {};
        
        % create number of module in final SiL
        nCreateOrderNum = [];
        
        % create string of SFU
        sCreateString = '';
        
    end % properties
    
    % =====================================================================
    
    properties (Access = protected)
        
        % transformation constant object
        CONST = cbtClassTrafoCONST.empty;
        
        % sMP structure object
        oMP = dveClassSmp.empty;
        
    end % protected properties
    
    % =====================================================================
    
    methods
        
        function obj = cbtClassSilverSfu(oCONST,oMP,sName,xSetup)
            
            % assign constant object
            obj.CONST = oCONST;
            
            % assign sMP structure object
            obj.oMP = oMP;
            
            % handle variable input
            if nargin < 4
                xSetup = struct([]);
            end
               
            % check input arguments and type of SFU
            if isempty(sName) && isempty(xSetup)        % is unknown SFU
                
                % error if empty input arguments
                error('No name was set for non module SFU.');
                
            elseif isempty(sName) && ~isempty(xSetup)   % is module SFU
                
                % assign setup for type module SFU
                obj.xSetup = xSetup;
                
                % set species for type module SFU
                obj.sSpecies = obj.xSetup.species;
                
                % set SFU name for type module SFU
                obj.sName = sprintf('SFU_%s_%s_%s_%s_%s_%s',...
                    upper(xSetup.context),...
                    upper(xSetup.species),...
                    upper(xSetup.family),...
                    upper(xSetup.type),...
                    upper(xSetup.variant),...
                    upper(xSetup.modelSet));
                
            elseif ~isempty(sName) && ~isempty(xSetup)  % is cosim SFU
                
                % assign setup for type cosim SFU
                obj.xSetup = xSetup;
                
                % set species for type cosim SFU
                obj.sSpecies = ['SFU_',obj.CONST.sCosimName];
                
                % set name for type cosim SFU
                obj.sName = upper(obj.sSpecies);
                
            else                                        % is standard SFU
                
                % assign setup for type standard SFU
                obj.xSetup = xSetup;
                
                % set species for type standard SFU
                obj.sSpecies = sName;
                
                % set name for type standard SFU
                obj.sName = upper(obj.sSpecies);
                
            end
            
            % set SFU sil file name
            obj.sSfuSilFile = [obj.sName,obj.CONST.sStdSilverSfuExt];
            
            % set SFU config file name
            obj.sParamConfigFile = [obj.sName,obj.CONST.sStdSilverIniExt];
            
        end % cbtClassSilverSfu
        
        % =================================================================
        
        function assignSfuParameter(obj,nCreateOrderNum,oSfuParam,sModuleFileExt)
            
            % user info
            fprintf(1,'sfu: Create SFU "%s".\n',obj.sName);
            
            % assign parameter
            obj.nCreateOrderNum = nCreateOrderNum;
            
            if nargin > 2
                obj.oSfuParam = oSfuParam;
                obj.sSfuTemplateName = obj.oSfuParam.getSfuName;
            end
            
            if nargin > 3
                obj.sModuleFileExt = sModuleFileExt;
            end
            
        end % assignSfuParameter
        
    end % methods
    
    % =====================================================================
    
    methods (Access = protected)
        
        function createSfuFiles(obj)
            
            % create SFU parameter ini file
            obj.createSfuIniFile;
            
            % create SFU config ini file
            obj.copySfuConfigFile;
            
            % create SFU sil file
            obj.patchSfuSilFile;
            
            % set sil create string for SFU
            obj.setCreateString;
            
        end % createSfuFiles
        
        % =================================================================
        
        function sModuleFilePath = getModuleFilePath(obj)
            
            % get model file structure for given file extension
            xFile = obj.getModelFileWithExt;
            
            % check if any file was found
            if isempty(xFile)
                error('Missing %s file for species "%s" with modelSet "%s".',...
                    obj.sModuleFileExt,obj.xSetup.species,obj.xSetup.modelSet);
            end
            
            % if module file is copied to run directory use copied file, 
            % otherwise use file from DIVe Content
            if str2double(xFile.copyToRunDirectory)
                sModuleFilePath = xFile.name;
            else
                sModuleFilePath = fullfile(...
                    silGetConfigParamResolve(...
                    obj.CONST.sStdConfigParamDiveContentPath),...
                    xFile.relFilepath);
            end
            
        end % getModuleFilePath
        
        % =================================================================
        
        function xFile = getModelFileWithExt(obj)
            
            % init file structure
            xFile = struct([]);
            
            % check if main file has extension or not
            if fleCheckFileExtension(obj.xSetup.MainFile.name,obj.sModuleFileExt)
                xFile = obj.xSetup.MainFile;
            else
                
                % search in other model files for given extension
                for nFile=1:numel(obj.xSetup.ModelFile)
                    if fleCheckFileExtension(obj.xSetup.ModelFile(nFile).name,...
                            obj.sModuleFileExt)
                        xFile = obj.xSetup.ModelFile(nFile);
                        break;
                    end
                end
                
            end
            
        end % getModelFileWithExt
        
        % =================================================================
        
        function sOutRenameFile = createOutRenameFile(obj)
            
            % init output
            sOutRenameFile = '';
            
            % return if not has property
            if not(isprop(obj.oSfuParam,obj.CONST.sStdOutRenameProp))
                return;
            end
            
            % create file name
            sOutRenameName = sprintf('%s_rbu_renameOutput.txt',...
                obj.sSpecies);
            
            % create file path
            sOutRenameFilepath = fullfile(obj.CONST.sRbuFolder,...
                sOutRenameName);
            
            % write rename output file
            fleFileWrite(sOutRenameFilepath,'');
            
            % create relative path of file from master folder
            sOutRenameFile = fleRelativePathGet(obj.CONST.sMasterFolder,...
                sOutRenameFilepath);
            
        end % createOutRenameFile
        
        % =================================================================
        % SUBMETHODS:
        % =================================================================
        
        function createSfuIniFile(obj)
            
            % create header
            sTxt = sprintf('# configuration parameters for %s:\n',obj.sSpecies);
            
            % get config parameter names from parameter class
            cParamNames = obj.oSfuParam.getConfigParams;
            
            % no ini file is  needed if no parameters exists
            if isempty(cParamNames)
                return;
            end
            
            % write assginment of all parameters
            for nPar=1:numel(cParamNames)
                
                % format config parameter
                sParameterName = cParamNames{nPar};
                sParameterValue = obj.oSfuParam.(sParameterName);
                sParameterValue = strrep(sParameterValue,'\','\\');
                
                % create line for current config parameter
                sTxt = sprintf('%s%s=%s\n',sTxt,...
                    sParameterName,sParameterValue);
                
            end
            
            % ini file name
            sIniFile = [obj.sName,'.ini'];
            
            % create file path of ini file
            sIniFilePath = fullfile(obj.CONST.sInitParamFolder,sIniFile);
            
            % write ini file
            fleFileWrite(sIniFilePath,sTxt,'w');
            
            % add ini file to list
            obj.cIniFileList = [obj.cIniFileList;sIniFile]; 
            
        end % createSfuIniFile
        
        % =================================================================
        
        function copySfuConfigFile(obj)
            
            % no config file if no template exists
            if isempty(obj.sSfuTemplateName)
                return;
            end
            
            % create filename of template
            sTemplateFile = [obj.sSfuTemplateName,obj.CONST.sStdSilverIniExt];
            
            % create filepath of template
            sTemplateFilepath = fullfile(...
                obj.CONST.sSilverTemplateConfigParamFolder,sTemplateFile);
            
            % check if file exist
            if ~chkFileExists(sTemplateFilepath)
                error('No config ini template file "%s" was found.',...
                    sTemplateFile);
            end
            
            % create filepath of destination
            sParamConfigFilepath = fullfile(obj.CONST.sConfigParamFolder,...
                obj.sParamConfigFile);
            
            % copy file to final SiL location
            copyfile(sTemplateFilepath,sParamConfigFilepath);
            
        end % copySfuConfigFile
        
        % =================================================================
        
        function patchSfuSilFile(obj)
            
            % no sil file if no template exists
            if isempty(obj.sSfuTemplateName)
                return;
            end
            
            % create filename of template
            sTemplateFile = [obj.sSfuTemplateName,obj.CONST.sStdSilverSfuExt];
            
            % create filepath of template
            sTemplateFilepath = fullfile(obj.CONST.sSilverTemplateSfuFolder,...
                sTemplateFile);
            
            % check if file exist
            if ~chkFileExists(sTemplateFilepath)
                error('No SFU template file "%s" was found.',sTemplateFile);
            end
            
            % read text from SFU template file
            sSfuTxt = fleFileRead(sTemplateFilepath);
            
            % -------------------------------------------------------------
            
            % create relative filepath of config parameter file
            sConfigRelFilepath = fullfile(obj.CONST.sConfigParamFromMaster,...
                obj.sParamConfigFile);
            
            % replace config file relative path in SFU text
            sSfuTxt = strrep(sSfuTxt,obj.CONST.sConfigIniReplaceString,...
                sConfigRelFilepath);
            
            % -------------------------------------------------------------
            
            % create filepath of destination
            sSfuSilFilepath = fullfile(obj.CONST.sSfuFolder,...
                obj.sSfuSilFile);
            
            % write SFU sil file
            fleFileWrite(sSfuSilFilepath,sSfuTxt);
            
        end % patchSfuSilFile
        
        % =================================================================
        
        function setCreateString(obj)
            
            % relative path of SFU from main folder
            sSfuSilRelFilepath = fullfile(obj.CONST.sSfuFolderFromMain,...
                obj.sSfuSilFile);
            
            % init ini file lines
            sIniLines = '';
            
            % get ini file lines
            for nFile=1:numel(obj.cIniFileList)
                
                % current ini file
                sIniFile = obj.cIniFileList{nFile};
                
                % relative path of SFU ini file from main folder
                sSfuIniRelFilepath = fullfile(obj.CONST.sInitParamFromMain,...
                    sIniFile);
                
                % set ini file line
                sIniLines = sprintf('%s --sfuParams %s ^\n',...
                    sIniLines,sSfuIniRelFilepath);
                
            end
            
            % end of line check
            if isempty(sIniLines)
                sIniLines = sprintf(' ^\n');
            end
            
            % create sil create line for sfu
            obj.sCreateString = sprintf('--sfu %s%s',...
                sSfuSilRelFilepath,sIniLines);
            
        end % createSilLine
        
    end % protected methods
    
end