function docNode = struct2dom(structVariable, rootName)
% convert the matlab structure to a DOM node
%
% DESCRIPTION:
% This function converts the input "structVariable" to a Document Object 
% Model (DOM) node. The name of the root of the DOM node is given by the
% input "rootName". DOM node can save as an xml file by using the matlab
% built-in function xmlwrite.
%
% INPUT:
%     structVariable: matlab structure
%     rootName      : the name of the root of the output DOM "docNode"
%
% OUTPUT:
%     docNode: DOM node as the result of the conversion of "structVariable"
%

docNode = com.mathworks.xml.XMLUtils.createDocument(rootName);
docRootNode = docNode.getDocumentElement;
appendChildNodeRecursive(docRootNode, structVariable);

% =========================================================================
function appendChildNodeRecursive(currentElement, currentStruct)
% append the fields of "currentStruct" as children of "currentElement"
%
% DESCRIPTION:
% This function appends the fields of the input "currentStruct" to the DOM
% node "currentElement". This function calls itself (recursive) if the
% "currentStruct" has one or more fields.
%
% INPUT:
%     currentElement: DOM node at the current iteration. Note that DOM node
%                     is a java object it is passed by reference. Any
%                     changing in this function will affect its value in
%                     the caller function. Thus, we can say that this input
%                     is also an output of this function.
%     currentSruct:   matlab structure whose fields are appended to
%                     "currentElement"
% OUTPUT:
%    currentElement:  it is passed by reference (see input)
%

if isstruct(currentStruct)
    % "currentStruct" is a matlab structure. Add its fields as children of
    % "currentElement"
    fieldNames = fieldnames(currentStruct);
    for fieldIndex = 1:length(fieldNames)
        newChild = currentElement.getOwnerDocument.createElement(fieldNames{fieldIndex});
        currentElement.appendChild(newChild);
        appendChildNodeRecursive(newChild, currentStruct.(fieldNames{fieldIndex}));
    end
else
    % "currentStruct" is not a matlab structre, stop the recursion
    if ischar(currentStruct)
        currentElement.setTextContent(currentStruct);
    end
    return
end