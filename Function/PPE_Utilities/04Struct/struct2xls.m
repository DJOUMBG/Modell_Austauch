function struct2xls(xStruct,sFile)
% STRUCT2XLS write a MATLAB structure content to an Excel file.
%
% Syntax:
%   struct2xls(xStruct,sFile)
%
% Inputs:
%   xStruct - structure with arbitrary fields
%     sFile - string with save file name or pathname 
%
% Outputs:
%
% Example: 
%   struct2xls(xStruct,sFile)
%
% See also: xlsSheetEmptyDelete, struct2cells
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2014-02-28

% get first element for initializations
[cName,cValue] = struct2cells(xStruct(1),inf);

% initialize Excel output cell
cXls = cell(numel(xStruct)+1,numel(cName));
cXls(1,:) = cName;
cXls(2,:) = cValue;

% get followup lines
for nIdxVector = 2:numel(xStruct)
    [cName,cValue] = struct2cells(xStruct(nIdxVector),inf); %#ok
    cXls(nIdxVector+1,:) = cValue;
end

% get save name if not specified
if ~exist('sFile','var')
    % get save path
    [sFile, sPath] = uiputfile({'*.xlsx','Excel files (*.xlsx)';'*.xls','Excel files (*.xls)'}, ...
                                'save configuration as',pwd);
    sFile = fullfile(sPath,sFile);
end

% write files
xlswrite(sFile,cXls);
% xlsSheetEmptyDelete(sFile); % remove empty sheets
return
