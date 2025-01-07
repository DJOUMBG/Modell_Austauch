function x = structUnify(x,xAdd) 
% STRUCTUNIFY add a structure to another structure while preserving any
% content. The resulting structure contains any field of the source
% structure. If a field is present in both structures, the field value of
% the second source structure is used.
%
% Syntax:
%   x = structUnify(x,xAdd)  
%
% Inputs:
%      x - structure with arbitrary MATLAB structure
%   xAdd - structure with arbitrary MATLAB structure
%
% Outputs:
%   x - structure containing the fields of both source structures
%
% Example: 
%   x = structUnify(struct('a',{11},'b',{11}),struct('b',{22},'c',{22}))
%
% See also: fieldnames, structAdd, structUpdate, structDiff, structExtract,
% structFind, structDisp
% 
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2014-06-17

cFieldAdd = fieldnames(xAdd);
for nIdxField = 1:numel(cFieldAdd)
    x.(cFieldAdd{nIdxField}) = xAdd.(cFieldAdd{nIdxField});
end
return
