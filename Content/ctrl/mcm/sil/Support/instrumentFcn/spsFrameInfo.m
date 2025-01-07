function [cFrame,cFrameBlockPath,bFrameSFcn,xLibrary] = spsFrameInfo(sBlockPath)
% SPSFRAMEINFO determine information about the frame model state of a xCU
% (MCM/ACM) in specified Simulink model and on its file system path.
% (Originally a subfunction of the xCMFrameSwitcher)
%
% Syntax:
%   [cFrame,cFrameBlockPath,bFrameSFcn,xLibrary] = spsFrameInfo(sBlockPath)
%
% Inputs:
%   sBlockPath - string with Simulink blockpath of "xCU Internal" subsystem
%                (e. g. .../MCM__M04_54_00_50/MCM Internal)
%
% Outputs:
%            cFrame - cell (mxn) 
%   cFrameBlockPath - cell (mxn) 
%        bFrameSFcn - boolean 
%          xLibrary - (implicit by save file!) structure with information 
%                     of available frame libraries 
%            .<framename> - struct named by frame
%              .sl        - boolean for availability of open simulink 
%                           instance of frame
%              .sfcn      - boolean for availability of s-function instance
%                           of frame
%              .libname   - string with name of simulink library
%
% Example: 
%   [cFrame,cFrameBlockPath,bFrameSFcn,xLibrary] = spsFrameInfo(sBlockPath)

%% determine xCM type: sEcuType
if ~isempty(regexpi(sBlockPath,'ACM'))
    sEcuType = 'acm';
elseif ~isempty(regexpi(sBlockPath,'MCM'))
    sEcuType = 'mcm';
else % no chance of determination any more
    error('clcFrameInfo:TypeDeterminationFailed','Not able to determine control module type');
end
    
%% robust path determination
cBlockPath = pathpartsSL(sBlockPath);
if isempty(strfind(cBlockPath{end},'Internal'))
    
end

%% determine Simulink block paths of used frames in xCU: cFrameBlockPath
cSubsystem = find_system(sBlockPath,'SearchDepth',1,'RegExp','on','Name','^Model ');
cFrameBlockPath = {};
for nIdxSubsystem = 1:length(cSubsystem)
    cTemp = find_system(cSubsystem{nIdxSubsystem},'SearchDepth',1,'RegExp','on','Name','_frame$');
    cFrameBlockPath = [cFrameBlockPath; cTemp]; %#ok
end

%% get info of available frames and sl/sfcn versions on file system: xLibrary
% determine library path on file system
sBlockReference = get_param(cFrameBlockPath{1},'ReferenceBlock');
sBlockReferenceMdl = fileparts(sBlockReference);
sPathLibrary = fileparts(which(sBlockReferenceMdl));

% directory content of potential libraries
xDirContent = dir(fullfile(sPathLibrary,[lower(sEcuType) '_*_frame_s*.mdl']));

% derive information structure
xLibrary = struct;
for nIdxFile = 1:numel(xDirContent)
    % derive frame and type information from library name
    sFrame = regexp(xDirContent(nIdxFile).name,'(?<=^[a-zA-Z]+_)\w+_frame(?=_s\w+.mdl)','match','once');
    sType = regexp(xDirContent(nIdxFile).name,'(?<=_frame_)s\w+(?=.mdl)','match','once');
    
    xLibrary.(sFrame).(sType) = true;
    % create other element if not present
    if ~isfield(xLibrary.(sFrame),'sl')
        xLibrary.(sFrame).sl = false;
    end
    if ~isfield(xLibrary.(sFrame),'sfcn')
        xLibrary.(sFrame).sfcn = false;
    end
end

%% get current use of frame sfcn: bFrameSFcn
bFrameSFcn = false(size(cFrameBlockPath));
for nIdxFrame = 1:length(cFrameBlockPath)
    bFrameSFcn(nIdxFrame) = ismdl(fullfileSL(cFrameBlockPath{nIdxFrame},'S-Function Frame'));
end

%% get list of used frames: cFrame
cFrame = cell(size(cFrameBlockPath));
for nIdxFrame = 1:numel(cFrameBlockPath)
    [sTrash,sFrame] = fileparts(cFrameBlockPath{nIdxFrame});  %#ok<ASGLU>
    cFrame{nIdxFrame,1} = sFrame;
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

function cPath = pathpartsSL(sBlockpath)
% PATHPARTSSL decompose a Simulink blockpath into the single model levels.
%
% Syntax:
%   cPath = pathpartsSL(sBlockpath)
%
% Inputs:
%   sBlockpath - string with a block path (slash '/' as model level
%                separator. Slashes as model name components must be
%                doubled '//'
%
% Outputs:
%   cPath - cell (1xn) with string of single model level names
%
% Example: 
%   cPath = pathpartsSL('test1/subsystem1/blockwithunit[kg//h]')
% % returns
% % cPath = 
% %     'test1'    'subsystem1'    'blockwithunit[kg/h]'
%
% Other m-files required: fullfileSL
%
% See also: fullfileSL, fileparts, gcb
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2013-03-26

% initialize output
cPath = {}; %#ok

% separator string
sSep = '/'; 

% find separators
vSepPos = strfind(sBlockpath,sSep);

% catch non-path but single system call
if isempty(vSepPos)
    cPath = {sBlockpath};
    return
end

% remove double separators
vPosDouble = find(diff(vSepPos)==1); % get first element of a double position
vPosDouble = [vPosDouble, vPosDouble+1]; % add second element of double position to list
vSepPos = vSepPos(~ismember(vSepPos,vSepPos(vPosDouble)));
vSepPos = sort(vSepPos);

% remove leading and ending separators
if vSepPos(1) == 1
    vSepPos = vSepPos(2:end);
    sBlockpath = sBlockpath(2:end);
end
if vSepPos(end) == length(sBlockpath)
    vSepPos = vSepPos(1:end-1);
    sBlockpath = sBlockpath(1:end-1);
end

% split blockpath according separator positions
vSepPos = [vSepPos length(sBlockpath)+1];
nPosLast = 0;
cPath = cell(1,length(vSepPos));
for nPart = 1:length(vSepPos)
%     cPath{nPart} =strrep(sBlockpath(nPosLast+1:vSepPos(nPart)-1),'//','/'); % get part and remove double slash
    cPath{nPart} = sBlockpath(nPosLast+1:vSepPos(nPart)-1); % get part 
    nPosLast = vSepPos(nPart);
end
return


% =========================================================================
% == linked from file: fullfileSL.m 
% =========================================================================


function str = fullfileSL(varargin)
% FULLFILESL creates a simulink block path from single block names.
%
% Syntax:
%   str = fullfileSL(varargin)
%
% Inputs:
%   varargin - strings with blocknames or a cell with strings
%
% Outputs:
%   str - string with Simulink block path
%
% Example: 
%  str = fullfileSL('MyModel','Subsystem','Constant'); % returns 'MyModel/Subsystem/Constant' 
%  str = fullfileSL({'MyModel','Subsystem','Constant'}); % returns 'MyModel/Subsystem/Constant' 
%
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2013-03-26

% create homogen cell input
strcell = {};
for k = 1:nargin
    try
        if iscell(varargin{k})
            strcell = [strcell, varargin{k}]; %#ok
        else
            strcell = [strcell, varargin(k)]; %#ok
        end
    catch
        disp(['An error occured with input argument number ' num2str(k)]);
        rethrow(lasterror)
    end
end
   
% remove empty cells
bEmpty = cellfun(@isempty,strcell);
strcell = strcell(~bEmpty);

% create block path
str = strcell{1};
for k = 2:length(strcell)
    str = [str '/' strcell{k}]; %#ok
end
if strcmp(str(end),'/')
    str = str(1:end-1);
end
return
