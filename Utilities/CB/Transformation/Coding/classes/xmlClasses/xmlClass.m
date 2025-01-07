classdef xmlClass < handle
    
    properties
        
        % mirrored xml structure
        xXml = struct([]);

    end % properties
    
    % =====================================================================
    
    properties (Access = private)
        
        % xml filepath
        sXmlFilepath = '';
        
        % xml doc object
        oDocXml;
        
    end % private properties
    
    % =====================================================================
    
    properties (Constant, Access = private)
        
        % default field name of element name
        sStdElementName = 'name';
        
        % default field name of attribute structure
        sStdAttribName = 'attrib';
        
        % default field name of child number in doc object
        sStdChildNumber = 'refNum';
        
        % default field name of child structure
        sStdChildName = 'child';
        
    end % private constant properties
    
    % =====================================================================
    
    methods
        
        function obj = xmlClass(sXmlFilepath)
            
            % check input argument
            if ~chkFileExists(sXmlFilepath)
                error('Xml file "%s" does not exist.',...
                    sXmlFilepath);
            end
            
            % assing input file
            obj.sXmlFilepath = sXmlFilepath;
            
            % read xml file to doc object
            obj.oDocXml = xmlread(sXmlFilepath);
            
            % create user xml structure
            obj.xXml = obj.getElementStructure('XML DATA',...
                struct([]),0,obj.getChildStructList(obj.oDocXml));
            
        end % (constructor)
        
        % =================================================================
        
        function writeXmlFile(obj,sNewXmlFilepath)
            
            % check input argument
            if nargin < 2
                sNewXmlFilepath = obj.sXmlFilepath;
            end
            
            % modify original doc object from usered defined xml structure
            obj.setChildren(obj.oDocXml,obj.xXml);
            
            % write xml file
            xmlwrite(sNewXmlFilepath,obj.oDocXml);
            
        end
        
        % =================================================================
        
        function [nLevelNum,nChildNum] = getChildPosFromLevelNames(obj,cLevelNames)
            
            % init position lists
            nLevelNum = [];
            nChildNum = [];
            
            % init element
            xElem = obj.xXml;
            
            % levels
            for nLevel=1:numel(cLevelNames)
                
                % get name of element in level
                sChildName = cLevelNames{nLevel};
                
                % check for child elements of name
                nChildPosList = obj.getChildPosOfName(xElem,sChildName);
                
                % check for next level
                if nLevel < numel(cLevelNames)
                    if numel(nChildPosList) == 1
                        % next element level
                        nLevelNum = [nLevelNum,nChildPosList]; %#ok<AGROW>
                        xElem = xElem.(obj.sStdChildName)(nChildPosList(1));
                    elseif isempty(nChildPosList)
                        error('No child elements was found for name "%s".',...
                            sChildName);
                    else
                        error('Multiple child elements was found for name "%s".',...
                            sChildName);
                    end
                else
                    % append position list
                    nChildNum = nChildPosList;
                end
                
            end % cLevelNames
            
        end % getChildPosFromLevelNames
        
    end % methods
    
    % =====================================================================
    
    methods (Access = private)
        
        % =================================================================
        % STRUCTURES:
        % =================================================================
        
        function xElemStruct = getElementStructure(obj,sChildName,xAttribList,nRefNum,xChildList)
            xElemStruct.(obj.sStdElementName) = sChildName;
            xElemStruct.(obj.sStdAttribName) = xAttribList;
            xElemStruct.(obj.sStdChildNumber) = nRefNum;
            xElemStruct.(obj.sStdChildName) = xChildList;
        end % getElementStructure
        
        % =================================================================
        % READ:
        % =================================================================
        
        function xChildList = getChildStructList(obj,oElem)
            
            % init output
            xChildList = struct([]);
            
            % ceck for children
            if oElem.hasChildNodes
                
                % get children object list
                oChildList = oElem.getChildNodes;
                
                % get any child
                for nChild=1:oChildList.getLength
                    
                    % referenced item number in original doc object
                    nRefNum = nChild-1;
                    
                    % get single child
                    oChild = oChildList.item(nRefNum);
                    
                    % get name of child
                    sChildName = char(oChild.getNodeName);
                    
                    % set attribute and child structure
                    if obj.isAlphaNumeric(sChildName)
                        
                        % get attribute structure list
                        xThisAttribList = obj.getAttributeStruct(oChild);
                        
                        % get child structure list
                        xThisChildList = obj.getChildStructList(oChild);
                        
                        % create child structure
                        xThisChild = obj.getElementStructure(sChildName,...
                            xThisAttribList,nRefNum,xThisChildList);
                        
                        % append child structure in child list
                        xChildList = [xChildList,xThisChild]; %#ok<AGROW>
                        
                    end % isAlphaNumeric
                    
                end % oChildList
                
            end % hasChildNodes
            
        end % getChildStruct
        
        % =================================================================
        
        function xAttribStruct = getAttributeStruct(obj,oElem)
            
            % check for attributes
            if oElem.hasAttributes
                
                % get attributes object list
                oAttribList = oElem.getAttributes;
                
                % get any attribute
                for nAttrib=1:oAttribList.getLength
                    
                    % get single attribute
                    oAttrib = oAttribList.item(nAttrib-1);
                    
                    % get name and value of attribute
                    sAttribName = char(oAttrib.getName);
                    sAttribValue = char(oAttrib.getValue);
                    
                    % set new attribute field in structure
                    if obj.isAlphaNumeric(sAttribName)
                        xAttribStruct.(sAttribName) = sAttribValue;
                    end
                    
                end % oAttribList
                
            else
                xAttribStruct = struct([]);
            end
            
        end % getAttributeStruct
        
        % =================================================================
        % WRITE:
        % =================================================================
        
        function setChildren(obj,oElem,xElem)
            
            % set attributes
        	obj.setAttributes(oElem,xElem);
            
            % check for any child
            if oElem.hasChildNodes
            
            	% get children object list
                oChildList = oElem.getChildNodes;
                xChildList = xElem.(obj.sStdChildName);
                
                % get any child
                for nChild=1:numel(xChildList)
                    
                    % get child structure
                    xChild = xChildList(nChild);
                    
                    % get single child
                    oChild = oChildList.item(xChild.(obj.sStdChildNumber));
                    
                    % set children
                   	obj.setChildren(oChild,xChild);
                    
                end % oChildList
                
            end % hasChildNodes
            
        end % setChildren
        
        % =================================================================
        
        function setAttributes(obj,oElem,xElem)
            
            % check for attributes
            if oElem.hasAttributes
                
                % get attributes object list
                oAttribList = oElem.getAttributes;
                xAttribList = xElem.(obj.sStdAttribName);
                
                % get any attribute
                for nAttrib=1:oAttribList.getLength
                    
                    % get single attribute
                    oAttrib = oAttribList.item(nAttrib-1);
                    
                    % get name of attribute
                    sAttribName = char(oAttrib.getName);
                    
                    % get attribute value
                    sValue = obj.getValueFromStructure(xAttribList,sAttribName);
                    
                    % check value
                    if not(isnan(sValue))
                        oElem.setAttribute(sAttribName,sValue);
                    else
                        error('Attribute "%s" in object does not exit in structure.',...
                            sAttribName);
                    end
                    
                end % oAttribList
                
            end % hasAttributes
            
        end % setAttributes
        
        % =================================================================
        % SUBMETHODS:
        % =================================================================
        
        function sValue = getValueFromStructure(~,xAttribList,sAttribName)
            
            % init child structure
            sValue = NaN;
            
            % get attribute name list
            cAttribNameList = fieldnames(xAttribList);
            
            % check each attribute name
            for nAttrib=1:numel(cAttribNameList)
                
                % search for same attribute name
                if strcmp(cAttribNameList{nAttrib},sAttribName)
                    sValue = xAttribList.(cAttribNameList{nAttrib});
                    return;
                end
                
            end % cAttribNameList
            
        end % getChildFromStructure
        
        % =================================================================
        
        function nChildPos = getChildPosOfName(obj,xElem,sName)
            
            % init output
            nChildPos = [];
            
            % get child list of element
            xChildList = xElem.(obj.sStdChildName);
            
            % get each child of given names
            for nChild=1:numel(xElem.(obj.sStdChildName))
                
                % check equal name
                if strcmp(xChildList(nChild).(obj.sStdElementName),sName)
                    nChildPos = [nChildPos,nChild]; %#ok<AGROW>
                end
                
            end % xElem.child
            
        end % getChildElementsOfName
        
    end % private methods
    
    % =====================================================================
    
    methods (Static, Access = private)
        
        function bValid = isAlphaNumeric(sString)
            bValid = ~isempty(regexp(sString,'^\w*$','once'));
        end % isAlphaNumeric
        
    end % static private methods
    
end % xmlClass
