function [xSum] = Marc2DIVeFcn(xMarc,xBase,sPath,sPathSource)
% MARC2DIVEFCN create a new dataset in the specified path, based on the
% dataset of the source path and a MARC dataset export of a matching xCM
% dataset.
%
% Syntax:
%   xSum = Marc2DIVeFcn(xMarc,xBase,sPath,sPathSource)
%
% Inputs:
%         xMarc - structure of MARC export with fields: 
%           .CalParam
%         xBase - structure of xCM mainData dataset mat file with fields: 
%           .<workspace_parameter>
%           .sMP.ctrl.<xcm>.<param>
%         sPath - string with path of new dataset variant
%   sPathSource - string with path of basis dataset variant
%
% Outputs:
%   xSum - structure with fields: 
%     .msg - structure with messages cells
%       .marc - cell (mx4) with MARC conversion messages
%       .smp  - cell (mx2) with MARC to sMP transfer messages
%       .ws   - cell (mx2) with sMP to Workspace transfer messages
%     .var - structure with cells of strings with parameter names
%       .Transfer      - cell with parameters updated in sMP
%       .TransferFail  - cell with parameters in sMP but not updated
%       .WsUpdate      - cell with parameters updated in Workspace
%       .WsNoUpdate    - cell with parameters in Workspace but not updated
%       .BaseNotInMarc - cell with parameters in base sMP structure missing
%                        in MARC dataset
%       .MarcNotInBase - cell with parameters in MARC datset but missing in
%                        in sMP structure
%
% Example: 
%   xSum = Marc2DIVeFcn(xMarc,xBase,sPath,sPathSource)
%   xSum = Marc2DIVeFcn(xMarc,xBase,sPath,sPathSource)
%
%
% Subfunctions:
% Private functions:
% Other m-files required:
% MAT-files required:
%
% See also: MARCstruct2set, dstXmlDataSet, pathparts
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2016-04-07

%% generate a waitbar
hWaitbar = waitbar(0,'Converting MARC data into Simulation xCM dataset...',...
        'Name','Convert MARC data to DIVe xCM dataset'); 

%% parse MARC calparam structure
[xSet,xSum.msg.marc,xSetProperty] = MARCstruct2set(xMarc,hWaitbar,[0 0.35]); %#ok<ASGLU>
clear xMarc

%% create new dataset folder
if ~exist(sPath,'dir')
    mkdir(sPath);
end

%% copy xcm_data_set_add.m
cPath = pathparts(sPath);
copyfile(fullfile(sPathSource,[cPath{end-5} '_data_set_add.m']),...
    fullfile(sPath,[cPath{end-5} '_data_set_add.m']));
touch(fullfile(sPath,[cPath{end-5} '_data_set_add.m']));

%% update base dataset sMP
waitbar(0.37,hWaitbar,'Generating sMP structure of xCM...');
cBase = fieldnames(xBase.sMP.ctrl.(cPath{end-5}));
cSet = fieldnames(xSet);
bSetInBase = ismember(cSet,cBase);
bBaseInSet = ismember(cBase,cSet);
xSum.var.MarcNotInBase = cSet(~bSetInBase);
xSum.var.BaseNotInMarc = cBase(~bBaseInSet);
cTransfer = cSet(bSetInBase);
bTransferRemove = false(size(cTransfer));
cMsg = cell(numel(cTransfer),2);
nMsg = 0;
% for each matching paramater
for nIdxField = 1:numel(cTransfer)
    % if size of parameter matches
    nSizeBase = size(xBase.sMP.ctrl.(cPath{end-5}).(cTransfer{nIdxField}));
    nSizeSet = size(xSet.(cTransfer{nIdxField}));
    if all(nSizeBase == nSizeSet) || ... % equal dimensions or
        (nSizeSet(1) ~= nSizeSet(2) && ... % just flipped dimensions
         nSizeBase(1) == nSizeSet(2) && ...
         nSizeBase(2) == nSizeSet(1))
     
        % transfer parameter
        xBase.sMP.ctrl.(cPath{end-5}).(cTransfer{nIdxField}) = xSet.(cTransfer{nIdxField});
    else
        % log message
        bTransferRemove(nIdxField) = true;
        nMsg = nMsg + 1;
        nSizeBase = size(xBase.sMP.ctrl.(cPath{end-5}).(cTransfer{nIdxField}));
        nSizeSet = size(xSet.(cTransfer{nIdxField}));
        cMsg(nMsg,1:2) = {cTransfer{nIdxField},...
            sprintf(['The parameter "%s" has a different size in '...
            'MARC(%1.0fx%1.0f) than in the base dataset(%1.0fx%1.0f) ' ...
            '- the parameter can not be updated'],...
            cTransfer{nIdxField},...
            nSizeSet(1),nSizeSet(2),...
            nSizeBase(1),nSizeBase(2))};
    end
end
% remove failed parameter transfers to extra list
xSum.var.Transfer = cTransfer(~bTransferRemove);
xSum.var.TransferFail = cTransfer(bTransferRemove);
% store failure messages
xSum.msg.smp = cMsg(1:nMsg,:);
    
%% update base dataset WS
waitbar(0.4,hWaitbar,'Updating workspace paramters of xCM...');
% get workspace parameters
cWorkspace = fieldnames(xBase);
% remove sMP from list
bSmp = strcmp('sMP',cWorkspace);
cWorkspace = cWorkspace(~bSmp);
% initialize/reduce variables
bWsInTransfer = ismember(cWorkspace,xSum.var.Transfer);
xSum.var.WsUpdate = cWorkspace(bWsInTransfer);
xSum.var.WsNoUpdate = cWorkspace(~bWsInTransfer);
cWorkspace = cWorkspace(bWsInTransfer);
bWorkspaceRemove = false(size(cWorkspace));
cMsg = cell(numel(cWorkspace),2);
nMsg = 0;
for nIdxPar = 1:numel(cWorkspace)
    % if size of parameter matches
    nSizeBase = size(xBase.sMP.ctrl.(cPath{end-5}).(cWorkspace{nIdxPar}));
    nSizeSet = size(xBase.(cWorkspace{nIdxPar}));
    if all(nSizeBase == nSizeSet) || ... % equal dimensions or
        (nSizeSet(1) ~= nSizeSet(2) && ... % just flipped dimensions
         nSizeBase(1) == nSizeSet(2) && ...
         nSizeBase(2) == nSizeSet(1))
        % transfer parameter
        xBase.(cWorkspace{nIdxPar}) = xBase.sMP.ctrl.(cPath{end-5}).(cWorkspace{nIdxPar});
    else
        % log message
        bWorkspaceRemove(nIdxPar) = true;
        nMsg = nMsg + 1;
        nSizeSmp = size(xBase.sMP.ctrl.(cPath{end-5}).(cWorkspace{nIdxPar}));
        nSizeWs = size(xBase.(cWorkspace{nIdxPar}));
        cMsg(nMsg,1:2) = {cWorkspace{nIdxPar},...
            sprintf(['The parameter "%s" has a different size in '...
            'the workspace(%1.0fx%1.0f) than in the sMP structure(%1.0fx%1.0f) ' ...
            '- the parameter can not be updated in Workspace'],...
            cWorkspace{nIdxPar},...
            nSizeWs(1),nSizeWs(2),...
            nSizeSmp(1),nSizeSmp(2))};
    end
end
% remove failed parameters to extra list
xSum.var.WsNoUpdate = [xSum.var.WsNoUpdate;cWorkspace(bWorkspaceRemove)];
xSum.var.WsUpdate = cWorkspace(~bWorkspaceRemove);
% store failure messages
xSum.msg.ws = cMsg(1:nMsg,:);

%% save xcm_data_set.mat
waitbar(0.42,hWaitbar,'Save dataset mat-file...');
cField = fieldnames(xBase)';
save(fullfile(sPath,[cPath{end-5} '_data_set.mat']),'-struct','xBase',cField{:});

%% save/generate Excel report of update
waitbar(0.45,hWaitbar,'Generating Excel report...');
sExcel = fullfile(sPath,'GenerationReport.xlsx');
cSummary = {'Summary','';...
    numel(xSum.var.Transfer),'Updated parameters in sMP structure (active parameters in dataset)';...
    numel(xSum.var.TransferFail),'Failed parameter updates in sMP structure due to different parameter sizes';...
    numel(xSum.var.WsUpdate),'Updated parameters in Workspace (E2P/Par/Stateflow)';...
    numel(xSum.var.WsNoUpdate),'Parameters in Workspace which can not be updated by MARC dataset';...
    numel(xSum.var.BaseNotInMarc),'Parameters of base dataset sMP structure not in MARC dataset (E2P/Par)';...
    numel(xSum.var.MarcNotInBase),'Parameters of MARC not in base dataset sMP structure (FMM, low level etc. can be some more)'};
if isempty(xSum.var.Transfer)
    xSum.var.Transfer = {'none'};
end
if isempty(xSum.var.TransferFail)
    xSum.var.TransferFail = {'none'};
end
if isempty(xSum.var.WsUpdate)
    xSum.var.WsUpdate = {'none'};
end
if isempty(xSum.var.WsNoUpdate)
    xSum.var.WsNoUpdate = {'none'};
end
if isempty(xSum.var.BaseNotInMarc)
    xSum.var.BaseNotInMarc = {'none'};
end
if isempty(xSum.var.MarcNotInBase)
    xSum.var.MarcNotInBase = {'none'};
end
if isempty(xSum.msg.smp)
    xSum.msg.smp = {'none'};
end
if isempty(xSum.msg.ws)
    xSum.msg.ws = {'none'};
end
if isempty(xSum.msg.marc)
    xSum.msg.marc = {'none'};
end
warning('off','MATLAB:xlswrite:AddSheet')
xlswrite(sExcel,cSummary,'Summary');
waitbar(0.5,hWaitbar)
xlswrite(sExcel,xSum.var.Transfer,'sMP Transfer');
waitbar(0.55,hWaitbar)
xlswrite(sExcel,xSum.var.TransferFail,'sMP Fail');
waitbar(0.6,hWaitbar)
xlswrite(sExcel,xSum.msg.smp,'sMP Fail Msg');
waitbar(0.65,hWaitbar)
xlswrite(sExcel,xSum.var.WsUpdate,'Workspace Update');
waitbar(0.7,hWaitbar)
xlswrite(sExcel,xSum.var.WsNoUpdate,'Workspace NoUpdate');
waitbar(0.75,hWaitbar)
xlswrite(sExcel,xSum.msg.ws,'Workspace Fail Msg');
waitbar(0.8,hWaitbar)
xlswrite(sExcel,xSum.var.BaseNotInMarc,'BaseNotInMarc');
waitbar(0.85,hWaitbar)
xlswrite(sExcel,xSum.var.MarcNotInBase,'MarcNotInBase');
waitbar(0.9,hWaitbar)
xlswrite(sExcel,xSum.msg.marc,'MARC conversion');
waitbar(0.95,hWaitbar)
warning('on','MATLAB:xlswrite:AddSheet')

%% generate dataset XML
waitbar(0.97,hWaitbar,'Generating XML file...');
if exist('dstXmlDataset','file')
    dstXmlDataSet(sPath,{'isStandard','';'executeAtInit','';'copyToRunDirectory',''});
end
waitbar(1,hWaitbar);
close(hWaitbar);
return
