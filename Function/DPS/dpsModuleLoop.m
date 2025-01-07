function [cPath,cPostExec] = dpsModuleLoop(xConfiguration,xModule,sPathContent,sPathRunDir,cPathBlock,nModelCopy,nDGPSuccess,nDGPFatal)
% DPSMODULELOOP loops over all modules for initialization according the
% DIVe module initialization order:
% 1.1 loop over all modules and load the files initIO dataset classTypes
% 1.2 propagate output initialization values to connected input
%     initialization values
% 2.  loop over all modules for following steps per module (dpsModuleInit)
% 2.1 add module's ModelSet path
% 2.2 add module's supportset pathes
% 2.3 copy all tagged files of ModelSet
% 2.4 [optional by nModelCopy] enable model within platform simulation
%     model (DIVe MB: copy to main model)
% 2.5 copy all tagged files of DataSets
% 2.6 load isStandard DataSet files except of dataClass initIO
% 2.7 exectute all tagged DataSet files
% 2.8 overwrite local dependent parameters from available global parameters
% 2.9 copy all tagged files from supportsets
% 2.10 execute all tagged files from supportsets
% 2.11 set global parameters
%
% Syntax:
%   cPath = dpsModuleLoop(xConfiguration,xModule,sPathContent,sPathRunDir,cPathBlock)
%   [cPath,cPostExec] = dpsModuleLoop(xConfiguration,xModule,sPathContent,sPathRunDir,cPathBlock)
%
% Inputs:
%   xConfiguration - structure with fields according DIVe configuration XML:  
%     .ModuleSetup - structure (1xn) with fields according DIVe 
%                    configuration XML: 
%       .Module    - structure with module information and fields:
%         .context - string with module context
%         .species - string with module species
%         .family  - string with module family
%         .type    - string with module type
%        ...
%       .Interface - structure with signal information
%         .Signal  - structure (1xm) with fields:
%           .name  - string with signal name
%           .modelRefSource - string with source ModuleSetup name
%           .source - structure (1x1) with fields:
%             .name - string with outport name at source module
%             .modelRef - string with source ModuleSetup name
%           .destination - structure (1xo) with fields:
%             .name - string with inport name at destination module
%             .modelRef - string with destination ModuleSetup name
%         ...
%          xModule - structure (1xn) with fields according DIVe module XML
%     sPathContent - string with path of DIVe content (contains folder 
%                    trees of bdry, phys, ctrl, human)
%      sPathRunDir - string with path of runtime directory for simulation
%       cPathBlock - cell (1xn) with the Simulink block pathes of each
%                    module defined in xConfiguration in the same order as
%                    in xConfiguration
%       nModelCopy - integer (1x1) or (1xn) for Simulink model block copy 
%                    operation to specified destination
%                       0: no copy
%                       1: DIVe MB style
%      nDGPSuccess - integer (1x1) with flag for display of successful
%                    overwrite local dependent parameter global parameter
%                      0: no success messages
%                      1: print success messages
%        nDGPFatal - integer (1x1) with flag if warning/error messages 
%                    should be fatal (use of warning and error functions)
%                      0: non fatal - use fprintf(2,...)
%                      1: fatal - use warning(...) and error(...)
%
% Outputs:
%   cPath - cell (1xn) with strings of filesystem pathes added to the
%           Matlab path
%   cPostExec - cell (1xn) with filepathes for post processing execution
%
% Example: 
%   cPath = dpsModuleLoop(xConfiguration,xModule,sPathContent,sPathRunDir,cPathBlock)
%
% Subfunctions: dpsDataSetVariantCollect, dpsPathModelLibCreate
%
% See also: dpsInitIOLoad, dpsInitTransfer, dpsModuleInit, dpsModuleSetupInfoGlue, pathparts
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-8485-3325
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2016-06-22

% check input
if nargin < 7
    nDGPSuccess = 1;
end
if nargin < 8
    nDGPFatal = 0;
end

%% initialization of initIO and value transfer
% get sMP structure from base workspace
if evalin('base','exist(''sMP'',''var'')')
    sMP = evalin('base','sMP');
else
    sMP = struct();
end

% remove old global parameters, if existing
if isfield(sMP,'global')
    sMP = rmfield(sMP,'global');
    fprintf(1,'dps: Info - the already existing sMP.global was removed from sMP.\n');
end

% load initialization value of all modules
fprintf(1,'dps: Loading initialization values of all modules...\n');
sMP = dpsInitIOLoad(sMP,xConfiguration.ModuleSetup,sPathContent);

% propagate outport to inport initialization values of connected ports
% umsMsg('DIVe',1,'dmb: Transfering initialization values...\n');
fprintf(1,'dps: Transfering initialization values...\n');
sMP = dpsInitTransfer(sMP,xConfiguration);

% check initIO values against inconsistent selection on multiple 
fprintf(1,'dps: Checking initialization value consistency among Modules...\n');
dpsInportValueCheck(sMP);

% transfer sMP structure back to Module workspace
assignin('base','sMP',sMP);

%% initialization of modules
% generate order vector
nInit = str2double({xConfiguration.ModuleSetup.initOrder}); 
[nTrash,nInitOrder] = sort(nInit); %#ok<ASGLU>

% loop according initialization order
cPath = {};
cPostExec = {};
for nIdxModule = nInitOrder 
    % get shortcuts
    sName = xConfiguration.ModuleSetup(nIdxModule).name;
    xModuleSetup = xConfiguration.ModuleSetup(nIdxModule);
    
    % fill species subsystem and init module (includes loading datasets)
    % umsMsg('DIVe',1,'dmb: Adding module "%s"...\n',sName);
    fprintf(1,'dps: Initializing module "%s"...\n',sName);
    
     % get main/library file of modelset                    
    sPathModelLib = dpsPathModelLibCreate(xModuleSetup,xModule(nIdxModule),sPathContent);
    
    % get model simulink block path
    sPathBlock = cPathBlock{nIdxModule}; % platform dependent - input required
    
    % generate pathes to dataset variant selections
    [cPathDataVariant,cDataClassName] = dpsDataSetVariantCollect(xModuleSetup,sPathContent);
    
    % get model copy option
    if numel(nModelCopy) > 1
        nModelCopyThis = nModelCopy(nIdxModule);
    else
        nModelCopyThis = nModelCopy;
    end
    
    %% initialize module by DIVe platform standard init function
    [cPathAdd,cPostExecAdd] = dpsModuleInit(xModule(nIdxModule),... % xModule
        sPathRunDir,... % sPathRunDir
        sPathModelLib,... % sPathModelLib
        sPathBlock,... sModelBlockPath
        cPathDataVariant,... % cPathDataVariant
        cDataClassName,...
        nModelCopyThis,...
        nDGPSuccess,...
        nDGPFatal); % cDataClassName
    
    cPath = [cPath,cPathAdd]; %#ok<AGROW>
    cPostExec = [cPostExec,cPostExecAdd]; %#ok<AGROW>
end
return
