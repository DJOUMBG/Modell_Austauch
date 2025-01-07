function [cInport,cOutport,xParam,sVersion,sAuthoringTool,sExecutionTool] = dstModuleFmuParse(sFile)
% DSTMODULEFMUPARSE parse interface information from FMU files.
%
% Syntax:
%   [cInport,cOutport,xParam] = dstModuleFmuParse(sFile)
%   [cInport,cOutport,xParam,sVersion,sAuthoringTool,sExecutionTool] = dstModuleFmuParse(sFile)
%
% Inputs:
%   sFile - string with filepath of FMU zip-file
%
% Outputs:
%    cInport - cell (1xm) with strings of inport names
%   cOutport - cell (1xn) with strings of outport names
%     xParam - structure (1xo) with fields: 
%         sVersion - char (1xm) with FMI standard version of FMU e.g. '2.0'
%   sAuthoringTool - char (1xm) with authoring tool of FMU e.g. 'Simpack_w64_2020x_3'
%   sExecutionTool - char (1xm) with execution tool information of FMU 'fmu10_w64'
%
% Example: 
%   [cInport,cOutport,xParam] = dstModuleFmuParse(sFile)
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2021-07-06

%% check input
if ~exist(sFile,'file')
    error('dstModuleFmuParse:fileNotFound',...
        'The specified file is not on the file system: %s',sFile)
end
[sPath,sName,sExt] = fileparts(sFile); %#ok<ASGLU>
if ~strcmpi(sExt,'.fmu')
    error('getFileVersionFmu:unknownFileType',...
        'Only *.fmu files allowed in %s fmu parsing - passed file: %s',mfilename,sFile);
end

%% read info XML file of FMU
% extract file modelDescription.xml from zip file
sFileExtract = 'modelDescription.xml';
cList = zip7Extract(sFile,sFileExtract,sPath,true);
% more than one version of modelDescription.xml could be in the FMU
bHit = ~cellfun(@isempty,regexp(cList,'^modelDescription.xml','match','once'));
if sum(bHit) > 1
    error('zip7:MultipleMainModel','Multiple files in zip-file found: %s\n',sFile);
end
sFileModel = fullfile(sPath,sFileExtract);
if ~exist(sFileModel,'file')
    % file not found in zipfile
    fprintf(2,'File "modelDescription.xml" could not be retrieved from *.fmu file');
end

% read XML file
xTree = dsxRead(sFileModel,1,0,1);
delete(sFileModel); % delete file

%% check XML structure
% define sub-structures / XML tag pathes to check
cCheck = {''    ,'fmiModelDescription';...
    'fmiVersion','fmiModelDescription.fmiVersion';...
    [4,5]       ,'fmiModelDescription.CoSimulation';...
    3           ,'fmiModelDescription.Implementation';...
    3           ,'fmiModelDescription.Implementation.CoSimulation_StandAlone';...
    ''          ,'fmiModelDescription.ModelVariables';...
    ''          ,'fmiModelDescription.ModelVariables.ScalarVariable';...
    ''          ,'fmiModelDescription.ModelVariables.ScalarVariable.name';...
    ''          ,'fmiModelDescription.ModelVariables.ScalarVariable.Real';...
    ''          ,'fmiModelDescription.ModelVariables.ScalarVariable.causality';...
    ''          ,'fmiModelDescription.ModelVariables.ScalarVariable.variability';...
    'fmuGenTool','fmiModelDescription.generationTool';...
    };

% check sub-structure availability
bCheck = isfieldRecursive(xTree,cCheck(:,2));

% report missing structures
for nIdxCheck = find(~bCheck)'
    if ~isnumeric(cCheck{nIdxCheck,1}) || ... % no alias content
            (isnumeric(cCheck{nIdxCheck,1}) && ... % alias content defined
            ~all(bCheck(cCheck{nIdxCheck,1}))) % alias content was found
        error('getFileVersionFmu:missingXmlAttribute',...
        'The FMU''s "modelDescription.xml" is missing the tag "%s"',...
        cCheck{nIdxCheck,2});
    end
end

% assert FMI version 1.0 or 2.0
assert(ismember(xTree.fmiModelDescription.fmiVersion,{'1.0','2.0'}),...
    sprintf('"%s" can only handle FMU Version 1.0 and 2.0!',mfilename));

% obtain base values
sVersion = xTree.fmiModelDescription.fmiVersion;
sGenTool = xTree.fmiModelDescription.generationTool;

%% determine available bit versions
sFS = regexptranslate('escape',filesep);
nW32 = double(any(~cellfun(@isempty,regexp(cList,[sFS 'win32' sFS],'once'))));
nW64 = 2*double(any(~cellfun(@isempty,regexp(cList,[sFS 'win64' sFS],'once'))));
nL32 = double(any(~cellfun(@isempty,regexp(cList,[sFS 'linux32' sFS],'once'))));
nL64 = 2*double(any(~cellfun(@isempty,regexp(cList,[sFS 'linux64' sFS],'once'))));
cBinW = {'','w32','w64','w3264'}; % possible values
cBinL = {'','l32','l64','l3264'}; % possible values
if nW32+nW64 < 1 
    fprintf(2,'Warning: No Windows implementation found in FMU "%s"\n',sFile);
end
sBin = [cBinW{nW32+nW64+1} cBinL{nL32+nL64+1}];
        
%% create output
sGenTool = regexprep(sGenTool,'\([^\)]+\)',''); % remove bracket with content
sExecutionTool = ['fmu' strrep(sVersion,'.','') '_' sBin]; % create e.g. fmu10_w3264
[sFront,nEnd] = regexp(sGenTool,'^\w+','match','end','once'); % get front word
sRear = strtrim(sGenTool(nEnd+2:end)); % rear part without blanks
sRear = regexprep(sRear,'[ \.\(\)]','_'); % replace .()blank with _
sAuthoringTool = [sFront,'_',sBin,'_',sRear]; % create e.g. SimulationX_w3264_3_7_0_34479

%% extract ports
% code shortcut
xVar = xTree.fmiModelDescription.ModelVariables.ScalarVariable;

% contect vectors
cCausality = {xVar.causality};
bInport = strcmp('input',cCausality);
bOutport = strcmp('output',cCausality);

% check variable type of ports
bReal = arrayfun(@(x)~isempty(x.Real),xVar(bInport|bOutport));
if ~all(bReal)
    nPort = find(bInport|bOutport);
    fprintf(2,'The following ports are not of Type "Real" (mandatory for DIVe):\n');
    fprintf(2,'    %s\n',xVar(nPort(~bReal)).name);
    error('getFmuInfo:failedPortTypeCheck','FMU port variables must be of type Real in DIVe!')
end

% create port lists
cInport = {xVar(bInport).name};
cOutport = {xVar(bOutport).name};

%% extract parameters
xParam = dstModuleFmuParameterParse(xVar);
return

% =========================================================================

function xParam = dstModuleFmuParameterParse(xVar)
% DSTMODULEFMUPARAMETERPARSE <one line description>
% <Optional file header info (to give more details about the function than in the H1 line)>
%
% Syntax:
%   xParam = dstModuleFmuParameterParse(xVar)
%
% Inputs:
%   xVar - structure with fields from FMU modelDescription.xml : 
%      .name        - string with name of Parameter
%      .causality   - string with causality of Parameter according FMI
%      .variability - string (fixed|tunable) of Parameter variability
%
% Outputs:
%   xParam - structure with fields: 
%
% Example: 
%   xParam = dstModuleFmuParameterParse(xVar)

%% find parameter create support arrays
% determine parameters according FMI version
cCausality = {xVar.causality};
cVariability = {xVar.variability};
bParam = (strcmp('parameter',cCausality) & ...
          ( strcmp('fixed',cVariability) | strcmp('tunable',cVariability) )) | ... % FMI version 2.0
         (strcmp('internal',cCausality) & strcmp('parameter',cVariability)); % FMI version 1.0
nParam = find(bParam);

% empty return structure
if isempty(nParam)
    xParam = structInit({'name','index','subspecies'});
    return
end

% support arrays for further use
cVar = {xVar(bParam).name}; % get parameter names
ccSplit = cellfun(@(x)strsplitOwn(x,'.'),cVar,'UniformOutput',false); % split sMP in struct levels
nLevel = cellfun(@(x)numel(x),ccSplit);
cVarName = cellfun(@(x)x{end},ccSplit,'UniformOutput',false); % variable fullname (includes array component syntax)
cVarShort = regexp(cVarName,'^\w+','match','once'); % variable name without array syntax

%% check and report variable type
cType = {'Real','Integer','String','Boolean'};
bType = false(numel(cType),sum(bParam));
for nIdxType = 1:numel(cType)
    if isfield(xVar,cType{nIdxType})
        bType(nIdxType,:) = arrayfun(@(x)~isempty(x.(cType{nIdxType})),xVar(bParam));
    end
end
bTypeAny = cellfun(@any,num2cell(bType,1));
if any(~bTypeAny)
    fprintf(2,'The following parameters are not of types Real, Integer, String or Boolean:\n');
    fprintf(2,'    %s\n',xVar(nParam(~bTypeAny)).name);
    error('getFmuInfo:failedParameterTypeCheck',...
        'FMU parameters must be of types Real, Integer, String or Boolean!')
end

%% check and report variable source rules (sMP structure)
% parameter uses sMP structure
bSmp = strncmp('sMP',cVar,3);
if any(~bSmp)
    fprintf(2,'The following parameters are not from the DIVe "sMP" parameter structure:\n');
    fprintf(2,'    %s\n',xVar(nParam(~bSmp)).name);
    error('getFmuInfo:failedParameterSmpCheck',...
        'FMU parameters must be of fed by the DIVe "sMP" when using this function!')
end
% parameter sMP structure is of correct sizing (4: standard, 5: subspecies)
bLevel = ismember(nLevel,[4,5]);
if any(~bLevel)
    fprintf(2,'The following parameters are not from the DIVe "sMP" parameter structure:\n');
    fprintf(2,'    %s\n',xVar(nParam(~bSmp)).name);
    error('getFmuInfo:failedParameterSmpCheck',...
        'FMU parameters must be fed by the DIVe "sMP" when using this function!')
end   

%% check parameter name rules
% parameter name follows DIVe/Matlab rules (no implicit vector/matrix
% passing; SimX FMU must use other process)
bCharFail = cellfun(@isempty,regexp(cVarName,'\w+(\[[\d,]+\])?$','once'));
if any(bCharFail)
    fprintf(2,['The following parameters use illegal characters - only allowed ' ...
               '[a-zA-Z0-9_] + optional matrix notatation [nx,ny]:\n']);
    fprintf(2,'    %s\n',xVar(nParam(bCharFail)).name);
    error('getFmuInfo:failedParameterCharCheck',...
        ['FMU parameter names must be only of characters [a-zA-Z0-9_] + optional ' ...
         'matrix notatation [nx,ny] in this function (implicit vector/matrices ' ...
         'should use other approach!']);
end   

%% compress pseudo-matrix notation parameters
% cVar = {xVar(bParam).name}; % get parameter names
% ccSplit = cellfun(@(x)strsplitOwn(x,'.'),cVar,'UniformOutput',false); % split sMP in struct levels
% cVarName = cellfun(@(x)x{end},ccSplit,'UniformOutput',false); % variable fullname (includes array component syntax)
% cVarShort = regexp(cVarName,'^\W+','match','once'); % variable name without array syntax

% create size information
cSizeParse = regexp(cVarName,'(?<=\[)[\d,]+(?=\])','match','once');
bEmpty = cellfun(@isempty,cSizeParse);
[cSizeParse{bEmpty}] = deal('1');

% capture last variable use -> assumption to capture largest array index
cVarShortUnique = unique(cVarShort);
bParCompress = false(size(cVarName));
for nIdxVarShort = 1:numel(cVarShortUnique)
    nLast = find(strcmp(cVarShortUnique{nIdxVarShort},cVarShort),1,'last');
    bParCompress(nLast) = true;
end

%% create parameter structure
% create subspecies information
cSubspecies = repmat({''},1,numel(cVarName));
nSub = find(nLevel>4);
for nIdxSub = nSub
    cSubspecies(nIdxSub) = ccSplit{nIdxSub}(4);
end

% create indices
cIndex = num2cell(1:sum(bParCompress));

% create parameter struct
xParam = struct('name',cVarName(bParCompress),...
                'index',cIndex,...
                'subspecies',cSubspecies(bParCompress),...
                'size',cSizeParse(bParCompress));
return
