function dstGetParamaterInfo(sPathDiveContent)
% dstGetParamaterInfo This function reports the usage of global parameter 
% in all modules of DIVe content. It creates a copy of
% DIVe_GlobalParameter_report.xlsx with 1 new column mentioning the
% classification which uses the parameter
%
% Syntax:
%   dstGetParamaterInfo(sPathDiveContent))
%
% Inputs:
%   sPathDiveContent - DIVe Content location file path
%
% Example:
%    dstGetParamaterInfo(sPathDiveContent)
%
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

%get all dependency XMLs specfied Content tree
cAllDependenyXmls=sdmGetAllDependenyXmls(sPathDiveContent);

% determine location of DIVe_GlobalParameter.xlsx
cPathFileThis = pathparts(mfilename('fullpath'));
sPathGlobaParamsList = fullfile(cPathFileThis{1:end-3},'Interface','DIVe_GlobalParameter.xlsx');
%copy the signal list
sPathGlobalParamLstCopy = fullfile(cPathFileThis{1:end-3},'Interface', ...
    [datestr(now, 'yyyymmdd_HHMMSS') '_DIVe_GlobalParameter_report.xlsx']);
[nCopyStatus,~] = copyfile(sPathGlobaParamsList,sPathGlobalParamLstCopy);
if nCopyStatus==0
    fprintf(1,'Error:Cannot create a copy of DIVe_GlobalParameter.xlsx list. Script is terminating\n');
    return
else
    %set file attribute as writeable
    fileattrib(sPathGlobalParamLstCopy,'+w');
end

% evaluate local dependent parameter for all global parameters from file 
[nColEnd,cLocalUse] = dstLocalDependentParameterGet(cAllDependenyXmls,sPathGlobalParamLstCopy);
cLocalUse = [{'destinationParameterStruct','LogicalHierarchyUse'};cLocalUse];

% update report file copy
xlswriteActiveXCell(sPathGlobalParamLstCopy,[1,nColEnd],cLocalUse);

% display link to excel sheet
fprintf(1,'<a href="matlab:winopen(''%s'')">Click here to open the report</a>\n',sPathGlobalParamLstCopy);
return

% =========================================================================

function [nColEnd,cLocalUse] = dstLocalDependentParameterGet(cFileXml,sFileGlob)
% DSTLOCALDEPENDENTPARAMETERGET determine the local dependend parameters
% usages of all global parameters listed in the specified
% DIVe_GlobalParameter.xlsx.
%
% Syntax:
%   [nColEnd,cLocalUse] = dstLocalDependentParameterGet(cFileXml,sFileGlob)
%
% Inputs:
%    cFileXml - cell (mx1) with strings of all dependency.xml filepathes
%   sFileGlob - string with filepath of DIVe_GlobalParameter.xlsx
%
% Outputs:
%     nColEnd - integer (1x1) with final used column of DIVe_GlobalParameter.xlsx
%   cLocalUse - cell (mx2) with strings of 
%               {:,1}: local dependent parameter structure 
%               {:,2}: local dependent parameter use in logical hierarchy 
%
% Example: 
%   [nColEnd,cLocalUse] = dstLocalDependentParameterGet(cFileXml,sFileGlob)

% get context level (unique for parsed context)
cPathFile = pathparts(cFileXml{1});
nContext = find(ismember(cPathFile,{'ctrl','phys','bdry','human','pltm'}));

% read all depdency xmls and collect the local dependent parameters
xLocal = struct;
for nIdxFile = 1:numel(cFileXml)
    % determine logical hierarchy of file
    cPathFile = pathparts(cFileXml{nIdxFile});
    sLogHier = fullfile(cPathFile{nContext:end-4});
    
    % read file
    xTree = dsxRead(cFileXml{nIdxFile});
    
    % collect parameters
    if isfield(xTree.Dependency,'LocalParameter') && ...
            ~isempty(xTree.Dependency.LocalParameter)
        xLocalAdd = xTree.Dependency.LocalParameter;
        for nIdxPar = 1:numel(xLocalAdd)
            xLocalAdd(nIdxPar).loghierarchy = sLogHier;
            xLocalAdd(nIdxPar).context = cPathFile{nContext};
            xLocalAdd(nIdxPar).species = cPathFile{nContext+1};
        end
        xLocal = structConcat(xLocal,xLocalAdd);
    end
end

% read content of DIVe_GlobalParameter.xlsx
xParam = dbread(sFileGlob,1);
cGlobalName = xParam.subset.value(1:end,1); % get globalName
nColEnd = numel(xParam.subset.field); % get last filled column

% loop over all global parameters
cLocalUse = cell(numel(cGlobalName),2);
for nIdxParam = 1:numel(cGlobalName)
    % get local dependent parameters of global parameter
    bMatch = strcmp(cGlobalName{nIdxParam},{xLocal.globalName});
    cParThis = arrayfun(@(x)strGlue({'sMP',x.context,x.species,x.name},'.'),...
                        xLocal(bMatch),'UniformOutput',false);
    [cSort,nSort] = unique(cParThis); %#ok<ASGLU>
    cParThis = cParThis(sort(nSort));
                    
    % check for existing non-matched entries in "destinationParameterStruct" 
    cExist = strsplitOwn(xParam.subset.value{nIdxParam,end},';');
    bDouble = ismember(cParThis,cExist);
    cParStruct = [cExist;cParThis(~bDouble)'];
    [cSort,nSort] = unique(cParStruct); %#ok<ASGLU>
    cParStruct = cParStruct(sort(nSort));
    cLogHier = {xLocal(bMatch).loghierarchy};
    [cSort,nSort] = unique(cLogHier); %#ok<ASGLU>
    cLogHier = cLogHier(sort(nSort));
    cLocalUse{nIdxParam,1} = strGlue(cParStruct,';');
    cLocalUse{nIdxParam,2} = strGlue(cLogHier,',');
end
return

% =========================================================================

function cPath = sdmGetAllDependenyXmls(sPath)
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

% sPath='C:\Backup\DIVe_space\05_DIVeGUI\sysDMgui\sysDMGUIdevelopment\phys\eng\detail\gtfrm'

% initialize output
cPath = {};

% get directories in current folder
cFolder = dirPattern(sPath,'*','folder');

% determine type
bNext = false(1,numel(cFolder));
for nIdxFolder = 1:numel(cFolder)
    switch cFolder{nIdxFolder}
        case 'Data'
            cDataFolder = dirPattern(fullfile(sPath,cFolder{nIdxFolder}),'*','folder');
            cDataFolder = cellfun(@(x)fullfile(sPath,cFolder{nIdxFolder},x),cDataFolder,'UniformOutput',false);
            %get only depenedentParameter dataset
            cOnlyDepFolder = cellfun(@(x) regexp(x,'dependentParameter','match'),cDataFolder,'UniformOutput',false);
            cOnlyDepFolder= cDataFolder(cellfun(@(x) ~isempty(x),cOnlyDepFolder,'UniformOutput',true));
            %if dependentParameter folder exists
            if ~isempty(cOnlyDepFolder)
            %get depedendentParameter dataset variant
                cDataVarFolder = dirPattern(cOnlyDepFolder{1},'*','folder');
                cAdd= {};
                for nEachVar=1:numel(cDataVarFolder)
                    cAllXMLs = dirPattern(fullfile(cOnlyDepFolder{1},cDataVarFolder{nEachVar}),'dependency.xml','file');
                    cAllXMLPaths = cellfun(@(x) fullfile(cOnlyDepFolder{1},cDataVarFolder{nEachVar},x),cAllXMLs,'UniformOutput',false);
                    cAdd = [cAdd cAllXMLPaths]; %#ok<AGROW>
                end
                cPath = [cPath cAdd]; %#ok<AGROW>
            end
        otherwise
            bNext(nIdxFolder) = true;
    end
end
cNext = cFolder(bNext);
cNext = cellfun(@(x)fullfile(sPath,x),cNext,'UniformOutput',false);

% proceed to next level
for nIdxNext = 1:numel(cNext)
    cAdd = sdmGetAllDependenyXmls(cNext{nIdxNext});
    cPath = [cPath cAdd]; %#ok<AGROW>
end
return

% =========================================================================

function xlswriteActiveXCell(sFile,nStart,cContent)
% XLSWRITEACTIVEXCELL write a cell to the first Excel sheet of an Excel
% file with defined start location of the cell content.
%
% Syntax:
%   xlswriteActiveXCell(sFile,nStart,cContent)
%
% Inputs:
%      sFile - string with filepath of Excel to be changed
%     nStart - integer (1x2) with start index of content write (row,column)
%   cContent - cell (mxn) with content to be written
%
% Outputs:
%
% Example: 
%   xlswriteActiveXCell(sFile,nStart,cContent)
%   xlswriteActiveXCell(fullfile(pwd,'SomeExcel.xlsx'),[2 3],{'asd','bla','blubblublub';1,2,3})

%use actxserver instead of xlswriter for speed
oExcel = actxserver('Excel.Application');
oWorkbook = oExcel.workbooks.Open(sFile);
if oWorkbook.ReadOnly ~= 0
    %This means the file is probably open in another process.
    error('MATLAB:xlswrite:LockedFile', ['The file %s is not writable. It ' ...
            'may be locked by another process.'], sPathSignalLstCopy);
end
oSheets = oExcel.ActiveWorkbook.Sheets;
oSheet1 = oSheets.get('Item',1);
oSheet1.Activate;

% write cell columnwise
for nIdxColumn = 1:size(cContent,2)
    nColWrite = nStart(2) + nIdxColumn - 1;
    sColWrite =  xlColumnLetter(nColWrite);
    
    % loop over rows
    for nIdxRow = 1:size(cContent,1)
        nRowWrite = nStart(1) + nIdxRow - 1;
        oActiveRange = get(oExcel.Activesheet,'Range',strcat(sColWrite,num2str(nRowWrite)));
        if isempty(cContent{nIdxRow,nIdxColumn})
            oActiveRange.Value = '';
        else
            oActiveRange.Value = cContent{nIdxRow,nIdxColumn};
        end
    end
    
    % resize column 
    oActiveRange.cells.EntireColumn.AutoFit();
end

% save and close workbook
oWorkbook.Save;
Close(oWorkbook);
delete(oExcel); % release ActiveX object
return

% =========================================================================

function sColLetter = xlColumnLetter(nColNumber)
% XLCOLUMNLETTER returns the letter combination that corresponds to a given
% column number to be used in Excel.
%
% Syntax:
%   sColLetter = xlColumnLetter(nColNumber)
%
% Inputs:
%   nColNumber - integer (1x1) of column number
%
% Outputs:
%   sColLetter - string which denotes nth column in Excel
%
% Example: 
%   sColLetter = xlColumnLetter(1)  % returns 'A'
%   sColLetter = xlColumnLetter(3)  % returns 'C'
%   sColLetter = xlColumnLetter(87) % returns 'CI'

if( nColNumber > 26*27 )
    error('XLCOLUMNLETTER: Requested column number is larger than 702.');
else
    % Start with A-Z letters
    sAtoZ = char(65:90)';
    % Single character columns are first
    cSingleChar = cellstr(sAtoZ);
    % Calculate all combinations
    lAlphaIdx = (1:26)';
    [mGrid1,mGrid2] = ndgrid(lAlphaIdx,lAlphaIdx);
    mAllCombination = reshape(cat(3,mGrid2,mGrid1),[],2);      
    cDoubleChar  = cellstr(sAtoZ(mAllCombination));
    % Concatenate
    xlLetters = [cSingleChar;cDoubleChar];
    % Return requested column
    sColLetter = xlLetters{nColNumber};
end
return
