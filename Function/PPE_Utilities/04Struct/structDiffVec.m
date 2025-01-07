function [xBaseDiff,xNewDiff,cBaseXor,cNewXor] = structDiffVec(xBase,xNew,nOutput) 
% STRUCTDIFFVEC gives the difference between two structures. Explicitly
% also for structure vectors.
% WORKS CURRENTLY ONLY ON CHAR VALUES OF FIELDS!
%
% Syntax:
%   [xBaseDiff,xNewDiff,cBaseXor,cNewXor] = structDiffVec(xBase,xNew)
%   [xBaseDiff,xNewDiff,cBaseXor,cNewXor] = structDiffVec(xBase,xNew,nOutput)
%
% Inputs:
%   xBase - structure with one level of fields
%    xNew - structure with one level of fields, to be compared to values of
%           base fields
% nOutput - integer, if output shall be displayed on command window
%
% Outputs:
%   xBaseDiff - structure (1xn) elements which in at least one field 
%    xNewDiff - structure (1xn) elements which in at least one field 
%    cBaseXor - cell with fields of xBase not in xNew
%     cNewXor - cell with fields of xNew not in xBase
%
% Example: 
%   structDiffVec(struct('a',{'aa','bb'},'b',{'aa','bc'},'c',{'aa','ae'}),struct('b',{'bb','bc'},'c',{'z','ae'},'d',{'cc','dd'}))
%   [xBaseDiff,xNewDiff,xBaseXor,xNewXor] = structDiffVec(struct('a',{'aa','bb'},'b',{'aa','bc'},'c',{'aa','ae'}),struct('b',{'bb','bc'},'c',{'z','ae'},'d',{'cc','dd'}))
%
% See also: fieldnames, structAdd, structUpdate, structDiff, structExtract,
% structFind, structDisp
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2021-03-26

% check input 
if isempty(xBase)
    fprintf(1,'First argument structure is empty - stopping diff operation!');
    return
end
if isempty(xNew)
    fprintf(1,'Second argument structure is empty - stopping diff operation!');
    return
end 
if nargin < 3
    if nargout == 0
        nOutput = 1;
    else
        nOutput = 0;
    end
end

% get fieldnames
cBase = fieldnames(xBase);
cNew = fieldnames(xNew);

% check occurence
bBaseInNew = ismember(cBase,cNew);
bNewInBase = ismember(cNew,cBase);
cBoth = cBase(bBaseInNew);
cBaseXor = cBase(~bBaseInNew);
cNewXor = cNew(~bNewInBase);

% check class of values
cClassBothBase = cellfun(@(x)class(xBase(1).(x)),cBoth,'UniformOutput',false);
cClassBothNew = cellfun(@(x)class(xNew(1).(x)),cBoth,'UniformOutput',false);
bClassMatch = strcmp(cClassBothBase,cClassBothNew);
nClassMiss = ~find(bClassMatch);
if ~all(bClassMatch)
    fprintf(1,['Class of field values differ from first struct (of vector) '...
        'of both structures - stopping evaluation!\n'])
    for nIdxMiss = nClassMiss'
        fprintf(1,'   field: %s    1st struct class: %s    2nd struct class: %s\n',...
            cBoth{nIdxMiss},cClassBothBase{nIdxMiss},cClassBothNew{nIdxMiss});
    end
end

% filter class for further evaluation
% bKeep = ismember(cClassBothBase,{'char','double','logical','int8','int16','int32'});
bKeep = ismember(cClassBothBase,{'char'});
cBoth = cBoth(bKeep);

% check unique values in struct vector of single fieldnames
sMsg = '';
for nIdxBoth = 1:numel(cBoth)
    [cValXor,nBaseXor,nNewXor] = setxor({xBase.(cBoth{nIdxBoth})},{xNew.(cBoth{nIdxBoth})}); %#ok<ASGLU>
    if ~isempty(nNewXor)
        sMsg = [sMsg sprintf('Unique value in 1st struct:\n')]; %#ok<AGROW>
    end
    for nIdxEntry = 1:numel(nBaseXor)
        sMsg = [sMsg sprintf('   index: %5.0i  field: %s  value: %s\n',...
            nBaseXor(nIdxEntry),cBoth{nIdxBoth},xBase(nBaseXor(nIdxEntry)).(cBoth{nIdxBoth}))]; %#ok<AGROW>
    end
    if ~isempty(nNewXor)
        sMsg = [sMsg sprintf('Unique value in 2nd struct:\n')]; %#ok<AGROW>
    end
    for nIdxEntry = 1:numel(nNewXor)
        sMsg = [sMsg sprintf('   index: %5.0i  field: %s  value: %s\n',...
            nNewXor(nIdxEntry),cBoth{nIdxBoth},xNew(nNewXor(nIdxEntry)).(cBoth{nIdxBoth}))]; %#ok<AGROW>
    end
end
if ~isempty(sMsg) && nOutput
    fprintf(1,'Unique value check:\n%s\n',sMsg);
end

% check differences in all char value fieldnames of struct vector
cChar = cBoth(strcmp('char',cClassBothBase(bKeep)));
cBaseComb = arrayfun(@(x)strGlue(cellfun(@(y)x.(y),cChar,'UniformOutput',false),'__'),xBase,'UniformOutput',false);
cNewComb = arrayfun(@(x)strGlue(cellfun(@(y)x.(y),cChar,'UniformOutput',false),'__'),xNew,'UniformOutput',false);
[cCombXor,nBaseXor,nNewXor] = setxor(cBaseComb,cNewComb); %#ok<ASGLU>
xBaseDiff = xBase(nBaseXor);
xNewDiff = xNew(nNewXor);

% generate display output
sMsg = '';
if ~isempty(nNewXor)
    sMsg = [sMsg sprintf('Unique char value field combination in 1st struct:\n')]; 
end
for nIdxEntry = 1:numel(nBaseXor)
    sMsg = [sMsg sprintf(' 1st struct x(%i) field values:\n',nBaseXor(nIdxEntry))]; %#ok<AGROW>
    for nIdxField = 1:numel(cChar)
        sMsg = [sMsg sprintf('%s%s: %s\n',...
            repmat(' ',1,max(cellfun(@numel,cChar))+6-numel(cChar{nIdxField})),...
            cChar{nIdxField},xBase(nBaseXor(nIdxEntry)).(cChar{nIdxField}))]; %#ok<AGROW>
    end
end
if ~isempty(nNewXor)
    sMsg = [sMsg sprintf('Unique char value field combination in 2nd struct:\n')]; 
end
for nIdxEntry = 1:numel(nNewXor)
    sMsg = [sMsg sprintf(' 2nd struct x(%i) field values:\n',nNewXor(nIdxEntry))]; %#ok<AGROW>
    for nIdxField = 1:numel(cChar)
        sMsg = [sMsg sprintf('%s%s: %s\n',...
            repmat(' ',1,max(cellfun(@numel,cChar))+6-numel(cChar{nIdxField})),...
            cChar{nIdxField},xNew(nNewXor(nIdxEntry)).(cChar{nIdxField}))]; %#ok<AGROW>
    end
end
if ~isempty(sMsg) && nOutput
    fprintf(1,'Unique value check:\n%s\n',sMsg);
end
return
