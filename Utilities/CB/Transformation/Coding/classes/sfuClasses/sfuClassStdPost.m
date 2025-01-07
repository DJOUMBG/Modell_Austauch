classdef sfuClassStdPost < cbtClassSilverSfu
    
	properties (Access = private)
        
        % config parameters must be confirmed with:
        oThisSfuParam = parClassStdPost.empty;
        
    end % private properties
    
    % =====================================================================

    properties (Constant, Access = private)
        
        % standard file name of post script list
        sStdScriptListFileName = 'pltmPostSilver.txt';
        
    end % private constant properties
    
    % =====================================================================
    
    methods
        
        function obj = sfuClassStdPost(oCONST,oMP,cPostScripts)
            
            % create from super class
            obj@cbtClassSilverSfu(oCONST,oMP,'SFU_Post');
            obj.oThisSfuParam = parClassStdPost(oCONST);
            obj.assignSfuParameter(obj.CONST.nCreateOrderPost,...
                obj.oThisSfuParam);
            
            % -------------------------------------------------------------
            
            % assign matlab path
            obj.oSfuParam.Matlab64Exe = silGetConfigParamResolve(...
                obj.CONST.sStdConfigParamMatlabPath);
            
            % create post script list file
            obj.createPostScriptFile(cPostScripts);
            
        end % sfuClassStdPost
        
        % =================================================================

        function thisCreateSfuFiles(obj)
            
            % DEFAULT create actions
            obj.createSfuFiles;
            
            % -------------------------------------------------------------
            % INDIVIDUAL create actions
            
            
        end % thisCreateSfuFiles
        
    end % methods
    
    % =====================================================================
    
    methods (Access = private)
        
        function createPostScriptFile(obj,cPostScripts)
            
            % name of post script list file
            obj.oSfuParam.PostScriptListFile = obj.sStdScriptListFileName;
            
            % filepath of post script list file
            sPostScriptListFilepath = fullfile(obj.CONST.sMasterFolder,...
                obj.oSfuParam.PostScriptListFile);
            
            % create text string from post script list
            sPostScriptListTxt = strLinesToString(cPostScripts);
            
            % write post script list to file
            fleFileWrite(sPostScriptListFilepath,sPostScriptListTxt,'w');
            
        end % createPostScriptFile
        
    end % private methods
    
end