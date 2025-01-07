function [xModuleSetup,cInitOrder,xGlobalParDef] = dpsModuleInitOrderAuto(sPathContent,xModuleSetup)
% DPSMODULEINITORDERAUTO determines the initOrder of all modules in a
% moduleSetup structure of a DIVe Configuration.
%
% Syntax:
%   [xModuleSetup,cInitOrder,xGlobalParDef] = dpsModuleInitOrderAuto(sPathContent,xModuleSetup)
%
% Inputs:
%   sPathContent - string with path of DIVe Content folder structure
%                  according DIVe logical hierachy
%   xModuleSetup - structure with fields according DIVe Configuration
%
% Outputs:
%   xModuleSetup - structure with fields according DIVe Configuration
%   cInitOrder - cell (mx3) with LDYN output a row for each moduleSetup in the column specified
%                   {:,1}: string with species name
%                   {:,2}: integer with LDYN init level
%                   {:,3}: cell with strings of LDYN level specification
%   xGlobalParDef - struct with source and destination information
%                   .src - cell (nx3) source information of each global parameter dependency
%                       (:,1): string with global parameter name
%                       (:,2): string with source parameter
%                       (:,3): string with source moduleSetup name
%                   .dest - cell (nx3) destination information of each global parameter dependency
%                       (:,1): string with global parameter name
%                       (:,2): string with destination parameter
%                       (:,3): string with destination moduleSetup name
% Example: 
%   [xModuleSetup,cInitOrder,xGlobalParDef] = dpsModuleInitOrderAuto(sPathContent,xModuleSetup)
%
% See also: dpsGlobalParameterCompress, strGlue
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2017-05-04
% 
% Internal Variable:
%     cSetup - cell (mx6) with a row for each moduleSetup in the column
%                  specified:
%                   {:,1}: string with ModuleSetup name
%                   {:,2}: string with species name
%                   {:,3}: cell with string with source ModuleSetup names for global
%                          parameters of module (can be for debug output comma separated)
%                   {:,4}: cell with string with destination moduleSetup names for global
%                          parameters of module (can be for debug output comma separated)
%                   {:,5}: integer with LDYN init level
%                   {:,6}: cell with strings of LDYN level specification

% get information of all dependentParameter dataset classes of all modules
[cSetup,cGlobal,xGlobalParDef] = dpsGlobalParameterCompress(sPathContent,xModuleSetup); %#ok<ASGLU>

% check for pltm.io for last sorting
bPltmIo = strcmp('io',cSetup(:,2));
if any(bPltmIo) && ...
        strcmp(xModuleSetup(bPltmIo).Module.context,'pltm')
    bPltmIoLast = true;
else
    bPltmIoLast = false;
end
% temporarily remove pltm.io
if bPltmIoLast
    bPltmIo = strcmp('io',cSetup(:,2)); % 'Last'
    cSetupIo = cSetup(bPltmIo,:);
    cSetupIo{1,5} = 3;
    cSetupIo{1,6} = 'LastByDefinition';
    cSetup = cSetup(~bPltmIo,:);
end

% alphabetic pre-search
[cTrash,nSort] = sort(cSetup(:,1)); %#ok<ASGLU> sort alphabetical according ModuleSetup name
cSetup = cSetup(nSort,:);
[cTrash,nSort] = sort(cSetup(:,2)); %#ok<ASGLU> sort alphabetical according species name
cSetup = cSetup(nSort,:);

% generate presort index vectors
bNoGlobalPar = cellfun(@isempty,cSetup(:,4));
bNoLocDepPar = cellfun(@isempty,cSetup(:,3));
bNone = bNoGlobalPar & bNoLocDepPar; % 'independent'
bBoth = ~bNoGlobalPar & ~bNoLocDepPar; % 'WritingToGlobalAndLocal'
bGlobOnly = ~bNoGlobalPar & bNoLocDepPar; % 'onlyWritingToGlobal'
bDepOnly = bNoGlobalPar & ~bNoLocDepPar; % 'WritingToGlobalAndLocal'

% presort no-brainers due to no or single interaction with global parameters
cSetup = [[cSetup(bNone,:)     repmat({1 'independent'},[sum(bNone),1])];...
          [cSetup(bGlobOnly,:) repmat({2 'onlyWritingToGlobal'},[sum(bGlobOnly),1])];...
          [cSetup(bBoth,:)     repmat({3 'WritingToGlobalAndLocal'},[sum(bBoth),1])];...
          [cSetup(bDepOnly,:)  repmat({3 'WritingToGlobalAndLocal'},[sum(bDepOnly),1])]]; % onlyWritingToLocal
nBothStart = sum(bNone) + sum(bGlobOnly) + 1;
nBothEnd = sum(bNone) + sum(bGlobOnly) + sum(bBoth); % sort only write global and local
% nBothEnd = size(cSetup,1); % sorting alike orignal LDYN

% sort modules, which have a write and read dependency on global parameters
cSort = cSetup(nBothStart:nBothEnd,:);
nDone = sum(bNone) + sum(bGlobOnly);
bChange = true;
nLevelIncr = 0;
while ~isempty(cSort) && bChange
    % get all modules, which global parameters are already available
    bGlobalDone = cellfun(@(x)all(ismember(x,cSetup(1:nDone,1))),cSort(:,3));
    
    % increment level information
    cSort(bGlobalDone,5) = cellfun(@(x)x+nLevelIncr,cSort(bGlobalDone,5),'UniformOutput',false);
    nLevelIncr = nLevelIncr + 1;
    
    % update setup cell and index of finally sorted modules
    cSetup(nDone+1:nDone+sum(bGlobalDone),:) = cSort(bGlobalDone,:);
    nDone = nDone + sum(bGlobalDone);
    
    % reduce modules to sort by sorted ones
    cSort = cSort(~bGlobalDone,:);
    
    % protection against loops in dependency logic
    bChange = any(bGlobalDone); 
end

% patch level for direct presort of onlyWritingToLocal
if nBothEnd ~= size(cSetup,1)
    cSetup(nBothEnd+1:end,5) = cellfun(@(x)x+nLevelIncr,cSetup(nBothEnd+1:end,5),'UniformOutput',false);
end

% fix LDYN information for pltm.io.provetech last sorting
if bPltmIoLast
    cSetupIo{1,5} = max(cell2mat(cSetup(:,5)))+1;
    cSetup = [cSetup;cSetupIo];
end

% report error on invalid loops
if ~bChange
    fprintf(2,['Error during initOrder determination with Modules ' ...
        '(source;destination) due to global/dependent paramters:\n']);
    for nIdxModule = 1:size(cSort,1)
        fprintf(2,'   %s (%s;%s)\n',cSort{nIdxModule,1},...
            strGlue(cSort{nIdxModule,3},','),...
            strGlue(cSort{nIdxModule,4},','));
    end
end

% change cells of source and destination modules into string for debug overview 
% cSetup(:,3) = cellfun(@(x)strGlue(x,','),cSetup(:,3),'UniformOutput',false);
% cSetup(:,4) = cellfun(@(x)strGlue(x,','),cSetup(:,4),'UniformOutput',false);

% assign output
% cInitOrder = cSetup; % full output for debug
cInitOrder = cSetup(:,[2,5,6]); % LDYN style output

% assign new initOrder values to moduleSetups
[bTrash,nOrder] = ismember({xModuleSetup.name},cSetup(:,1)); %#ok<ASGLU>
for nIdxSetup = 1:numel(xModuleSetup)
    xModuleSetup(nIdxSetup).initOrder = num2str(nOrder(nIdxSetup));
end
return
