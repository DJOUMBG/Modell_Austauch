function [bStatus,sMessage] = spsFrameCopy(sBlockPath,cFrame,sCopySuffix,bBreakLink,xLibrary)
% SPSFRAMECOPY copy specified frames from frame libraries. 
% (Originally a subfunction of the xCMFrameSwitcher)
%
% Syntax:
%   [bStatus,sMessage] = spsFrameCopy(sBlockPath,cFrame)
%   [bStatus,sMessage] = spsFrameCopy(sBlockPath,cFrame,sCopySuffix,bBreakLink,xLibrary)
%
% Inputs:
%    sBlockPath - string with Simulink blockpath of "xCU Internal" 
%                 subsystem (e. g. .../MCM__M04_54_00_50/MCM Internal)
%        cFrame - cell (1xn) with frames to be copied
%   sCopySuffix - string defining the library type to copy (sl or sfcn)
%    bBreakLink - boolean if library link of copied frame shall be disabled
%      xLibrary - structure with fields: 
%       .<framename>: struct named by frame
%         .sl       : boolean for availability of open simulink instance of
%                     frame
%         .sfcn     : boolean for availability of s-function instance of
%                     frame
%
%
% Outputs:
%    bStatus - boolean (1xn) with 0:fail or 1:success of copy operation 
%   sMessage - string with messages of copy operation 
%
% Example: 
%   [bStatus,sMessage] = spsFrameCopy('.../MCM__M04_54_00_50/MCM Internal','ccf_frame')
%   [bStatus,sMessage] = spsFrameCopy(sBlockPath,cFrame,sCopySuffix,bBreakLink,xLibrary)

% initialize output
bStatus = false(1,numel(cFrame));
sMessage = '';

% check input
if nargin < 5
    [cFrameAll,cFrameBlockPath,bFrameSFcn,xLibrary] = spsFrameInfo(sBlockPath); %#ok<ASGLU>
end
if nargin < 4
    bBreakLink = false;
end
if nargin < 3
    sCopySuffix = 'sl';
end

% determine xCM type
if ~isempty(strfind(sBlockPath,'ACM'))
    sEcuType = 'acm';
elseif ~isempty(strfind(sBlockPath,'MCM'))
    sEcuType = 'mcm';
else
    error('Unknown xCM type for switching.')
end

% prepare mdl for modification
set_param(bdroot(sBlockPath),'Lock','off'); % unlock library
slcDisableLink(sBlockPath); % disable link of parent
 
% copy frames
for nIdxFrame = 1:numel(cFrame) % for all selected frames
    if isfield(xLibrary,cFrame{nIdxFrame}) && xLibrary.(cFrame{nIdxFrame}).(sCopySuffix)
        % get target information
        sPathTarget = find_system(sBlockPath,'SearchDepth',2,'RegExp','on','Name',['^' cFrame{nIdxFrame}]);
        sPathTarget = sPathTarget{1};
        if isempty(sPathTarget)
            error('xwsGUIcbCopyFrame:FrameNotFound',['The frame ' cFrame{nIdxFrame} ' was not found in the model.']);
        end
        xBiTarget = slcBlockInfo(sPathTarget);
        
        % copy frame
        sFrameLibraryMdl = [sEcuType '_' cFrame{nIdxFrame} '_' sCopySuffix];
        slcLoadEnsure(sFrameLibraryMdl);
        delete_block(sPathTarget);
        add_block(fullfileSL(sFrameLibraryMdl,cFrame{nIdxFrame}),sPathTarget,'Position',xBiTarget.Position);
        if bBreakLink
            set_param(sPathTarget,'LinkStatus','inactive');
        end
        close_system(sFrameLibraryMdl);
        disp([ cFrame{nIdxFrame} ' copied from library...']);
        bStatus(nIdxFrame) = true;
    else
        sMessageCurrent = ['The ' sCopySuffix ' library model for ' cFrame{nIdxFrame} ' is not available - frame not copied.\n'];
        disp(sMessageCurrent);
        sMessage = [sMessage sMessageCurrent]; %#ok<AGROW>
    end
end
return

% =========================================================================

function slcLoadEnsure(mdlpath,bVerbose)
% slcLoadEnsure - returns vector with all line handles from specified line
% up to the next trunk line.
% 
% Input variables:
% mdlpath       - string with mdl-name on MATLAB path or mdl-filename with
%                 full path
% bVerbose      - boolean verbose flag: false - no display
%                                       true - display message if no load
% 
% Example call:
% slcLoadEnsure('mymodel')
% slcLoadEnsure('mymodel',false)

if nargin < 2
    bVerbose = false;
end

% divide path
[path,filename,ext] = fileparts(mdlpath);

% check input elements
if ~isempty(path) && exist(path,'dir') ~= 7
    error('slcLoadEnsure:FilepathNotValid',['The specified file path is not valid: ' path]);
end
if ~ismember(exist(mdlpath,'file'),[2,4]) && ~ismember(exist([mdlpath '.mdl'],'file'),[2,4])
    error('slcLoadEnsure:FileNotValid',['The specified file is not valid: ' mdlpath]);
end
if exist(mdlpath,'file')~=4 && ~strcmpi(ext,'.mdl')
    error('slcLoadEnsure:FileNotMdl',['The specified file is no Simulink model: ' mdlpath]);
end
if isempty(path)
    path = pwd;
end
   
% check if specified model is already loaded
TFload = true;
if ismdl(filename) && strcmpi(get_param(filename,'filename'),which(mdlpath))
    TFload = false;
    if bVerbose
        disp(['slcLoadEnsure: ' filename ' is already loaded from path: ' path])
    end
end
   
% load simulink model
if TFload
    load_system(mdlpath);
end
return

% =========================================================================

function bMdl = ismdl(cSystemPath)
% ISMDL checks cSystemPath for being a loaded Simulink model or submodel.
% Alternative implemetation would be with a direct try/catch find_system
% call.
%
% Syntax:
%   bMdl = ismdl(cSystemPath)
%
% Inputs:
%   cSystemPath - string or cell of strings with Simulink model paths
%
% Outputs:
%   bMdl - boolean scalar or vector true/false
%
% Example: 
%  load_system('simulink')
%  bMdl = ismdl('simulink/Sinks/Terminator')
%  bMdl = ismdl({'simulink/Sinks/Terminator','simulink/Sources/Clock'})
%  bMdl = ismdl({'simulink/NoValidSubsystem/Terminator','simulink/Sources/NoValidBlock'})
%
%
% Subfunctions:
% Private functions:
% Other m-files required:
% MAT-files required:
%
% See also: find_system 
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2013-03-26

% path input
if ~iscell(cSystemPath)
    cSystemPath = {cSystemPath};
end

% intialize output
bMdl = false(size(cSystemPath));

% check all model paths
for nIdx = 1:numel(bMdl)
    try
        bMdl(nIdx) = ~isempty(find_system(cSystemPath{nIdx},'SearchDepth',0));
    catch %#ok
        bMdl(nIdx) = false;
    end
end
return

% =========================================================================

function cb = slcBlockInfo(hp)
% slcBlockInfo - generates a structure with important block properties.
% (for lean code with reduced get_param calls)
% 
% Input variables:
% hp            - handle or path to block or handle vector or cell with
%                 block paths
% 
% Output variables:
% cb           - struct with
%   .Name               - string 
%   .Handle             - double/handle
%   .Parent             - string with full path of parent
%   .BlockPath        	- string with full path of block
%   .BlockType          - string with block type
%   .MaskType           - string with mask type
%   .Ports              - vector (1x8) with amount of port types
%                         1: Inport, 2: Outport
%   .PortCon         	- structure (1xNumberOfAllPorts) with
%       .Type           - string with number of port type (1-8)
%       .Position       - vector(1x2) with position
%       .SrcBlock       - handle of source block (only if port is Inport)
%       .SrcPort        - vector with handles of inports
%       .DstBlock       - handle of source block (only if port is Outport)
%       .DstPort        - vector with handles of inports
%   .PortHandles        - structure with
%       .Inport         - vector with handles of inports
%       .Outport        - vector with handles of outports
%       .Enable         - vector with handles 
%       .Trigger        - vector with handles 
%     	.State          - vector with handles 
%     	.LConn          - vector with handles 
%     	.RConn          - vector with handles 
%       .Ifaction       - vector with handles 
%   .LineHandles      	- handle of "upstream" line if branched,  
%       .Inport         - vector with line handles of inports
%       .Outport        - vector with line handles of outports
%       .Enable         - vector with line handles 
%       .Trigger        - vector with line handles 
%     	.State          - vector with line handles 
%     	.LConn          - vector with line handles 
%     	.RConn          - vector with line handles 
%       .Ifaction       - vector with line handles 
%   .Position           - vector (1x4) absolute point extensions of block
%                         (left top right bottom)
%   .Tag                - string with tag of block

% take current block if not specified
if nargin == 0
    hp = gcb;
end

% ensure handle (not path)
if ischar(hp)
    hp = get_param(hp,'Handle');
end


% ensure cell type of hp
if all(ishandle(hp)) 
    hp = num2cell(hp);
end

% reduce to block handles only
tf = cell2mat(cellfun(@(x)strcmpi(get_param(x,'Type'),'block'),hp,'UniformOutput',false));
hp = hp(tf);

% initialize output structure
cb = struct('Name',[],'Handle',[],'Parent',[],'BlockPath',[],... 
            'BlockType',[],'MaskType',[],'Ports',[],...
            'PortCon',[],'PortHandles',[],'LineHandles',[],'Position',[]);
        
% get block information
for k = 1:numel(hp)
    cb(k).Name = get_param(hp{k},'Name');
    cb(k).Handle = get_param(hp{k},'Handle');
    cb(k).Parent = get_param(hp{k},'Parent');
    cb(k).BlockPath = [cb(k).Parent '/' cb(k).Name];
    cb(k).BlockType = get_param(hp{k},'BlockType');
    cb(k).MaskType = get_param(hp{k},'MaskType');
    cb(k).Ports = get_param(hp{k},'Ports');
    cb(k).PortCon = get_param(hp{k},'PortConnectivity');
    cb(k).PortHandles = get_param(hp{k},'PortHandles');
    cb(k).LineHandles = get_param(hp{k},'LineHandles');
    cb(k).Position = get_param(hp{k},'Position');
    cb(k).Tag = get_param(hp{k},'Tag');
end
return

% =========================================================================

function refBlock = slcDisableLink(blockHandle)
% disable the library link of the block in the simulink model
%
% DESCRIPTION:
% If a block is linked to a library then its contents cannot be changed as
% long as the link is active. This function disables the link of the
% "blockHandle" or its parent subsystem so that its content can be 
% modified. The output "refBlock" is the path of the "blockHandle" in the
% library. Example: let's say that the full path of the input
% "blockHandle" is system/subsys1/subsys2/blockName and assumed that
% subsys1 is a link to the library "lib1" then this function returns the
% string "lib1/subsys1/subsys2/blockName".
%
% INPUT:
%     blockHandle: the handle of a simulink block
%
% OUTPUT:
%     refBlock: the path of the block "blockHandle" in the library

refBlock = '';
fullPathName = [get_param(blockHandle,'Parent') '/' get_param(blockHandle,'Name')];
% each slash indicates the consecutive parent subsystem of the
% "blockHandle".
slashPos = strfind(fullPathName,'/');
% add virtual slash position since we want also check whether "blockHandle"
% is linked.
slashPos(end+1) = length(fullPathName)+1;
% The for-loop is until the parent index is 2 since if parentIndex = 1 
% then it is the top level model which doesn't have the property "LinkStatus"
for parentIndex = length(slashPos):-1:2
   currentParent = fullPathName(1:slashPos(parentIndex)-1);
   linkStatus = get_param(currentParent,'LinkStatus');
   if strcmp(linkStatus,'resolved')
       set_param(currentParent,'LinkStatus','inactive');
       refBlock = [get_param(currentParent,'AncestorBlock') fullPathName(slashPos(parentIndex):end)];
       return
   end
end

% =========================================================================

function str = fullfileSL(varargin)
% fullfileSL - creates a simulink block path from single block names.
% 
% Input variables:
% varargin       - strings with blocknames or a cell with strings
% 
% Example calls:
% str = fullfileSL('MyModel','Subsystem','Constant'); % returns 'MyModel/Subsystem/Constant' 
% str = fullfileSL({'MyModel','Subsystem','Constant'}); % returns 'MyModel/Subsystem/Constant' 

% create homogen cell input
strcell = {};
for k = 1:nargin
    try
        if iscell(varargin{k})
            strcell = [strcell, varargin{k}]; %#ok
        else
            strcell = [strcell, varargin(k)]; %#ok
        end
    catch %#ok<CTCH>
        disp(['An error occured with input argument number ' num2str(k)]);
        rethrow(lasterror) %#ok<*LERR>
    end
end
    
% create block path
str = strcell{1};
for k = 2:length(strcell)
    str = [str '/' strcell{k}]; %#ok
end
return


