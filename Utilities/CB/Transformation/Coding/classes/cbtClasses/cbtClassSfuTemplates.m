classdef cbtClassSfuTemplates < handle
    
    properties (Access = private)
        
        % transformation constant object
        CONST = cbtClassTrafoCONST.empty;
        
    end
    
    % =====================================================================
    
    methods
        
        function obj = cbtClassSfuTemplates(oCONST)
            
            % assign constant object
            obj.CONST = oCONST;
            
            % -------------------------------------------------------------
            
            % create template main folder
            fleCreateFolder(obj.CONST.sSilverTemplateMainFolder);
            
        end % cbtClassSfuTemplates
        
        % =================================================================
        
        function createSfuTemplates(obj)
            
            % write template version file
            obj.writeVersionFile;
            
            % module SFUs
            cbtClassSfuTemplateCreation(obj.CONST,parClassCosim(obj.CONST));
            cbtClassSfuTemplateCreation(obj.CONST,parClassDll(obj.CONST));
            cbtClassSfuTemplateCreation(obj.CONST,parClassFmu(obj.CONST));
            cbtClassSfuTemplateCreation(obj.CONST,parClassFmuCs(obj.CONST));
            cbtClassSfuTemplateCreation(obj.CONST,parClassSfcn(obj.CONST));
            cbtClassSfuTemplateCreation(obj.CONST,parClassSfcnGt(obj.CONST));
            
            % standard SFUs
            cbtClassSfuTemplateCreation(obj.CONST,parClassStdLogging(obj.CONST,'mdf'));
            cbtClassSfuTemplateCreation(obj.CONST,parClassStdLogging(obj.CONST,'mat'));
            cbtClassSfuTemplateCreation(obj.CONST,parClassStdLogging(obj.CONST,'csv'));
            cbtClassSfuTemplateCreation(obj.CONST,parClassStdPost(obj.CONST));
            cbtClassSfuTemplateCreation(obj.CONST,parClassStdRangeCheck(obj.CONST));
            cbtClassSfuTemplateCreation(obj.CONST,parClassStdSupport(obj.CONST));
            
            % template SFU
            cbtClassSfuTemplateCreation(obj.CONST,parClassStdMainTemplate(obj.CONST));
            
            % clean up
            obj.cleanUpTemplateCreation;
            
        end % createSfuTemplates
        
        % =================================================================
        
        function checkTemplateVersion(obj)
            
            % get version of installed Silver
            sSilverVersion = strtrim(obj.getSilverVersionString);
            
            % get version of SFU templates
            sTemplateVersion = strtrim(obj.readVersionFile);
            
            % compare version strings
            if ~strcmp(sSilverVersion,sTemplateVersion)
                fprintf(2,['cbt: WARNING: Local Silver version "%s" differs from SFU template version "%s".\n',...
                    '\tThis can lead to errors.\n'],...
                    sSilverVersion,sTemplateVersion);
            end
            
        end % checkTemplateVersion
        
    end % methods
    
    % =====================================================================
    
    methods (Access = private)
        
        function writeVersionFile(obj)
            
            % write Silver version string to template version file
            fleFileWrite(obj.CONST.sSfuTemplateVersionFile,...
                obj.getSilverVersionString,'w');
            
        end % writeVersionFile
        
        % =================================================================
        
        function sTemplateVersion = readVersionFile(obj)
            
            % check if file exists
            if ~chkFileExists(obj.CONST.sSfuTemplateVersionFile)
                error('Template version file "%s" does not exist.',...
                    obj.CONST.sSfuTemplateVersionFile);
            end
            
            % read file
            sTxt = fleFileRead(obj.CONST.sSfuTemplateVersionFile);
            
            % return version string
            sTemplateVersion = strtrim(sTxt);
            
        end % readVersionFile
        
        % =================================================================
        
        function cleanUpTemplateCreation(obj)
            
            % delete dummy Silver setup
            try
                rmdir(obj.CONST.sSilMainFolder,'s');
            catch
                error('Can not delete dummy Silver setup "%s".',...
                    obj.CONST.sSilMainFolder);
            end
            
        end % cleanUpTemplateCreation
        
    end % private methods
    
    % =====================================================================
    
    methods (Static, Access = private)
        
        function sVersionString = getSilverVersionString
            
            % get Silver version
            [~,sSilverVersion] = silSilverInstallationCheck;
            
            % clean into version string
            cSplit = strsplit(sSilverVersion,'(');
            sVersionString = strtrim(cSplit{1});
            
        end % getSilverVersionString
        
    end % static private methods
    
end