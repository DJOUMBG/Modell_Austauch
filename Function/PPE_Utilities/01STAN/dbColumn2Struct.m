function xStruct = dbColumn2Struct(cHeader,cData)
% DBCOLUMN2STRUCT convert a data cell block with a header to a struct
% vector with a field for each column.
%
% Syntax:
%   xStruct = dbColumn2Struct(cHeader,cData)
%
% Inputs:
%   cHeader - cell (1xn) with strings of column header -> struct field 
%     cData - cell (mxn) with data
%
% Outputs:
%   xStruct - structure with fields: 
%
% Example: 
%   xStruct = dbColumn2Struct(cHeader,cData)
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2014-07-16

for nIdxData = 1:size(cData,1)
    for nIdxHeader = 1:numel(cHeader)
        xStruct(nIdxData).(cHeader{nIdxHeader}) = cData{nIdxData,nIdxHeader};  %#ok<AGROW>
    end
end
return
