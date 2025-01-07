function xlsSheetEmptyDelete(sFile) 
% XLSSHEETEMPTYDELETE delete all empty Excel sheets via ActiveX API
%
% Syntax:
%   xlsSheetEmptyDelete(sFile)
%
% Inputs:
%   sFile - string with file/filepath of an Excel file
%
% Outputs:
%
% Example: 
%   sFile = 'Test1.xlsx';xlswrite('Test1.xlsx',{'some'}),xlsSheetEmptyDelete(sFile)
%
% See also: xlsread, xlswrite
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-8485-3325
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2007-04-05

% input check
if ~exist(sFile,'file')
    error('xlsSheetEmptyDelete:fileNotFound',...
        'The specified file "%s" does not exist',sFile);
end
% check file type
[sPath,sName,sExt] = fileparts(sFile);
if ~ismember(sExt,{'.xls','.xlsx','.xlsm','.xlsb'})
    error('xlsSheetEmptyDelete:unknownFileType',...
        'The specified file "%s" is not of a known Excel file type',sFile);
end
% explicit filepath is needed for ActiveX
if isempty(sPath)
    sFile = fullfile(pwd,[sName sExt]);
end

% open ActiveX server
oExcel = actxserver('Excel.Application');
oWorkbook = oExcel.workbooks.Open(sFile);
oSheets = oExcel.sheets;
oExcel.EnableSound = false;

% Loop through all sheets
for nIdxSheet = oSheets.Count:-1:1
    if oSheets.Item(nIdxSheet).UsedRange.Count == 1 && ... % isempty sheet
            (nIdxSheet == 1 && oSheets.Count > 1) % last sheet cannot be removed
        % delete sheet
        oSheets.Item(nIdxSheet).Delete;
    end
end

% save and cleanup
oWorkbook.Save;
oWorkbook.Close(false);
oExcel.Quit;
delete(oExcel);
return;
 
