classdef parClassStdMainTemplate < parSuperclassMethods
    
    properties % MUST NOT BE PRIVATE AND CONSTANT !
        
        % -----------------------------------------------------------------
        % DEFINE CONFIG PARAMETER NAMES OF SFU:
        % -----------------------------------------------------------------
        
    end % properties
    
    % =====================================================================
    
    properties (Constant, Access = private) % MUST BE PRIVATE !
        
        % -----------------------------------------------------------------
        % DEFINE NAME OF SFU TEMPLATE:
        sThisSfuName = 'template_SFU_stdMainTemplate';
        % -----------------------------------------------------------------
        
    end % constant private properties
    
    % =====================================================================
    
    methods
    
        function obj = parClassStdMainTemplate(oCONST)
            
            % create SFU parameter object
            obj@parSuperclassMethods(oCONST);
            obj.setSfuName(obj.sThisSfuName);
            
            % set defined module sil lines
            obj.setModuleSilLines({});
            
        end % parClassStdMainTemplate
        
    end % methods
    
end