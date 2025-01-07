function bStatus = buildDIVeFMU(sFileXml)
%% BUILDDIVEFMU  build a FMU
% from a simple masked Simulink subsystem of DIVe with DIVe standard data.
%
% Syntax:
%   bStatus = buildDIVeSfcn
%   bStatus = buildDIVeSfcn(sFileXml)
%
% Inputs:
%   sFileXml - string with path of DIVe Module XML file
%              or path of DIVe Module variant folder
%
% Outputs:
%   bStatus - boolean (1x1) if FMU generation terminated successful
%
% Example:
%   buildDIVeFMU(sFileXml)
%   buildDIVeFMU('C:\dirsync\06DIVe\01Content\phys\eng\simple\transient\Module\std\std.xml')
%   buildDIVeFMU('C:\dirsync\06DIVe\01Content\ctrl\mcm\rebuild\MCM21_m04_54\Module\std\std.xml')
%   buildDIVeFMU('C:\dirsync\06DIVe\01Content\ctrl\mcm\rebuild\MR2_r24\Module\std\std.xml')
%   buildDIVeFMU('C:\dirsync\06DIVe\01Content\phys\eng\simple\transient\Module\std')
%
% See also: buildDIVeFMU
%
% Author: Roktim Bruder, TT/XCF, Daimler Truck AG
%  Phone: +49-711-8485-3302
% MailTo: roktim.bruder@daimlertruck.com
%   Date: 2021-12-13

% init output
bStatus = false;

% input check
if nargin == 0
    [sFileXmlName,sFileXmlPath] = uigetfile( ...
        {'*.xml','DIVe Module Description (xml)'; ...
        '*.*',  'All Files (*.*)'}, ...
        'Open Module Description (*.xml)',...
        'MultiSelect','off');
    if isequal(sFileXmlName,0) % user chosed cancel in file selection popup
        return
    else
        sFileXml = fullfile(sFileXmlPath,sFileXmlName);
    end
else
    if exist(sFileXml,'dir') == 7
        [sRest,sFolder] = fileparts(sFileXml); %#ok<ASGLU>
        sFileXml = fullfile(sFileXml,[sFolder '.xml']);
        sMsgAdd = '\nAssuming a Module variant folder as input failed as well.';
    else
        sMsgAdd = '';
    end
    if ~exist(sFileXml,'file')
        error('buildDIVeSfcn:fileNotFound','The specified file does not exist: %s%s',sFileXml,sMsgAdd);
    end
end

% load module XML description
sFileXmlPath = fileparts(sFileXml);
xTree = dsxRead(sFileXml);

% determine MATLAB version
bOpen = ismember({xTree.Module.Implementation.ModelSet.type},'open');
xModelSetOpen = xTree.Module.Implementation.ModelSet(bOpen);
if verLessThanMATLAB('9.10')
    error('ERROR: FMU compilation requires Matlab R2021a or newer.')
end
bIsMain = ismember({xModelSetOpen.ModelFile.isMain},'1');
sModelFile = xModelSetOpen.ModelFile(bIsMain).name;
sModelName = sModelFile(1:end-4);

% prepare directories
sMatlabBitType = regexprep(computer('arch'),'^win','w'); % returns 'w32' or 'w64'
xVersion = ver('MATLAB');
sMatlabRelease = xVersion.Release(2:end-1);
sPathModel = fullfile(sFileXmlPath,'open');
sPathCreate = fullfile(sPathModel,['createFMU_' sMatlabBitType '_' sMatlabRelease]);
if exist(sPathCreate,'dir')
    clear mex; %#ok<CLMEX> unload for restart after failure
    recycle('on');
    rmdir(sPathCreate,'s');
end
mkdir(sPathCreate); % make directory for sfunction creation

% determine masked subsystem for FMU generation
uiopen(fullfile(sPathModel,sModelFile),true); % open library
cBlockMask = find_system(sModelName,'SearchDepth',1,'BlockType','SubSystem','Mask','on');
if isempty(cBlockMask)
    % Model without parameter doesn't have a mask
    cBlockMask = find_system(sModelName,'SearchDepth',1,'BlockType','SubSystem');
end
sBlockMask = cBlockMask{1};
[sTrash,sBlock] = fileparts(sBlockMask); %#ok<ASGLU>

% create Simulink model for code generation
sPathOrg = pwd;
cd(sPathCreate);
sModelNameCreate = [sModelName '_create'];
new_system(sModelNameCreate); % create new model for code generation
open_system(sModelNameCreate);
add_block(sBlockMask,fullfileSL(sModelNameCreate,sBlock)); % copy of open model block
set_param(fullfileSL(sModelNameCreate,sBlock),'LinkStatus','none'); % break link from library
close_system(sModelName,0); % close library
addPortsIO(fullfileSL(sModelNameCreate,sBlock)) % add Inport and Outports
save_system(sModelNameCreate,sModelName); % save model under library name in creation directory
slcModelSolverOptions(sModelName);

% adapt solver stepsize to atomic subsystem or Module XML
sSampleTime = '0.005'; %#ok<NASGU>
% derive from Module XML
if isfield(xTree.Module,'maxCosimStepsize')
    sSampleTime = xTree.Module.maxCosimStepsize; %#ok<NASGU>
end
% derive from atomic subsystem properties, if set
cBlock = find_system(sModelName,'SearchDepth',1,'BlockType','SubSystem');
if numel(cBlock) == 1 % only 1 Block in System
    if strcmp(get_param(cBlock{1},'TreatAsAtomicUnit'),'on') % treat as atomic unit
        sSampleTime = get_param(cBlock{1},'SystemSampleTime'); % sample time
        if ~strcmp(sSampleTime,'-1')
            set_param(sModelName,'FixedStep',sSampleTime);
        end
    end
end

% load parameters from all data files
dmdLoadData(sFileXml)

% compile FMU
try
    exportToFMU2CS(...
        sModelName,...
        'CreateModelAfterGeneratingFMU','on',...
        'SaveSourceCodeToFMU','on',...
        'AddIcon', 'snapshot',...
        'SaveDirectory',sPathCreate);
catch %#ok<CTCH>
    disp('FMU build process failed!');
    xError = lasterror; %#ok<LERR>
    save(fullfile(sPathCreate,'xErrorBuild.mat'),'xError')
    close_system(sModelName,0);
    cd(sPathOrg);
    return
end

% save auto-generated simulink model with FMU block
sModelNameFMU = [sModelName '_fmu'];
save_system(sModelNameFMU);
close_system(sModelNameFMU,0);

% close previous system
close_system(sModelName,0);

% create library with fmu block in FMU directory
sPathFMU = fullfile(sFileXmlPath,'fmu20');
mkdir(sPathFMU);
copyfile(fullfile(sPathCreate,'*.fmu'),[sPathFMU filesep]);
copyfile(fullfile(sPathCreate,'*_fmu.slx'),[sPathFMU filesep]);

% delete create directory
recycle('on');
cd(sPathOrg);
rmdir(sPathCreate,'s');

% set flag
bStatus = true;
return

% ==================================================================================================

function addPortsIO(hBlock)
% ADDPORTSIO add inports and outports to wrapper
%
% Syntax:
%   addPortsIO(hBlock)
%
% Inputs:
%   hBlock - handle (1x1) 
%
% Outputs:
%
% Example: 
%   addPortsIO(hBlock)

% get name information
cSystem = get_param(hBlock,'Parent');
cBlock = get_param(hBlock,'Name');

% get IO port names
hInport = find_system(hBlock, 'LookUnderMasks', 'on', 'FollowLinks', 'on', 'SearchDepth', 1, 'BlockType', 'Inport');
hOutport = find_system(hBlock, 'LookUnderMasks', 'on', 'FollowLinks', 'on', 'SearchDepth', 1, 'BlockType', 'Outport');
cInport = cellstr(get_param(hInport, 'Name'));
cOutport = cellstr(get_param(hOutport, 'Name'));

% get IO port positions
xPortCon = get_param(hBlock,'PortConnectivity');
cPortPos = {xPortCon.Position};

% add input ports and lines from input to SimatBlock
for nIdxInport = 1:length(cInport)
    inportName = strcat(cSystem,'/',string(cInport(nIdxInport)));
    hBlock = add_block('simulink/Sources/In1', inportName);
    set_param(hBlock,'Position',[cPortPos{nIdxInport}(1)-200,cPortPos{nIdxInport}(2),cPortPos{nIdxInport}(1)-175,cPortPos{nIdxInport}(2)+10])
    add_line(cSystem, strcat(string(cInport(nIdxInport)),'/1'), strcat(cBlock,'/',num2str(nIdxInport)))
end

% add output ports and lines from input to SimatBlock
for nIdxOutport = 1:length(cOutport)
    outportName = strcat(cSystem,'/',string(cOutport(nIdxOutport)));
    hBlock = add_block('simulink/Sinks/Out1', outportName);
    set_param(hBlock,'Position',[cPortPos{nIdxInport+nIdxOutport}(1)+200,cPortPos{nIdxInport+nIdxOutport}(2),...
                                 cPortPos{nIdxInport+nIdxOutport}(1)+225,cPortPos{nIdxInport+nIdxOutport}(2)+10])
    add_line(cSystem, strcat(cBlock,'/',num2str(nIdxOutport)), strcat(string(cOutport(nIdxOutport)),'/1'))
end
return