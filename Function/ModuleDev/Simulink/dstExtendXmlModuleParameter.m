function xModule = dstExtendXmlModuleParameter(cPath,xModule,xParamSfcn,cClass)
% DSTEXTENDXMLMODULEPARAMETER create all parameter entries in a DIVe Module
% XML including the initIO parameter entries.
%
% Syntax:
%   xModule = dstExtendXmlModuleParameter(sPath,xModule) % call from dstXmlModule 
%   dstExtendXmlModuleParameter(sPath) % direct call to update parameter in module XML 
%
% Inputs:
%        cPath - cell with path of module variant folder in file system
%      xModule - structure with fields of a DIVe Module XML
%   xParamSfcn - structure (1xn) with fields: 
%     .name       - string with name of parameter
%     .index      - integer with index of parameter on s-function interface
%     .subspecies - string with subspecies name according sMP struct string
%                   on DIVe wrapper block mask
%
% Outputs:
%   xModule - structure with fields of a DIVe Module XML
%
% Example: 
%   xModule = dstExtendXmlModuleParameter(sPath,xModule)
%
% Subfunctions: dstParamDataSetDetermination, dstParamSfcnDetermination
%
% See also: dirPattern, dpsLoadStandardFile, dpsParameterSize, ismdl,
% strGlue, strsplitOwn, structUnify, uiopen
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2016-08-12

% check input
if ischar(cPath)
    % split module path
    cPath = pathparts(cPath);
end
% fix specification depth of path
nModule = find(strcmp('Module',cPath));
cPath = cPath(1:nModule+1);
% ensure Module XML availability
if nargin < 2
    xTree = dsxRead(fullfile(cPath{:},[cPath{end} '.xml']));
    xModule = xTree.Module;
    if isfield(xModule.Interface,'Parameter')
        xModule.Interface = rmfield(xModule.Interface,'Parameter');
    end
end
if nargin < 3
    % determine parameter indices for s-functions from base model
    sFolderSfcn = dstFolderMatlabVersionNext(dirPattern(fullfile(cPath{:}),'*','folder'));
    cFileMdl = dirPattern(fullfile(cPath{:},sFolderSfcn),'\w+\.mdl$|\w+\.slx$','file',true);
    [cInport,cOutport,xParamSfcn] = dstModuleSfcnParse(fullfile(cPath{:},sFolderSfcn,cFileMdl{1})); %#ok<ASGLU>
end
cParamSfcn = {xParamSfcn.name};
cParamSfcnSubspecies = {xParamSfcn.subspecies};

% get parameters from DataSet classTypes
xVariableClass = dstClassDataParameterGet(xModule,cPath);
% apply classType -> className alias and expansion on class variables
xVariableClass = dstSubspeciesVariableExpansion(xVariableClass,cClass);

% create Module XML parameter entries of initIO
xParameterIO = dstParameterInitIOGet(xModule.Interface);
% create Module XML parameter entries from DataSet parameter/variables
xParameterClass = dstParameterFromClassParamCreate(xVariableClass);
% combine parameters
xParameter = [xParameterIO, xParameterClass];

% match Module XML parameters with parameters of mask/s-function interface -> fill indices
xModule.Interface.Parameter = dstParameterIndexMatch(xParameter,xParamSfcn);

% rewrite module XML, if in update mode
if nargin < 2
    xTree.Module = xModule;
    dsxWrite(fullfile(cPath{:},[cPath{end} '.xml']),xTree);
end
return

% =========================================================================

function xParameter = dstParameterInitIOGet(xInterface)
% DSTPARAMETERINITIOGET creates all parameters for DIVe Module XML which are derived from initIO
% initial values for in- and outports.
%
% Syntax:
%   xParameter = dstParameterInitIOGet(xInterface)
%
% Inputs:
%   xInterface - structure with fields: 
%    .Inport - structure with fields: 
%     .name - string with port name
%     .unit - string with port unit
%     .manualDescription - string with manual description of port
%    .Outport - structure with fields: 
%     .name - string with port name
%     .unit - string with port unit
%     .manualDescription - string with manual description of port
%
% Outputs:
%   xParameter - structure with fields: 
%    .name  - string with port name
%    .index - string (empty here, filled later) with parameter index on s-function interface
%    .size  - string with parameter variable size information
%    .unit  - string with port unit
%    .description - string with manual description of port
%    .className   - string with DataSet className which create the parameter
%
% Example: 
%   xInterface.Inport = struct('name',{'in1','in2','in3'},'unit',{'kg','m²','-'},'manualDescription',{'some bla','more bla','no bla'})
%   xInterface.Outport = struct('name',{'out1','out2','out3'},'unit',{'kg','m²','-'},'manualDescription',{'some bla','more bla','no bla'})
%   xParameter = dstParameterInitIOGet(xInterface)

% intialize empty parameter structure
xParamEmpty = structInit('name','index','size','unit','description','className');

% create parameter structures
if isfield(xInterface,'Inport') && ~isempty(xInterface.Inport)
    xParamInport = dstParameterFromPortCreate(xInterface.Inport);
else
    xParamInport = xParamEmpty;
end
if isfield(xInterface,'Outport') && ~isempty(xInterface.Outport)
    xParamOutport = dstParameterFromPortCreate(xInterface.Outport);
else
    xParamOutport = xParamEmpty;
end

% combine parameters from inport and outport intialization
xParameter = [xParamInport, xParamOutport];
return

% =========================================================================

function xParameter = dstParameterFromPortCreate(xPort)
% DSTPARAMETERFROMPORTCREATE create parameter structure entries by DIVe Module XML port structures.
%
% Syntax:
%   xParameter = dstParameterFromPortCreate(xPort)
%
% Inputs:
%   xPort - structure with fields: 
%    .name - string with port name
%    .unit - string with port unit
%    .manualDescription - string with manual description of port
%
% Outputs:
%   xParameter - structure with fields: 
%    .name  - string with port name
%    .index - string (empty here, filled later) with parameter index on s-function interface
%    .size  - string with parameter variable size information
%    .unit  - string with port unit
%    .description - string with manual description of port
%    .className   - string with DataSet className which create the parameter
%
% Example: 
%   xPort = struct('name',{'par1','par2','par3'},'unit',{'kg','m²','-'},'manualDescription',{'some bla','more bla','no bla'})
%   xParameter = dstParameterFromPortCreate(xPort)

xParameter = struct('name',{xPort.name},...
                    'index',repmat({''},1,numel(xPort)),...
                    'unit',{xPort.unit},...
                    'size',repmat({'1'},1,numel(xPort)),...
                    'description',{xPort.manualDescription},...
                    'className',repmat({'initIO'},1,numel(xPort)));
return

% =========================================================================

function xParameter = dstParameterFromClassParamCreate(xVariableClass)
% DSTPARAMETERFROMCLASSPARAMCREATE create structure of parameters from variables defined in DIVe
% isStandard DataSets.
%
% Syntax:
%   xParameter = dstParameterFromClassParamCreate(xVariableClass)
%
% Inputs:
%   xVariableClass    - structure vector with fields: 
%     .name       - string with vaiable name
%     .size       - string with vaiable value size information
%     .className  - string with className of the containing dataset
%
% Outputs:
%   xParameter - structure with fields: 
%    .name  - string with port name
%    .index - string (empty here, filled later) with parameter index on s-function interface
%    .size  - string with parameter variable size information
%    .unit  - string with port unit
%    .description - string with manual description of port
%    .className   - string with DataSet className which create the parameter
%
% Example: 
%   xVariableClass = struct('name',{'par1','par2','par3'},'size',{'1','2,:','3,3'},'className',{'classA','classA','classB'})
%   xParameter = dstParameterFromClassParamCreate(xVariableClass)

if isempty(xVariableClass)
    xParameter = structInit('name','index','size','unit','description','className');
else
    xParameter = struct('name',{xVariableClass.name},...
                        'index',repmat({''},1,numel(xVariableClass)),...
                        'unit',repmat({''},1,numel(xVariableClass)),...
                        'size',{xVariableClass.size},...
                        'description',repmat({''},1,numel(xVariableClass)),...
                        'className',{xVariableClass.className});
end
return

% =========================================================================

function xVariable = dstSubspeciesVariableExpansion(xVariable,cClass)
% DSTSUBSPECIESVARIABLEEXPANSION expand variables/parameters of DataSet classType to
% classType/className expansion by SupportSet subspecies definition.
%
% Syntax:
%   xVariable = dstSubspeciesVariableExpansion(xVariable,cClass)
%
% Inputs:
%   xVariable     - structure vector with fields: 
%     .name       - string with parmeter name
%     .size       - string with parameter value size information
%     .className  - string with classType of the containing dataset
%   cClass - cell (mx2) with
%             {:,1} string with DataSet classType e.g. 'axle'
%             {:,2} cell of strings with DataSet classNames for this DataSet classType e.g. {'axle1','axle2'}
%
% Outputs:
%   xVariable     - structure vector with fields: 
%     .name       - string with parmeter name
%     .size       - string with parameter value size information
%     .className  - string with className of the containing dataset
%
% Example: 
%   xVariable = dstSubspeciesVariableExpansion(xVariable,cClass)

% loop over class alias definitions
for nIdxClass = 1:size(cClass,1)
    cClassOfVar = {xVariable.className};
    % get vars/params of classType
    bClass = strcmp(cClass{nIdxClass,1},cClassOfVar);
    xVarClass = xVariable(bClass);
    xVariable = xVariable(~bClass);
    
    % add vars/params of classNames
    for nIdxName = 1:numel(cClass{nIdxClass,2})
        xVarName = xVarClass; % copy classType vars/params
        [xVarName.className] = deal(cClass{nIdxClass,2}{nIdxName}); % apply className
        xVariable = [xVariable, xVarName]; %#ok<AGROW> add to vars/params
    end
end
return

% =========================================================================

function xParameter = dstParameterIndexMatch(xParameter,xParamSfcn)

% cases
% var1    sMP.species.var1
% var1__cn1    sMP.species.var1
% var1__cn1    sMP.species.cn1.var1 % isSubspecies = 1
% var1 (initIO) sMP.species.in.var1

%% match Module XML parameter with parameters of mask/s-function interface 
% with respect to subspecies
oParameter = ocKey(xParameter,{'name','className'});
oParamSfcn = ocKey(xParamSfcn,{'name','subspecies'});
[bParSfcn,nIdParam] = ismember(oParamSfcn,oParameter);
nIdParam = nIdParam(bParSfcn);
nIdSfcn = find(bParSfcn);
for nIdxPar = 1:numel(nIdParam)
    xParameter(nIdParam(nIdxPar)).index = num2str(xParamSfcn(nIdSfcn(nIdxPar)).index);
end
xParamSfcn = xParamSfcn(~bParSfcn);

% plain parameter name matching
[bParSfcn,nIdParam] = ismember({xParamSfcn.name},{xParameter.name});
nIdParam = nIdParam(bParSfcn);
nIdSfcn = find(bParSfcn);
for nIdxPar = 1:numel(nIdParam)
    xParameter(nIdParam(nIdxPar)).index = num2str(xParamSfcn(nIdSfcn(nIdxPar)).index);
end
xParamSfcn = xParamSfcn(~bParSfcn);

%% reporting of leftover parameters
% report s-function parameters not covered by isStandard datasets
if ~isempty(xParamSfcn)
    fprintf(1,'Remark: The following parameters of the s-function are not covered in the module''s datasets:\n');
    for nIdxPar = 1:numel(xParamSfcn)
        fprintf(1,'       "%s" (index: %s , subspecies: %s)\n',xParamSfcn(nIdxPar).name,xParamSfcn(nIdxPar).index,xParamSfcn(nIdxPar).subspecies);
    end
end
% report excessive parameters in datasets, which are not in the mask
nIdNoindex = find(cellfun(@isempty,{xParameter.index})&~strcmp('initIO',{xParameter.className}));
if ~isempty(nIdNoindex)
    fprintf(1,'Remark: The following parameters of the DataSets are not used in the module''s block mask:\n');
    for nIdxPar = nIdNoindex
        fprintf(1,'       "%s" (className: %s)\n',xParameter(nIdxPar).name,xParameter(nIdxPar).className);
    end
end
return

% =========================================================================

function xParameter = dstClassDataParameterGet(xModule,cPath)
% DSTPARAMDATASETDETERMINATION determine parameter of all specified
% datasets, which are in 'isStandard'-files.
%
% Syntax:
%   xParameter = dstParamDataSetDetermination(xDataClass,cPath)
%
% Inputs:
%   xModule - structure with DIVe module XML content except
%             Interface.Parameter entries  
%             Interface.DataSet - structure ... according DIVe spec
%     cPath - cell (1xn) with strings containing each one level of the 
%             module directory path
%
% Outputs:
%   xParameter    - structure vector with fields: 
%     .name       - string with parmeter name
%     .size       - string with parameter value size information
%     .className  - string with className of the containing dataset
%
% Example: 
%   xParameter = dstParamDataSetDetermination(xDataClass,cPath)

% initializte output
xParameter = struct('name',{},'size',{},'className',{});

% determine parameters of non-initIO datasets
bInitIO = strcmp('initIO',{xModule.Interface.DataSet.classType});
for nIdxSet = find(~bInitIO)
    % determine file system path of data class
    switch xModule.Interface.DataSet(nIdxSet).level
        case 'species'
            nlevel = 0;
        case 'family'
            nlevel = 1;
        case 'type'
            nlevel = 2;
        otherwise
            error(['Unknown DataSet attribute level="' xModule.Interface.DataSet(nIdxSet).level...
                '" in DataSet "' xModule.Interface.DataSet(nIdxSet).className '" of module "' ...
                strGlue({xModule.context,xModule.species,xModule.family,xModule.type,...
                'Module',xModule.name},'.') '"!']);
    end
    sPathClass = fullfile(cPath{1:end-4+nlevel},'Data',xModule.Interface.DataSet(nIdxSet).classType);
    
    % get XML of reference dataset
    sReference = xModule.Interface.DataSet(nIdxSet).reference;
    sPathDataXml = fullfile(sPathClass,sReference,[sReference,'.xml']);
    if exist(sPathDataXml,'file')~=2
        % take first available dataset
       cDataSet = dirPattern(sPathClass,'*','folder');
       sPathDataXml = fullfile(sPathClass,cDataSet{1},[cDataSet{1},'.xml']);
    end
    xTree = dsxRead(sPathDataXml);
    
    % load standard data files
    xData = struct;
    for nIdxFile = find(str2num(strGlue({xTree.DataSet.DataFile.isStandard},','))) %#ok<ST2NM> 
        xDataAdd = dpsLoadStandardFile(fullfile(sPathClass,...
            xTree.DataSet.name,xTree.DataSet.DataFile(nIdxFile).name));
        xData = structUnify(xData,xDataAdd);
    end
    
    % generate parameter structure with information
    cParameter = fieldnames(xData);
    for nIdxParameter = 1:numel(cParameter)
        xParameter(end+1).name = cParameter{nIdxParameter}; %#ok<AGROW>
        xParameter(end).size = dpsParameterSize(xData.(cParameter{nIdxParameter}));
        xParameter(end).className = xModule.Interface.DataSet(nIdxSet).className; 
    end
end
return

% =========================================================================

function sFolderSfcn = dstFolderMatlabVersionNext(cModelSet)
% DSTFOLDERMATLABVERSIONNEXT determine s-function ModelSet folder name of
% next matching Matlab version.
%
% Syntax:
%   sFolderSfcn = dstFolderMatlabVersionNext(cModelSet)
%
% Inputs:
%   cModelSet - cell (1xn) with strings of ModelSets
%
% Outputs:
%   sFolderSfcn - string with name of sfcn ModelSet with next matching
%                 Matlab version. Empty if there is no matching version.
%
% Example: 
%   sFolderSfcn = dstFolderMatlabVersionNext({'open','fmu10','sfcn_w32_R2010bSP1','sfcn_w64_R2014a'})

% details of this version
sMatlabBitType = regexprep(computer('arch'),'^win','w'); % returns 'w32' or 'w64'
xVersion = ver('MATLAB');
sMatlabRelease = xVersion.Release(2:end-1); % remove brackets from '(R2010bSP1)'

% determine next matching ModelSet
sVersionThis = ['sfcn_' sMatlabBitType '_' sMatlabRelease];
if any(strcmp(sVersionThis,cModelSet))
    % use this specific MATLAB version
    sFolderSfcn = sVersionThis;
else
    % determine next matching Matlab version of available ModelSet
    % details of ModelSets
    cVersion = regexp(cModelSet,'(?<=^sfcn_w\d+_)R\d{4}\w','match','once');
    cBit = regexp(cModelSet,'(?<=^sfcn_)w\d+(?=_R\d{4}\w)','match','once');
    
    % compare this Version against ModelSets
    cVersionNum = cell(size(cModelSet));
    bUse = false(size(cModelSet));
    for nIdxSet = 1:numel(cModelSet)
        if ~isempty(cVersion{nIdxSet})
            cVersionNum{nIdxSet} = versionAliasMatlab(cVersion{nIdxSet});
            bUse(nIdxSet) = strcmp(cBit{nIdxSet},sMatlabBitType) && ...
                ~verLessThanMATLAB(cVersionNum{nIdxSet});
        end
    end
    
    % take next or failure exit
    if any(bUse)
        % automatically use next matching version
        nUse = find(bUse);
        sFolderSfcn = cModelSet{nUse(1)};
    else
        % no matching version available
        sFolderSfcn = '';
    end
end
return
