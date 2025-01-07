classdef cbtEnumRunTypes < int32
    
    enumeration
        Open        (0)
        Run         (1)
        Silent      (2)
        Transform   (3)
    end
    
    % =====================================================================
    
    methods (Static)
        
        function eRunType = getType(nRunNumber)
            
            % assign enumeration
            if nRunNumber == uint32(cbtEnumRunTypes.Open)
                eRunType = cbtEnumRunTypes.Open;
            elseif nRunNumber == uint32(cbtEnumRunTypes.Run)
                eRunType = cbtEnumRunTypes.Run;
            elseif nRunNumber == uint32(cbtEnumRunTypes.Silent)
                eRunType = cbtEnumRunTypes.Silent;
            elseif nRunNumber == uint32(cbtEnumRunTypes.Transform)
                eRunType = cbtEnumRunTypes.Transform;
            else
                error('Unkown run type %d.',nRunNumber);
            end
            
        end % getType
        
    end % static methods
     
end