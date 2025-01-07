function hlxConfigSubmit(cFile,nVerbose)
% HLXCONFIGSUBMIT sumit the specified array of DIVe configurations
%
% Syntax:
%   hlxConfigSubmit(cFile,nVerbose)
%
% Inputs:
%      cFile - cell (1xn) with strings of DIVe Configuration filepathes
%   nVerbose - integer (1x1) verbosity flag 
%               0: revert changes/deletes on existing DIVe elements within
%                  a configuration (configuration is not submitted)
%               1: ask user via dialogue if proceeding with submit or
%                  revert
%
% Outputs:
%
% Example: 
%   hlxConfigSubmit(cFile,nVerbose)
%
% Subfunctions: hcsConfigSubmitSingle, hcsConfigVersionUpdate,
% hcsElementCollect, hcsGuiProperties, hcsPathReconcile, hcsWarnList
%
% See also: dsxRead, dsxWrite, fullfileSL, hlxDescribeParse, hlxOutParse,
% p4, p4change, p4fileBatch, p4switch, pathparts, strGlue, structAdd
%
% Author: Rainer Frey, TP/EAC, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2020-12-14

% check input
if ischar(cFile)
    cFile = {cFile};
end

% create waitbar
if nVerbose
    hWait = waitbar(0,'Configuration submit...');
end

% loop over configurations
nWait = 1/numel(cFile);
for nIdxFile = 1:numel(cFile)
%     try
        % submit single configuration
        if nVerbose
            waitbar((nIdxFile-0.97)*nWait,hWait,...
                sprintf('Configuration (%i/%i) submit ...',nIdxFile,numel(cFile)));
            nStatus = hcsConfigSubmitSingle(cFile{nIdxFile},nVerbose,hWait,[nIdxFile-1 1].*nWait);
        else
            nStatus = hcsConfigSubmitSingle(cFile{nIdxFile},nVerbose);
        end
        if nStatus
            fprintf(2,'ACS: Abort for configuration "%s" - not submitted\n',cFile{nIdxFile});
        else
            fprintf(1,'ACS: Submitted configuration "%s"\n',cFile{nIdxFile});
        end
%     catch ME
%         % error catching
%         fprintf(2,'ACS: Fail during submit of configuration "%s" with message: %s\n',...
%             cFile{nIdxFile},ME.message);
%     end
    if nVerbose
        waitbar((nIdxFile-0.03)*nWait,hWait);
    end
end
if nVerbose
    delete(hWait);
end
return

%==========================================================================

function nStatus = hcsConfigSubmitSingle(sFile,nVerbose,hWait,vWait)
% HCSCONFIGSUBMITSINGLE submit a single DIVe Configuration with all
% Elements.
%
% Syntax:
%   nStatus = hcsConfigSubmitSingle(sFile)
%
% Inputs:
%   sFile - string with filepath of a DIVe Configuration
%   nVerbose - integer (1x1) verbosity flag 
%               0: revert changes/deletes on existing DIVe elements within
%                  a configuration (configuration is not submitted)
%               1: ask user via dialogue if proceeding with submit or
%                  revert
%   hWait - [optional] handle of a waitbar
%   vWait - [optional] vector (1x2) with start and max increment of waitbar
%
% Outputs:
%   nStatus - integer with submit status
%               0: configuration submitted
%               1: not submitted
%
% Example: 
%   nStatus = hcsConfigSubmitSingle(sFile)

% load configuration
if nargin > 2
    waitbar(vWait*[1;0.05],hWait);
end
xTree = dsxRead(sFile);
if nargin > 2
    waitbar(vWait*[1;0.08],hWait);
end

% check for content folder
cPath = pathparts(sFile);
sPathBase = fullfile(cPath{1:end-4}); % path containing "Configuration" and "Content"
sPathContent = fullfile(sPathBase,'Content');
if ~exist(sPathContent,'dir')
    error('hlxConfigSubmitSingle:ContentFoldernotfound',...
          'Could not find the content folder for DIVe Configuration "%s".',sFile);
end

% check and switch workspace
[nStatus,sWorkspace,sPrevious,cClient] = p4switch(sPathContent,false);
if ~nStatus
    error('hlxConfigSubmitSingle:ClientChangeFailed',...
          'Changing to a Perforce Helix Workspace with the Content folder failed.');
end
if nargin > 2
    waitbar(vWait*[1;0.1],hWait);
end

% get elements of DIVe configuration
cElement = hcsElementCollect(xTree,sPathContent);
if nargin > 2
    waitbar(vWait*[1;0.15],hWait);
end

% issue Content reconciles
if ~isempty(cElement)
    [nStatus,cElement] = hcsPathReconcile(cElement,cPath{end},nVerbose);
    
    % break on error case
    if nStatus
        return
    end
end
if nargin > 2
    waitbar(vWait*[1;0.6],hWait);
end

% updaten versionID in configuration if necessary 
xTree = hcsConfigVersionUpdate(xTree,cElement);
if nargin > 2
    waitbar(vWait*[1;0.7],hWait);
end

% save configuration
nChange = p4change(sprintf('ACS: %s - Configuration submit',cPath{end}),{},'public');
p4(sprintf('reconcile -ae -c %i %s',nChange,sFile));
dsxWrite(sFile,xTree);
if nargin > 2
    waitbar(vWait*[1;0.8],hWait);
end

% submit configuration
[sMsg,nStatus] = p4(sprintf('submit -c %i',nChange));
if nargin > 2
    waitbar(vWait*[1;0.9],hWait);
end
if nStatus % error handling
    fprintf(2,['ACS Error: The submit of Configuration "%s" failed with ' ...
        'message:\n%s\n'],...
        cPath{end},sMsg);
    p4(sprintf('revert -c %i -k ...',nChange));
    p4(sprintf('change -d %i',nChange));
    fprintf(2,'The configuration was reverted and the pending changelist deleted.\n')
end

% switch to original workspace
p4switch(sPrevious,false,sWorkspace,cClient);
if nargin > 2
    waitbar(vWait*[1;0.95],hWait);
end
return

% =========================================================================

function cElement = hcsElementCollect(xTree,sPathContent)
% HCSELEMENTCOLLECT collect all folder pathes of DIVe elements in a DIVe
% configuration structure.
% 
% Syntax:
%   cElement = hcsElementCollect(xTree,sPathContent)
%
% Inputs:
%        xTree - structure with fields of DIVe Configuration XML
%         .Configuration - structure (1x1)
%           .ModuleSetup - structure (1xn)
%    sPathContent - string with path of DIVe Content folder
%
% Outputs:
%   cElement - cell (mx5) with element information
%              {:,1} - nSetup integer with ModuleSetup index
%              {:,2} - sType string with element type (Module, DataSet, SupportSet) 
%              {:,3} - nItem integer with item number in this type
%              {:,4} - versionId string with current DIVe version ID value
%              {:,5} - sPath filesystem path of this element
%              {:,6} - nUpdate boolean if needed update for Configuration
%
% Example: 
%   cElement = hcsElementCollect(xTree,sPathContent)

% loop over setups and collect reconcile locations (Module, DataSet
% variant, SupportSet), store also gaps in versionIDs
xSetup = xTree.Configuration.ModuleSetup; % shortcut
cLevel =  {'species','family','type'};
% element cell {:,1}nSetup, {:,2}sType, {:,3}nItem, {:,4}versionId, {:,5}sPath 
cElement = cell(numel(xSetup)*2,6); 
nElement = 0;
for nIdxSetup = 1:numel(xSetup)
    xMod = xSetup(nIdxSetup).Module;
    cHierarchy = {xMod.context,xMod.species,xMod.family,xMod.type};
    
    % get DataSet variant folders
    for nIdxElem = 1:numel(xSetup(nIdxSetup).DataSet)
        xElem = xSetup(nIdxSetup).DataSet(nIdxElem);
        nLevel = find(strcmp(xElem.level,cLevel));
        nElement = nElement + 1;
        cElement(nElement,1:6) = {nIdxSetup,'DataSet',nIdxElem,xElem.versionId,...
        fullfile(sPathContent,cHierarchy{1:1+nLevel},'Data',xElem.classType,xElem.variant),0};
    end
    
    % get SupportSet folders
    if isfield(xSetup,'SupportSet')
        for nIdxElem = 1:numel(xSetup(nIdxSetup).SupportSet)
            xElem = xSetup(nIdxSetup).SupportSet(nIdxElem);
            nLevel = find(strcmp(xElem.level,cLevel));
            nElement = nElement + 1;
            cElement(nElement,1:6) = {nIdxSetup,'SupportSet',nIdxElem,xElem.versionId,...
                fullfile(sPathContent,cHierarchy{1:1+nLevel},'Support',xElem.name),0};
        end
    end
    
    % get Module folder
    nElement = nElement + 1;
    cElement(nElement,1:6) = {nIdxSetup,'Module',1,xMod.versionId,...
        fullfile(sPathContent,cHierarchy{:},'Module',xMod.variant),0};
end
return

% =========================================================================

function [nStatus,cElement] = hcsPathReconcile(cElement,sConfig,nVerbose)
% HCSPATHRECONCILE reconcile on specififed DIVe element pathes and submit
% per Module species. If files have other actions than "add", ask user
% dialogue for proceed (silent default: revert files, break from
% configuration submit). Pipe Perforce errors (e.g. Content Trigger Check)
% to user. 
% Uses a "rolling" changelist per function call (configuration), so not
% every Module in a configuration wastes a changelist number.
%
% Syntax:
%   [nStatus,cElement] = hcsPathReconcile(cElement,sConfig,nVerbose)
%
% Inputs:
%   cElement - cell (mx6)with DIVe Element details
%              {:,1} - nSetup integer with ModuleSetup index
%              {:,2} - sType string with element type (Module, DataSet, SupportSet) 
%              {:,3} - nItem integer with item number in this type
%              {:,4} - versionId string with current DIVe version ID value
%              {:,5} - sPath filesystem path of this element
%              {:,6} - nUpdate boolean if needed update for Configuration
%    sConfig - string with configuration name for user messages
%   nVerbose - integer (1x1) with verbosity level
%
% Outputs:
%    nStatus - integer (1x1) 
%   cElement - cell (mx6)with DIVe Element details
%              {:,1} - nSetup integer with ModuleSetup index
%              {:,2} - sType string with element type (Module, DataSet, SupportSet) 
%              {:,3} - nItem integer with item number in this type
%              {:,4} - versionId string - updated for submitted elements
%              {:,5} - sPath filesystem path of this element
%              {:,6} - nUpdate boolean if needed update for Configuration
%
% Example: 
%   [nStatus,cElement] = hcsPathReconcile(cElement,sConfig,nVerbose)

% init output
nStatus = 0;

% prepare changelist
nChange = p4change(sprintf('ACS: [%s]',sConfig),{},'public');

% get Perforce client details
[cStream,cRoot] = hlxFormParse(p4('client -o'),{'Stream','Root'},{' '},inf,true);

% loop from Module to Module
nSetup = unique(cell2mat(cElement(:,1)));
for nIdxSetup = nSetup'
    % determine Elements of this Module
    bThis = nIdxSetup == cell2mat(cElement(:,1));
    nThis = find(bThis);
    % determine species
    cModulePath = pathparts(cElement{find(bThis,1,'last'),5});
    sSpecies = strGlue(cModulePath(end-5:end-4),'.'); % context.species
    sDescription = sprintf('ACS: %s [%s]',sSpecies,sConfig);
    p4form('change',num2str(nChange,'%i'),'Description',{sDescription});
    
    % check for pending changelists
    sMsg = p4fileBatch('changes -s pending %s',...
        cellfun(@(x)fullfile(x,'...'),cElement(bThis,5),'UniformOutput',false),10,true);
    if ~isempty(sMsg)
        fprintf(2,['Pending changelist(s) exist for species "%s" ' ...
            'in Configuration "%s":\n'],sSpecies,sConfig);
        fprintf(2,['Pending changelist(s) preventing a submit:\n%s'...
            'Please submit or revert these changelists before trying to ' ...
            'submit configuration "%s".\n'],...
            sMsg,sConfig);
        if nVerbose
            errordlg(sprintf(['Pending changelist(s) exist for species "%s" ' ...
            'in Configuration "%s" and prevent an automated submit:\n\n%s\nPlease submit ' ...
            'or revert these changelists before retrying.'],sSpecies,sConfig,sMsg),...
            'Pending changelists ');
        end
        % set failure state for this configuration and break
        nStatus = 1;
        break
    end
    
    % reconcile Elements
    p4fileBatch(sprintf('reconcile -aed -c %i %%s',nChange),...
        cellfun(@(x)fullfile(x,'...'),cElement(bThis,5),'UniformOutput',false),10,true);
    
    % get details of changelist
    xChange = hlxDescribeParse(nChange);
    if isempty(xChange) || isempty(xChange.cFile)
        continue
    end
    
    % check for edits/deletes - all non-add actions
    if ~all(strcmp('add',xChange.cFileAction))
        if nVerbose
            sAction = hcsWarnList(xChange,sConfig,sSpecies);
        else
            sAction = 'Revert';
        end
        
        % revert and cleanup current changelist
        if strcmp(sAction,'Revert')
            % revert changelist
            p4fileBatch(sprintf('revert -c %i -k %%s',nChange),xChange.cFile);
            
            % set failure state for this configuration and break
            nStatus = 1;
            break
        end
    end
    
    % mark elements for update on cElement(:,6)
    cPathCheck = hcsPathContentReduce(cElement(bThis,5));
    cFileCheck = hcsPathContentReduce(xChange.cFile);
    nElementThisChangelist = [];
    while ~isempty(cFileCheck)
        % compare file to element pathes
        bPathCheck = cellfun(@(x)strncmp(cFileCheck{1},x,numel(x)),cPathCheck);
        % set update flag for element
        cElement{nThis(bPathCheck),6} = 1;
        nElementThisChangelist = [nElementThisChangelist nThis(bPathCheck)];
        % remove files of element
        bFileRemove = ~strncmp(cFileCheck,cPathCheck{bPathCheck},...
            numel(cPathCheck{bPathCheck}));
        cFileCheck = cFileCheck(bFileRemove);
    end
    nElementThisChangelist = unique(nElementThisChangelist);
    
    % submit changelist
    [sMsg,nStatus] = p4(sprintf('submit -c %i',nChange));
    
    if nStatus % capture errors and trigger issues
        fprintf(2,['Error during submit of changelist %i for species "%s" ' ...
            'in Configuration "%s"\n'],nChange,sSpecies,sConfig);
        fprintf(2,['\nPerforce error message:\n%s\n'...
            'Please fix issues in changelist %i and then re-stage the ' ...
            'Configuration "%s" for submit.\n'],sMsg,nChange,sConfig);
        if nVerbose
            errordlg(sprintf('Perforce error message:\n%s\n',sMsg),'Perforce Submit Error');
        end
        
        % set failure state for this configuration and break
        nStatus = 1;
        break
    else % submit success
        % store new changelist number for listing
        cOut = hlxOutParse(p4(sprintf('changes -m 1 %s',xChange.cFile{1})),{' '},2,true);
        if ~isnan(str2double(cOut{1,2}))
            % assign changelist number to elements
            [cElement{nElementThisChangelist,4}] = deal(cOut{1,2});
        else
            % changelist determination failed
            % TODO how to proceed
            fprintf(2,['Changelist determination failed for species "%s" ' ...
                'in Configuration "%s"\n'],sSpecies,sConfig);
        end
        
        % create next changelist
        nChange = p4change(sprintf('ACS: [%s]',sConfig),{},'public');
    end % if error on submit
end % for setup

% cleanup rolling changelist
cChange = hlxOutParse(p4(sprintf('changes -e %i -s pending --me',nChange)),{' '},2,true);
if ismember(nChange,cellfun(@str2double,cChange))
    p4(sprintf('change -d %i',nChange));
end
return

% =========================================================================

function xTree = hcsConfigVersionUpdate(xTree,cElement)
% HCSCONFIGVERSIONUPDATE update verionIds of submitted elements in 
% configuration structure.
%
% Syntax:
%   xTree = hcsConfigVersionUpdate(xTree,cElement)
%
% Inputs:
%      xTree - structure with fields: 
%   cElement - cell (mxn) 
%
% Outputs:
%   xTree - structure with fields: 
%
% Example: 
%   xTree = hcsConfigVersionUpdate(xTree,cElement)

%   cElement - cell (mx5) with element information
%              {:,1} - nSetup integer with ModuleSetup index
%              {:,2} - sType string with element type (Module, DataSet, SupportSet) 
%              {:,3} - nItem integer with item number in this type
%              {:,4} - versionId string with current DIVe version ID value
%              {:,5} - sPath filesystem path of this element
%              {:,6} - nUpdate boolean if needed update for Configuration

% reduce elements to update elements
bKeep = cell2mat(cElement(:,6)) > 0;
cElement = cElement(bKeep,:);

% update relevant elements
for nIdxElem = 1:size(cElement,1)
    xTree.Configuration.ModuleSetup(cElement{nIdxElem,1}).(cElement{nIdxElem,2})(cElement{nIdxElem,3}).versionId = ...
        cElement{nIdxElem,4};
end
return

% =========================================================================

function cPathNew = hcsPathContentReduce(cPath)
% HCSPATHCONTENTREDUCE change a cell with file path statements
%
% Syntax:
%   cPathNew = hcsPathContentReduce(cPath)
%
% Inputs:
%   cPath - cell (1xn) with path strings
%
% Outputs:
%   cPathNew - cell (1xn) with path strings reduced to part behind "Content", path separator is a
%   slash
%
% Example: 
%   cPathNew = hcsPathContentReduce('c:\myStream\Content\phys\test\simple\std') % -> 'phys/test/simple/std'

% set backslach to slash (depot notation)
cPath = strrep(cPath,'\','/');

% reduce path to content
ccSplit = regexp(cPath,'Content[\\/]','split','once');
cPathNew = cellfun(@(x)x{end},ccSplit,'UniformOutput',false);
return

% =========================================================================

function sAction = hcsWarnList(xChange,sConfig,sSpecies)
% HCSWARNLIST create dialogue to warn about non-"add" changes
%
% Syntax:
%   sAction = hcsWarnList(xChange,sConfig)
%
% Inputs:
%   xChange - structure with fields: 
%   sConfig - string with configuration name for user interface
%   sConfig - string with species name for user interface
%
% Outputs:
%   sAction - string with further action of changelist (Revert/Submit)
%
% Example: 
%   sAction = hcsWarnList(hlxDescribeParse(15800,'SomeConfig.xml')
%
% Subfunctions: hcsGuiProperties
%
% See also: structAdd

% singleton
if ~isempty(findobj('Tag','HlxConfigurationSubmitWarn'))
    % bring existing instance to front
    figure(findobj('Tag','HelixConfigSubmitWarn'));
    return
end

% initialize output
sAction = 'Revert';

% get standard properties for GUI elements
data.const.prop = hcsGuiProperties;

% main figure
data.hcw.main = figure ('Units','pixel',...
   'Position',[60 80 900 550],... 'Position',[120 120 750 550],...
   'NumberTitle','off',...
   'DockControls','off',...
   'MenuBar','none',...
   'Name','Warning - non-add action of changelist files',...
   'Tag','HlxConfigurationSubmitWarn',...
   'WindowStyle','modal',...
   'Color',data.const.prop.color.default.BackgroundColor,...
   'Visible','on');  

% standard sizes
gap = 0.005;
hb = 0.04; % height button
wb = 0.1; % width button

data.hcw.t(1) = uicontrol(...
    'Parent',data.hcw.main,...
    data.const.prop.text,...
    'Position',[gap 1-gap-hb 1-2*gap hb],...
    'HorizontalAlignment','left', ...
    'FontSize',12,...
    'FontWeight','bold',...
    'String',sprintf('Warning: Content change in species "%s" of Configuration "%s"',sSpecies,sConfig));

% text about warning
sNote = sprintf(['Below are files in your changelist, which are edited or deleted. \n' ...
    'Editing or deleting existing DIVe Elements might affect the work of ' ...
    'other users in unexpected ways. \n\nPlease review these files carefully. \n'...
    'If you have created and submitted e.g. a DataSet previously, you might ' ...
    'change or delete it by "Submit". \nIf you are unsure, please "Revert" and contact the ' ...
    'Module Developer.']);
htw = 0.22; % height warning text
data.hcw.t(2) = uicontrol(...
    'Parent',data.hcw.main,...
    data.const.prop.text,...
    'Position',[gap 1-gap-htw 1-2*gap htw-hb-gap],...
    'HorizontalAlignment','left', ...
    'FontSize',10,...
    'String',sNote);

% table of assgined channels
cTableColWidth = {50,770};
cTableColHeader = {'Action','File'}; % text box contents
cTableColHeader = cellfun(@(x)['<html><b>' x '</b></html>'],cTableColHeader,'UniformOutput',false);
cTableColEditable = [false,false];
cTableColFormat = {'char','char'};
data.hcw.tb(1) = uitable('Parent',data.hcw.main,...
    'Units','normalized',...
    'Position',[gap 2*gap+hb 1-2*gap 1-4*gap-htw-hb],...
    'ColumnFormat',cTableColFormat,...
    'ColumnWidth',cTableColWidth,...
    'ColumnEditable',cTableColEditable,...
    'ColumnName',cTableColHeader,...
    'Data',[xChange.cFileAction,xChange.cFile],...
    'Tooltipstring',sprintf('Files in changelist %s',xChange.nChange));

% button create instrumentation
data.hcw.b(1) = uicontrol(...
    'Parent',data.hcw.main,...
    data.const.prop.pushbutton,...
    'Position',[1-2*gap-2*wb gap wb hb],...
    'UserData',false,...
    'Callback','set(gcbo,''UserData'',true)',...
    'Fontweight','bold',...
    'TooltipString',sprintf(['<html>Submit changelist %i including the shown files: <br />' ...
                     '%s</html>'],xChange.nChange,xChange.sDescription),...
    'String','Submit');

% button cancel
data.hcw.b(2) = uicontrol(...
    'Parent',data.hcw.main,...
    data.const.prop.pushbutton,...
    'Position',[1-1*gap-1*wb gap wb hb],...
    'Callback','close(findobj(''Tag'',''HlxConfigurationSubmitWarn''));',...
    'Fontweight','bold',...
    'TooltipString',['<html>Discard all changes and revert this changelist <br />', ...
                     'The current Configuration cannot be submitted. <br />', ...
                     'Other Configurations will be further processed.</html>'],...
    'String','Revert');

% wait for OK exit
waitfor(data.hcw.b(1),'UserData');

% retrieve user decision1
if ishandle(data.hcw.b(1))
    bSubmit = get(data.hcw.b(1),'UserData');
    if bSubmit
        sAction = 'Submit';
    end

    % close dialogue
    close(data.hcw.main);
end
return

% =========================================================================

function prop = hcsGuiProperties
% HCSGUIPROPERTIES defines central standard properties for GUI elements.
%
% Syntax:
%   prop = hcsGuiProperties
%
% Outputs:
%   prop - structure with default properties for GUI generation

% standard color schemes
prop.color.default.BackgroundColor = [.85 .85 .85];
prop.color.default.ForegroundColor = [ 0 0 0 ];

prop.color.editable.BackgroundColor = [1 1 1];
prop.color.editable.ForegroundColor = prop.color.default.ForegroundColor;

prop.color.nonEdit.BackgroundColor = (prop.color.default.BackgroundColor + [1 1 1]).*0.5;
prop.color.nonEdit.ForegroundColor = prop.color.default.ForegroundColor;

prop.color.disable.BackgroundColor = (prop.color.default.BackgroundColor + [1 1 1]).*0.5;
prop.color.disable.ForegroundColor = [.3 .3 .3];

% color schemes for user interaction/feedback
prop.color.confirmed.BackgroundColor = [204 223 247]./255; % light blue % manual/confirmed setting
prop.color.autoset.BackgroundColor = [ 50  14  96]./255; % yellow % autoset - needs confirmation
prop.color.autosetChild.BackgroundColor = [ 45  61  98]./255; % orange % child is autoset - needs internal attention
prop.color.violation.BackgroundColor = [  0  60  90]./255; % red % violates dependency
prop.color.violationChild.BackgroundColor = [ 28  61  98]./255; % reddish orange% child violates dependency

%% common properties
prop.basic.Units = 'normalized';
prop.basic.FontName = 'arial';
prop.basic.FontSize = 9;

% panel
prop.uipanel = structAdd(prop.basic,prop.color.default);
prop.uipanel.FontAngle = 'italic';
% prop.uipanel.FontWeight = 'bold';
prop.uipanel.FontSize = prop.basic.FontSize-1;

% pushbutton
prop.pushbutton = structAdd(prop.basic,prop.color.default);
prop.pushbutton.Style = 'pushbutton';
prop.pushbutton.HorizontalAlignment = 'center';

% listbox
prop.listbox = structAdd(prop.basic,prop.color.editable);
prop.listbox.Style = 'listbox';
prop.listbox.string = '-';

% listbox settings for non editable listboxes
prop.listboxNon = prop.listbox;
prop.listboxNon.BackgroundColor = prop.color.nonEdit.BackgroundColor;

% checkbox
prop.checkbox = structAdd(prop.basic,prop.color.default);
prop.checkbox.Style = 'checkbox';
% prop.checkbox.BackgroundColor = [1 1 0.8];

% radiobutton
prop.radiobutton = structAdd(prop.basic,prop.color.default);
prop.radiobutton.Style = 'radiobutton';

% popupmenu
prop.popupmenu = structAdd(prop.basic,prop.color.editable);
prop.popupmenu.Style = 'popupmenu';
prop.popupmenu.FontSize = prop.basic.FontSize-1;

% slider
prop.slider = structAdd(prop.basic,prop.color.nonEdit);
prop.slider.Style = 'slider';
prop.slider.value= 1;
prop.slider.min = 0;
prop.slider.max = 1;
prop.slider.sliderstep= [0 0];

% static text
prop.text = structAdd(prop.basic,prop.color.default);
prop.text.Style = 'text';
% prop.text.BackgroundColor = [1 1 0.8];
prop.text.HorizontalAlignment = 'left';

% edit text
prop.edit = structAdd(prop.basic,prop.color.editable);
prop.edit.Style = 'edit';
prop.edit.HorizontalAlignment = 'right';
% prop.edit.FontSize = prop.basic.FontSize-1;

% edit text, non editable
prop.editNon = structAdd(prop.basic,prop.color.nonEdit);
prop.editNon.Style = 'edit';
prop.editNon.HorizontalAlignment = 'right';
prop.editNon.enable = 'inactive';
% prop.editNon.FontSize = prop.basic.FontSize-1;
return