function x = structConcat(x,xAdd) 
% STRUCTCONCAT concatenate structures to a structure vector. If fields
% are missing in one structure, they are added to the structure with
% numeric empty value. 
%
% Syntax:
%   x = structConcat(x,xAdd)
%
% Inputs:
%      x - structure with arbitrary MATLAB structure
%   xAdd - structure with arbitrary MATLAB structure
%
% Outputs:
%   x - structure containing of both source structures as vector
%
% Example: 
%   x = structConcat(struct,struct('a',{1},'b',{2})) % concat with initial struct 
%   x = structConcat(struct('a',{11},'b',{12}),struct('b',{22},'a',{21})) % resort fields 
%   x = structConcat(struct('a',{11},'b',{12}),struct('b',{22},'c',{23})) % add fields 
%   x = structConcat(struct('c',{},'d',{},'b',{}),struct('a',{1},'b',{2})) % concat with empty struct with fields 
%   x = structConcat(struct('a',{11},'b',{12}),struct('b',{22,32},'c',{23,33})) % add structure vector 
%
% See also: fieldnames, structAdd, structUpdate, structDiff, structExtract,
% structFind, structDisp, structUnify, structInit
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2015-03-04

% fast track if one structure is empty
if isempty(xAdd) || isempty(fieldnames(xAdd))
    return
elseif isempty(x) 
    % empty structure without fields
    if isempty(fieldnames(x))
        x = xAdd;
        return
    end
end
   
% check field names
cField = fieldnames(x);
cFieldAdd = fieldnames(xAdd);

% ensure same structure for concatenation
if any(~isfield(x,cFieldAdd)) || any(~isfield(xAdd,cField))
    % get missing fields
    bMissX = ~isfield(x,cFieldAdd);
    bMissXAdd = ~isfield(xAdd,cField);
    if isempty(cFieldAdd)
        cFieldCreate = {};
    else
        cFieldCreate = cFieldAdd(bMissX);
    end
    if isempty(cField)
        cFieldCreateAdd = {};
    else
        cFieldCreateAdd = cField(bMissXAdd);
    end
    
    if isempty(x) % struct has fields, but is empty
        % create empty structure with fields in correct order
        x = structInit([cField' cFieldCreate']);
    else % struct is non empty
        % patch base structure with new fields
        for nIdxField = 1:numel(cFieldCreate)
            x(1).(cFieldCreate{nIdxField}) = [];
        end
    end
    for nIdxField = 1:numel(cFieldCreateAdd)
        xAdd(1).(cFieldCreateAdd{nIdxField}) = [];
    end
end

% % adapt structure vector orientation - TODO full test coverage DIVe and other usages needed!
% if size(x,1)<size(x,2) && size(xAdd,1)>size(xAdd,2)
%     xAdd = xAdd';
% end

% concatenate structures
nSizeX = size(x);
nSizeAdd = size(xAdd);
if nSizeX(1) > nSizeX(2) || nSizeAdd(1) > nSizeAdd(2)
    x = [x;xAdd];
else
    x = [x xAdd];
end
return
