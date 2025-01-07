function [cData,cColNames,cRowNames] = getTableData(tTable)
% GETTABLEDATA gets data and column and row names of given Matlab table.
%
% Syntax:
%   [cData,cColNames,cRowNames] = getTableData(tTable)
%
% Inputs:
%   tTable - table object
%
% Outputs:
%	cData - cell (mxn):
%       cell matrix with table data
%   cColNames - cell (1xn)/(nx1) (optional):
%       cell array of strings with column names
%   cRowNames - cell (1xm)/(mx1) (optional):
%       cell array of strings with row names
%
% Example: 
%   [cData,cColNames,cRowNames] = getTableData(tTable)
%
%
% See also: setTableData
%
% Author: Elias Rohrer, TE/PTC-H, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2024-06-13


%% get table data

% get table data
try
    cData = table2cell(tTable);
catch
    cData = {};
end

% get table column names
try
    cColNames = tTable.Properties.VariableNames;
catch
    cColNames = {};
end

% get table row names
try
    cRowNames = tTable.Properties.RowNames;
catch
    cRowNames = {};
end

return