function xSortedStruct = sortStructByField(xStruct,sField,bAscend,bNum2Str)

%% check input arguments

if nargin < 4
    bNum2Str = false;
end

if nargin < 3
    bAscend = true;
end

% return if structure is not to be sorted
if numel(xStruct) <= 1
    xSortedStruct = xStruct;
    return;
end

% check if field exists
if ~isfield(xStruct,sField)
    error('sortStructureByFieldValues:NoField',...
        'Structure has no field with name "%s".',...
        sField);
end

% check if sort field is from same type
value = xStruct(1).(sField);
sType = class(value);
for nNum=1:numel(xStruct)
    if ~isa(xStruct(nNum).(sField),sType)
        error('sortStructureByFieldValues:WrongTypes',...
            'Field values of "%s" in structure are from different data types.',...
            sField);
    end
end

% check if field has valid data type for beeing sorted
if ~isnumeric(value) && ~ischar(value)
    error('sortStructureByFieldValues:WrongTypes',...
            'Field values of "%s" in structure are from data type "%s" and can not be sorted.',...
            sField,sType);
end


%% sort structure

% get all field values (rows: struct elements, columns: fieldnames)
[cStructTable,cFieldNames] = getStructAsTable(xStruct);

% number of column with field
nColumn = getColumnNumber(cFieldNames,sField);

% get sort reference column
cSortRefColumn = cStructTable(:,nColumn);

% sort alphabetic if strings
if ischar(value)
    % convert elements from string to double to sort numeric
    if bNum2Str
        SortRefColumn = str2double(cSortRefColumn);
    else
        SortRefColumn = lower(cSortRefColumn);
    end
else
    SortRefColumn = cell2mat(cSortRefColumn);
end

% get sorted indices
[~,nSortOrder] = sort(SortRefColumn);

% flip indices if descending order should used
if ~bAscend
    nSortOrder = flip(nSortOrder);
end

% sort table with order
cSortStructTable = cStructTable(nSortOrder,:);

% generate sorted structure from table
xSortedStruct = cell2struct(cSortStructTable',cFieldNames);

return

% =========================================================================

function nColumn = getColumnNumber(cFieldNames,sField)

for nPos=1:numel(cFieldNames)
    if strcmp(cFieldNames{nPos},sField)
        nColumn = nPos;
        return;
    end
end

return
