function sPathResult = dqsResultCopy(xSim,sPathResultScratch,sIssuer)
% DQSRESULTCOPY copy results to an upper level folder (intended for local simulation via DIVeONE
% companion).
%
% Syntax:
%   sPathResult = dqsResultCopy(xSim)
%
% Inputs:
%   xSim - structure with fields: 
%    .pathWork  - string with path of base working directory (DIVeONE specified or DQS)
%    .pathRun   - string with path of simulation runtime folder (only from Simulink currently)
%    .simType   - string with Simulation Technology type used
%   sPathResultScratch - char (1xn) with path of results/scratch directory to copy results folder
%   sIssuer - char (1xn) with name of issuing file/function
%
% Outputs:
%   sPathResult - string with path of copied results
%
% Example: 
%   sPathResult = dqsResultCopy(xSim)
%
% Subfunctions: dqsResultCopyFiles
%
% See also: pathparts, robocopy, dsim, dqsPipeline
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-8485-3325
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2023-08-01

% determine specific run folder name and potential result/log source folder
cPathRun = pathparts(xSim.pathRun);
switch xSim.simType
    case 'Simulink'
        sFolderRun = cPathRun{end};
        cPathCopy = {xSim.pathRun % Simulink: run folder
            fullfile(xSim.pathRun,'results')}; % Simulink ExACT
    case 'Silver'
        sFolderRun = cPathRun{end-1};
        cPathCopy = {
            fileparts(xSim.pathRun) % Silver base SiL folder for Config XML
            fullfile(fileparts(xSim.pathRun),'Master') % sMP.mat
            fullfile(fileparts(xSim.pathRun),'logs') % Silvers logs folder
            fullfile(fileparts(xSim.pathRun),'Slave_Simulink') % Silver Matlab Slave runtime
            fullfile(fileparts(xSim.pathRun),'Slave_Simulink','results') % Silver Matlab Slave ExACT
            xSim.pathRun % Silver: results folder
            };
end

% define simulation results copy target folder
if isempty(sPathResultScratch)
    sPathResult = fullfile(xSim.pathWork,'results',sFolderRun);
else
    sPathResult = fullfile(sPathResultScratch,sFolderRun);
end
if exist(sPathResult,'dir')~=7
    mkdir(sPathResult);
end

% copy files (based on returned path - Simulink: run folder, Silver: results folder)
pause(0.4);
bStatus = false; % of base folder
for nIdxCopy = 1:numel(cPathCopy)
    if exist(cPathCopy{nIdxCopy},'dir')
        if strcmp(xSim.simType,'Silver') && nIdxCopy==numel(cPathCopy)
            bCopyAll = true;
        else
            bCopyAll = false;
        end
        if nIdxCopy > 1 && strcmp(xSim.simType,'Simulink') && strncmpi(fliplr(cPathCopy{nIdxCopy}),fliplr('results'),7)
            if exist(fullfile(sPathResult,'results'),'dir')~=7
                mkdir(fullfile(sPathResult,'results'));
            end
            bStatusAdd = dqsResultCopyFiles(cPathCopy{nIdxCopy},fullfile(sPathResult,'results'),true,sIssuer);
        else
            bStatusAdd = dqsResultCopyFiles(cPathCopy{nIdxCopy},sPathResult,bCopyAll,sIssuer);
        end
        bStatus = bStatus || bStatusAdd; % give report, if at least something was copied
    end
end
if bStatus
    fprintf(1,'%s: Results/logs copied also to folder: %s\n',sIssuer,sPathResult);
else
    fprintf(2,'%s:dqsResultCopy - Result copy failure or nothing to copy.\n',sIssuer);
end
return

% =========================================================================

function bStatus = dqsResultCopyFiles(sPathSource,sPathTarget,bAll,sIssuer)
% DQSRESULTCOPYFILES copy an internal defined list of files from a source to a target path.
%
% Syntax:
%   bStatus = dqsResultCopyFiles(sPathSource,sPathTarget)
%   bStatus = dqsResultCopyFiles(sPathSource,sPathTarget,bAll)
%   bStatus = dqsResultCopyFiles(sPathSource,sPathTarget,bAll,sIssuer)
%
% Inputs:
%   sPathSource - string with source path
%   sPathTarget - string with target path
%          bAll - boolean (1x1) to copy all files in folder
%       sIssuer - char (1xn) with name of issuing file/function
% 
% Outputs:
%   bStatus - boolean (1x1) with overall copy status of result files
%
% Example: 
%   bStatus = dqsResultCopyFiles(sPathSource,sPathTarget)

% check input
if nargin < 3
    bAll = false;
end
if nargin < 4
    sIssuer = '';
end

% file patterns for copy
if bAll
    cFileDef =  {'*.*'};
else
    cFileDef =  {'*.xml','*.xlsx','*.dsm','*.out','*.trn','*.glx','*.log','*.csv','*.mdf','*.mf4',...
        'sMP.mat','MVA*.mat','WS*.mat','signalsLog.mat',...
        'WS*.txt','*raw.txt','*finalE2Ps.txt','ConfigurationSource.txt',...
        '*merge.asc','*norm.asc','DMB_*.ATF_ZYK','DMB_*.ATF_FU'};
end

% pattern reduction on present files         
cFileDefRegexp = regexptranslate('wildcard',cFileDef);
cFile = dirPattern(sPathSource,'*.*','file');
bDefExist = cellfun(@(x)any(~cellfun(@isempty,regexpi(cFile,x))),cFileDefRegexp);
cFileDefExist = cFileDef(bDefExist);

% copy for existing patterns
bStatus = true;
for nIdxDef = 1:numel(cFileDefExist)
    fprintf(1,'%s: Issue copy of %s files from "%s" to "%s"\n',sIssuer,cFileDefExist{nIdxDef},sPathSource,sPathTarget);
    bStatusAdd = robocopy(sPathSource,sPathTarget,cFileDefExist{nIdxDef});
    bStatus = bStatus && bStatusAdd;
end
return
