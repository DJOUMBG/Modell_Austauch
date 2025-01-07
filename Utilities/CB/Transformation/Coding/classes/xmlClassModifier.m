classdef xmlClassModifier < handle
   
    properties
        
        % xml file text content
        sXmlTxt = '';
        
        % xml file path
        sXmlFilepath = '';
        
    end % properties
    
    % =====================================================================
    
    properties (Constant, Access = private)
        
        % key characters for complexes
        sNameStart = '<';
        sNameEnd = '>';
        sCloseString = '/';
        
        % replace string for values in complexes
        sValReplaceString = '$$$%%%$$$';
        
    end % constant private properties
    
    % =====================================================================
    
    methods 
        
        function obj = xmlClassModifier(sXmlFile,bIsXmlTxt)
            
            % variable input arguments
            if nargin < 2
                bIsXmlTxt = false;
            end
            
            % check file path
            if ~bIsXmlTxt
                if ~chkFileExists(sXmlFile)
                    error('File "%s" does not exist.',sXmlFile);
                end
            end
            
            % assign xml filepath
            if ~bIsXmlTxt
                obj.sXmlFilepath = sXmlFile;
            else
                obj.sXmlFilepath = '';
            end
            
            % read file content
            if ~bIsXmlTxt
                obj.sXmlTxt = fleFileRead(obj.sXmlFilepath);
            else
                obj.sXmlTxt = sXmlFile;
            end
            
        end % xmlClassModifier
        
        % =================================================================
        
        function bValid = isComplex(obj,sComplex)
            
            % get content from complex
            cComplexBlueprint = obj.splitUpXmlComplex(sComplex);
            
            % check if any value exists
            if isempty(cComplexBlueprint)
                bValid = false;
            else
                bValid = true;
            end
            
        end % isComplex
        
        % =================================================================
        
        function cValue = getComplex(obj,sComplex)
            
            % get values from complexes
            [~,cValue] = obj.splitUpXmlComplex(sComplex);
            
        end % getComplex
        
        % =================================================================
        
        function setComplex(obj,sComplex,cNewValue)
            
            % split complex data
            [cComplexBlueprint,cComplexValue,cOtherContent] = ...
                obj.splitUpXmlComplex(sComplex);
            
            % check number of values
            if numel(cNewValue) > size(cComplexValue,1)
                error('More replace values was given than values in xml exists for complex "%s".',...
                    sComplex);
            end
            
            % replace with new values
            obj.sXmlTxt = obj.setNewValues(cComplexBlueprint,cComplexValue,...
                cNewValue,cOtherContent);
            
        end % setComplex
        
        % =================================================================
        
        function deleteComplex(obj,sComplex,nDelNumberList)
            
            % split complex data
            [cComplexBlueprint,cComplexValue,cOtherContent] = ...
                obj.splitUpXmlComplex(sComplex);
            
            % delete all complexes if no number is given
            if nargin < 3
                nDelNumberList = 1:1:numel(cComplexBlueprint);
            end
            
            % unique complexe sction numbers to be deleted
            nDelNumberList = unique(nDelNumberList);
            
            % check number of complexes
            if numel(cComplexBlueprint) < numel(nDelNumberList)
                error('More complex sections to be deleted was given than exist in xml for complex "%s".',...
                    sComplex);
            end
            
            % check range of delete list
            sNewXmlTxt = obj.deleteValues(cComplexBlueprint,cComplexValue,...
                nDelNumberList,cOtherContent);
            
            % delete empty lines
            obj.sXmlTxt = strDeleteEmptyLines(sNewXmlTxt);
            
        end % deleteComplex
        
        % =================================================================
        
        function writeFile(obj,sNewXmlFilepath)
            
            % check input arguments
            if nargin < 2
                
                % check whether a xml file path was given
                if isempty(obj.sXmlFilepath)
                    error('No xml filepath was given for original xml file.');
                end
                
                % new name is original name
                sNewXmlFilepath = obj.sXmlFilepath;
            end
            
            % write xml file
            fleFileWrite(sNewXmlFilepath,obj.sXmlTxt,'w');
            
        end % writeFile
        
    end % methods
    
    % =====================================================================
    
    methods (Access = private)
        
        function [cComplexBlueprint,cComplexValue,cOtherContent] = splitUpXmlComplex(obj,sComplex)
            
            % init output
            cComplexBlueprint = {};
            cComplexValue = {};
            
            % standard error message
            sErrorMsg = sprintf('Wrong definition of start and end section of complex "%s".',...
                sComplex);
            
            % create complex key strings
            sStartKey = obj.getStartString(sComplex);
            sEndKey = obj.getEndString(sComplex);
            
            % split xml content by given complex
            [cSplits,cKeys] = strsplit(obj.sXmlTxt,{sStartKey,sEndKey},...
                'CollapseDelimiters',false);
            
            % return if complex not exists
            if numel(cSplits) < 2
                cOtherContent = cSplits;
                return;
            end
            
            % -------------------------------------------------------------
            
            % check if number of elements is even
            if mod(numel(cKeys),2)
                error(sErrorMsg); %#ok<*SPERR>
            end
            
            % split into start and end complex key
            cKeys = reshape(cKeys,2,numel(cKeys)/2)';
            cStartKeys = cKeys(:,1);
            cEndKeys = cKeys(:,2);
            
            % check if each key is correct defined
            if ~prod(strcmp(cStartKeys,sStartKey))
                error(sErrorMsg);
            end
            if ~prod(strcmp(cEndKeys,sEndKey))
                error(sErrorMsg);
            end
            
            % -------------------------------------------------------------
            
            % split begin cell
            cBegin = cSplits(1);
            cValues = cSplits(2:end);
            
            % check if values and other content is even
            if mod(numel(cValues),2)
                error(sErrorMsg); %#ok<*SPERR>
            end
            
            % split complex values from other content
            cKeys = reshape(cValues,2,numel(cValues)/2)';
            cComplexValue = cKeys(:,1);
            cOtherContent = [cBegin;cKeys(:,2)];
            
            % init complex content array
            cComplexBlueprint = cComplexValue;
            
            % concatenate full content of complex with keys and values
            for nCplx=1:numel(cComplexValue)
                cComplexBlueprint{nCplx} = sprintf('%s%s%s',...
                    sStartKey,obj.sValReplaceString,sEndKey);
            end
            
        end % splitUpXmlComplex
        
        % =================================================================
        
        function sNewXmlTxt = setNewValues(obj,cComplexBlueprint,cOldValue,cNewValue,cOtherContent)
            
            % init final complex content
            cComplexContent = cComplexBlueprint;
            
            % replace in bluepints with new values and set the left old
            % values
            for nVal=1:numel(cComplexBlueprint)
                
                % check for new values
                if nVal <= numel(cNewValue)
                    sComplexContent = strrep(cComplexBlueprint{nVal},...
                        obj.sValReplaceString,cNewValue{nVal});
                else
                    sComplexContent = strrep(cComplexBlueprint{nVal},...
                        obj.sValReplaceString,cOldValue{nVal});
                end
                
                % assing replaces complex value
                cComplexContent(nVal) = {sComplexContent};
                
            end
            
            % combine new values to new xml text
            sNewXmlTxt = obj.combineComplexData(cComplexContent,cOtherContent);
            
        end % setNewValues
        
        % =================================================================
        
        function sNewXmlTxt = deleteValues(obj,cComplexBlueprint,cComplexValue,nDelNumberList,cOtherContent)
            
            % init complex content list
            cComplexContent = cComplexBlueprint;
            
            % delete specified complex section number
            for nNum=1:numel(cComplexBlueprint)
                
                % check for deletion
                if ismember(nNum,nDelNumberList)
                    sComplexContent = '';
                else
                    sComplexContent = strrep(cComplexBlueprint{nNum},...
                        obj.sValReplaceString,cComplexValue{nNum});
                end
                
                % assign value
                cComplexContent(nNum) = {sComplexContent};
                
            end
            
            % combine new values to new xml text
            sNewXmlTxt = obj.combineComplexData(cComplexContent,cOtherContent);
            
        end % deleteValues
        
        % =================================================================
        % =================================================================
        
        function sStartString = getStartString(obj,sComplex)
            sStartString = sprintf('%s%s%s',...
                obj.sNameStart,sComplex,obj.sNameEnd);
        end % getStartString
        
        % =================================================================
        
        function sEndString = getEndString(obj,sComplex)
            sEndString = sprintf('%s%s%s%s',...
                obj.sNameStart,obj.sCloseString,sComplex,obj.sNameEnd);
        end % getStartString
        
    end % private methods
    
    % =====================================================================
    
    methods (Static, Access = private)
        
        function sXmlTxt = combineComplexData(cComplexContent,cOtherContent)
            
            % init final list
            cXmlTxtLines = cOtherContent(1);
            
            % reduce other list
            cOtherContent = cOtherContent(2:end);
            
            % combine odd and even lines from lists
            for nLine=1:numel(cComplexContent)
                cXmlTxtLines = [cXmlTxtLines;...
                    cComplexContent(nLine);cOtherContent(nLine)]; %#ok<AGROW>
            end
            
            % join list to text
            sXmlTxt = strjoin(cXmlTxtLines,'');
            
        end % combineComplexData
        
    end % static private methods
    
end