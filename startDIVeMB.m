function varargout = startDIVeMB(varargin)
% STARTDIVEMB start and initialization of platform DIVe ModelBased.
% All platform scripts and functions are added to the MATLAB path
%
% Syntax:
%   startDIVeMB
%   startDIVeMB(sFile)
%   startDIVeMB(sPath)
%   startDIVeMB(sFile,nStartType)
%   startDIVeMB(sFile,nStartType,sPathPrevious)
%   startDIVeMB(sFile,nStartType,sPathPrevious,cOption)
%   startDIVeMB(sFile,nStartType,sPathPrevious,cOption,<parameter>,<value>)
%
% Inputs:
%        sFile - [optional] string with filepath of DIVe Configuration or 
%                starting folder for configuration selection
%   nStartType - [optional] integer (1x1) with start type
%                0: open Configuration as model in Simulink
%                1: open Confiugration as model in Simulink and run 
%                   simulation 
%                2: run Simulation with hidden model
%                3: run Simulation with hidden model (might change in future)
%                4: open configuration in DBC
%   sPathPrevious - [optional] string with path of previous simulation run
%         cOption - [optional] cell (1xn) with either strings of special options
%                   'EatsInitAll': restart with exact state of all elements
%                                  including temperature
%                   'EatsInitScr': restart with load states of SCR (NH3,
%                                  H2O)
%                   'MdlHide': hide the Simulink Model during runtime
%                   'RunPwd': use current path as runtime path
%        varargin - parameter/value pairs [optional]:
%                   'Endpoint' - string with DIVeONE simulationi endpoint
%                   'Token'    - string with DIVeONE simulation state update token
%                   'SimId'    - string with number of simlation ID of DIVeONE
%                   'Stream'   - string with Perforce Helix stream name (needed for determination of
%                                stream in dsim and dqsPipeline call environments)
%                   'User'     - string with Perforce Helix user ID (needed for determination of
%                                stream in dsim and dqsPipeline call environments)
%
% Outputs:
%   sPathSim - [optional] string with simulation path in case of specified
%              configuration and/or startoption
%
% Example: 
%   startDIVeMB
%   startDIVeMB('C:\DIVe\Configuration\Vehicle_Other\LDYN\EDB_cool_test.xml') % select config
%   startDIVeMB(['C:\DIVe\Configuration\Vehicle_Other\LDYN'); % select config from preferred folder
%   startDIVeMB(fullfile(pwd,'Configuration','Vehicle_Other','LDYN'); % select config from preferred folder
%   startDIVeMB('C:\DIVe\Configuration\Vehicle_Other\LDYN\EDB_cool_test.xml',0) % open Simulink model
%   startDIVeMB('C:\DIVe\Configuration\Vehicle_Other\LDYN\EDB_cool_test.xml',1) % simulate Simulink model
%   startDIVeMB('C:\DIVe\Configuration\Vehicle_Other\LDYN\EDB_cool_test.xml',2) % open Confgiuration in DBC
%   startDIVeMB('C:\dirsync\08Helix\11d_main\com\DIVe\Configuration\Vehicle_Other\DIVeDevelopment\CosimCheckTime.xml',1,[],{},'Stream','testStream','User','rafrey5'),sMP.platform.version
%
% See also: dmb, dbc, strsplitOwn, systeminfo
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-8485-3325
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2015-10-19

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
assignin('base','sMP',sMP)

% platform ready
umsMsg('DIVe',1,'DIVe ModelBased Stream/Version "%s" is ready... (%s)\n',...
    sMP.platform.version,sMP.platform.path);
if usejava('desktop')
    fprintf(1,'Click to <a href="matlab:dbc">open Configurator</a>\n');
end

% execute batch calls
sPathSim = dmsBatchCall(varargin{:});

% assign output
if nargout < 1
    varargout = {};
else
    varargout = {sPathSim};
end
return

% =========================================================================

function sMP = dmsInit
% DMSINIT initialization of DIVeMB with check of restart or new
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

% check for existing sMP of DIVe MB
sPathRoot = fileparts(mfilename('fullpath'));
if evalin('base','exist(''sMP'',''var'')')
    sMP = evalin('base','sMP');
    
    % check for same version
    if isfield(sMP,'platform') && ...
            isfield(sMP.platform,'name') && ...
            strcmp(sMP.platform.name,'DIVe ModelBased')
        if strcmp(sMP.platform.path,sPathRoot)
            % reset runtime paths
            if isfield(sMP.platform,'mpath') && ...
                    isfield(sMP.platform.mpath,'runtime') && ...
                    ~isempty(sMP.platform.mpath.runtime)
                cPath = strsplitOwn(path,';');
                for nIdxPath = 1:numel(sMP.platform.mpath.runtime)
                    if any(strcmp(sMP.platform.mpath.runtime{nIdxPath},cPath))
                        rmpath(sMP.platform.mpath.runtime{nIdxPath});
                    end
                end
                sMP.platform.mpath.runtime = {};
            end
        else
            % different version loaded
            fprintf(2,['ERROR: Another DIVe MB Version is still active: %s\n' ...
                       'The new DIVe ModelBased instance was not started!'],...
                sMP.platform.path);
            return
        end
    else % no valid DIVeMB struct within sMP
        % reset needed or other platform loaded
        if usejava('desktop') % user interface available
            sButton = questdlg({'The workspace contains a corrupt or non-DIVe MB sMP variable.',...
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
if strncmp(computer,'GLNX',4)
    sPathSep = ':';
else 
    sPathSep = ';';
end
xPlatform.mpath.utilities = strsplitOwn(strGlue(...
    cellfun(@genpath,cPathExpand,'UniformOutput',false),sPathSep),sPathSep);

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
    addpath(xPlatform.mpath.utilities{:});
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
xPlatform.name = 'DIVe ModelBased';
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
sLine = strrep(sLineMulti,char(10),''); %#ok<CHARTEN>
sVolume = regexp(sLine,'\w{4}-\w{4}','match','once');
xUser = systeminfo;
xUser.mversion = ver;
xUser.volume = sVolume;
return

% =========================================================================

function sPathSim = dmsBatchCall(varargin)
% DMSBATCHCALL execute batch and direct call options of startDIVeMB.
%
% Syntax:
%   sPathSim = dmsBatchCall(varargin)
%   sPathSim = dmsBatchCall(sFile)
%   sPathSim = dmsBatchCall(sPath)
%   sPathSim = dmsBatchCall(sFile,nStartType)
%   sPathSim = dmsBatchCall(sFile,nStartType,sPathPrevious)
%   sPathSim = dmsBatchCall(sFile,nStartType,sPathPrevious,cOption)
%   sPathSim = dmsBatchCall(sFile,nStartType,sPathPrevious,cOption,<parameter>,<value>)
% 
% Inputs:
%        sFile - [optional] string with filepath of DIVe Configuration or 
%                starting folder for configuration selection
%   nStartType - [optional] integer (1x1) with start type
%                0: open configuration as model in Simulink
%                1: open confiugration as model in Simulink and start 
%                   simulation directly
%                2: open configuration in DBC
%
% Inputs:
%        sFile - [optional] string with filepath of DIVe Configuration or 
%                starting folder for configuration selection
%   nStartType - [optional] integer (1x1) with start type
%                0: open Configuration as model in Simulink
%                1: open Confiugration as model in Simulink and run 
%                   simulation 
%                2: run Simulation with hidden model
%                3: run Simulation with hidden model (might change in future)
%                4: open configuration in DBC
%   sPathPrevious - [optional] string with path of previous simulation run
%         cOption - [optional] cell (1xn) with either strings of special options
%                   'EatsInitAll': restart with exact state of all elements
%                                  including temperature
%                   'EatsInitScr': restart with load states of SCR (NH3,
%                                  H2O)
%                   'MdlHide': hide the Simulink Model during runtime
%                   'RunPwd': use current path as runtime path
%        varargin - parameter/value pairs [optional]:
%                   'Endpoint' - string with DIVeONE simulationi endpoint
%                   'Token'    - string with DIVeONE simulation state update token
%                   'SimId'    - string with number of simlation ID of DIVeONE
%                   'Stream'   - string with Perforce Helix stream name (needed for determination of
%                                stream in dsim and dqsPipeline call environments)
%                   'User'     - string with Perforce Helix user ID (needed for determination of
%                                stream in dsim and dqsPipeline call environments)
%
% Outputs:
%   sPathSim - [optional] string with simulation path in case of specified configuration and/or
%               startoption
%
% Example: 
%   dmsBatchCall
%   dmsBatchCall('C:\DIVe\Configuration\Vehicle_Other\LDYN\EDB_cool_test.xml') % select config
%   dmsBatchCall(['C:\DIVe\Configuration\Vehicle_Other\LDYN'); % select config from preferred folder
%   dmsBatchCall(fullfile(pwd,'Configuration','Vehicle_Other','LDYN'); % select config from preferred folder
%   sPathSim = dmsBatchCall('C:\DIVe\Configuration\Vehicle_Other\LDYN\EDB_cool_test.xml',0) % open Simulink model
%   sPathSim = dmsBatchCall('C:\DIVe\Configuration\Vehicle_Other\LDYN\EDB_cool_test.xml',1) % simulate Simulink model
%   dmsBatchCall('C:\DIVe\Configuration\Vehicle_Other\LDYN\EDB_cool_test.xml',2) % open Confgiuration in DBC
%
% See also: dmb, dbc

% initialize output
sPathSim = '';

% patch input
if nargin < 2
    nStartType = 0; % open model in Simulink
else
    nStartType = varargin{2};
end

% batch mode
if nargin > 0
    % configuration file determination
    if exist(varargin{1},'file')==2
        sFileConfig = varargin{1};
    elseif exist(varargin{1},'dir')==7
        % Select config or configurator
        sDir = fullfile(varargin{1}, '*.xml');
        [sFile, sPath] = uigetfile(sDir, 'Select config or press ESC to open DIVe Basic Configurator');
        if isnumeric(sFile) && sFile == 0
            % Open configurator
            nStartType = 2;
            sFileConfig = '';
        else
            sFileConfig = fullfile(sPath,sFile);
        end
    else
        fprintf(2,'Unkown 1st argument type passed to startDIVeMB.m\n');
    end
    
    % issue batch operation
    switch nStartType
        case {0,1} % open configuration with dmb
            sPathSim = dmb(sFileConfig,nStartType,varargin{3:end});
        case {2,3} % run simulation with dmb and hidden model
            if nargin > 3 && iscell(varargin{4})
                varargin{4} = [{'MdlHide'} varargin{4}];
            else
                if nargin > 2
                    varargin = [varargin(1:3) {{'MdlHide'}} varargin(4:end)];
                else
                    varargin = [varargin(1) {2 '' {'MdlHide'}} varargin(4:end)];
                end
            end
            sPathSim = dmb(sFileConfig,nStartType,varargin{3:end});
        case 4 % open configuration with DBC
            dbc(sFileConfig);
        otherwise
            fprintf(2,'Unkown 2nd argument type passed to startDIVeMB.m\n');
    end
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
        bMultipleDelimsAsOne); %#ok<CHARTEN>
end
cString = ccString{1};
return
