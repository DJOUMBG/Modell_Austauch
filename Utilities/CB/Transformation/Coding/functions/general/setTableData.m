function tTable = setTableData(cData,cColNames,cRowNames)
% SETTABLEDATA creates a Matlab table from 2D cell matrix. Optional with
% column and row names.
%
% Syntax:
%   tTable = setTableData(cData)
%   tTable = setTableData(cData,cColNames)
%   tTable = setTableData(cData,cColNames,cRowNames)
%
% Inputs:
%	cData - cell (mxn):
%       cell matrix with table data
%   cColNames - cell (1xn)/(nx1) (optional):
%       cell array of strings with column names
%   cRowNames - cell (1xm)/(mx1) (optional):
%       cell array of strings with row names
%
% Outputs:
%   tTable - table object
%
% Example: 
%   tTable = setTableData(cData,cColNames,cRowNames)
%
%
% See also: getTableData
%
% Author: Elias Rohrer, TE/PTC-H, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2024-06-13


%% check input

% set flag for row names
if nargin < 2
    bColNames = false;
else
    bColNames = true;
end

% set flag for row names
if nargin < 3
    bRowNames = false;
else
    bRowNames = true;
end


%% check dimensions

% check column name dimension
if bColNames
    if size(cData,2) ~= numel(cColNames)
        error('Number of column names does not match with number of columns in data.');
    end
end

% check row name dimension
if bRowNames
    if size(cData,1) ~= numel(cRowNames)
        error('Number of row names does not match with number of rows in data.');
    end
end


%% create table

% set data
try
    tTable = cell2table(cData);
catch
    tTable = table([]);
    return;
end

% set column names
if bColNames
    tTable.Properties.VariableNames = cColNames;
end

% set row names
if bRowNames
    tTable.Properties.RowNames = cRowNames;
end

return