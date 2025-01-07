function [sPathSim,bSuccess,oCbt] = startDIVeCodeBased(varargin)
% STARTDIVECODEBASED start and initialization of platform DIVe CodeBased 
% (simulation technique Silver).
% All platform scripts and functions are added to the MATLAB path.
%
% Syntax:
%
%   startDIVeCodeBased
%       start dbc
%
%   startDIVeCodeBased(sFile)
%       run transformation for given configuration xml file
%
%   startDIVeCodeBased(sFile,nStartType)
%       open / run configuration with specific runtype (see Inputs)
%
%   startDIVeCodeBased(sFile,nStartType,sPathPrevious)
%       => currently not supported!
%
%   startDIVeCodeBased(__,'shortName',bFlag)
%       create short name for final SiL location without date and time 
%       string in name of SiL
%
%   startDIVeCodeBased(__,'debugMode',bFlag)
%       run transformation in debug mode
%
%   startDIVeCodeBased(__,'resultFolder',sString)
%       user defined Sil results folder (containing main Sil folder as setup name):
%           sString = {workspace path}\SiLs\{setup name}\results
%
%   startDIVeCodeBased(__,'Endpoint',sString)
%   startDIVeCodeBased(__,'Token',sString)
%   startDIVeCodeBased(__,'SimId',sString)
%   startDIVeCodeBased(__,'Stream',sString)
%   startDIVeCodeBased(__,'User',sString)
%
%   sPathSim = startDIVeCodeBased(__)
%   [sPathSim,bSuccess] = startDIVeCodeBased(__)
%   [sPathSim,bSuccess,oCbt] = startDIVeCodeBased(__)
%
% Inputs:
%
%   sFile - string [optional]:
%       filepath of DIVe Configuration or starting folder for configuration
%       selection
%
%   nStartType - integer [optional]:
%       start and run type of configuration, default = 3 (only transform)
%           0: Open transformed configuration with Silver GUI
%           1: Run transformed configuration with Silver GUI
%           2: Run transformed configuration in background
%           3: Only transform configuration to Silver
%           4: Open configuration in dbc
%
%   sPathPrevious - string [optional] => currently not supported!:
%       path of previous simulation run
%
%   varargin - parameter/value pairs [optional]:
%       'shortName' - logical (default: false):
%           true: Name of final Silver environment is name of DIVe config
%           without date and user name tags: Attention! 
%           Older environments with equal names will be overwritten!
%       'debugMode' - logical (default: false):
%           true: D2S process will run in Matlab debug mode and will stop
%           in any case of errors.
%       'resultFolder' - string (default: '')
%           user defined result folder path with following format;
%           {root}\{workspace}\SiLs\{setup name}\results
%       'Endpoint' - string:
%           DIVeONE simulation endpoint, e.g. URL of DIVe ONE
%       'Token' - string:
%           DIVeONE simulation state update token
%       'SimId' - string:
%           number of simlation ID of DIVeONE
%       'Stream' - string:
%           Perforce Helix stream name (needed for determination of stream
%           in dsim and dqsPipeline call environments)
%       'User' - string:
%           Perforce Helix user ID (needed for determination of stream in
%           dsim and dqsPipeline call environments)
%       
% Outputs:
%
%   sPathSim - string:
%       simulation path in case of specified configuration and/or 
%       startoption
%
%   bSuccess - logical:
%       flag if DIVe code based transformation/simulation was successfully
%       finished
%
%   oCbt - object of type cbtClassCbtMain
%       contains all neccessary data of DIVe Code Based transformation
%       process
%
%
% See also: startDIVeMB, dsv
%
% Subfunctions: dmsBatchCall, dmsInfoClientGet, dmsInit, dmsPathMatlabInit, 
%   dmsPathRootInit, dmsPlatformVersion, dmsStreamOfPath, strsplitOwn
%
% See also: dbcPreferences, dsv, getenvOwn, hlxFormParse, hlxOutParse, p4, 
%   parseArgs, pathparts, startDIVeCB, strGlue, systeminfo, umsInit, 
%   umsMsg, verLessThanMATLAB, startDIVeMB
%
% Author: Elias Rohrer, TE/PTC, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2024-08-13

% init and handle reset of sMP structure variable
sMP = dmsInit;

% set Matlab pathes 
sMP.platform = dmsPathMatlabInit(sMP.platform);

% get platform root/Content pathes
sMP.platform = dmsPathRootInit(sMP.platform);

% get user/client specific information
sMP.platform.user = dmsInfoClientGet;

% get and display platform information
sMP.platform = dmsPlatformVersion(sMP.platform,varargin{:});

% store sMP
assignin('base','sMP',sMP);

% check Silver installation
silSilverInstallationCheck;

% platform ready
umsMsg('DIVe',1,'DIVe CodeBased Stream/Version "%s" is ready... (%s)\n',...
    sMP.platform.version,sMP.platform.path);

% get DIVe config xml file
[sFileConfig,nStartType,cVarArgs] = dmsParseInputArgs(varargin{:});

% execute with given start type
[sPathSim,bSuccess,oCbt] = dmsExecWithStartType(sFileConfig,nStartType,...
    cVarArgs);

return

% =========================================================================

function sMP = dmsInit
% DMSINIT initialization of DIVeCB with check of restart or new
% initialization. Determines platform root on basis of this file location
% (no free refactoring of this function possible).
%
% Syntax:
%   sMP = dmsInit
%
% Inputs:
%
% Outputs:
%   sMP - struct with fields
%    .platform - struct with fields
%      .path - string with platform root path
%
% Example: 
%   sMP = dmsInit

% check for existing sMP of DIVe CB
sPathRoot = fileparts(mfilename('fullpath'));
if evalin('base','exist(''sMP'',''var'')')
    sMP = evalin('base','sMP');
    
    % check for same version
    if isfield(sMP,'platform') && ...
            isfield(sMP.platform,'name') && ...
            strcmp(sMP.platform.name,'DIVe CodeBased')
        if strcmp(sMP.platform.path,sPathRoot)
            % reset runtime paths
            if isfield(sMP.platform,'mpath') && ...
                    isfield(sMP.platform.mpath,'runtime') && ...
                    ~isempty(sMP.platform.mpath.runtime)
                cPath = strsplitOwn(path,pathsep);
                for nIdxPath = 1:numel(sMP.platform.mpath.runtime)
                    if any(strcmp(sMP.platform.mpath.runtime{nIdxPath},cPath))
                        rmpath(sMP.platform.mpath.runtime{nIdxPath});
                    end
                end
                sMP.platform.mpath.runtime = {};
            end
        else
            % different version loaded
            fprintf(2,['ERROR: Another DIVe CB Version is still active: %s\n' ...
                       'The new DIVe CodeBased instance was not started!'],...
                sMP.platform.path);
            return
        end
    else % no valid DIVeCB struct within sMP
        % reset needed or other platform loaded
        if usejava('desktop') % user interface available
            sButton = questdlg({'The workspace contains a corrupt or non-DIVe CB sMP variable.',...
                                'Do want to reset the sMP variable?'},...
                'Reset sMP Workspace','Reset','Cancel','Reset');
            if strcmp(sButton,'Reset')
                sMP = struct();
            end
        else % only commandline in batchmode available
            % reset sMP variable
            sMP = struct();
        end
    end
else % no sMP variable exist - standard initialization
    % initialilize message queue and add basic function pathes
    addpath(fullfile(sPathRoot,'Utilities','MB'));
    addpath(genpath(fullfile(sPathRoot,'Function')));
    umsInit({'DIVe'},{'commandLine'},4,1);
end
sMP.platform.path = sPathRoot;
return

% =========================================================================

function xPlatform = dmsPathMatlabInit(xPlatform)
% DMSPATHMATLABINIT add Matlab pathes of platform.
%
% Syntax:
%   xPlatform = dmsPathMatlabInit(xPlatform)
%
% Inputs:
%   xPlatform - struct with fields
%      .path - string with platform root path
%
% Outputs:
%   xPlatform - struct with fields
%      .mpath.utilities - cell with pathes added to Matlab path
%      .content - string with path of Content folder tree
%      .configuration - string with path of Configuration folder tree
%      .cPath - cell (1xn) of strings with potential other base folders
% 
% Example: 
%   xPlatform.path = fileparts(mfilename('fullpath'));
%   xPlatform = dmsPathMatlabInit(xPlatform);

% initialize runtime paths added to the MATLAB path environment
xPlatform.mpath.runtime = {};

% generate addpath information for utility folders 
% (will be removed from MATLAB path on exit)
% standard (ddm, drm) setting
cPathExpand = {fullfile(xPlatform.path,'Utilities')};
% other options
cPath = pathparts(xPlatform.path);
nInt = find(strcmp('int',cPath));
if ~isempty(nInt)
    % dbm setting
    cPathExpand{end+1} = fullfile(cPath{1:nInt-1},'com','Function','CHK');
    cPathExpand{end+1} = fullfile(cPath{1:nInt-1},'com','Function','DPS');
    cPathExpand{end+1} = fullfile(cPath{1:nInt-1},'com','Function','ModuleDev');
    cPathExpand{end+1} = fullfile(cPath{1:nInt-1},'com','Function','TEST');
    % d_main setting starting from int
    cPathExpand{end+1} = fullfile(cPath{1:nInt-1},'com','DIVe','Function','CHK');
    cPathExpand{end+1} = fullfile(cPath{1:nInt-1},'com','DIVe','Function','DPS');
    cPathExpand{end+1} = fullfile(cPath{1:nInt-1},'com','DIVe','Function','ModuleDev');
    cPathExpand{end+1} = fullfile(cPath{1:nInt-1},'com','DIVe','Function','TEST');
    cPathExpand{end+1} = fullfile(cPath{1:nInt-1},'int','DIVe','Function','DBC');
    cPathExpand{end+1} = fullfile(cPath{1:nInt-1},'int','DIVe','Function','PPE_Utilities');
end
xPlatform.mpath.utilities = strsplitOwn(strGlue(...
    cellfun(@genpath,cPathExpand,'UniformOutput',false),pathsep),pathsep);

% remove pathes from addpath scope
cRemove = {fullfile('TISC','src') % TISC source parts (get added individually)
           fullfile('Utilities','Tools','Roadmaker') % remove numerous subfolders of roadmaker
           fullfile('Utilities','CB','Documentation') % remove documentation folder
           };
for nIdxRemove = 1:numel(cRemove)
       bKeep = cellfun(@isempty,strfind(xPlatform.mpath.utilities,cRemove{nIdxRemove}));
       xPlatform.mpath.utilities = xPlatform.mpath.utilities(bKeep);
end

% add only base path of Roadmaker, if it is present
sPathRoadmaker = fullfile(xPlatform.path,'Utilities','Tools','Roadmaker');
if exist(sPathRoadmaker,'dir')
    xPlatform.mpath.utilities{end+1} = sPathRoadmaker;
end

% % check against existing MATLAB path environment
% cPath = strsplitOwn(path,';'); % get list of current MATLAB path
% bRoot = cellfun(@(x)strcmp(matlabroot,x(1:min(numel(x),numel(matlabroot)))),cPath);
% cPath = cPath(~bRoot);
% bPath = ismember(xPlatform.mpath.utilities,cPath);
% xPlatform.mpath.utilities = xPlatform.mpath.utilities(~bPath);

% add paths 
if ~isempty(xPlatform.mpath.utilities)
    xPlatform.mpath.utilities = unique(xPlatform.mpath.utilities,'stable');
    warning('off'); %#ok<WNOFF>
    addpath(xPlatform.mpath.utilities{:});
    warning('on'); %#ok<WNON>
end
return

% =========================================================================

function xPlatform = dmsPathRootInit(xPlatform)
% DMSPATHROOTINIT initialize root pathes for content and configuration.
%
% Syntax:
%   xPlatform = dmsPathRootInit(xPlatform)
%
% Inputs:
%   xPlatform - struct with fields
%      .path - string with platform root path
%
% Outputs:
%   xPlatform - struct with fields
%      .content - string with path of Content folder tree
%      .configuration - string with path of Configuration folder tree
%      .cPath - cell (1xn) of strings with potential other base folders
% 
% Example: 
%   xPlatform.path = fileparts(mfilename('fullpath'));
%   sMP = dmsPathRootInit(sMP)

if exist('dbcPreferences','file')==2
    % get content and configuration path from DIVe Basic Configurator
    xDBC = dbcPreferences;
    xPlatform.content = xDBC.sPathContent;
    xPlatform.configuration = xDBC.sPathConfiguration;
    xPlatform.cPath = xDBC.cPath;
else
    % backup - use local directories (with speculative correction of int/com)
    sPathRoot = strrep(xPlatform.path,[filesep 'int' filesep],[filesep 'com' filesep]);
    xPlatform.content = fullfile(sPathRoot,'Content');
    xPlatform.configuration = fullfile(sPathRoot,'Configuration');
    xPlatform.cPath = {sPathRoot};
end
return

% =========================================================================

function xUser = dmsInfoClientGet
% DMSINFOCLIENTGET get information on execution client with hardware and
% software version for result and error tracing.
%
% Syntax:
%   sMP = dmsInfoClientGet
%
% Inputs:
%
% Outputs:
%   xUser - structure with user client information
%
% Example: 
%   sMP = dmsInfoClientGet

% get general info of current system
[nStatus,sLineMulti] = system('vol c:'); %#ok
sLine = strrep(sLineMulti,char(10),'');
sVolume = regexp(sLine,'\w{4}-\w{4}','match','once');
xUser = systeminfo;
xUser.mversion = ver;
xUser.volume = sVolume;
return

% =========================================================================

function xPlatform = dmsPlatformVersion(xPlatform,varargin)
% DMSPLATFORMVERSION determine platform version and release dates. E.g.
% used for Transfer Manager diff package creation.
%
% Syntax:
%   xPlatform = dmsPlatformVersion(xPlatform)
%   xPlatform = dmsPlatformVersion(xPlatform,varargin)
%
% Inputs:
%   xPlatform - structure with fields: 
%    .path - string with platform root path
%
% Outputs:
%   xPlatform - structure with fields: 
%    .version - string with platform version
%    .datestr - string with release date & time
%    .datenum - real with release date & time
%
% Example: 
%   xPlatform = dmsPlatformVersion(xPlatform)

% get and display platform information
xPlatform.name = 'DIVe CodeBased';
sFileVersion = fullfile(xPlatform.path,'Utilities','MB','PlatformVersion.txt');
if exist(sFileVersion,'file')
    nFid = fopen(sFileVersion,'r');
    xPlatform.version = fgetl(nFid);
    xPlatform.datestr = fgetl(nFid);
    fclose(nFid);
    xPlatform.datenum = datenum(xPlatform.datestr);
else
    % PlatformVersion.txt file missing - limited capability on
    % TransferManager for diff packages
    xPlatform.version = 'unknown';
    
    % try to determine Perforce Helix stream
    if nargin > 5
        xPlatform.version = dmsStreamOfPath(varargin{5:end});
    else
        xPlatform.version = dmsStreamOfPath('dummy','noValue');
    end
        
    vTime = now;
    xPlatform.datestr = datestr(vTime);
    xPlatform.datenum = vTime;
end
return

% =========================================================================

function sStream = dmsStreamOfPath(varargin)
% dmsStreamOfPath determine stream name either from input parameters of via
% Perforce Helix  requests. 
%
% Syntax:
%   sStream = dmsStreamOfPath(varargin)
%
% Inputs:
%   varargin - cell with dmb deditcated parameter cell and parameter value pairs
%              Stream: Perforce Helix Stream used for simulation 
%              (needed in case of DIVeONE simulations SyncType/Download "simOnly" via dsim or 
%              dqsPipeline, where the workspace is already deleted)
%
% Outputs:
%   sStream - string with Perforce Helix stream name, if no determination
%             is possible "unknown" is returned
%
% Example: 
%   sStream = dmsStreamOfPath(varargin{:})
%   sStream = dmsStreamOfPath('Stream','d_main')

% check input
if nargin > 0 && iscell(varargin{1})
    varargin = varargin(2:end);
end
xArg = parseArgs({'Stream','',[];...
                  'User','',[]},...
                 varargin{:});

% return specified stream
if isfield(xArg,'Stream') && ~isempty(xArg.Stream)
    sStream = xArg.Stream;
    return
else
    % init output
    sStream = 'unknown';
end

% get environment
sHost = getenvOwn({'computername'});
sPathFile = mfilename('fullpath');

% try to determine user for Perforce Query
if isempty(xArg.User)
    cSet = hlxOutParse(p4('set'),{'=',' '},2,true);
    bUser = strcmp('P4USER',cSet(:,1));
    if any(bUser)
        xArg.User = cSet{bUser,2};
    end
end

% determine stream
if ~isempty(xArg.User)
    cClient = hlxOutParse(p4(sprintf('-u %s clients -E %s_%s*',xArg.User,xArg.User,sHost)),' ',5,true);
    if strcmp(cClient{1,1},'Client')
        cRoot = cellfun(@(x)['^' regexptranslate('escape',[x,filesep])],cClient(:,5),'UniformOutput',false);
        bClient = ~cellfun(@isempty,regexpi([sPathFile,filesep],cRoot,'once','start'));
        if sum(bClient) == 1
            cStream = hlxFormParse(p4(sprintf('client -o %s',cClient{bClient,2})),'Stream',' ',1);
            sStream = regexp(cStream{1},'\w+$','match','once');
        end
    end
end
return

% =========================================================================

function [sFileConfig,nStartType,cVarArgs] = dmsParseInputArgs(varargin)

% init output
sFileConfig = '';
nStartType = 3; % transform configuration to Silver as default
cVarArgs = {};

% optional arguments
if nargin > 2
    cVarArgs = varargin(3:end);
end

% start type
if nargin > 1
    nStartType = varargin{2};
end

% configuration file
if nargin > 0
    sFileConfig = dmsCheckFileConfig(varargin{1});
end
    
% no arguments
if nargin == 0
    nStartType = 4; % just open dbc if no arguments given
end

return

% =========================================================================

function sFileConfig = dmsCheckFileConfig(sPathArg)

% configuration file determination
if exist(sPathArg,'file')==2
    sFileConfig = sPathArg;
elseif exist(sPathArg,'dir')==7
    % Select config or configurator
    sDir = fullfile(sPathArg, '*.xml');
    [sFile, sPath] = uigetfile(sDir, 'Select config or press ESC to open DIVe Basic Configurator');
    if isnumeric(sFile) && sFile == 0
        % Open configurator
        sFileConfig = '';
    else
        sFileConfig = fullfile(sPath,sFile);
    end
else
    fprintf(2,'Unkown 1st argument type passed to startDIVeCodeBased.m\n');
end

return

% =========================================================================

function [sPathSim,bSuccess,oCbt] = dmsExecWithStartType(sFileConfig,nStartType,cVargArgs)

% init output
sPathSim = '';
bSuccess = false;
oCbt = [];

% check start type
switch nStartType
    
    case {0,1,2,3} % execute configuration with dsv
        
        % call DIVe simulation technology Silver scripts
        [bSuccess,sPathSim,oCbt] = dsv(sFileConfig,nStartType,cVargArgs{:});
        
    case 4 % open configuration with DBC
        
        % open dbc (with configuration if exists)
        fprintf('DIVe basic configurator is opening ...\n\n');
        if ~isempty(sFileConfig)
            dbc(sFileConfig);
        else
            dbc;
        end
        bSuccess = true;
        
    otherwise
        fprintf(2,'Unkown 2nd argument type passed to startDIVeCodeBased.m\n');
        
end

return

% =========================================================================

function cString = strsplitOwn(str,split,bMultipleDelimsAsOne)
% STRSPLITOWN splits a string into segements divided by another specfied
% string or character.
% The function uses a boolean copy of the vector, so is not suitable for
% splitting very long strings.
%
% Syntax:
%   cString = strsplitOwn(str,split)
%   cString = strsplitOwn(str,split,bMultipleDelimsAsOne)
% 
% Inputs:
%   str     - string to be split
%   split   - string or cell with strings 
% bMultipleDelimsAsOne - boolean for treating multiple split delimiters as one
% 
% Outputs:
%   cString - cell with strings containing the non-empty split parts of the
%             passed string
% 
% Example:
% cellstr = strsplitOwn('this is bump a string','bump')
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-8485-3325
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2009-05-23

% return on empty string
if isempty(str)
    cString = {};
    return
end

% path input parameters
if nargin<3
    bMultipleDelimsAsOne = true;
end

% ensure cell type of split
if ~iscell(split)
    split = {split};
end
    
% create splitting information
tf = true(size(str));
for k = 1:length(split)
    pos = strfind(str,split{k});
    for m = 1:length(pos)
        tf(pos(m):pos(m)+length(split{k})-1) = false;
    end
end

% split string
str(~tf) = char(10); %#ok<CHARTEN>
if verLessThanMATLAB('8.4.0')
    ccString = textscan(str, '%s', 'Delimiter',char(10),'MultipleDelimsAsOne',...
        bMultipleDelimsAsOne,'BufSize',262144); %#ok<BUFSIZE,CHARTEN>
else
    ccString = textscan(str, '%s', 'Delimiter',char(10),'MultipleDelimsAsOne',...
        bMultipleDelimsAsOne);
end
cString = ccString{1};
return
