function xSort = structFieldOrder(xTemplate,xSort)
% STRUCTFIELDORDER order the fields of a second specified structure (can be
% complex with struct arrays and multiple levels) along the fields of the
% first specified structure.
%
% Syntax:
%   xSort = structFieldOrder(xTemplate,xSort)
%
% Inputs:
%   xTemplate - structure with fields: 
%       xSort - structure with fields: 
%
% Outputs:
%   xSort - structure with fields: 
%
% Example: 
%   xSort = structFieldOrder(struct('a',{1},'b',{2},'c',{3},'d',{4}),struct('b',{2},'a',{1},'d',{4},'c',{3}))
%   xSort = structFieldOrder(struct('a',{1},'b',{2},'c',{3},'d',{4},'f',{6}),struct('b',{2},'a',{1},'d',{4},'c',{3}))
%   xSort = structFieldOrder(struct('a',{1},'b',{2},'c',{3},'d',{4}),struct('b',{2},'a',{1},'d',{4},'c',{3},'e',{5}))
%
% See also: orderfields, structAdd
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-8485-3325
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2022-05-12

% check input
if ~isstruct(xTemplate)
    error('structFieldOrder:noStructFirstArgument',...
        'The first argument of structFieldOrder must be a structure');
end
if ~isstruct(xSort)
    error('structFieldOrder:noStructSecondArgument',...
        'The second argument of structFieldOrder must be a structure');
end

% get fields of structure
cFieldTemplate = fieldnames(xTemplate);
cFieldSort = fieldnames(xSort);

% check occurence
bTemplateInSort = ismember(cFieldTemplate,cFieldSort);
bSortInTemplate = ismember(cFieldSort,cFieldTemplate);

% reccursion into subsequent structures
nTemplateUse = find(bTemplateInSort);
for nIdxField = nTemplateUse'
    if isstruct(xTemplate(1).(cFieldTemplate{nIdxField}))
        for nIdxArray = 1:numel(xSort)
            if isstruct(xSort(nIdxArray).(cFieldTemplate{nIdxField})) && ...
                    ~isempty(xSort(nIdxArray).(cFieldTemplate{nIdxField}))
                xSort(nIdxArray).(cFieldTemplate{nIdxField}) = structFieldOrder(...
                    xTemplate(1).(cFieldTemplate{nIdxField}),...
                    xSort(nIdxArray).(cFieldTemplate{nIdxField}));
            end
        end
    end
end

% adapt order regarding excessive fields
cFieldOrder = [cFieldTemplate(bTemplateInSort);cFieldSort(~bSortInTemplate)];
xSort = orderfields(xSort,cFieldOrder);
return

