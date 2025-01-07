function [cStructTable,cFieldNames] = getStructAsTable(xStruct)
% GETSTRUCTASTABLE returns a structure as a cell table by order the values
% in columns for each fieldname and number of structure elements in rows.
%
% Syntax:
%   [cStructTable,cFieldNames] = getStructAsTable(xStruct)
%
% Inputs:
%   xStruct - structure with fields
%
% Outputs:
%   cStructTable - cell (mxn): cell-matrix
%       rows: structure elements
%       columns: fieldnames of structure
%    cFieldNames - cell (1xn): list of fieldnames of structure
%
% Example: 
%   [cStructTable,cFieldNames] = getStructAsTable(xStruct)
%
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2023-02-08

%% create table from structure

% get all fieldnames
cFieldNames = fieldnames(xStruct)';
cStructTable = {};

% create table from structure
for nRow=1:numel(xStruct)
    
    % init next row
    cColFields = {};
    
    % get values from each field for current structure element ( = row)
    for nCol=1:numel(cFieldNames)
        cColFields = [cColFields,{xStruct(nRow).(cFieldNames{nCol})}]; %#ok<AGROW>
    end
    
    % append row to table
    cStructTable = [cStructTable;cColFields]; %#ok<AGROW>
    
end

return