function [cName,cValue] = struct2cells(xStruct,nNameLevel,cFieldRec)
% STRUCT2CELLS convert non-cell structure elements to two cells: one with
% the structure name/path and one with the respective value. Function is
% reccursive and the levels of fieldnames used for the structure name/path
% can be limited up to the last field level.
%
% Syntax:
%   [cName,cValue] = struct2cells(xStruct,nNameLevel)
%
% Inputs:
%      xStruct - structure with arbitrary fields
%   nNameLevel - integer (1x1) with level of structure field names used for
%                the name
%    cFieldRec - cell with so far occuring fieldnames in reccursive call
%
% Outputs:
%    cName - cell (mxn) with strings containing the names of variables
%   cValue - cell (mxn) with variable values
%
% Example: 
%   [cName,cValue] = struct2cells(xStruct,inf)
%   [cName,cValue] = struct2cells(struct('a',{1,2,3},'b',{'asdf'}),inf)
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2013-08-20

% initialization
cName = {};
cValue = {}; 
if nNameLevel < 1
    nNameLevel = inf;
end

% catch first call
if nargin < 3;
    cFieldRec = {};
end


% parse all structure fields
cField = fieldnames(xStruct);
for nIdxField = 1:numel(cField)
    if isstruct(xStruct.(cField{nIdxField}))
        % recursive call
        [cNameReccursion,cValueReccursion] = struct2cells(xStruct.(cField{nIdxField}),nNameLevel,[cFieldRec cField(nIdxField)]);
        cName = [cName cNameReccursion]; %#ok
        cValue = [cValue cValueReccursion]; %#ok
    elseif iscell(xStruct.(cField{nIdxField}))
        % create name
        cFieldRecAct = [cFieldRec cField(nIdxField)];
        sName = '';
        % combine the last specified field names a:b (limited 1<=a<=numel(cFieldRecAct) ) 
        for nIdxLevel = min(max(1,numel(cFieldRecAct)-(nNameLevel-1)),numel(cFieldRecAct)):numel(cFieldRecAct)
            sName = [sName cFieldRecAct{nIdxLevel} '.']; %#ok
        end
        sName = sName(1:end-1);
        cName = [cName {sName}]; %#ok
            
        % assign value
        sValue = '{';
        for nIdxCell = 1:numel(xStruct.(cField{nIdxField}))
            if ischar(xStruct.(cField{nIdxField}){nIdxCell})
                sValue = [sValue '''' xStruct.(cField{nIdxField}){nIdxCell} '''']; %#ok
            end
        end
        sValue = [sValue '}']; %#ok
            
        cValue = [cValue {sValue}]; %#ok        
    else
        % create name
        cFieldRecAct = [cFieldRec cField(nIdxField)];
        sName = '';
        % combine the last specified field names a:b (limited 1<=a<=numel(cFieldRecAct) ) 
        for nIdxLevel = min(max(1,numel(cFieldRecAct)-(nNameLevel-1)),numel(cFieldRecAct)):numel(cFieldRecAct)
            sName = [sName cFieldRecAct{nIdxLevel} '.']; %#ok
        end
        sName = sName(1:end-1);
        cName = [cName {sName}]; %#ok
            
        % assign value
        cValue = [cValue {xStruct.(cField{nIdxField})}]; %#ok
    end
end
return
