function xBase = structUpdate(xBase,xNew,varargin) 
% STRUCTUPDATE update a base structure with the non-empty and non-zero
% elements of a new structure. Does not account for different field
% lengths.
%
% Syntax:
%   xBase = structUpdate(xBase,xNew,varargin)
%
% Inputs:
%      xBase - structure with fields 
%       xNew - structure to update existing elements in the base
%              structure or to add the missing elements
%
% Outputs:
%   xBase - structure with updated/addtional elements of "new" struct
%
% Example: 
%   sMP.mcm = structUpdate(sMP.mcm,sMPnew.mcm)
%   x = structUpdate(struct('a',{11},'b',{11},'c',{11}),struct('b',{22},'c',{0},'d',{33}))
%
% See also: fieldnames, structAdd, structDiff, structExtract, structFind,
%  structDisp
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2012-10-15

cBase = fieldnames(xBase);
cNew = fieldnames(xNew);

for k = 1:length(cNew)
    if ismember(cNew{k},cBase)
        if ~isempty(xNew.(cNew{k})) && ...
                (~isnumeric(xNew.(cNew{k})) || ...
                 ~all(all(xNew.(cNew{k})==0)))
            xBase.(cNew{k}) = xNew.(cNew{k});
        end
    else
        xBase.(cNew{k}) = xNew.(cNew{k});
    end
end
return
