function dstBlockMaskFullCreate(sFileXml)
% DSTBLOCKMASKFULLCREATE create a basic DIVe Simulink block mask for all parameters of a Module.
% Prompt will be reset to parameter name, but mask values are automatically set to the sMP structure
% variable.
% Internal variable is for scalar parameters alike the parameter name. For structures (e.g. by
% subspecies) the structure level fields are joined by underscore e.g. 
%   sMP.phys.lvs.par1 -> (internal) par1
%   sMP.phys.lvs.subspecies1.par2 -> (internal) subspecies1_par2
%   sMP.phys.lvs.struct1.struct2.par3 -> (internal) struct1_struct2_par3
% 
%
% Syntax:
%   dstBlockMaskFullCreate(sFileXml)
%
% Inputs:
%   sFileXml - string with filepath of Module XML File or path of Module variant
%
% Outputs:
%
% Example: 
%   sFileXml = 'c:\dirsync\06DIVe\03Platform\com\Content\phys\lvs\detail\e_truck\Module\std\std.xml'
%   dstBlockMaskFullCreate(sFileXml)
%
% Subfunctions: bmfParameterGet, bmfParameterReccursion
%
% See also: dmdLoadData, dstBlockMaskFullCreate, pathparts, strGlue
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-8485-3325
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2022-09-15

% load Module XML
cPathXml = pathparts(sFileXml);
if exist(sFileXml,'dir') % Module variant folder -> derive XML file
    sFileXml = fullfile(sFileXml,[cPathXml{end} '.xml']);
    cPathXml = [cPathXml cPathXml(end)];
end
if exist(sFileXml,'file')
    xTree = dsxRead(sFileXml);
else
    error('dstBlockMaskFullCreate:fileNotFoung',...
        'The specified Module XML file is not on the file system: %s',sFileXml);
end
    
% add pathes of SupportSets
bmfSupportSetPathAdd(xTree.Module,fileparts(sFileXml));

% load DataSets in sMP in base workspace
dmdLoadData(sFileXml)
% parse parameter info from DataSets
[cParameter,cSmp] = bmfParameterGet(xTree.Module);

% determine/open Simulink model block
bOpen = strcmp('open',{xTree.Module.Implementation.ModelSet.type});
bMain = strcmp('1',{xTree.Module.Implementation.ModelSet(bOpen).ModelFile.isMain});
sModelFile = fullfile(cPathXml{1:end-1},'open',xTree.Module.Implementation.ModelSet(bOpen).ModelFile(bMain).name);
uiopen(sModelFile,true); % open main file as Simulink model
[sModelPath,sModelName,sModelExt] = fileparts(sModelFile); %#ok<ASGLU> get model name
cBlock = find_system(sModelName,...
    'SearchDepth',1,...
    'LookUnderMasks','on',...
    'FollowLinks','on',...
    'BlockType','SubSystem'); % 
sSubsystem = cBlock{1};

% unlock library if needed
try  %#ok<TRYNC>
    set_param(sModelName,'Lock','off');
end

% get mask entries from parameters or existing mask
[xMask] = bmfMaskPrepare(cParameter,cSmp,sSubsystem);

% adapt mask to parameters
slcMaskCreate(sSubsystem,xMask);
return

% ==================================================================================================

function [xMask] = bmfMaskPrepare(cParameter,cSmp,sSubsystem)
% BMFMASKPREPARE create mask entries of parameters from sMP parsed
% parameters.
% Where the parsed sMP structure string matches the value string of an
% already existing mask parameter, the prompt of the existing mask is
% applied.
%
% Syntax:
%   xMask = bmfMaskPrepare(cParameter,cSmp,sSubsystem)
%
% Inputs:
%   cParameter - cell (1xn) with strings of pure paramter name 
%         cSmp - cell (1xn) with strings of sMP parameter structure string
%   sSubsystem - string with Simulink blockpath of mask subsystem
%
% Outputs:
%   xMask - structure with fields: 
%    .MaskVariables - string with mask variable notation (e.g. v1=@1;v2=@2) 
%    .MaskPrompts   - cell (1xn) of strings with mask prompts
%    .MaskValues    - cell (1xn) of strings with mask values
%
% Example: 
%   xMask = bmfMaskPrepare(cParameter,cSmp,sSubsystem)

% retrieve existing mask
if ismdl(sSubsystem) && strcmp(get_param(sSubsystem,'Mask'),'on')
    cMaskPrompt = get_param(sSubsystem,'MaskPrompts');
    cMaskValue = get_param(sSubsystem,'MaskValues');
end

% generate mask entries by parameters
cMaskVariable = cellfun(@(x,y)[x '=@' num2str(y)],cParameter,num2cell(1:numel(cParameter)),'UniformOutput',false);
xMask.MaskVariables = strGlue(cMaskVariable,';');
xMask.MaskPrompts = cSmp;
xMask.MaskValues = cSmp;

% patch original prompts, where applicable
if exist('cMaskPrompt','var')
    [bOrgInNew,nOrgInNew] = ismember(cMaskValue,xMask.MaskValues);
    nOrgInNew = nOrgInNew(bOrgInNew);
    cMaskValue = cMaskValue(bOrgInNew);
    cMaskPrompt = cMaskPrompt(bOrgInNew);
    
    for nIdxValue = 1:numel(cMaskValue)
        xMask.MaskPrompts{nOrgInNew(nIdxValue)} = cMaskPrompt{nIdxValue};
    end
end
return

% ==================================================================================================

function [cParameter,cSmp] = bmfParameterGet(xModule)
% BMFPARAMETERGET determine the parameters from isStandard DataSet files
%
% Syntax:
%   [cParameter,cSmp] = bmfParameterGet(xModule)
%
% Inputs:
%   xModule - structure with fields of DIVe Module XML
%
% Outputs:
%   cParameter - cell (1xn) of strings with internal variable name (equals parameter or for deeper
%                structures like subspecies <subspecies>_<parameter>)
%         cSmp - cell (1xn) of strings with sMP structure string for mask value entry
%
% Example: 
%   [cParameter,cSmp] = bmfParameterGet(xModule)

% init output
cParameter = {};
cSmp = {};

% get sMP parameters from base workspace
sMP = evalin('base','sMP');

% remove inport and outport initial values
xPar = sMP.(xModule.context).(xModule.species);
if isfield(xPar,'in')
    xPar = rmfield(xPar,'in');
end
if isfield(xPar,'out')
    xPar = rmfield(xPar,'out');
end

% parse parameter structure
[cParameterAdd,cSmpAdd] = bmfParameterReccursion(xPar);
cParameter = [cParameter cParameterAdd];
cSmpAdd = cellfun(@(x)strGlue({'sMP',xModule.context,xModule.species,x},'.'),cSmpAdd,'UniformOutput',false);
cSmp = [cSmp cSmpAdd];

return

% ==================================================================================================

function [cParameter,cSmp] = bmfParameterReccursion(xPar)
% BMFPARAMETERRECCURSION reccursive determination of parameters/fields of a structure with capturing
% of structure string and deep parameter name.
%
% Syntax:
%   [cParameter,cSmp] = bmfParameterReccursion(xPar)
%
% Inputs:
%   xPar - structure with fields/structures 
%
% Outputs:
%   cParameter - cell (1xn) of strings with internal variable name (equals parameter or for deeper
%                structures like subspecies <subspecies>_<parameter>)
%         cSmp - cell (1xn) of strings with sMP structure string for mask value entry
%
% Example: 
%   [cParameter,cSmp] = bmfParameterReccursion(struct('par1',{1},'par2',{2},struct1,{struct('par3',{3})}))

% init output
cParameter = {};
cSmp = {};

% loop over structure fields
cField = fieldnames(xPar);
for nIdxField = 1:numel(cField)
    if isstruct(xPar.(cField{nIdxField}))
        % reccursion into deeper structure level (e.g. subspecies)
        [cParameterAdd,cSmpAdd] = bmfParameterReccursion(xPar.(cField{nIdxField}));
        cParameterAdd = cellfun(@(x)strGlue({cField{nIdxField},x},'_'),cParameterAdd,'UniformOutput',false);
        cParameter = [cParameter cParameterAdd]; %#ok<AGROW>
        cSmpAdd = cellfun(@(x)strGlue({cField{nIdxField},x},'.'),cSmpAdd,'UniformOutput',false);
        cSmp = [cSmp cSmpAdd]; %#ok<AGROW>
    else
        cParameter = [cParameter cField(nIdxField)]; %#ok<AGROW>
        cSmp = [cSmp cField(nIdxField)]; %#ok<AGROW>
    end
end
return

% ==================================================================================================

function bmfSupportSetPathAdd(xModule,sPathModule)
% BMFSUPPORTSETPATHADD add pathes of Module's SupportSets to Matlab path.
%
% Syntax:
%   bmfSupportSetPathAdd(xModule)
%
% Inputs:
%   xModule - structure with fields of DIVe Module XML
%     .Implementation.SupportSet - structure with SuppportSets of Module
%   sPathModule - string with path of DIVe Module in file system
%
% Outputs:
%
% Example: 
%   bmfSupportSetPathAdd(xModule)

if isfield(xModule.Implementation,'SupportSet') && ...
        ~isempty(xModule.Implementation.SupportSet)
    for nIdxSet = 1:numel(xModule.Implementation.SupportSet)
        % determine support set location
        xSet = xModule.Implementation.SupportSet(nIdxSet);
        sPathSupportSet = fullfile(dpsPathLevel(sPathModule,xSet.level),'Support',xSet.name);
        
        % add SupportSet path to Matlab environment
        addpath(sPathSupportSet);
    end
end
return

