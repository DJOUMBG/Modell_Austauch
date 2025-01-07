function bField = isfieldRecursive(xVar,cField)
% ISFIELDRECURSIVE checks a structure for the occurence of specified (sub-)
% structures and fields as string.
%
% Syntax:
%   bField = isfieldRecursive(xVar,cField)
%
% Inputs:
%     xVar - structure to check for fields
%   cField - string or cell (1xn) of strings with the structure/field to be
%            checked
%
% Outputs:
%   bField - boolean (1xn) if specified structure/field is in passed struct
%
% Example: 
%   myStruct.field1.field2.field3 = 5;
%     isfieldRecursive(myStruct,'field1.field2') % true
%     isfieldRecursive(myStruct,'field1.field3') % false
%     isfieldRecursive(myStruct,{'field1.field2','field1.field2.field3','field1.field3'}) % [true, true, false]
%
% See also: getfieldRecursive, setfieldRecursive, isfield
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2011-08-02

% check input 
if ischar(cField)
    % ensure cell
    cField = {cField};
end

% init output
bField = false(size(cField));

% loop over field specs
for nIdxField = 1:numel(cField)
    % get the name of the field separated by the character '.', example:
    % 'field1.field2.field3' -> {'field1' 'field2' 'field3'}
    cSplit = strsplitOwn(cField{nIdxField},'.');
    
    % check if the fields is a part of the structure
    xCurrent = xVar;
    for nIdxSplit = 1:numel(cSplit) % for all field consecutively
        sField = cSplit{nIdxSplit};
        bField(nIdxField) = isfield(xCurrent, sField);
        if bField(nIdxField)
            % the field is a part of the structure, check the next field
            if numel(xCurrent.(sField)) > 1
                xCurrent = xCurrent.(sField)(1);
            else
                xCurrent = xCurrent.(sField);
            end
        else
            % the field is not a part of the structure, break the iteration,
            % return false
            break
        end
    end
end
return
