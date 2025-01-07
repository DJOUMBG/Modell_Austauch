function x = structInit(cField,varargin)
% STRUCTINIT create an empty structure with the fieldnames specified in a
% cell with strings.
%
% Syntax:
%   x = structInit(cField)
%   x = structInit(sField)
%   x = structInit(sField1,sField2,...)
%
% Inputs:
%   cField - cell (1xn) with strings of fieldnames or string with fieldname
%
% Outputs:
%   x - structure (empty) with specified fieldnames
%
% Example: 
%   x = structInit({'Field1','Field2'})
%   x = structInit('Field')
%   x = structInit('Field1','Field2')

% check input
if ischar(cField) 
    if nargin > 1 % list of strings
        cField = [{cField} varargin];
    else
        cField = {cField};
    end
end
% check for matrix
nSize = size(cField);
if min(nSize) > 1
    error('structInit:matrixInputDetected',...
        ['Only cell vectors are allowed as input, but the specfied cell ' ...
         'has size: ' num2str(nSize)]);
end
% check orientation
if nSize(1) > nSize(2)
    cField = cField';
end

% create cell with empty cells of field size for empty struct creation
ccEmpty = cellfun(@(x){},cell(size(cField)),'UniformOutput',false);

% reshape
cField = [cField;ccEmpty];
cField = reshape(cField,1,numel(cField));

% generate empty struct
x = struct(cField{:});
return
