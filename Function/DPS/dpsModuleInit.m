function [cPathAdd,cPostExec] = dpsModuleInit(xModule,sPathRunDir,sPathModelLib,...
    sModelBlockPath,cPathDataVariant,cDataClassName,nModelCopy,nDGPSuccess,nDGPFatal)
% DPSMODULEINIT initialization of simple and extended DIVe modules.
% Includes process steps of DIVe spec 0.9.0 with adding paths of modelset
% and supportsets. Copy files of modelset, supportset and datasets. Load
% datasets of attribute isStandard. Execute files of datasets and
% supportsets.
% Part of the DIVe platform standard package (dps).
%
% Syntax:
%   cPathAdd = dpsModuleInit(xModule,sPathRunDir,sPathModelLib,sModelBlockPath,cPathDataVariant,cDataClassName)
%   cPathAdd = dpsModuleInit(xModule,sPathRunDir,sPathModelLib,sModelBlockPath,...
%                     cPathDataVariant,cDataClassName,bModelCopy)
%   cPathAdd = dpsModuleInit(xModule,sPathRunDir,sPathModelLib,sModelBlockPath,...
%                     cPathDataVariant,cDataClassName,bModelCopy,nDGPSuccess,nDGPFatal)
%   [cPathAdd,cPostExec] = dpsModuleInit(xModule,sPathRunDir,sPathModelLib,sModelBlockPath,...
%                     cPathDataVariant,cDataClassName,bModelCopy,nDGPSuccess,nDGPFatal)
%
% Inputs:
%            xModule - structure with fields of DIVe module XML 
%        sPathRunDir - string with path of simulation run directory
%      sPathModelLib - string with path of model library file
%    sModelBlockPath - string Simulink model path of block in main model
%                      (main model is already loaded)
%   cPathDataVariant - cell (1xn) with folder paths of selected data
%                      variants
%     cDataClassName - cell (1xn) with dataset className in same size and
%                      order as cPathDataVariant
%         nModelCopy - integer for Simulink model block copy operation to
%                      specified destination
%                       0: no copy
%                       1: DIVe MB style
%         nDGPSuccess - integer (1x1) with flag for display of successful
%                       overwrite local dependent parameter global parameter
%                         0: no success messages
%                         1: print success messages
%           nDGPFatal - integer (1x1) with flag if warning/error messages 
%                       should be fatal (use of warning and error functions)
%                         0: non fatal - use fprintf(2,...)
%                         1: fatal - use warning(...) and error(...)
%
% Outputs:
%   cPathAdd - cell (1xn) with paths added to the Matlab path
%   cPostExec - cell (1xn) with filepathes for post processing execution
%
% Example: 
%   cPathAdd = dpsModuleInit(xModule,sPathRunDir,sPathModelLib,sModelBlockPath,cPathDataVariant)
%
% Subfunctions: dpsFileCopy
%
% See also: dpsLoadStandard, dpsPathLevel, dsxRead, pathparts,
% slcBlockReplace, slcLoadEnsure, structUnify
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-8485-3325
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2015-09-07

% initialize output
cPathAdd = {};
cPostExec = {};

% check input
if nargin < 7
    nModelCopy = 1;
end
if nargin < 8
    nDGPSuccess = 1;
end
if nargin < 9
    nDGPFatal = 0;
end
sPathModelSet = fileparts(sPathModelLib);
cPathModelSet = pathparts(sPathModelSet);
if ~strcmp(cPathModelSet{end-2},'Module')
    error('dpsModuleInit:invalidFileSystem',['The specified Module''s '...
          'ModelSet Library is not in a correct location below a "Module" '...
          'folder ("' cPathModelSet{end-2} '" instead of "Module"): ' ...
          sPathModelLib]);
end
[sPathModule,sModelSet] = fileparts(sPathModelSet);

%% add path of module's ModelSet
cPathAdd = [cPathAdd {sPathModelSet}];
addpath(sPathModelSet);

%% add path of module's SupportSets
if isfield(xModule.Implementation,'SupportSet') && ...
        ~isempty(xModule.Implementation.SupportSet)
    for nIdxSet = 1:numel(xModule.Implementation.SupportSet)
        % get support set path
        xSet = xModule.Implementation.SupportSet(nIdxSet);
        sPathSet = fullfile(dpsPathLevel(sPathModule,xSet.level),'Support',xSet.name);
        
        % check and add path
        if exist(sPathSet,'dir')
            cPathAdd = [cPathAdd {sPathSet}]; %#ok<*AGROW>
            addpath(sPathSet);
        else
            error('dpsModuleInit:invalidSupportSetPath',['The support set '...
                  'path derived from module file system path and module '...
                  'XML info of support sets does not exist in the file '...
                  'system (support set index ' num2str(nIdxSet) '): ' sPathSet]);
        end
    end
end

%% build list for files of ModelSet 
cModelFileCopy = {};
[bTF,nIdSet] = ismember(sModelSet,{xModule.Implementation.ModelSet.type}); %#ok<*ASGLU>
for nIdxFile = 1:numel(xModule.Implementation.ModelSet(nIdSet).ModelFile)
    % if file needs copy operation
    if strcmp('1',xModule.Implementation.ModelSet(nIdSet).ModelFile(nIdxFile).copyToRunDirectory)
        % get file path to copy
        sFilePath = fullfile(sPathModelSet,xModule.Implementation.ModelSet(nIdSet).ModelFile(nIdxFile).name);
        cModelFileCopy = [cModelFileCopy sFilePath];
    end
end

%% build list for files of SupportSet 
cSupportFileCopy = {};
cSupportFileExecute = {};
if isfield(xModule.Implementation,'SupportSet') && ...
        ~isempty(xModule.Implementation.SupportSet)
    for nIdxSet = 1:numel(xModule.Implementation.SupportSet)
        % load support set XML
        xSet = xModule.Implementation.SupportSet(nIdxSet);
        sPathSupportSet = fullfile(dpsPathLevel(sPathModule,xSet.level),'Support',xSet.name);
        xSupport = dsxRead(fullfile(sPathSupportSet,[xSet.name '.xml']));
        xSet = xSupport.SupportSet;
            
        for nIdxFile = 1:numel(xSet.SupportFile)
            % get file path to copy
            sFilePath = fullfile(sPathSupportSet,xSet.SupportFile(nIdxFile).name);
            
            % if file needs copy operation
            if strcmp('1',xSet.SupportFile(nIdxFile).copyToRunDirectory)
                cSupportFileCopy = [cSupportFileCopy {sFilePath}]; % add to copy cell
            end
            
            % if file requires execution
            if strcmp('1',xSet.SupportFile(nIdxFile).executeAtInit)
                cSupportFileExecute = [cSupportFileExecute {sFilePath}]; % add to execute cell
            end
        end % for file
    end % for set
end % if support set exists

%% build list for files of DataSet and global/dependent parameters
cPathDataXml = {}; % list of dataset variant XML file locations
cClassName = {}; % list of dataset classNames 
cXmlDataContent = cell(1,numel(cPathDataVariant)-1); % array with dataset variants' XML content
cDataFileCopy = {}; % list of datafiles for copy operation
cDataFileExecute = {}; % list of datafiles to execute
cDependentParameterFile = {}; % list of datafiles with dependent parameter infos
% for all specified data variants
for nIdxSet = 1:numel(cPathDataVariant)
    % exempt initIO datset
    [sRest,sDataVariant] = fileparts(cPathDataVariant{nIdxSet});
    [sRest,sDataClass] = fileparts(sRest);
    sPathDataXml = fullfile(cPathDataVariant{nIdxSet},[sDataVariant,'.xml']);
    if strcmp(sDataClass,'dependentParameter')
        % get global/dependent parameter entries from file
        cDependentParameterFile = [cDependentParameterFile ...
            {fullfile(cPathDataVariant{nIdxSet},'dependency.xml')}];
        
    elseif ~strcmp(sDataClass,'initIO')
        % get dataset XML content
        cPathDataXml = [cPathDataXml {sPathDataXml}];
        cClassName = [cClassName cDataClassName{nIdxSet}];
        xTree = dsxRead(sPathDataXml);
        cXmlDataContent{numel(cPathDataXml)} = xTree;
        
        % for all data files
        for nIdxFile = 1:numel(xTree.DataSet.DataFile)
            % check for copy files
            if strcmp('1',xTree.DataSet.DataFile(nIdxFile).copyToRunDirectory)
                sFilePath = fullfile(cPathDataVariant{nIdxSet},xTree.DataSet.DataFile(nIdxFile).name);
                cDataFileCopy = [cDataFileCopy {sFilePath}];
            end
            
            % check for execute files
            if strcmp('1',xTree.DataSet.DataFile(nIdxFile).executeAtInit) 
                sFilePath = fullfile(cPathDataVariant{nIdxSet},xTree.DataSet.DataFile(nIdxFile).name);
                if (strcmp(xModule.context,'pltm') && strcmp(xModule.species,'post')) 
                    cPostExec = [cPostExec {sFilePath}];
                else % exempt pltm.post DataSet Files from execution
                    cDataFileExecute = [cDataFileExecute {sFilePath}];
                end
            end
        end
    end
end % for each dataset

%% copy necessary files
dpsFileCopy(cModelFileCopy,sPathRunDir);
dpsFileCopy(cSupportFileCopy,sPathRunDir);
dpsFileCopy(cDataFileCopy,sPathRunDir);

%% copy Simulink library block to main model
[sPathLib,sFileLib,sExtLib] = fileparts(sPathModelLib);
switch nModelCopy
    case 1
        if ismember(sExtLib,{'.mdl','.slx'})
            % load library
            slcLoadEnsure(sPathModelLib)
            
            % determine model block in library
            cBlockMask = find_system(sFileLib,'FollowLinks','on','SearchDepth',1,'BlockType','SubSystem','Mask','on');
            if isempty(cBlockMask)
                cBlockMask = find_system(sFileLib,'FollowLinks','on','SearchDepth',1,'BlockType','SubSystem');
                if isempty(cBlockMask)
                    cBlockMask = find_system(sFileLib,'FollowLinks','on','SearchDepth',1,'BlockType','S-Function');
                end
            end
            sBlockMask = cBlockMask{1};
            
            % replace block
            slcBlockReplace(sBlockMask,sModelBlockPath)
        end
    otherwise
        % no copy operation requested
end

%% load data files with isStandard = 1
xData = struct;
for nIdxFile = 1:numel(cPathDataXml)
    % check for subsystem status
    bSubspecies = false;
    if isfield(xModule.Interface,'DataSet')
        bClass = strcmp(cClassName{nIdxFile},{xModule.Interface.DataSet.className});
        if any(bClass)
            bSubspecies = str2double({xModule.Interface.DataSet(bClass).isSubspecies});
        end
    end
    
    % load dataset content into structure
    if bSubspecies
        xDataAdd.(cClassName{nIdxFile}) = dpsLoadStandard(cPathDataXml{nIdxFile},...
                                                              cXmlDataContent{nIdxFile});
    else
        xDataAdd = dpsLoadStandard(cPathDataXml{nIdxFile},...
                                   cXmlDataContent{nIdxFile});
    end
    xData = structUnify(xData,xDataAdd);
    xDataAdd = struct();
end

% create dataset in base workspace
if evalin('base','exist(''sMP'',''var'')')
    sMP = evalin('base','sMP');
end
if exist('sMP','var') && ...
        isfield(sMP,xModule.context) && ...
        isfield(sMP.(xModule.context),xModule.species)
    sMP.(xModule.context).(xModule.species) = structUnify(sMP.(xModule.context).(xModule.species),xData);
else
    sMP.(xModule.context).(xModule.species) = xData;
end
assignin('base','sMP',sMP);

%% execute all data files with executeAtInit = 1
for nIdxFile = 1:numel(cDataFileExecute)
    [sTrash,sName,sExt] = fileparts(cDataFileExecute{nIdxFile});
    if any(strcmp(sExt,{'.m','.p'}))
        evalin('base',['run(''' cDataFileExecute{nIdxFile} ''');']);
    else
        fprintf(1,['dpsModuleInit - the following DataFile is marked as "executeAtInit" ' ...
            'but has no allowed file extension (.m, .p): %s\n'],cDataFileExecute{nIdxFile});
    end
end

%% get global/dependent parameter entries from ddependency.xml files
xGlobal = structInit({'parameter','subspecies','name','description',...
    'dimension','minimum','maximum','unit'});
xDependent = structInit({'name','description','dimension','minimum',...
    'maximum','unit','subspecies','global'});
for nIdxFile = 1:numel(cDependentParameterFile)
    % read depdency XML
    xTree = dsxRead(cDependentParameterFile{nIdxFile});
    % add global parameters to struct
    if isfield(xTree,'Dependency') && ...
            isfield(xTree.Dependency,'GlobalParameter') && ...
            ~isempty(xTree.Dependency.GlobalParameter)
        xGlobal = structConcat(xGlobal,xTree.Dependency.GlobalParameter);
    end
    % add local dependent parameters
    if isfield(xTree,'Dependency') && ...
            isfield(xTree.Dependency,'LocalParameter') && ...
            ~isempty(xTree.Dependency.LocalParameter)
        xDependent = structConcat(xDependent,xTree.Dependency.LocalParameter);
    end
end

%% set local dependent parameters
dpsDependentParameterSet(xModule,xDependent,nDGPSuccess,nDGPFatal);

%% execute all support files with executeAtInit = 1
for nIdxFile = 1:numel(cSupportFileExecute)
    % check for allowed file extension
    [sTrash,sName,sExt] = fileparts(cSupportFileExecute{nIdxFile});
    if ~any(strcmp(sExt,{'.m','.p'}))
        fprintf(1,['dpsModuleInit - the following SupportFile is marked as "executeAtInit" ' ...
            'but has no allowed file extension (.m, .p): %s\n'],cSupportFileExecute{nIdxFile});
        continue
    end
    
    % feval filename - file should be on top of Matlab path due to adding
    % of support folders to Matlab path
    [sPath,sFile] = fileparts(cSupportFileExecute{nIdxFile});
    if nargout(sFile) < 1
        %call function without output
        feval(sFile,...
            'sPathRunDir',sPathRunDir,...
            'sPathModelLib',sPathModelLib,...
            'sModelBlockPath',sModelBlockPath,...
            'cPathDataVariant',cPathDataVariant);
    else
        % call function with output
        cArgOut = feval(sFile,...
            'sPathRunDir',sPathRunDir,...
            'sPathModelLib',sPathModelLib,...
            'sModelBlockPath',sModelBlockPath,...
            'cPathDataVariant',cPathDataVariant);
        
        % check for new Matlab paths in output argument
        if iscell(cArgOut) && ...
                ~isempty(cArgOut) && ... % not empty
                all(cellfun(@ischar,cArgOut)) % is string cell
            
            % get Matlab path
            ccPath = textscan(path,'%s','delimiter',';');
            
            % check for output arguments equal Matlab path entries
            bInPath = ismember(cArgOut,ccPath{1});
            cPathAdd = [cPathAdd cArgOut(bInPath)];
        end
    end
end

%% set global parameters
dpsGlobalParameterSet(xModule,xGlobal,nDGPSuccess,nDGPFatal);
return

% =========================================================================

function dpsGlobalParameterSet(xModule,xGlobal,nDGPSuccess,nDGPFatal)
% DPSGLOBALPARAMETERSET create the global parameters derived from the local
% source parameters of this module.
%
% Syntax:
%   dpsGlobalParameterSet(xModule,xGlobal)
%   dpsGlobalParameterSet(xModule,xGlobal,nDGPSuccess,nDGPFatal)
%
% Inputs:
%   xModule - structure with fields: 
%   xGlobal - structure with fields: 
%  nDGPSuccess - integer (1x1) with flag for display of successful
%                overwrite local dependent parameter global parameter
%                  0: no success messages
%                  1: print success messages
%    nDGPFatal - integer (1x1) with flag if warning/error messages should
%                be fatal (use of warning and error functions)
%                  0: non fatal - use fprintf(2,...)
%                  1: fatal - use warning(...) and error(...)
%
% Outputs:
%
% Example: 
%   dpsGlobalParameterSet(xModule,xGlobal)

% stop if no global parameters defined for this module
if isempty(xGlobal)
    return
end

% check input
if nargin < 3
    nDGPSuccess = 1;
end
if nargin < 4
    nDGPFatal = 0;
end

% get parameter structure from workspace
sMP = evalin('base','sMP');

% check availability of modules data structure
if ~(isfield(sMP,xModule.context) || ...
        isfield(sMP.(xModule.context),xModule.species))
	% modules parameters are not in sMP
    sMsg = sprintf(['Error GlobalParameters: The sMP structure does not contain parameters ' ...
        'of this module "' strGlue({'sMP',xModule.context,xModule.species},'.') ...
        '" - all local dependent parameters of module "' xModule.species '" are not set!\n']);
    if nDGPFatal == 0
        fprintf(2,'%s',sMsg);
    elseif nDGPFatal == 1
        error('dpsModuleInit:dpsGlobalParameterSet:missingLocStruct',sMsg); %#ok<SPERR>
    end
    return
end

% for all global parameters
for nIdxGlob = 1:numel(xGlobal)
    % catch empty name fields
    if isempty(xGlobal(nIdxGlob).name)
        fprintf(2,['dpsModuleInit:dpsGlobalParameterSet - encountered an empty "name" field for global parameter ' ...
            'with local source parameter "%s" (incomplete entry in dependency.xml).\n' ...
            '        No global parameter is overwritten by local source parameter "%s"!\n'],...
            xGlobal(nIdxGlob).parameter,xGlobal(nIdxGlob).parameter);
        continue
    end
    if isempty(xGlobal(nIdxGlob).parameter)
        fprintf(2,['dpsModuleInit:dpsGlobalParameterSet - encountered an empty "parameter" field for global parameter ' ...
            'with local source parameter "%s" (incomplete entry in dependency.xml).\n' ...
            '        No global parameter is overwritten by local source parameter "%s"!\n'],...
            xGlobal(nIdxGlob).name,xGlobal(nIdxGlob).name);
        continue
    end
    
    % generate string of local source parameter for messages and calls
    sVarField = strGlue({xModule.context,xModule.species,...
        xGlobal(nIdxGlob).subspecies,xGlobal(nIdxGlob).parameter},'.');
    sVarStruct = strGlue({'sMP',sVarField},'.');
    
    % check existence of local parameter
    [bFieldExist,sFieldType] = structFieldExist(sMP,sVarField);
    if ~bFieldExist
        sMsg = sprintf(['Error GlobalParameters: The local source parameter "' sVarStruct ...
            '" is not available in the specified datasets and hence the global ' ...
            'parameter "' ['sMP.global.' xGlobal(nIdxGlob).name] '" cannot be set!\n']);
        if nDGPFatal == 0
            fprintf(2,'%s',sMsg);
        elseif nDGPFatal == 1
            error('dpsModuleInit:dpsGlobalParameterSet:missingLocPar',sMsg); %#ok<SPERR>
        end
        continue
    else
        cVarField = strsplitOwn(sVarField,'.'); % split deep struct string into single fields
        vLocal = getfield(sMP,cVarField{:}); % get value from deep structure
    end
    
    % check availability of global parameter
    if isfield(sMP,'global') && isfield(sMP.global,xGlobal(nIdxGlob).name)
        sMsg = sprintf(['Error GlobalParameters: The global parameter "' ...
            ['sMP.global.' xGlobal(nIdxGlob).name] '" is already available ' ...
            '(but should not be) - initialization is stoppend (rID0065)!\n']);
        fprintf(1,['<a href="matlab:' ...
                   'if isfield(sMP,''global''),sMP = rmfield(sMP,''global'');end">' ...
                   'Remove global variables from sMP structure before restart!</a>\n']);
        if nDGPFatal == 0
            fprintf(2,'%s',sMsg);
        elseif nDGPFatal == 1
            error('dpsModuleInit:dpsGlobalParameterSet:globParExist',sMsg);  %#ok<SPERR>
        end
        continue
    end
    
    % check dimension match
    if ~isempty(xGlobal(nIdxGlob).dimension)
        if strcmp(sFieldType,'numeric')
            % convert string to vector
            if strcmp(xGlobal(nIdxGlob).dimension,'1')
                nSize = [1 1];
            else
                sSize = strrep(xGlobal(nIdxGlob).dimension,',',' ');
                sSize = strrep(sSize,':','Inf');
                nSize = str2num(sSize); %#ok<ST2NM>
            end
            bInf = isinf(nSize); % boolean for infinite identification
            
            % compare size of local source parameter
            nSizeLocal = size(vLocal);
            if numel(nSize) == numel(nSizeLocal)
                bLocal = nSize == nSizeLocal;
                bLocal = bLocal(~bInf);
            else
                bLocal = false;
            end
            if ~all(bLocal)
                sMsg = sprintf(['Warning GlobalParameters: The local source parameter "'  sVarStruct ...
                    '" (size: ' num2str(size(vLocal)) ') does not match the global ' ...
                    'parameter specification size (' sSize ') and hence the global parameter ' ...
                    '"' ['sMP.global.' xGlobal(nIdxGlob).name] '" is not set!\n']);
                if nDGPFatal == 0
                    fprintf(2,'%s',sMsg);
                elseif nDGPFatal == 1
                    warning('dpsModuleInit:dpsGlobalParameterSet:locParSizeMismatch',sMsg); %#ok<SPWRN>
                end
                continue
            end
        elseif strcmp(sFieldType,'struct')
            % do nothing to make CPC & PPC people happy...
        elseif strcmp(sFieldType,'char')
            % do nothing to make CPC & PPC people happy...
        end
    else
        sMsg = sprintf(['Warning GlobalParameters: The local dependent parameter "'  sVarStruct ...
            '" has no size specification or is not numeric, hence the size cannot be checked.\n']);
        if nDGPFatal == 0
            fprintf(2,'%s',sMsg);
        elseif nDGPFatal == 1
            warning('dpsModuleInit:dpsGlobalParameterSet:locParNoSpec',sMsg); %#ok<SPWRN>
        end
    end
    
    % check unit string
    % TODO - how to implement, store unit of global or central check before init Loop?
    
    % get value/minmax info of parameter values for log message
    if strcmp(sFieldType,'struct')
        sValueLocal = '(structure)';
    elseif strcmp(sFieldType,'char')
        sValueLocal = ['(char: "' vLocal '")'];
    elseif max(size(vLocal)) == 1
        sValueLocal = ['(value: ' num2str(vLocal) ')'];
    else
        sSize = num2str(size(vLocal));
        sSize = regexprep(sSize,' +',',');
        sValueLocal = ['(size: (' sSize ') , min: ' num2str(min(min(vLocal))) ...
            ', max: ' num2str(max(max(vLocal))) ')'];
    end
    
    % assign parameter
    sMP.global.(xGlobal(nIdxGlob).name) = vLocal;
    % create log message
    if nDGPSuccess == 1
        fprintf(1,['     GlobalParameters: The global parameter "' ...
            ['sMP.global.' xGlobal(nIdxGlob).name] ...
            '" was generated by the local source parameter "' sVarStruct...
            '" ' sValueLocal '.\n']);
    end
end

% store changed sMP in base workspace
assignin('base','sMP',sMP);
return

% =========================================================================

function dpsDependentParameterSet(xModule,xDependent,nDGPSuccess,nDGPFatal)
% DPSDEPENDENTPARAMETERSET set the local dependent parameters from the
% global parameters in the workspace sMP structure.
%
% Syntax:
%   dpsDependentParameterSet(xModule,xDependent)
%   dpsDependentParameterSet(xModule,xDependent,nDGPSuccess,nDGPFatal)
%
% Inputs:
%      xModule - structure with fields of a DIVe module XML
%   xDependent - structure with fields of dependent parameter:
%     .name        - string with local dependent parameter name
%     .description - string description of global parameter
%     .dimension   - string with dimension of global parameter
%     .minimum     - string with max of global parameter
%     .maximum     - string with min of global parameter
%     .unit        - string with unit of global parameter
%     .subspecies  - string subspecies of local dependent parameter
%     .global      - string with name of global parameter
%  nDGPSuccess - integer (1x1) with flag for display of successful
%                overwrite local dependent parameter global parameter
%                  0: no success messages
%                  1: print success messages
%    nDGPFatal - integer (1x1) with flag if warning/error messages should
%                be fatal (use of warning and error functions)
%                  0: non fatal - use fprintf(2,...)
%                  1: fatal - use warning(...) and error(...)
%
% Outputs:
%
% Example: 
%   dpsDependentParameterSet(xModule,xDependent,nDGPSuccess,nDGPFatal)

% stop if no dependent parameters defined for this module
if isempty(xDependent)
    return
end

% check input
if nargin < 3
    nDGPSuccess = 1;
end
if nargin < 4
    nDGPFatal = 0;
end

% get parameter structure from workspace
sMP = evalin('base','sMP');

% check availability of modules data structure
if ~(isfield(sMP,xModule.context) || ...
        isfield(sMP.(xModule.context),xModule.species))
	% modules parameters are not in sMP
    sMsg = sprintf(['Error GlobalParameters: The sMP structure does not contain parameters ' ...
        'of this module "' strGlue({'sMP',xModule.context,xModule.species},'.') ...
        '" - all local dependent parameters of module "' xModule.species '" are not set!\n']);
    if nDGPFatal == 0
        fprintf(2,'%s',sMsg);
    elseif nDGPFatal == 1
        error('dpsModuleInit:dpsDependentParameterSet:missingLocPar',sMsg); %#ok<SPERR>
    end
    return
end

% check availability of global parameters
if ~isfield(sMP,'global') 
    if ~isfield(xDependent,'optionalRead') || any(strcmp('0',{xDependent.optionalRead}))
        % no global parameters available
        sMsg = sprintf(['Warning GlobalParameters: The sMP structure does not contain ' ...
            'global parameters - all local dependent parameters of module "' ...
            xModule.species '" are not set!\n']);
        if nDGPFatal == 0
            fprintf(2,'%s',sMsg);
        elseif nDGPFatal == 1
            warning('dpsModuleInit:dpsDependentParameterSet:missingGlobStruct',sMsg); %#ok<SPWRN>
        end
    end
    return
end

% for all local dependent parameters
for nIdxDep = 1:numel(xDependent)
    % catch empty name fields
    if isempty(xDependent(nIdxDep).name)
        fprintf(2,['dpsModuleInit:dpsDependenParameterSet - encountered an empty "name" field with ' ...
                   'global parameter "%s" (incomplete entry in dependency.xml).\n' ...
                   '        No local parameter is overwritten by global parameter "%s"!\n'],...
                   xDependent(nIdxDep).globalName,xDependent(nIdxDep).globalName);
        continue
    end
    if isempty(xDependent(nIdxDep).globalName)
        fprintf(2,['dpsModuleInit:dpsDependenParameterSet - encountered an empty "globalName" field with ' ...
                   'local parameter "%s" (incomplete entry in dependency.xml).\n' ...
                   '        No local parameter "%s" is overwritten by global parameter!\n'],...
                   xDependent(nIdxDep).name,xDependent(nIdxDep).name);
        continue
    end
    
    % generate strings of local dependent parameter struct for messages and calls
    sVarField = strGlue({xModule.context,xModule.species,...
        xDependent(nIdxDep).subspecies,xDependent(nIdxDep).name},'.');
    sVarStruct = strGlue({'sMP',sVarField},'.');
    
    % check existence of local parameter
    [bFieldExist,sFieldType] = structFieldExist(sMP,sVarField);
    if ~bFieldExist
        sMsg = sprintf(['Error GlobalParameters: The local dependent parameter "' sVarStruct ...
            '" is not available in the specified datasets and hence is not set by ' ...
            'the global parameter "' ['sMP.global.' xDependent(nIdxDep).globalName] '"!\n']);
        if nDGPFatal == 0
            fprintf(2,'%s',sMsg);
        elseif nDGPFatal == 1
            error('dpsModuleInit:dpsDependentParameterSet:missingLocPar',sMsg); %#ok<SPERR>
        end
        continue
    else
        cVarField = strsplitOwn(sVarField,'.'); % split deep struct string into single fields
        vLocal = getfield(sMP,cVarField{:}); % get value from deep structure
    end
    
    % check availability of global parameter
    if ~isfield(sMP.global,xDependent(nIdxDep).globalName) 
        if isfield(xDependent,'optionalRead') && ... % extension due to rID0065
                strcmp(xDependent(nIdxDep).optionalRead,'0')
            sMsg = sprintf(['Warning GlobalParameters: The global parameter "' ...
                ['sMP.global.' xDependent(nIdxDep).globalName] ...
                '" is not available and hence the local dependent parameter "' ...
                sVarStruct '" is not overwritten!\n']);
            if nDGPFatal == 0
                fprintf(2,'%s',sMsg);
            elseif nDGPFatal == 1
                warning('dpsModuleInit:dpsDependentParameterSet:missingGlobPar',sMsg); %#ok<SPWRN>
            end
        end
        continue
    end
    
    % check dimension match
    if ~isempty(xDependent(nIdxDep).dimension)
        if strcmp(sFieldType,'numeric') && ...
            ~isempty(vLocal)
            % convert string to vector
            if strcmp(xDependent(nIdxDep).dimension,'1')
                nSize = [1 1];
            else
                sSize = strrep(xDependent(nIdxDep).dimension,',',' ');
                sSize = strrep(sSize,':','Inf');
                nSize = str2num(sSize); %#ok<ST2NM>
            end
            bInf = isinf(nSize); % boolean for infinite identification
            
            % compare size of local dependent parameter
            nSizeLocal = size(vLocal);
            if numel(nSize) == numel(nSizeLocal)
                bLocal = nSize == nSizeLocal;
                bLocal = bLocal(~bInf);
            else
                bLocal = false;
            end
            if ~all(bLocal)
                sMsg = sprintf(['Warning GlobalParameters: The local dependent parameter "'  sVarStruct ...
                    '" (size: ' num2str(size(vLocal)) ') does not match the dependent ' ...
                    'parameter specification size (' sSize ') and hence is not overwritten by ' ...
                    'the global parameter "' ['sMP.global.' xDependent(nIdxDep).globalName] '"!\n']);
                if nDGPFatal == 0
                    fprintf(2,'%s',sMsg);
                elseif nDGPFatal == 1
                    warning('dpsModuleInit:dpsDependentParameterSet:locParSizeSpecMismatch',sMsg); %#ok<SPWRN>
                end
                continue
            end
            
            % compare size of global parameter
            nSizeGlobal = size(sMP.global.(xDependent(nIdxDep).globalName));
            if numel(nSize) == numel(nSizeGlobal)
                bGlobal = nSize == nSizeGlobal;
                bGlobal = bGlobal(~bInf);
            else % amount of dimension missmatch
                bGlobal = false;
            end
            if ~all(bGlobal)
                sMsg = sprintf(['Warning GlobalParameters: The global parameter "'  ...
                    ['sMP.global.' xDependent(nIdxDep).globalName] '" (size: ' ...
                    num2str(size(sMP.global.(xDependent(nIdxDep).globalName))) ...
                    ') does not match the dependent parameter specification size (' ...
                    sSize ') and hence the dependent parameter "' sVarStruct '" is not ' ...
                    'overwritten!\n']);
                if nDGPFatal == 0
                    fprintf(2,'%s',sMsg);
                elseif nDGPFatal == 1
                    warning('dpsModuleInit:dpsDependentParameterSet:locParSizeMismatch',sMsg); %#ok<SPWRN>
                end
                continue
            end
        elseif strcmp(sFieldType,'struct')
            % do nothing to make CPC & PPC people happy...
        elseif strcmp(sFieldType,'char')
            % do nothing to make CPC & PPC people happy...
        end
    else
        sMsg = sprintf(['Warning GlobalParameters: The local dependent parameter "'  sVarStruct ...
            '" has no size specification, hence the size cannot be checked.\n']);
        if nDGPFatal == 0
            fprintf(2,'%s',sMsg);
        elseif nDGPFatal == 1
            warning('dpsModuleInit:dpsDependentParameterSet:locParNoSpec',sMsg); %#ok<SPWRN>
        end
    end
    
    % check unit string
    % TODO - how to implement, store unit of global or central check before init Loop?
    
    % get value/minmax info of parameter values for log message
    if strcmp(sFieldType,'struct')
        sValueLocal = '(structure)';
        sValueGlobal = '(structure)';
    elseif strcmp(sFieldType,'char')
        sValueLocal = ['(char: "' vLocal '")'];
        sValueGlobal = ['(char: "' sMP.global.(xDependent(nIdxDep).globalName) '")'];
    elseif max(size(sMP.global.(xDependent(nIdxDep).globalName))) == 1
        sValueLocal = ['(value: ' num2str(vLocal) ')'];
        sValueGlobal = ['(value: ' num2str(sMP.global.(xDependent(nIdxDep).globalName)) ')'];
    else
        sSize = num2str(size(vLocal));
        sSize = regexprep(sSize,' +',',');
        sValueLocal = ['(size: (' sSize ') , min: ' num2str(min(min(vLocal))) ...
            ', max: ' num2str(max(max(vLocal))) ')'];
        sValueGlobal = ['(size: (' sSize ') , min: ' ...
            num2str(min(min(sMP.global.(xDependent(nIdxDep).globalName)))) ...
            ', max: ' num2str(max(max(sMP.global.(xDependent(nIdxDep).globalName)))) ')'];
    end
    
    % assign parameter
    sMP = setfield(sMP,cVarField{:},sMP.global.(xDependent(nIdxDep).globalName));
    % create log message
    if nDGPSuccess == 1
        fprintf(1,['     GlobalParameters: The local dependent parameter "' sVarStruct...
            '" ' sValueLocal ' is overwritten by the global parameter "' ...
            ['sMP.global.' xDependent(nIdxDep).globalName] ...
            '" ' sValueGlobal '.\n']);
    end
end

% store changed sMP in base workspace
assignin('base','sMP',sMP);
return

% =========================================================================

function dpsFileCopy(cFilePath,sPathRunDir)
% DPSFILECOPY copy the specified file to the specified run directory.
%
% Syntax:
%   dpsFileCopy(cFilePath,sPathRunDir)
%
% Inputs:
%     cFilePath - cell (1xn) with strings of full paths of files to copy
%   sPathRunDir - string with path of run directory
%
% Outputs:
%
% Example: 
%   dpsFileCopy(cFilePath,sPathRunDir)

for nIdxFile = 1:numel(cFilePath)
    [sPath,sFile,sExt] = fileparts(cFilePath{nIdxFile});
    
    % check and copy file
    if exist(cFilePath{nIdxFile},'file')
        [bStatus,sMessage,~] = copyfile(cFilePath{nIdxFile},fullfile(sPathRunDir,[sFile sExt]));
        if ~bStatus % throw error if copy failed
             error('dpsModuleInit:dpsFileCopy','Copy operation failed from %s to %s with error message "%s"',...
                cFilePath{nIdxFile},fullfile(sPathRunDir,[sFile sExt]),strtrim(sMessage));
        end
    else
        error('dpsModuleInit:dpsFileCopy:invalidFilePath',['The following '...
            'file does not exist on the file system for copy operation to run directory'...
            '(derived from module location and XML information):\n%s\n'], ...
            cFilePath{nIdxFile});
    end
end
return
