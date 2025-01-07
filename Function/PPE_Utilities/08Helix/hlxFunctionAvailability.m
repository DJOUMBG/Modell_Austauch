function [nStatus] = hlxFunctionAvailability(cFunctionName,cStream,cFolder)
% HLXFUNCTIONAVAILABILITY ensure availability of specified Matlab functions
% and add pathes derived from stream/folder specifications to Matlab path
% if missing functions are found there.
% If current system user differs from Helix p4 set user, the current system
% is also included in the clientr/workspace search.
%
% Syntax:
%   nStatus = hlxFunctionAvailability(cFunctionName,cStream,cFolder)
%
% Inputs:
%   cFunctionName - cell (1xn) of strings with functions needed
%         cStream - cell (1xm) of strings with streams, which may include
%                   the function
%         cFolder - cell (1xo) of string with subpathes to search
%
% Outputs:
%   nStatus - integer (1x1) 
%
% Example: 
%   nStatus = hlxFunctionAvailability(cFunctionName,cStream,cFolder)
%   nStatus = hlxFunctionAvailability({'chkContent'},{'drd_DIVeScripts'},{'CHK'})
%
%
% Subfunctions: hlxClientHost, hlxClientStream2Root
%
% See also: getenvOwn, hlxFunctionAvailability, hlxOutParse, p4
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-8485-3325
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2022-04-08

%% check input
if nargin < 3
    cFolder = {};
end
if ischar(cFunctionName)
    cFunctionName = {cFunctionName};
end
if ischar(cStream)
    cStream = {cStream};
end
if ischar(cFolder)
    cFolder = {cFolder};
elseif iscell(cFolder) && ~isempty(cFolder)
    for nIdxFolder = 1:numel(cFolder)
        if iscell(cFolder{nIdxFolder})
            cFolder{nIdxFolder} = fullfile(cFolder{nIdxFolder}{:});
        end
    end
end

%% check function availability in Matlab
bMiss = false(size(cFunctionName));
for nIdxFcn = 1:numel(cFunctionName)
    sPathFunction = which(cFunctionName{nIdxFcn});
    if isempty(sPathFunction)
        bMiss(nIdxFcn) = true;
    end
end

%% check for functions in available workspaces of specified streams
if any(bMiss)
    % determine possible folders/files
    xClient = hlxClientHost;
    [cPathName,cName] = hlxFunctionPathGet(xClient,cStream,cFolder);
    if isempty(cName)
        fprintf(2,['hlxFunctionAvailability:noFunctionFound - no ' ...
            'functions found, no pathes added to Matlab path.'])
        nStatus = 1;
        return
    end
        
    % check for functions in file list
    [bExist,nExist] = ismember(cFunctionName(bMiss),cName);
    nExist = nExist(bExist);
    % add path of file to Matlab path
    if ~isempty(nExist)
        addpath(cPathName{nExist});
        for nIdxName = nExist
            fprintf(1,'added path to Matlab path for function "%s": %s\n',cName{nIdxName},cPathName{nIdxName});
        end
    end
    
    % report any non patched functions
    if any(~bExist)
        nStatus = 1;
        fprintf(2,'hlxFunctionAvailability:noFunctionFound - the functions below are not available:\n')
        cMiss = cFunctionName(bMiss);
        cMiss = cMiss(~bExist);
        fprintf(2,'  %s\n',cMiss{:});
    else
        nStatus = 0;
    end
else
    nStatus = 0;
end
return

% =========================================================================

function [xClient] = hlxClientHost
% HLXCLIENTHOST get list of clients of this host
%
% Syntax:
%   xClient = hlxClientHost
%
% Outputs:
%   xClient - structure (1xn) with fields: 
%     .name - string with workspace/client name
%     .root - string with root path of workspace
%
% Example: 
%   xClient = hlxClientHost

% get possible clients
cClient = hlxOutParse(p4('clients','--me'),' ',5,true);
if ~strcmpi(p4info('User name'),getenv('username'))
    cClientAdd = hlxOutParse(p4(sprintf('clients -u %s',lower(getenv('username')))),' ',5,true);
    cClient = [cClient;cClientAdd];
end

% limit clients to current host
sHost = upper(getenvOwn('computername'));
bHost = ~cellfun(@isempty,regexpi(cClient(:,2),sHost,'once'));
cClient = cClient(bHost,[2,5]); % reduce to (nx2)

% create output struct
xClient = struct('name',cClient(:,1),'root',cClient(:,2));
return

% =========================================================================

function [cPathName,cName] = hlxFunctionPathGet(xClient,cStream,cFolder)
% HLXFUNCTIONPATHGET get function names and their folders
%
% Syntax:
%   [cPathName,cName] = hlxFunctionPathGet(xClient,cStream)
%
% Inputs:
%   xClient - structure with fields: 
%     .name - string with workspace/client name
%     .root - string with root path of workspace
%   cStream - cell (1xn) of stream names
%   cFolder - cell (1xn) of subfolders within the stream workspace
%
% Outputs:
%   cPathName - cell (1xn) of strings with pathes of files
%       cName - cell (1xm) of strings of file names without extension
%
% Example: 
%   [cPathName,cName] = hlxFunctionPathGet(xClient,cStream)

cPath = {};
for nIdxStream = 1:numel(cStream)
    % determine client root of stream
    sRoot = hlxClientStream2Root(xClient,cStream{nIdxStream});
    
    if isempty(sRoot)
        fprintf(2,['hlxFunctionAvailability:hlxFunctionPathGet:noClientForStream - '...
            'the stream "%s" has no client for user "%s" on this computer.\n'],...
            p4info('User name'),cStream{nIdxStream})
    else
        cPathAdd = cellfun(@(x)fullfile(sRoot,x),cFolder,'UniformOutput',false);
        cPath = [cPath cPathAdd]; %#ok<AGROW>
    end
end

% check folders for existence
bPath = cellfun(@(x)exist(x,'dir')==7,cPath);
if ~any(bPath)
    fprintf(2,['hlxFunctionAvailability:hlxFunctionPathGet:noValidPathes - '...
            'no valid function pathes found - no pathes added.\n'])
    cPathName = {};
    cName = {};
    return
end
cPath = cPath(bPath);

% get files of folders
cFilePath = getFilesAll(cPath);
cName = cell(size(cFilePath));
cPathName = cell(size(cFilePath));
for nIdxFile = 1:numel(cFilePath)
    [cPathName{nIdxFile},cName{nIdxFile}] = fileparts(cFilePath{nIdxFile});
end
return

% =========================================================================

function sRoot = hlxClientStream2Root(xClient,sStream)
% HLXCLIENTSTREAM2ROOT get the root path of the first client matching a
% specified stream.
%
% Syntax:
%   sRoot = hlxClientStream2Root(xClient,sStream)
%
% Inputs:
%   xClient - structure with fields: 
%     .name - string with workspace/client name
%     .root - string with root path of workspace
%   sStream - string with stream name
%
% Outputs:
%   sRoot - string 
%
% Example: 
%   sRoot = hlxClientStream2Root(xClient,'drd_DIVeScripts')
cStream = regexp({xClient.name},'(?<=_)d[abdrsx]?[cdlm]?_\w+$','match','once');
nStream = find(strcmp(sStream,cStream));
if isempty(nStream)
    sRoot = '';
else
    sRoot = xClient(nStream(1)).root;
end
return
