classdef cbtClassSfuTemplateCreation < handle
    
    properties (SetAccess = private, GetAccess = public)
        
        % sfu parameter object
        oSfuParamObject = parSuperclassMethods.empty;
        
        % sfu template sil filepath
        sSilFilepath = '';
        
        % sfu tamplte config ini filepath
        sConfigFilepath = '';
        
    end % properties
    
    % =====================================================================
    
    properties (Access = private)
        
        % transformation constant object
        CONST = cbtClassTrafoCONST.empty;
        
    end % private properties
    
    % =====================================================================
    
    methods
        
        function obj = cbtClassSfuTemplateCreation(oCONST,oSfuParamObject)
            
            % assign constant object
            obj.CONST = oCONST;
            
            % prepare and check folders for template creation
            obj.prepareTemplateFolders;
            
            % assign parameter object
            obj.oSfuParamObject = oSfuParamObject;
            
            % -------------------------------------------------------------
            
            % user info
            fprintf(1,'\tCreate SFU template "%s". Please wait ...\n',...
                obj.oSfuParamObject.getSfuName);
            
            % create sfu config ini file
            obj.createConfigIniFile;
            
            % create sfu sil file
            obj.createSfuSilFile;
            
            % user info
            fprintf(1,'\tSFU template "%s" successfully created.\n',...
                obj.oSfuParamObject.getSfuName);
            
        end % cbtClassSfuTemplateCreation
        
    end % methods
        
    % =====================================================================
    
    methods (Access = private)
        
        function prepareTemplateFolders(obj)
            
            % create template main folder
            fleCreateFolder(obj.CONST.sSilverTemplateMainFolder);
            
            % create template master folder
            fleCreateFolder(obj.CONST.sSilverTemplateMasterFolder);
            
            % create template SFU folder
            fleCreateFolder(obj.CONST.sSilverTemplateSfuFolder);
            
            % create template SFU config folder
            fleCreateFolder(obj.CONST.sSilverTemplateConfigParamFolder);
            
        end % prepareTemplateFolders
        
        % =================================================================
        
        function createConfigIniFile(obj)
            
            % get config parameter list
            cConfigParams = obj.oSfuParamObject.getConfigParams;
            
            % init file content
            sTxt = '';
            
            % run through config parameter
            for nPar=1:numel(cConfigParams)
                
                % create config file line
                sLine = sprintf('[option]\n');
                sLine = sprintf('%stype=string\n',sLine);
                sLine = sprintf('%sname=%s\n',sLine,cConfigParams{nPar});
                sLine = sprintf('%srequired=true\n\n',sLine);
                
                % append line
                sTxt = sprintf('%s%s',sTxt,sLine);
                
            end
            
            % create name of config ini file
            sConfigIniFile = [obj.oSfuParamObject.getSfuName,...
                obj.CONST.sStdSilverIniExt];
            
            % full path of config ini file
            obj.sConfigFilepath = ...
                fullfile(obj.CONST.sSilverTemplateConfigParamFolder,...
                sConfigIniFile);
            
            % write file
            fleFileWrite(obj.sConfigFilepath,sTxt,'w');
            
        end % createConfigIniFile
        
        % =================================================================
        
    	function createSfuSilFile(obj)
            
            % get config parameter list
            cConfigParList = obj.oSfuParamObject.getConfigParams;
            
            % get module sil line list
            cModuleLineList = obj.oSfuParamObject.getModuleSilLines;
            
            % create python argumnt strings
            sModuleLineListString = strjoin(cModuleLineList,...
                obj.CONST.sPyArgSeperatorString);
            sConfigParListString = strjoin(cConfigParList,...
                obj.CONST.sPyArgSeperatorString);
            
            % create rename file blueprint
            if isprop(obj.oSfuParamObject,obj.CONST.sStdOutRenameProp);
                sOutputRenameFileParam = sprintf('${%s}',...
                    obj.CONST.sStdOutRenameProp);
            else
                sOutputRenameFileParam = obj.CONST.sQuotReplaceString;
            end
            
            % create name of sfu sil file
            sSfuSilFile = [obj.oSfuParamObject.getSfuName,...
                obj.CONST.sStdSilverSfuExt];
            
            % full path of sfu sil file
            sSfuSilFilepath = fullfile(obj.CONST.sSilverTemplateSfuFolder,...
                sSfuSilFile);
            
            % argument list for Python
            cArgs = {sSfuSilFilepath;...
                obj.CONST.sSilverTemplateMasterFolder;...
                sModuleLineListString;...
                sConfigParListString;...
                sOutputRenameFileParam;...
                obj.CONST.sPyArgSeperatorString;...
                obj.CONST.sConfigIniReplaceString;...
                obj.CONST.sQuotReplaceString};
            
            % call Python to create sfu with Silver API
            bSuccess = pytCallPythonScript(obj.CONST.sPythonExe,...
                obj.CONST.sPythonCreateSfuFile,true,cArgs);
            
            % check Python call
            if ~bSuccess
                error('SFU template "%s" could not be created.',sSfuSilFile);
            end
            
        end % createSfuSilFile
        
    end % private methods
    
end