function [bSuccess,sResultFolder,oCbt] = dsv(sConfigXmlFilepath,nRunType,~,varargin)
% DSV is the main function for simulations with DIVe simulation
% technique Silver (formerly DIVe CB): DIVe to Silver process -> "D2S"
% It is the starting point for building a simulation environment with 
% Silver from a DIVe configuration.
%
% Syntax:
%   dsv(sConfigXmlFilepath,nRunType)
%   dsv(sConfigXmlFilepath,nRunType,sPathPrevious) => not supported!
%   dsv(__,'Endpoint',sString)
%   dsv(__,'Token',sString)
%   dsv(__,'Endpoint',sString)
%   dsv(__,'SimId',sString)
%   dsv(__,'Stream',sString)
%   dsv(__,'User',sString)
%   dsv(__,'shortName',bFlag)
%   dsv(__,'debugMode',bFlag)
%   dsv(__,'resultFolder',sString)
%   bSuccess = dsv(__)
%   [bSuccess,sResultFolder] = dsv(__)
%   [bSuccess,sResultFolder,oCbt] = dsv(__)
%
% Inputs:
%   sConfigXmlFilepath - string:
%       full filepath of DIVe configuration xml file
%   nRunType - integer (1x1):
%       runtype of D2S process:
%           0: Open transformed configuration with Silver GUI
%           1: Run transformed configuration with Silver GUI
%           2: Run transformed configuration in background
%           3: Only transform configuration to Silver
%           4: Open configuration in dbc
%   (sPathPrevious) - string [optional]:  => not supported!
%       path of previous simulation run
%   varargin  - name/value pairs [optional]:
%       'shortName' - logical (default: false):
%           true: Name of final Silver environment is name of DIVe config
%           without date and user name tags: Attention! 
%           Older environments with equal names will be overwritten!
%       'debugMode' - logical (default: false):
%           true: D2S process will run in Matlab debug mode and will stop
%           in any case of errors.
%       'resultFolder' - string (default: '')
%           user defined result folder path with following format:
%               {workspace path}\SiLs\{setup name}\results
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
%   bSuccess - logical:
%       Flag, if process finished normaly (true) or not (false)
%   sResultFolder - string:
%       Result folder path of created Silver environment
%   oCbt - instance of class cbtClassCbtMain
%       Contains all informations about DIVe config and transformation
%       process
%
% Author: Elias Rohrer, TE/PTC, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2024-02-07


% check number of arguments
if nargin < 2
    error('Not enough input arguments.');
end

% convert into character vector
try
    sConfigXmlFilepath = char(sConfigXmlFilepath);
catch
    error('Input argument "sConfigXmlFilepath" can not be converted to character string.');
end

% check run type variable
if ~isnumeric(nRunType)
    error('Input argument "nRunType" must be numeric.');
end

% -------------------------------------------------------------------------

% split name-value pairs of variable optional input arguments
[xOneInfo,bShortName,bDebugMode,sResultFolderpath] = checkVarArgs(varargin);

% get workspace root folder
sWorkspaceRoot = getWorkspaceRootFolder(sConfigXmlFilepath);

% -------------------------------------------------------------------------

% call main class for transformation
oCbt = cbtClassCbtMain(sConfigXmlFilepath,nRunType,sWorkspaceRoot,bShortName,bDebugMode,xOneInfo,sResultFolderpath);

% get return value from object
bSuccess = oCbt.bSuccess;

% get final Sil folder
sResultFolder = oCbt.CONST.sResultFolder;

end % dsv

% =========================================================================

function [xOneInfo,bShortName,bDebugMode,sResultFolderpath] = checkVarArgs(cVarArgIn)

% init output
xOneInfo.Endpoint = '';
xOneInfo.Token = '';
xOneInfo.SimId = '';
xOneInfo.Stream = '';
xOneInfo.User = '';
bShortName = false;
bDebugMode = false;
sResultFolderpath = '';

% split varargin into name-value pairs
[cVarargNames,cVarargValues,bValid] = splitVarags(cVarArgIn);
if ~bValid
    error(['Incorrect constellation of variable name-value argument pairs.\n',...
        'Maybe missing value for name or name is not a char array.']);
end

% check for unique names
bValid = chkIsUnique(cVarargNames);
if ~bValid
    error('At least one variable argument was defined more than once.');
end

% assign optional arguments
for nVarArgs=1:numel(cVarargNames)

    % current vararg
    sVarargName = cVarargNames{nVarArgs};
    VarargValue = cVarargValues{nVarArgs};

    % switch argument name
    switch sVarargName
        
        case 'Endpoint'
            try
                xOneInfo.Endpoint = char(VarargValue);
            catch
                error('Can not convert value of variable argument "Endpoint" into character.');
            end
        
        % -----------------------------------------------------------------
        
        case 'Token'
            try
                xOneInfo.Token = char(VarargValue);
            catch
                error('Can not convert value of variable argument "Token" into character.');
            end
        
        % -----------------------------------------------------------------
        
        case 'SimId'
            try
                xOneInfo.SimId = char(VarargValue);
            catch
                error('Can not convert value of variable argument "SimId" into character.');
            end
        
        % -----------------------------------------------------------------
        
        case 'Stream'
            try
                xOneInfo.Stream = char(VarargValue);
            catch
                error('Can not convert value of variable argument "Stream" into character.');
            end
        
        % -----------------------------------------------------------------
        
        case 'User'
            try
                xOneInfo.User = char(VarargValue);
            catch
                error('Can not convert value of variable argument "User" into character.');
            end
        
        % -----------------------------------------------------------------
        
        case 'shortName'
            if isnumeric(VarargValue) || islogical(VarargValue)
                bShortName = logical(VarargValue);
            else
                error('Value of variable argument "%s" is not numeric or logical but from type "%s".',...
                    sVarargName,class(VarargValue));
            end
        
        % -----------------------------------------------------------------
     	
        case 'debugMode'
            if isnumeric(VarargValue) || islogical(VarargValue)
                bDebugMode = logical(VarargValue);
            else
                error('Value of variable argument "%s" is not numeric or logical but from type "%s".',...
                    sVarargName,class(VarargValue));
            end
            
        % -----------------------------------------------------------------
     	
        case 'resultFolder'
            if ischar(VarargValue)
                sResultFolderpath = VarargValue;
            else
                error('Value of variable argument "%s" is not a char array but from type "%s".',...
                    sVarargName,class(VarargValue));
            end
      	
        % -----------------------------------------------------------------
      	
        otherwise
            error('Unkown variable argument "%s".',sVarargName);

    end % switch sVarargName

end % for cVarargNames

end % checkVarArgs

% =========================================================================

function sWorkspaceRoot = getWorkspaceRootFolder(sConfigXmlFilepath)

% init output
sWorkspaceRoot = '';

% check for workspace root in sMP structure
if evalin('base','exist(''sMP'',''var'')')
    sMP = evalin('base','sMP');
    sWorkspaceRoot = sMP.platform.path;
end

% try to get workspace root from configuration xml file
if isempty(sWorkspaceRoot)
    sWorkspaceRoot = getWorkspaceFromConfig(sConfigXmlFilepath);
end

% check for valid workspace root folder
if isempty(sWorkspaceRoot) || ~exist(sWorkspaceRoot,'dir')
    error('No valid workspace root folder was found.');
end

end % getWorkspaceRootFolder

% =========================================================================

function sWorkspaceRoot = getWorkspaceFromConfig(sConfigXmlFilepath)

% init output
sWorkspaceRoot = '';

% get file parts
sConfigFolderpath = fileparts(sConfigXmlFilepath);

% get folder structure from config xml
cFolderParts = strsplit(sConfigFolderpath,filesep);

% check for correct number of folder parts in DIVe context
if numel(cFolderParts) < 5
    return;
end

% check for Configuration folder in folder structure
if ~strcmp(cFolderParts{end-2},'Configuration')
    return;
end

% assumption that the workspace folder is one level above "Configuration"
sWorkspaceRoot = fullfile(cFolderParts{1:end-3});

end % getWorkspaceFromConfig
