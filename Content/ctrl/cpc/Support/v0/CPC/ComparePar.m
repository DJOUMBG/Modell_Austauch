function [cDiff, par1, par2] = ComparePar(sDir, EEP, bPPC)
% COMPAREPAR Compare parameter of 2 par files (*.par)
% Output results in Cell array and Excel file
%
% Requirement:
% - CPC or PPC model paths are set (needed for conversion from raw to physical values)
%
%
% Syntax:  [cDiff, par1, par2] = ComparePar(sDir, EEP)
%
% Inputs:
%    sDir - [''] directory of par files (can be also an EEPROM struct)
%    EEP - [.] EEPROM struct, if parameter are already read (optional)
%    bPPC - [0,1] read PPC parameter (optional, default: 0 -> CPC)
%
% Outputs:
%    cDiff - [{}] Cell array of differences
%    par1 - [.] Parameter from 1st file
%    par2 - [.] Parameter from 2nd file
%
% Example:
%    [cDiff, par1, par2] = ComparePar;                  % CPC parameter (files) in current folder
%    cDiff = ComparePar('C:\par');                      % CPC parameter (files)
%    cDiff = ComparePar('C:\par', sMP.ctrl.cpc.EEP);    % CPC parameter (files and DIVe workspace)
%    cDiff = ComparePar('C:\ppc', [], 1);               % PPC parameter (files)
%    cDiff = ComparePar('C:\ppc', sMP.ctrl.ppc.EEP, 1); % PPC Parameter (files and DIVe workspace)
%    cDiff = ComparePar(EEP1, EEP2);                    % CPC Parameter (workspace)
%
%
% Subfunctions: getInput
%
% See also: fcFindDiff, fcGetCDI, read_par_file, read_ippc_par_file
%
% Author: ploch37
% Date:   31-Jul-2012

%% ------------- BEGIN CODE --------------

% PPC or CPC ?
if ~exist('bPPC', 'var') || isempty(bPPC)
    bPPC = false;
end

% Find par files
if ~exist('sDir', 'var')
    sDir = pwd;
end
if ischar(sDir)
    sFiles = dir(fullfile(sDir, '*.par'));
    sFiles = {sFiles.name}';
else
    % First input is EEP struct, not a directory
    EEP0 = sDir;
    sFiles = [];
end

% Try to use EEP parameter from DIVe workspace
if ~exist('EEP', 'var')
    EEP = [];
    try %#ok<TRYNC>
        if bPPC
            EEP = evalin('base', 'sMP.ctrl.ppc.EEP');
        else
            EEP = evalin('base', 'sMP.ctrl.cpc.EEP');
        end
    end
end
if exist('EEP', 'var') && ~isempty(EEP)
    fprintf(1, '0: EEP from input\n');
end
% Select par files
for k = 1:length(sFiles)
    fprintf(1, '%d: %s\n', k, sFiles{k});
end
% Lade par files
if exist('EEP0', 'var')
    par1 = getInput (0, EEP0, sDir, sFiles, bPPC);
    par2 = getInput (0, EEP, sDir, sFiles, bPPC);
else
    par1 = getInput (1, EEP, sDir, sFiles, bPPC);
    par2 = getInput (2, EEP, sDir, sFiles, bPPC);
end

% Compare parameter
cDiff = fcFindDiff(par1, par2);
% Only parameter on the left side, which don't exist on the right side
if size(cDiff, 2) == 2
    % Add 3rd column
    cDiff{1,3} = [];
end
% Wenn Src gleich ist, z.B. wenn nur die EEP Struktur eingegeben wird und
% keine Dateien, dann erstelle Titelzeile
if ~strcmp(cDiff{1}, 'src')
    cDiff = [cell(1,3); cDiff];
    cDiff{1,1} = 'src';
    cDiff{1,2} = 'base1';
    cDiff{1,3} = 'base2';
else
    cDiff{1,2} = ['1: ' cDiff{1,2}];
    cDiff{1,3} = ['2: ' cDiff{1,3}];
end

% Write all different parameter (also matrices)
for n = 2:3
    for k = 2:size(cDiff, 1)
        if ~isempty(cDiff{k,n})
            data = eval(['par' num2str(n-1) '.' cDiff{k,1}]);
            if isstruct(data)
                cDiff{k,n} = 'struct';
                continue
            end
            if isa(data, 'timeseries')
                data = data.Data;
            end
            if isa(data, 'embedded.fi')
                data = (double(data) - data.Bias) / data.Slope;
            else
                data = double(data);
            end
            cDiff{k,n} = data;
        end
    end
end

% Load CDI Table
if bPPC
    % PPC
    xCDI = fcGetCDI('IPPC');
else
    % CPC
    xCDI = fcGetCDI('CPC');
end

% Show differences
cDiff{1,4} = 'Description';
cDiff{1,5} = '1.phys';
cDiff{1,6} = '2.phys';
cDiff{1,7} = 'Unit';
cDiff{1,8} = 'Default (phys)';
for k = 1:size(cDiff,1)
    try %#ok<TRYNC>
        sSignal = cDiff{k,1}(5:end); % remove "par."
        if isempty(sSignal)
            continue
        end
        cDiff{k,1} = sSignal; % remove "par."
        xCDI_ = fcGetCDI(xCDI, sSignal);
        cDiff{k,4} = xCDI_.Description;
        try %#ok<TRYNC>
            if isnumeric(cDiff{k,2})
                [xCDI_, cDiff{k,5}] = fcGetCDI(xCDI_, sSignal, 'phys', cDiff{k,2});
            end
        end
        try %#ok<TRYNC>
            if isnumeric(cDiff{k,3})
                [xCDI_, cDiff{k,6}] = fcGetCDI(xCDI_, sSignal, 'phys', cDiff{k,3});
            end
        end
        cDiff{k,7} = xCDI_.Unit;
        cDiff{k,8} = xCDI_.DefaultValuePhys;
    end
end

%% Output in Excel
% Write Excel file
sFilename = sprintf('%s_%s.xlsx', mfilename, datestr(now, 30));
if exist([pwd '\' sFilename], 'file')
    delete(sFilename)
end
xlswrite(sFilename, cDiff);

% Open Excel file
ex.file = [pwd '\' sFilename];
ex.Excel = actxserver('Excel.Application');
% set(ex.Excel,'Visible',1) % show Excel file
ex.ExcelWorkbook = ex.Excel.workbooks.Open(ex.file); % Datei öffnen
% Comments at matrices
for n = [2:3,5:6]
    for k = 2:size(cDiff, 1)
        if ~isempty(cDiff{k, n}) && isnumeric(cDiff{k, n}) && ~isscalar(cDiff{k, n})
            % Address
            sAdresse = sprintf('$%s$%u', char('@'+n), k);
            % Select Cell
            Select(Range(ex.Excel,sAdresse));
            % Add comment field
            try %#ok<TRYNC> % If comment already exists
                invoke(ex.Excel.Selection, 'AddComment');
            end
            ex.Excel.Selection.Value = sprintf('%dx%d',size(cDiff{k,n},1), size(cDiff{k,n},2));
            sDiff = num2str(cDiff{k,n});
            % Add comment text
            invoke(ex.Excel.Selection.Comment, 'Text', sDiff);
            % Size of comment field
            % set(ex.Excel.Selection.Comment.Shape, 'Width', 4 * size(sDiff, 2)+10)
            % set(ex.Excel.Selection.Comment.Shape, 'Height', 10 * size(sDiff, 1)+10)
            set(ex.Excel.Selection.Comment.Shape.TextFrame, 'AutoSize', true)
        end
    end
end
% Column width
hRange = invoke(ex.Excel.Columns, 'Item', 1);
hRange.ColumnWidth = 40;
% Column color
color1 = 255; % red
color2 = 5287936; % green
hRange = invoke(ex.Excel.Columns, 'Item', 2);
hRange.Font.Color = color1;
hRange = invoke(ex.Excel.Columns, 'Item', 5);
hRange.Font.Color = color1;
hRange = invoke(ex.Excel.Columns, 'Item', 3);
hRange.Font.Color = color2;
hRange = invoke(ex.Excel.Columns, 'Item', 6);
hRange.Font.Color = color2;
% Freeze window
Select(Range(ex.Excel,'B2'));
ex.Excel.ActiveWindow.FreezePanes = true;
% AutoFilter at first row
hRange = invoke(ex.Excel.Rows, 'Item', 1);
hRange.AutoFilter
% Save file
ex.ExcelWorkbook.Save
% pause(5)
ex.ExcelWorkbook.Close(false)  % Close Excel workbook
ex.Excel.Quit;
% Matlab link in command window to Excel file
disp(['<a href = "matlab: winopen(''' sFilename ''') ">XLSX was exported</a>']);

function [x] = getInput (k, EEP, sDir, sFiles, bPPC)
switch k
    case 0
        nInput = 0;
    case 1
        nInput = input('Compare base (type in the number): ');
    case 2
        nInput = input('Compare to (type in the number): ');
end
if isempty(nInput) || nInput == 0
    x.src = 'base workspace';
    x.par = EEP;
else
    x.src = fullfile(sDir, sFiles{nInput});
    % Lade CAL Datei
    % x.src = [pwd, '\..\CPC\CAL\CAL_R09_11WE_02_SFTP963_ECONOMY_HYBRID_OM471_G211-12K_EURO6_RET.PAR'];
    % x.src = [pwd, '\..\CPC\CAL\CAL_R09_11WE_02_SFTP963_Economy_HYBRID_OM470_G211-12K_EURO6_RET_V02.PAR']; % AG-Parameter Release 2
    try
        x.par = read_par_file(x.src);
    catch
        x.par = read_ippc_par_file(x.src);
    end
end
% Wenn Daten bereits in physikalischer Form un din einer Struktur mit
% value', 'unit', etc. vorliegen, z.B. aus save_schaltdrehzahlen.m, dann
% zurückwandeln
sSignal = fieldnames(x.par);
if isstruct(x.par) && isfield(x.par.(sSignal{1}), 'value')
    % Lade CDI Table
    xCDI = fcGetCDI;
    % Wandle einzelne Werte zurück in Rohwerte um
    fprintf(1, '%s\n', 'Wandle physikalische Werte zurück in Rohwerte um (bitte um Geduld) ...');
    for k = 1:length(sSignal)
        % Finde Signaldefinition
        xCDI_ = fcGetCDI(xCDI, sSignal{k});
        % Wandle einzelne Werte mit Offset und Faktor zurück in Rohwerte um
        x.par.(sSignal{k}) = round((x.par.(sSignal{k}).value - xCDI_.Offset) ./ xCDI_.Factor);
    end
end