function xBase = structReplace(xBase,xNew) 
% STRUCTREPLACE replace all fields of base structure with the value of the
% new structure, if a matching field exists.
%
% Syntax:
%   xBase = structReplace(xBase,xNew)
%
% Inputs:
%      xBase - structure with fields 
%       xNew - structure to update existing elements in the base
%              structure
%
% Outputs:
%   xBase - structure with updated elements of "new" struct
%
% Example: 
%   sMP.mcm = structReplace(sMP.mcm,sMPnew.mcm)
%   x = structReplace(struct('a',{11},'b',{11},'c',{11},'e',{11}),struct('b',{22},'c',{0},'d',{33}))
%
% See also: fieldnames, structAdd, structDiff, structExtract, structFind,
%  structDisp
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2012-12-16

cBase = fieldnames(xBase);
cNew = fieldnames(xNew);

for nIdxField = 1:length(cBase)
    if any(strcmp(cBase{nIdxField},cNew))
        xBase.(cBase{nIdxField}) = xNew.(cBase{nIdxField});
    end
end
return
