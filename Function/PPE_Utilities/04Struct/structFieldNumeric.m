function x = structFieldNumeric(x)
% STRUCTFIELDNUMERIC returns only the fields of a structure, which have
% numeric values.
%
% Syntax:
%   x = structFieldNumeric(x)
%
% Inputs:
%   x - structure with arbitrary field values
%
% Outputs:
%   x - structure with only numeric fields
%
% Example: 
%   x = structFieldNumeric(struct('a',{1},'b',{'str'},'c',{NaN}))
%
% See also: rmfield
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2015-02-09

cField = fieldnames(x);
bRemove = false(size(cField));
for nIdxField = 1:numel(cField)
    if ~isnumeric(x.(cField{nIdxField}))
        bRemove(nIdxField) = true;
    end
end
x = rmfield(x,cField(bRemove));
return
