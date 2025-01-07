function p4mergeChangeSplitUp(nChange,sHlxSource,sHlxTarget,bSelect,bSubmitDirect)
% P4MERGECHANGESPLITUP split up the files in a (merge) changelist of the
% specified target stream according the changelists of the files in the
% source streams.
%
% Syntax:
%   p4mergeChangeSplitUp(nChange,sHlxSource,sHlxTarget)
%   p4mergeChangeSplitUp(nChange,sHlxSource,sHlxTarget,bSelect)
%   p4mergeChangeSplitUp(nChange,sHlxSource,sHlxTarget,bSelect,bSubmitDirect)
%
% Inputs:
%        nChange - integer (1x1) with changelist containing merge result
%     sHlxSource - string with source stream in Helix depot notation
%     sHlxTarget - string with target stream in Helix depot notation
%        bSelect - boolean (1x1) if selection dialogue is shown (default: 1)
%  bSubmitDirect - boolean (1x1) if changes shall be submitted directly 
%                  (default: 1)
%
% Outputs:
%
% Example: 
%   p4mergeChangeSplitUp(nChange,sHlxSource,sHlxTarget)
%
% See also: hlxDescribeParse, hlxFormParse, hlxOutParse, p4, p4change,
% p4fileBatch
%
% Author: Rainer Frey, TP/EAC, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2019-02-25

% check input
if nargin < 4 
    if getenvOwn('username','rafrey5')
        bSelect = false;
    else
        bSelect = true;
    end
end
if nargin < 5
    bSubmitDirect = true;
end

% determine next non-virtual source stream
[cParent,cType] = hlxFormParse(p4(sprintf('stream -o %s',sHlxSource)),{'Parent','Type'},' ',2,true);
while strcmp('virtual',cType{1})
    sHlxSource = cParent{1};
    [cParent,cType] = hlxFormParse(p4(sprintf('stream -o %s',sHlxSource)),{'Parent','Type'},' ',2,true);
end

% determine next non-virtual target stream
[cParent,cType] = hlxFormParse(p4(sprintf('stream -o %s',sHlxTarget)),{'Parent','Type'},' ',2,true);
while strcmp('virtual',cType{1})
    sHlxTarget = cParent{1};
    [cParent,cType] = hlxFormParse(p4(sprintf('stream -o %s',sHlxTarget)),{'Parent','Type'},' ',2,true);
end

% determine files in integration / split up changelist
[cFile] = hlxFormParse(p4(sprintf('change -o %i',nChange)),'Files','# ',1,true);
cFile = strtrim(cFile); 

% set files to source stream of change
cFileSource = regexprep(cFile,sHlxTarget,sHlxSource);

% get changelists of specified files
cOut = hlxOutParse(p4fileBatch('changes -m 1 %s',cFileSource,10),{' ','@'},6,true);
if isempty(cOut)
    return
end
cChangeSource = cellfun(@str2double,cOut(:,2),'UniformOutput',false); % convert to number vector
cFileSource = [cFileSource cOut(:,6) cChangeSource];

% limit changelists to ones after creation of source stream 
% (omit initial filling with many files)
nChangeSourceInit = sscanf(p4(sprintf('changes -r -m 1 %s/...',sHlxSource)),'Change %i');
bRelevant = cell2mat(cChangeSource) > nChangeSourceInit;
cFileSource = cFileSource(bRelevant,:);
cFileTarget = regexprep(cFileSource(:,1),sHlxSource,sHlxTarget); % reformat files to target string

% let user select
if bSelect 
    % ask user for files to be transferred
    [nSel,bSubmitDirect,bSingle] = csuSelect(cFileSource,bSubmitDirect);
    if isempty(nSel) || (numel(nSel)==1 && nSel==0)
        % Cancel and break up
        fprintf(1,'User cancelled split-up of merge changelist "%i".\n',nChange);
        [sMsg,nStatus] = p4(sprintf('revert -w -c %i ...',nChange));
        if nStatus
            fprintf(2,'The p4 revert operation on changelist %i failed with:\n%s\n',nChange,sMsg);
        else
            fprintf(1,'Files in changelist %i reverted.\n',nChange);
        end
        [sMsg,nStatus] = p4(sprintf('change -d %i',nChange));
        if nStatus
            fprintf(2,'The p4 change remove operation on changelist %i failed with:\n%s\n',nChange,sMsg);
        else
            fprintf(1,'Changelist %i deleted.\n',nChange);
        end
        return
    end
    nChangeSel = unique(cell2mat(cFileSource(nSel,3)));
else
    nChangeSel = unique(cell2mat(cFileSource(:,3)));
end

% get changelist details and their files
xChange = hlxDescribeParse(nChangeSel); 

%% merge all selected files into a single changelist 
if bSingle
    % get descriptions of all changelists with selected files
    % limit Description to 500 signs; in Test problems with descriptions
    % longer than 574 signs >> TODO 
    nDescrLimit = round(500/numel(xChange))-3;
    sDescriptionFull = [];
    for nIdxChange = 1:numel(xChange)
        if length(xChange(nIdxChange).sDescription)>nDescrLimit
            sDescriptionFull = [sDescriptionFull ' - ' xChange(nIdxChange).sDescription(1:nDescrLimit)]; %#ok<AGROW>
        else
            sDescriptionFull = [sDescriptionFull ' - ' xChange(nIdxChange).sDescription]; %#ok<AGROW>
        end
    end
    nChangeThis = p4change(sprintf('%s',...
        regexprep(sDescriptionFull,char(10),char(32))),...
        {},'public'); %#ok<CHARTEN>
    if isempty(nChangeThis)
        error('p4mergeChangeSplitUp:noChangelistGenerated',...
            'Changelist generation may have failed - abort from merge split up')
    end
    cFileReOpen = cFileTarget(nSel,1);
    cFileChange = cFileReOpen;
    csuReopen(nChangeThis,cFileReOpen,cFileChange,sHlxSource,sHlxTarget)

else
    
%% recreate changelist according relevant changelist 
    for nIdxChange = 1:numel(xChange)
        % create a changelist
        nChangeThis = p4change(sprintf('%s',...
            regexprep(xChange(nIdxChange).sDescription,char(10),char(32))),...
            {},'public'); %#ok<CHARTEN>
        if isempty(nChangeThis)
            error('p4mergeChangeSplitUp:noChangelistGenerated',...
                'Changelist generation may have failed - abort from merge split up')
        end
        
        % move files to new changelist
        bThis = ismember(cell2mat(cFileSource(:,3)),xChange(nIdxChange).nChange);
        cFileReOpen = cFileTarget(bThis,1);
        cFileChange = xChange(nIdxChange).cFile;
        csuReopen(nChangeThis,cFileReOpen,cFileChange,sHlxSource,sHlxTarget)
    end
end

% submit changelist
if bSubmitDirect
    p4(sprintf('submit -c %i',nChangeThis));
else
    fprintf(1,'Change %i created and ready for manual submit.\n',nChangeThis);
end

%% cleanup leftover files and changelist
% determine files in changelist for information
[cFile] = hlxFormParse(p4(sprintf('change -o %i',nChange)),'Files','# ',1,true);
cFile = strtrim(cFile); 
% revert all other files of changelist
p4(sprintf('revert -c %i //...',nChange));
fprintf(1,'Reverted files (not in selected changes):\n');
for nIdxFile = 1:numel(cFile)
    fprintf(1,'  %s\n',cFile{nIdxFile});
end
% remove Container changelist
p4(sprintf('change -d %i',nChange));
fprintf(1,'Deleted pending integration changelist "%i" (empty).\n',nChange);
return

% =========================================================================

function csuReopen(nChangeThis,cFileReOpen,cFileChange,sHlxSource,sHlxTarget)
% CSUREOPEN ensure reopen of file while avoiding command line failures.
%
% Syntax:
%   csuReopen(nChangeThis,cFileReOpen,cFileChange,sHlxSource,sHlxTarget)
%
% Inputs:
%   nChangeThis - integer (1x1) with changelist number
%   cFileReOpen - cell (1xm) with files to be re-opened from GUI selection
%   cFileChange - cell (1xn) with files of changelist description
%    sHlxSource - string with source stream path
%    sHlxTarget - string with target stream path
%
% Outputs:
%   <files are reopened in specified changelist of perforce>
%
% Example: 
%   csuReopen(nChangeThis,cFileReOpen,cFileChange,sHlxSource,sHlxTarget)
        
p4fileBatch(sprintf('reopen -c %i %s',nChangeThis,'%s'),cFileReOpen,10);

% ensure reopen of files
xChangeThis = hlxDescribeParse(nChangeThis);
bFileMiss = ~ismember(cFileChange,xChangeThis.cFile);
nBatch = [8 5 2 1 1];
nIdxLoop = 1;
while any(bFileMiss) && nIdxLoop < 5
    % get missing files
    cFileMiss = cFileChange(bFileMiss);
    cFileMissTarget = regexprep(cFileMiss,sHlxSource,sHlxTarget); % reformat files to target string
    
    % try another reopen of files
    sMsg = p4fileBatch(sprintf('reopen -c %i %s',nChangeThis,'%s'),cFileMissTarget,nBatch(nIdxLoop)); %#ok<NASGU>
    
    % update Helix state
    xChangeThis = hlxDescribeParse(nChangeThis);
    bFileMiss = ~ismember(cFileChange,xChangeThis.cFile);
    nIdxLoop = nIdxLoop + 1;
end
return

% =========================================================================

function [nSelection,bSubmit,bSingle] = csuSelect(cFile,bSubmitDirect)
% ESUCHANNELMODIFY ask user in GUI table for files of merge/copy split up
% while displaying also the changelist
%
% Syntax:
%    nSelection = csuSelect(cFile)
%    nSelection = csuSelect(cFile,bSubmitDirect)
%
% Inputs:
%   cFile - cell (mx2) with instrument channel information:
%                       m,1: string with filename
%                       m,2: integer with changelist number
%  bSubmitDirect - boolean (1x1) if changes shall be submitted directly 
%                  (default: 1)
%
% Outputs:
%   nSelection - integer (1xn) with selected files
%      bSubmit - boolean (1x1) of direct submit checkbox
%      bSingle - boolean (1x1) of creating single Changelist
%
% Example: 
%   nSelection = csuSelect({'c:\folderA\fileA.txt',2345;'c:\folderA\fileB.txt',2345;'c:\folderG\fileC.txt',2345})

% initialize output
nSelection = 0;
bSubmit = 0;

% initialize input
cFile = fliplr(cFile);

% get standard properties for GUI elements
data.const.prop = csuGuiProperties;

%% main figure
data.hca.main = figure ('Units','pixel',...
   'Position',[60 80 900 550],... 'Position',[120 120 750 550],...
   'NumberTitle','off',...
   'DockControls','off',...
   'MenuBar','none',...
   'Name','Select files of integration',...
   'Tag','p4mergeSplitUpDlg',...
   'Color',data.const.prop.color.default.BackgroundColor,...
   'Visible','on');  
%    'WindowStyle','modal',...

% standard sizes
gap = 0.005;
hb = 0.04; % height button
wb = 0.11; % width button

% table of assgined channels
cTableColWidth = {50,50,730};
cTableColHeader = {'Change','User','File'}; % text box contents
cTableColHeader = cellfun(@(x)['<html><b>' x '</b></html>'],cTableColHeader,'UniformOutput',false);
cTableColEditable = [false,false,false];
cTableColFormat = {'numeric','char','char'};
data.hca.tb(1) = uitable('Parent',data.hca.main,...
    'Units','normalized',...
    'Position',[gap 2*gap+hb 1-2*gap 1-3*gap-hb],...
    'ColumnFormat',cTableColFormat,...
    'ColumnWidth',cTableColWidth,...
    'ColumnEditable',cTableColEditable,...
    'ColumnName',cTableColHeader,...
    'Data',cFile,...
    'CellSelectionCallback',@csuCbStoreSelection,...
    'Tooltipstring',sprintf('Please select files for merge/copy and hit OK.'));
%     'RowName',{},...

% button create instrumentation
data.hca.b(1) = uicontrol(...
    'Parent',data.hca.main,...
    data.const.prop.pushbutton,...
    'Position',[1-2*gap-2*wb gap wb hb],...
    'UserData',false,...
    'Callback','set(gcbo,''UserData'',true)',...
    'Fontweight','bold',...
    'TooltipString',['<html>Split up selected files into original changelists <br />' ...
                     'all non-selected files will reverted</html>'],...
    'String','OK');

% button cancel
data.hca.b(2) = uicontrol(...
    'Parent',data.hca.main,...
    data.const.prop.pushbutton,...
    'Position',[1-1*gap-1*wb gap wb hb],...
    'Callback','close(findobj(''Tag'',''p4mergeSplitUpDlg''));',...
    'Fontweight','bold',...
    'TooltipString','Revert all files',...
    'String','Cancel');

% button sort according changelist
data.hca.b(3) = uicontrol(...
    'Parent',data.hca.main,...
    data.const.prop.pushbutton,...
    'Position',[1*gap+0*wb gap wb hb],...
    'Callback',{@csuSort,3},...
    'Fontweight','bold',...
    'TooltipString','Sort according changelists',...
    'String','<html>Sort Change</html>',...
    'UserData',0);

% button sort according file
data.hca.b(4) = uicontrol(...
    'Parent',data.hca.main,...
    data.const.prop.pushbutton,...
    'Position',[2*gap+1*wb gap wb hb],...
    'Callback',{@csuSort,4},...
    'Fontweight','bold',...
    'TooltipString','Sort according file path and name',...
    'String','<html>Sort File</html>',...
    'UserData',0);
% set resorter callback
set(data.hca.b(3:4),'Callback',{@GUIcbTableSort,data.hca.tb(1),data.hca.b(3:4)});

% checkbox direct
data.hca.cb(1) = uicontrol(...
    'Parent',data.hca.main,...
    data.const.prop.checkbox,...
    'Position',[1-3*gap-4*wb gap 2*wb hb],...
    'Fontweight','bold',...
    'TooltipString','Submit files on OK',...
    'Value',bSubmitDirect,...
    'String','Direct Submit');

% checkbox direct
data.hca.cb(2) = uicontrol(...
    'Parent',data.hca.main,...
    data.const.prop.checkbox,...
    'Position',[1-4*gap-5*wb gap wb hb],...
    'Fontweight','bold',...
    'TooltipString','Generate merged Changelist with description of selected items',...
    'Value',bSubmitDirect,...
    'String','Single CL');

% store data with GUI
guidata(data.hca.main,data);

% wait for OK exit
waitfor(data.hca.b(1),'UserData');

% retrieve data from table
if ishandle(data.hca.tb(1))
    nSelectSort = get(data.hca.tb(1),'UserData');
    cData = get(data.hca.tb(1),'Data');
    bSubmit = get(data.hca.cb(1),'Value');
    bSingle = get(data.hca.cb(2),'Value');
else % figure is already destroyed
    return
end

% determine selected files
cFileSel = cData(nSelectSort,3);
nSelection = find(ismember(cFile(:,3),cFileSel));

% close figure
close(data.hca.main);
return

% =========================================================================

function csuCbStoreSelection(varargin)
% ESUALIASMODIFYCBSTORESELECTION store last selection in table's UserData
%
% Syntax:
%   esuAliasModifyCbStoreSelection(varargin)
%
% Inputs:
%   varargin - cell (1x2) with 
%     hCaller - handle of caller object
%     xEvent  - structure with eventdata:
%       .Indices - vector (1x2) with selected cell
%       .Source  - handle of sourcing UI Object
%       .EventName - string with event name
%
% Outputs:
%
% Example: 
%   esuAliasModifyCbStoreSelection(varargin)
hTable = varargin{1};
xEvent = varargin{2};
set(hTable,'UserData',unique(xEvent.Indices(:,1)));
return

% =========================================================================

function prop = csuGuiProperties
% CSUGUIPROPERTIES defines central standard properties for GUI elements.
%
% Syntax:
%   prop = csuGuiProperties
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
% % VTruck
% prop.color.warning.popup = [.95 .87 .73]; % orange ocker
% prop.color.warning.popup_changed = [.76 .87 .78]; % mint green
% prop.color.warning.popup_undefined = [.73 .83 .96];% light blue

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
