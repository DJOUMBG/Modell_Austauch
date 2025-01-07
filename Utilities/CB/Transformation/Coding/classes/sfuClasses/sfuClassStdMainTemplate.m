classdef sfuClassStdMainTemplate < cbtClassSilverSfu
    
	properties (Access = private)
        
        % config parameters must be confirmed with:
        oThisSfuParam = parClassStdMainTemplate.empty;
        
    end % private properties
    
    % =====================================================================
    
    methods
        
        function obj = sfuClassStdMainTemplate(oCONST,oMP)
            
            % create from super class
            obj@cbtClassSilverSfu(oCONST,oMP,'SFU_TEMPLATE');    % DO NOT CHANGE! DUE TO POSTHOOKS
            obj.oThisSfuParam = parClassStdMainTemplate(oCONST);
            obj.assignSfuParameter(nan,obj.oThisSfuParam);
            
        end % sfuClassStdMainTemplate
        
        % =================================================================
        
        function thisCreateSfuFiles(obj)
            
            % DEFAULT create actions
            obj.createSfuFiles;
            
            % -------------------------------------------------------------
            % INDIVIDUAL create actions
            
            % filepath of SFU sil file
            sSfuSilFilepath = fullfile(obj.CONST.sSfuFolder,...
                obj.sSfuSilFile);
            
            % create xml object
            oXml = xmlClassModifier(sSfuSilFilepath);
            
            % get complex key from Silver versions
            if oXml.isComplex('modules')
                sComplexKey = 'modules';
            else
                sComplexKey = '';
            end
            
            % replace modules complex
            if ~isempty(sComplexKey)
                oXml.setComplex('modules',{''});
            else
                fprintf(2,'sfu: WARNING: No complex for modules was found in SFU "%s".\n',...
                    sSfuSilFilepath);
            end
            
            % write modified sil file
            oXml.writeFile(sSfuSilFilepath);
            
        end % thisCreateSfuFiles
        
    end % methods
    
    % =====================================================================
    
    methods (Access = private)
        
    end % private methods
    
end