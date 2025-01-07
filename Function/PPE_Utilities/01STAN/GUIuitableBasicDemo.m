function GUIuitableBasicDemo
% GUIUITABLEBASICDEMO basic demo for uitable properties and some technical
% solutions for resize and extended callbacks.
%
% CAUTION - limit points for MATLAB uitable usage:
%  - popupmenus can only have the same content options for each line
%  - proper resize can be only with a resize function of an ancestor
%    panel or the main GUI
%  - The column and row header strings can be only modified by html tags
% 
% Syntax:
%   GUIuitableBasicDemo
%
% Inputs:
%
% Outputs:
%
% Example: 
%   GUIuitableBasicDemo
%
% Subfunctions:
%
% See also: <OTHER_FUNCTION_NAME1>, <OTHER_FUNCTION_NAME2> 
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2015-08-17

% singleton
hFig = findobj('Tag','uitable_demo');
if ~isempty(hFig) % if figure exists already
%     figure(hFig); % bring to front
%     return
    close(hFig)
end

% get GUI standard properties
xProp = dbcGuiProperties;

% standard GUI spacings
gap = 0.005;

% Main figure (window)
data.htd.main = figure('Units','Pixels',...
   'Position',[200 160 400 300],...
   'NumberTitle','off',...
   'DockControls','off',...
   'MenuBar','none',...
   'Visible','on',...
   'Resize','on',...
   'Color',xProp.color.default.BackgroundColor,...
   'Name','Uitable Demo',...
   'WindowButtonMotionFcn','',...
   'Tag','uitable_demo');
data = GUIuitableUiMenu(data);

data.htd.p(1).main = uipanel(...
    'Parent',data.htd.main,...
    xProp.uipanel,...
    'Position',[gap gap .99 .99],...
    'ResizeFcn',@GUIuitableCbPanelResize,...
    'Title','UiTable');

% get context menu
data = GUIuitableUiContextMenu(data);

% uitable
data.htd.p(1).tb(1) = uitable(...
    'Parent',data.htd.p(1).main,...
    'Units','normalized',...
    'Position',[gap gap 0.99 0.99],...
    'BackgroundColor',[xProp.color.editable.BackgroundColor;xProp.color.nonEdit.BackgroundColor], ...
    'FontSize',9, ...
    'UIContextMenu',data.uicm(1), ...
    'ColumnName',{'<html><b>AA<font color=rgb(0,0,255)>&#8593;&#x25B2;&#x21E7;</font></b></html>','BB','C3','<html><i>Dttt</i></html>'}, ... cell [1xn] with strings or {'numbered'}
    'Data',{'bla',true,'option2','edit1';'blub',false,'option3','edit2';'blob',true,'option1','edit3'},...
    'ColumnFormat',{'char','logical',{'option1','option2','option3'}}, ... cell [1xn] 'char'/'logical'/'numeric'/'short'/'long'/'longG'/'bank',{'option1','option2','option3'}
    'ColumnEditable',[false true true true], ... matrix of booleans with size of table
    'ColumnWidth',{80 'auto' 'auto' 'auto'}, ... cell [1xn] with width in pixels or 'auto' per column
    'UserData',[0.2 0.07 0.5 0.23], ... vector for resize of column width in normalized units
    'CellSelectionCallback',@GUIuitableCbCellSelection, ... % fcn handle or cell of fcn handle with size of table 
    'CellEditCallback',@GUIuitableCbCellEdit ... % fcn handle or cell of fcn handle with size of table 
    );

% % Display the uitable and get its underlying Java object handle
% addpath('C:\dirsync\02Allgemeines\02CodeBase\Matlab\A_Matlab_File_Exchange\GUI\findjobj')
% jscrollpane = findjobj(data.htd.p(1).tb(1));
% jtable = jscrollpane.getViewport.getView;
%  
% % Now turn the JIDE sorting on
% jtable.setSortable(true);		% or: set(jtable,'Sortable','on');
% jtable.setAutoResort(true);
% jtable.setMultiColumnSortable(true);
% jtable.setPreserveSelectionsAfterSorting(true);

% special characters in HTML code
% uparrow broad &#x25B2; - from unicode
% downarrow broad &#x25BC; - from unicode
% uparrow hollow &#x21E7; - from unicode
% downarrow hollow &#x21E9; - from unicode
% uparrow &#8593;
% downarrow &#8595;
% leftarrow &#8592;
% rightarrow &#8594;
% franc sign &#8355; use for filter?
% function sign &#131; use for filter?

%     'BackgroundColor',[xProp.color.editable.BackgroundColor;xProp.color.nonEdit.BackgroundColor], ...
%     'ButtonDownFcn','', ...
%     'CellEditCallback',{}, ... % fcn handle or cell of fcn handle with size of table 
%     'CellSelectionCallback',{}, ... % fcn handle or cell of fcn handle with size of table 
%     'ColumnEditable',[], ... matrix of booleans with size of table
%     'ColumnFormat',{}, ... cell [1xn] 'char'/'logical'/'numeric'/'short'/'long'/'longG'/'bank',{'option1','option2','option3'}
%     'ColumnName',{}, ... cell [1xn] with strings or {'numbered'}
%     'ColumnWidth',{}, ... cell [1xn] with width in pixels or 'auto' per column
%     'Data',{}, ... matrix or cell with data
%     'FontAngle','normal', ... italic, oblique
%     'FontName','Arial', ...
%     'FontSize',10, ...
%     'FontWeight','bold', ... works only on cell content
%     'FontName','Arial', ...
%     'KeyPressFcn','', ... varargin{2} = struct('Character',...,'Modifier',...,'Key')
%     'RearrangeableColumns','on', ... user can change order of columns
%     'RowName',{}, ... cell [1xn] with strings or {'numbered'}
%     'RowStriping','off', ...
%     'Selected','on', ...
%     'SelectionHighlight','on', ...
%     'TooltipString','off', ...
%     'UIContextMenu','', ...
%     'UserData','', ...
%     'Visible','off', ... Setting Visible to off for uitables that are not displayed initially in the GUI, can result in faster startup time for the GUI.

% store main data 
guidata(data.htd.main,data);

return

% =========================================================================

function GUIuitableCbPanelResize(varargin)
% GUIUITABLECBPANELRESIZE resize function for panel to resize the column
% widht of the uitable.
%
% Syntax:
%   GUIuitableCbPanelResize(varargin)
%
% Inputs:
%   varargin - 
%
% Outputs:
%
% Example: 
%   GUIuitableCbPanelResize(varargin)

% get main data
data = guidata(gof);

% get current table size
set(data.htd.p(1).tb(1),'Units','pixels');
nPos = get(data.htd.p(1).tb(1),'Position');
set(data.htd.p(1).tb(1),'Units','normalized');

% determine new column sizes
vColumn = get(data.htd.p(1).tb(1),'UserData');
nWidth = floor(nPos(3)-nPos(1)) - 30;
nPosNew = nWidth*vColumn;

% set new column width
set(data.htd.p(1).tb(1),'ColumnWidth',num2cell(nPosNew));
return


% =========================================================================

function GUIuitableCbCellEdit(varargin)

hTable = varargin{1};
xEvent = varargin{2}; % Indices [1x2]; PreviousData; EditData; NewData; Error
return

% =========================================================================

function GUIuitableCbCellSelection(varargin)

hTable = varargin{1};
xEvent = varargin{2}; % Indices [1x2]; PreviousData; EditData; NewData; Error

disp('GUIuitableCbCellSelection')
return

% =========================================================================

function GUIuitableCbContextMenu(varargin)

hTable = varargin{1};
xEvent = varargin{2}; % Indices [1x2]; PreviousData; EditData; NewData; Error

return

% =========================================================================

function data = GUIuitableUiContextMenu(data)

% contextmenu of source listbox
data.uicm(1) = uicontextmenu(...
                    'Callback',@GUIuitableUiContextCallback);
        uimenu(data.uicm(1),...
            'Label','<html><i>Col. Xy</i></html>',...
            'Callback','');
        uimenu(data.uicm(1),...
            'Label','A->Z',...
            'Callback',@GUIuitableCbContextMenu);
        uimenu(data.uicm(1),...
            'Label','Z->A',...
            'Callback','');
        uimenu(data.uicm(1),...
            'Label','Filter...',...
            'Callback','',...
            'Separator','on');
        uimenu(data.uicm(1),...
            'Label','Bin1',...
            'Callback','',...
            'Separator','on');
        uimenu(data.uicm(1),...
            'Label','Bin2',...
            'Callback','',...
            'Separator','on');
        uimenu(data.uicm(1),...
            'Label','Bin3',...
            'Callback','');
        
return

% =========================================================================

function GUIuitableUiContextCallback(varargin)

get(gcf,'CurrentPoint')
data = guidata(gcf);
get(data.uicm(1),'Position')
return

% =========================================================================

function data = GUIuitableUiMenu(data)

nIdxMenu = 1;
data.uim(nIdxMenu).main = uimenu('Label','Edit');
         data.uim(nIdxMenu).uim(1) = uimenu(data.uim(nIdxMenu).main,... 
             'Label','Undo',...
             'Callback','',...
             'Accelerator','Z');
         data.uim(nIdxMenu).uim(2) = uimenu(data.uim(nIdxMenu).main,... 
             'Label','Restore',...
             'Callback',@dbcUiCbEditRestore,...
             'Accelerator','Y');
         
         uimenu(data.uim(nIdxMenu).uim(1),...
             'Label','bla1',...
             'Accelerator','Z');
         uimenu(data.uim(nIdxMenu).uim(1),...
             'Label','bla2',...
             'Accelerator','M');
         uimenu(data.uim(nIdxMenu).uim(1),...
             'Label','bla3',...
             'Accelerator','P');
return

% =========================================================================

function prop = dbcGuiProperties
% DBCGUIPROPERTIES defines central standard properties for GUI elements.
%
% Syntax:
%   prop = dbcGuiProperties
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

% checkbox
prop.checkbox = structAdd(prop.basic,prop.color.editable);
prop.checkbox.Style = 'checkbox';

% popupmenu
prop.popupmenu = structAdd(prop.basic,prop.color.editable);
prop.popupmenu.Style = 'popupmenu';
prop.popupmenu.FontSize = prop.basic.FontSize-1;

% slider
prop.slider = structAdd(prop.basic,prop.color.nonEdit);
prop.slider.Style = 'slider';
prop.slider.value= 1;
prop.slider.min = 1;
prop.slider.max = 2;
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