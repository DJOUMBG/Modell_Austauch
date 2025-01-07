function varargout = dbrColGet(xDB,sHeaderColumn)
% DBRCOLGET get the column content of a db data subset structure.
%
% Syntax:
%   varargout = dbrColGet(xDB,sHeaderColumn)
%
% Inputs:
%             xDB - structure with fields: 
%              .field - cell (1xn) with strings of column headers
%              .value - cell (mxn) with values of columns
%   sHeaderColumn - string with the identifier of a columns in the header
%
% Outputs:
%   cCol - cell (1xn) with db.value content of requested column
%   sMsg - string [optional] with error message
%
% Example: 
%   varargout = dbrColGet(xDB,sHeaderColumn)
%
% See also: dbread
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2018-07-10

bHeader = strcmp(xDB.field,sHeaderColumn);
switch sum(bHeader)
    case 0 % no header matched
        cCol = {};
        sMsg = sprintf('The column "%s" is not in this DB structure.',sHeaderColumn);
    case 1 % one header matched
        cCol = xDB.value(:,bHeader);
        sMsg = '';
    otherwise % more than one
        nHeader = find(bHeader);
        cCol = xDB.value(:,nHeader(1));
        sMsg = sprintf('The column "%s" was found multiple times.',sHeaderColumn);
end

% shape output
varargout{1} = cCol;
if nargout > 1
    varargout{2} = sMsg;
else
    fprintf(1,'%s\n',sMsg);
end
return