function vValue = getfieldRecursive(xVar,sField)
% GETFIELDRECURSIVE get values from the depth of a structure variable,
% where the field pathes are specified by a string
%
% Syntax:
%   vValue = getfieldRecursive(xVar,sField)
%
% Inputs:
%     xVar - structure to extract value from sub-structures/fields
%   sField - string with sub-structures/fields description
%
% Outputs:
%   vValue - vector (1x1) with value retrieved from structure
%
% Example: 
%   myStruct.field1.field2.field3 = 3;
%     getfieldRecursive(myStruct,'field1.field2.field3')
% 
% See also: setfieldRecursive, isfieldRecursive, getfield
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2011-08-02

eval(['vValue = xVar.' sField ';']);

% Alternative code without using eval()
% cField = strsplitOwn(sField,'.');
% vValue = xVar.(cField{1});
% for nIdxField = 2:numel(cField)
%     vValue = xVar.(cField{nIdxField});
% end
return