function xStructListRes = appendNormStructure(xStructList,xStructAppend)
% APPENDNORMSTRUCTURE appends a given structure to a list of structures by
% adapting the fields of each other and assing empty values for missing
% fields.
%
% Syntax:
%   xStructListRes = appendNormStructure(xStructList,xStructAppend)
%
% Inputs:
%   xStructList - list of structure with fields
%   xStructAppend - structure with fields
%
% Outputs:
%   xStructListRes - list of structure with fields
%
% Example: 
%   xStructListRes = appendNormStructure(xStructList,xStructAppend)
%
%
% Test:
%  A.a = 1; A.b = 2; A.c = 3; B.a = 2; B.d = 4;
%  xStructRes = appendNormStructure(A,B);
%
%  A = struct([]); B.a = 2; B.d = 4;
%  xStructRes = appendNormStructure(A,B);
%
%  A.a = 1; A.b = 2; A.c = 3; B = struct([]);
%  xStructRes = appendNormStructure(A,B);
%
%  A = struct([]); B = struct([]);
%  xStructRes = appendNormStructure(A,B);
%
%
% Subfunctions: getDataTypeListOfFields, getEmptyDataStruct
%
% See also: mergeStructures
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2023-11-07


%% premature conditions

% nothing to be appended if append structure ist empty
if isempty(xStructAppend)
    % nothing to append
    xStructListRes = xStructList;
    return;
end

% only append structure if list ist empty
if isempty(xStructList)
    xStructListRes = xStructAppend;
    return;
end


%% check field names

% field names in list
cFieldnamesList = fieldnames(xStructList);

% fields names of structure to be appended
cFieldnamesAppend = fieldnames(xStructAppend);

% get positions of missing fields in structure list
bNotInList = not(ismember(cFieldnamesAppend,cFieldnamesList));

% get missing field names in structure list
cMissingFieldsInList = cFieldnamesAppend(bNotInList);

% get data types of missing fields from append structure
cMissingFieldTypeInList = getDataTypeListOfFields(xStructAppend,cMissingFieldsInList);

% get positions of missing fields in append structure
bNotInAppend = not(ismember(cFieldnamesList,cFieldnamesAppend));

% get missing field names in append structure
cMissingFieldsInAppend = cFieldnamesList(bNotInAppend);

% get data types of missing fields from last structure list element
cMissingFieldTypeInAppend = getDataTypeListOfFields(xStructList(end),cMissingFieldsInAppend);


%% merge structures

% init new structure list
xStructListRes = struct([]);

% merge structure list
for nStruct=1:numel(xStructList)
    xEmptyDataMergeStruct = getEmptyDataStruct(cMissingFieldsInList,cMissingFieldTypeInList);
    xMergeStruct = mergeStructures(xStructList(nStruct),xEmptyDataMergeStruct);
    xStructListRes = [xStructListRes,xMergeStruct]; %#ok<AGROW>
end

% merge append structure
xEmptyDataMergeStruct = getEmptyDataStruct(cMissingFieldsInAppend,cMissingFieldTypeInAppend);
xMergeStruct = mergeStructures(xStructAppend,xEmptyDataMergeStruct);
xStructListRes = [xStructListRes,xMergeStruct];

return % appendNormStructure

% =========================================================================

function cTypeList = getDataTypeListOfFields(xStruct,cFields)

% init list
cTypeList = {};

% append data types in list
for nField=1:numel(cFields)
    cTypeList = [cTypeList;{class(xStruct.(cFields{nField}))}]; %#ok<AGROW>
end

return % getDataTypeListOfFields

% =========================================================================

function xEmptyDataStruct = getEmptyDataStruct(cFieldNames,cFieldTypes)

if ~isempty(cFieldNames)
    for nField=1:numel(cFieldNames)
        % create empty field of given type
        xEmptyDataStruct.(cFieldNames{nField}) = ...
            eval(sprintf('%s.empty',strtrim(cFieldTypes{nField})));
    end
else
    xEmptyDataStruct = struct([]);
end

return % getEmptyDataStruct
