function dstGetSignalInfo(sPathDiveContent)
% dstGetSignalInfo This function reports the usage of signal(taken from Signal List) 
% in all modules of DIVe content. It creates a copy of
% DIVe_Signals_report.xlsx with 2 new columns mentioning source and taget
% modules.
%
% Syntax:
%   dstGetSignalInfo(sPathDiveContent))
%
% Inputs:
%   sPathDiveContent - DIVe Content location file path
%
% Example:
%    dstGetSignalInfo(sPathDiveContent)
% Author: Nagaraj Ramachandra, RDI/TBP
% Mail : nagaraj.ramachandra@daimler.com
% Phone: +91-80-6768-6240
% Date: 06-06-2017

%check input
if nargin < 1
    fprintf(2,'Error: Please provide a valid DIVe Content path as argument\n');
    return
end
if isempty(sPathDiveContent)
    fprintf(2,'Error: Please provide a valid DIVe Content path as argument\n');
    return
end
if ~isdir(sPathDiveContent)
    fprintf(2,'Error: DIVe content path is not correct. Please provide a valid path\n');
    return
end
xDir = dir(sPathDiveContent);
if isempty(xDir)
    fprintf(2,'Error: DIVe content folder is empty. Please provide a valid path\n');
    return
end
hWait = waitbar(0,'Search for Module XMLs...','Name','Collect Signal info');

%get all Module XMLs from DIVe content
cAllModuleXmlPath=sdmGetAllModuleXmls(sPathDiveContent); 
waitbar(0.05,hWait,'Read Module XMLs...');
xTree = struct;
nModule = numel(cAllModuleXmlPath);
for nIdx=1:nModule
    xTreeAdd = dsxRead(cAllModuleXmlPath{nIdx});
    xTree = structAdd(xTree,xTreeAdd,0);
    waitbar(0.05+0.4*nIdx/nModule,hWait);
end
waitbar(0.45,hWait,'Write Excelsheet...');
sCwd = fileparts(mfilename('fullpath'));
sPathSignalList = fullfile(sCwd,'..\..\Interface\','DIVe_signals.xlsx');
%copy the signal list
sPathSignalLstCopy = fullfile(sCwd,['..\..\Interface\' ...
    datestr(now, 'yyyymmdd_HHMMSS') '_DIVe_Signals_Report.xlsx']);
[nCopyStatus,~] = copyfile(sPathSignalList,sPathSignalLstCopy);
if nCopyStatus==0
    fprintf(1,'Error: Failed to create a copy of the Signal List. Function is terminating\n');
    return
else
    %set file attribute as writeable
    fileattrib(sPathSignalLstCopy,'+w');
end
waitbar(0.46,hWait);
xSignalList=dbread(sPathSignalLstCopy,1);
cSignalNames=xSignalList.subset.value(1:end,1);
%get last filled column
[~, nColCnt]=size(xSignalList.subset.value);
sColTargetModel = xlcolumnletter(nColCnt+1);
% xlswrite(sPathSignalLstCopy,{'Target Models'},1,strcat(sColTargetModel,num2str(1)));
sColSourceModel = xlcolumnletter(nColCnt+2);
% xlswrite(sPathSignalLstCopy,{'Source Models'},1,strcat(sColSourceModel,num2str(1)));

%use actxserver instead of xlswriter for speed
oExcel = actxserver('Excel.Application');
oWorkbook = oExcel.workbooks.Open(sPathSignalLstCopy);
if oWorkbook.ReadOnly ~= 0
    %This means the file is probably open in another process.
    error('MATLAB:xlswrite:LockedFile', 'The file %s is not writable.  It may be locked by another process.', sPathSignalLstCopy);
end
oSheets = oExcel.ActiveWorkbook.Sheets;
oSheet1 = oSheets.get('Item',1);
oRange1 = oSheet1.Range(strcat(sColTargetModel,num2str(1)));
oRange1.cells.EntireColumn.AutoFit();
oRange2 = oSheet1.Range(strcat(sColSourceModel,num2str(1)));
oRange2.cells.EntireColumn.AutoFit();
oSheet1.Activate;
%Write Heading
oActiveRange = get(oExcel.Activesheet,'Range',strcat(sColTargetModel,num2str(1)));
oActiveRange.Value = 'Target Models';
oActiveRange = get(oExcel.Activesheet,'Range',strcat(sColSourceModel,num2str(1)));
oActiveRange.Value = 'Source Models';
%search for each Signal in inport of all modules
nSignal = numel(cSignalNames);
for nIdxSignal=1:nSignal
    waitbar(0.46+0.54*nIdxSignal/nSignal,hWait);
    sTargetModuleList = '';
    sSourceModuleList = '';
    for nModuleIdx=1:numel(xTree.Module)
        sSpecies = xTree.Module(nModuleIdx).species;
        sContext = xTree.Module(nModuleIdx).context;
        sFamily = xTree.Module(nModuleIdx).family;
        sType = xTree.Module(nModuleIdx).type;
        if isfield(xTree.Module(nModuleIdx).Interface,'Inport')
            if any(strcmp(cSignalNames(nIdxSignal),{xTree.Module(nModuleIdx).Interface.Inport.name}))
                sTargetModuleList = [sTargetModuleList ', ' strGlue({sContext,sSpecies,sFamily,sType},'_')]; %#ok<*AGROW>
            end
        end
        if isfield(xTree.Module(nModuleIdx).Interface,'Outport')
            if any(strcmp(cSignalNames(nIdxSignal),{xTree.Module(nModuleIdx).Interface.Outport.name}))
                sSourceModuleList = [sSourceModuleList ', ' strGlue({sContext,sSpecies,sFamily,sType},'_')];
            end
        end
    end
    %if any target module exist
    if ~isempty(sTargetModuleList)
        oActiveRange = get(oExcel.Activesheet,'Range',strcat(sColTargetModel,num2str(nIdxSignal+1)));
        oActiveRange.Value = sTargetModuleList(3:end);
    end
    %if any source modules exist
    if ~isempty(sSourceModuleList)
        %write to excel sheet
        oActiveRange = get(oExcel.Activesheet,'Range',strcat(sColSourceModel,num2str(nIdxSignal+1)));
        oActiveRange.Value = sSourceModuleList(3:end);
    end 
end
oWorkbook.Save;
Close(oWorkbook);
delete(oExcel);
close(hWait);
%Link to excel sheet
fprintf(1,'<a href="matlab:winopen(''%s'')">Click here to open the report</a>\n',sPathSignalLstCopy);
return

% =========================================================================+

function cPath = sdmGetAllModuleXmls(sPath)
% sdmGetAllModuleXmls look into all the subfolders of the giveb path and find Module XMLs .
%
% Syntax:
%   cPath = sdmGetAllModuleXmls(sPath))
%
% Inputs:
%   sPath - string with file path
%
% Outputs:
%   cPath - cell (1xn) with strings of all available paths of module XML
%
% Example:
%    cPath = sdmGuiPathCollectionGet(sPath))

% initialize output
cPath = {};

% get directories in current folder
cFolder = dirPattern(sPath,'*','folder');

% determine type
bNext = false(1,numel(cFolder));
for nIdxFolder = 1:numel(cFolder)
    switch cFolder{nIdxFolder}
        case 'Module'
            cModelVarNames = dirPattern(fullfile(sPath,cFolder{nIdxFolder}),'*','folder');
            cModelVarPaths = cellfun(@(x)fullfile(sPath,cFolder{nIdxFolder},x),cModelVarNames,'UniformOutput',false);
            for nIdx=1:numel(cModelVarPaths)
               %get module XML
               cFileXml = dirPattern(cModelVarPaths{nIdx},[cModelVarNames{nIdx} '.xml'],'file');
               cAdd = cellfun(@(x) fullfile(cModelVarPaths{nIdx},x),cFileXml,'UniformOutput',false);
            end
            cPath = [cPath cAdd]; %#ok<AGROW>
        otherwise
            bNext(nIdxFolder) = true;
    end
end
cNext = cFolder(bNext);
cNext = cellfun(@(x)fullfile(sPath,x),cNext,'UniformOutput',false);

% proceed to next level
for nIdxNext = 1:numel(cNext)
    cAdd = sdmGetAllModuleXmls(cNext{nIdxNext});
    cPath = [cPath cAdd]; %#ok<AGROW>
end
return

% =========================================================================+

function sColLetter = xlcolumnletter(nColNumber)
% This function returns the letter combination that corresponds to a given
% column number.
% Limited to 702 columns
% Inputs:
%   nColNumber = Integer column number
% Ouputs:
%   sColLetter = Column letter combination like AA,AB,..XA..ZZ
% Author: Nagaraj Ramachandra,RDI/TBP
%  Phone: +91-80-67686240
% MailTo: nagaraj.ramachandra@daimler.com
%   Date: 06-06-2017

if( nColNumber > 26*27 )
    error('XLCOLUMNLETTER: Requested column number is larger than 702.');
else
    % Start with A-Z letters
    sAtoZ        = char(65:90)';
    % Single character columns are first
    cSingleChar  = cellstr(sAtoZ);
    % Calculate all combinations
    lAlphaIdx           = (1:26)';
    [mGrid1,mGrid2]=ndgrid(lAlphaIdx,lAlphaIdx);
    mAllCombination=reshape(cat(3,mGrid2,mGrid1),[],2);      
    cDoubleChar  = cellstr(sAtoZ(mAllCombination));
    % Concatenate
    xlLetters   = [cSingleChar;cDoubleChar];
    % Return requested column
    sColLetter   = xlLetters{nColNumber};
end
