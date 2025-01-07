function xNew = setfieldRecursive(xOld, sFieldName, vFieldValue) %#ok<INUSD>
% SETFIELDRECURSIVE set the content of the field "sFieldName" of the
% structure "xOld" to the value "vFieldValue". This function is
% similar to the built-in matlab function setfield, however the field
% "sFieldName" may be also a structure string.
%
% Syntax:
%   xNew = setfieldRecursive(xOld,sFieldName,vFieldValue)
%
% Inputs:
%          xOld - structure to set new field values in 
%    sFieldName - string of structure/fields to be set
%   vFieldValue - any variable kind to be set as field value
%
% Outputs:
%   xNew - structure with fields of xOld, but changed value 
%
% Example: 
%     myStruct = setfieldRecursive(struct, 'field1.field2', 3)
%     myStruct = setfieldRecursive(myStruct, 'field3.field4.field5', 2)
%
% See also: getfieldRecursive, isfieldRecursive, setfield
%
% Author: Rainer Frey, TP/EAC, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2011-10-22

if ~isempty(xOld)
    % copy the old value
    xNew = xOld;
else
    % nothing to be copied
end
if strcmp(sFieldName(1),'(') || strcmp(sFieldName(1),'.')
    sPoint = '';
else
    sPoint = '.';
end
eval(['xNew' sPoint sFieldName '= vFieldValue;']);

% Alternativ code without using eval()
% cField = regexp(sFieldName, '[^/.]+', 'match');
% xTemp.(cField{end}) = vFieldValue;
% for nIdxField = length(cField)-1:-1:2
%     xTemp.(cField{nIdxField}) = xTemp;
% end
% xNew.(cField{1}) = xTemp;
return
