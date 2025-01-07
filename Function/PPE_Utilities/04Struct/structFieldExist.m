function [bExist,sType] = structFieldExist(xStruct,sField)
% STRUCTEXIST checks if a deep structure field exists and returns its type
% as a string.
% MATLAB has native functions setfield and getfield to get and set value
% deep inside structure (nested structure), but no test function to check
% the existence of a deep/nested structure field. This function closes this
% gap.
%
% Syntax:
%   [bExist,sType] = structExist(xStruct,sField)
%
% Inputs:
%   xStruct - structure, deep but scalar
%    sField - string with a deep structure field description, e.g. 'a.b.c'
%             or a cell of strings containing single field names e.g. 
%             {'a','b','c'}
%
% Outputs:
%   bExist - boolean if the specified structure field tree exists in the
%            specified structure
%    sType - string with type of specified structure field:
%               numeric: 'numeric'
%               structure: 'struct'
%               cell: 'cell'
%               string: 'char'
%               handle: 'handle'
%               other: 'other'
%               not existing: 'NotExisting'
%
% Example: 
%   xStruct.a.b.c = 1;
%   [bExist,sType] = structExist(xStruct,'a.b')
%   [bExist,sType] = structExist(xStruct,'a.b.c')
%   [bExist,sType] = structExist(xStruct,{'a','b','c'})
%
% See also: strsplitOwn, setfield, getfield
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2016-07-13

% initialize output
bExist = false;
sType = 'NotExisting';

% check input
if ~isstruct(xStruct) || ...
        isempty(sField)
    return
end
if ischar(sField)
    cField = strsplitOwn(sField,'.');
elseif iscell(sField)
    cField = sField;
else
    return
end

% extract array specifiers
nCell  = str2double(regexp(cField{1},'(?<=^\w+\{)\d+(?=\})','match','once'));
nArray = str2double(regexp(cField{1},'(?<=^\w+\()\d+(?=\))','match','once'));
cField{1} = regexp(cField{1},'^\w+','match','once');

% determine field content
if numel(cField) == 1
    % check field
    bExist = isfield(xStruct,cField{1});
    % determine field type
    if bExist
        if isnumeric(xStruct.(cField{1}))
            sType = 'numeric';
        elseif isstruct(xStruct.(cField{1}))
            sType = 'struct';
        elseif iscell(xStruct.(cField{1}))
            sType = 'cell';
        elseif ischar(xStruct.(cField{1}))
            sType = 'char';
        elseif ishandle(xStruct.(cField{1}))
            sType = 'handle';
        else
            sType = 'other';
        end
    end
elseif isfield(xStruct,cField{1})
    % reccursion for deep structures
    % TODO multidimensional cells and arrays
    if ~isnan(nCell)
        [bExist,sType] = structFieldExist(xStruct.(cField{1}){nCell},cField(2:end));
    elseif ~isnan(nArray)
        [bExist,sType] = structFieldExist(xStruct.(cField{1})(nArray),cField(2:end));
    else
        [bExist,sType] = structFieldExist(xStruct.(cField{1})(1),cField(2:end));
    end
end
return
