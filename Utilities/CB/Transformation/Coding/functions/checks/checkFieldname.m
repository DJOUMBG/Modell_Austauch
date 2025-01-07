function checkFieldname(xStruct,sField)
% CHECKFIELDNAME checks if fieldname is valid field in structure and
% raises an error if it does not.
%
% Syntax:
%   checkFieldname(xStruct,sField)
%
% Inputs:
%   xStruct - structure with fields
%    sField - string, specific fieldname to be checked
%
% Outputs:
%   (error message if check is unsuccessful)
%
% Example: 
%   checkFieldname(xStruct,sField)
%
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2022-12-15

%% check if structure contains field
if ~isfield(xStruct,sField)
    error('checkFieldname:NotIsField',...
        '"%s" is not a valid field in structure "%s".',...
        sField,inputname(1));
end

return

