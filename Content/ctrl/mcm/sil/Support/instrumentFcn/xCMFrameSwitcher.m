function xCMFrameSwitcher
% XCMFRAMESWITCHER GUI for changing the ACM/MCM frames in an integration model
% from open Simulink to closed S-function models or vice versa. The frame
% instances are copied from the available libraries.
% 
% This function is intended to be called by a block which is placed on the
% level of the frame subdivision level e. g. 'Model Common Functions'.
%
% Syntax:
%   xCMFrameSwitcher
%
% Inputs:
%
% Outputs:
%
% Used Structure Variables:
%     xLibrary: (implicit by save file!) structure with information of
%                available frame libraries 
%       .<framename>: struct named by frame
%         .sl       : boolean for availability of open simulink instance of
%                     frame
%         .sfcn     : boolean for availability of s-function instance of
%                     frame
%         .libname  : string with name of simulink library
% 
% Example: 
%   xCMFrameSwitcher
%
%
% Subfunctions: xwsCreateGUI, xwsGUIcbCopyFrame, xwsGUIcbListbox,
% xwsLibInfo
%
% See also: clcFrameCopy, clcFrameInfo, GUIcbListboxChangeContent,
% GUIcbRadioButton, fullfileSL, gof, ismdl, slcBlockInfo, slcDisableLink,
% slcLoadEnsure
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2014-10-09

% extract frame names in current subsystem
if isempty(gcb) % only for development
    cFrameBlockPath = {};
    sPathSL = '';
else
    sPathSL = fileparts(gcb);
    [cFrame,cFrameBlockPath,bFrameSFcn,xLibrary] = spsFrameInfo(sPathSL); %#ok<NASGU,ASGLU>
end

% Singleton - allow only one frame switcher per xCM
hMain = findobj('Tag','xfs_main_window');
cPath = {''};
for nIdxHandle = 1:length(hMain)
    data = guidata(hMain(nIdxHandle));
    cPath = [cPath,{data.sBlockPath}]; %#ok
end
if ismember(sPathSL,cPath)
    figure(hMain(nIdxHandle));
    warndlg('There is still an open instance of the xCM Switcher for this control module!','xCM Frame Switcher active')
    return
end

% get library information
[xLibrary,cLibDisp] = xwsLibInfo(sPathSL);

% create GUI
data.hxs.main = xwsCreateGUI(cLibDisp,sPathSL);

% add library data to guidata
data = guidata(data.hxs.main);
data.xLibrary = xLibrary;
data.cFrameBlockPath = cFrameBlockPath;
data.sBlockPath = sPathSL;
guidata(data.hxs.main,data);
return

% =========================================================================

function hMain = xwsCreateGUI(cLibDisp,sPathSL)
% XWSCREATEGUI creates the selection GUI for xCU frames
% 
% Syntax:
%   hMain = xwsCreateGUI(cLibDisp,sPathSL)
%
% Inputs:
%   cLibDisp - cell (nx1) with strings of frame listbox content
%    sPathSL - string with xCM model path 
%
% Outputs:
%   hMain - handle of main GUI 
%
% Example: 
%   hMain = xwsCreateGUI(cLibDisp,sPathSL)

% standard gaps in GUI
bs = 0.01; % standard width spacing
lbw = 0.5; % listbox width

% Main figure (window)
[path,slblock] = fileparts(sPathSL); %#ok<ASGLU>
data.hxs.main = figure ('Units','Pixels',...
   'Position',[230 150 400 500],...
   'NumberTitle','off',...
   'DockControls','off',...
   'MenuBar','none',...
   'Visible','on',...
   'Resize','on',...
   'Color',[0.8 0.8 0.8],...
   'Name',['xCM Frame Switcher: ' slblock],...
   'Tag','xfs_main_window');
hMain = data.hxs.main;

% text frame
data.hxs.t(1) = uicontrol('Parent',data.hxs.main,...
   'Units','normalized',...
   'Position',[bs 0.96 lbw 0.03],...
   'Style','text',...
   'FontName','Arial',...
   'FontWeight','bold',...
   'FontSize',9,...
   'BackgroundColor',[0.8 0.8 0.8],...
   'HorizontalAlignment','left',...
   'String','Frame');

% listbox frames
data.hxs.lb(1) = uicontrol(...
    'Parent',data.hxs.main,...
    'Units','normalized',...
    'BackgroundColor',[1 1 1],...
    'Position',[bs bs lbw 0.95],...
    'String',cLibDisp,...
    'Style','listbox',...
    'FontName','FixedWidth',...
    'Callback',@xwsGUIcbListbox,...
    'Min',1,...
    'Max',100,...
    'Value',1);

% radiobutton simulink open
data.hxs.r(1) = uicontrol('Parent',data.hxs.main,...
   'Units','normalized',...
   'Position',[2*bs+lbw 0.93 1-(2*bs+lbw) 0.03],...
   'Style','radiobutton',...
   'FontName','Arial',...
   'FontSize',9,...
   'Value',1,...
   'Callback',{@GUIcbRadioButton,@xwsGUIcbListbox},...
   'BackgroundColor',[0.8 0.8 0.8],...
   'String','Simulink Model (open)');

% radiobutton s-function
data.hxs.r(2) = uicontrol('Parent',data.hxs.main,...
   'Units','normalized',...
   'Position',[2*bs+lbw 0.90 1-(2*bs+lbw) 0.03],...
   'Style','radiobutton',...
   'FontName','Arial',...
   'FontSize',9,...
   'Value',0,...
   'Callback',{@GUIcbRadioButton,@xwsGUIcbListbox},...
   'BackgroundColor',[0.8 0.8 0.8],...
   'String','S-Function from TargetLink');
set(data.hxs.r,'UserData',data.hxs.r);

% text ignore dataset
data.hxs.t(2) = uicontrol('Parent',data.hxs.main,...
   'Units','normalized',...
   'Position',[2*bs+lbw+0.04 0.87 1-(2*bs+lbw)-0.04 0.03],...
   'Style','text',...
   'FontName','Arial',...
   'FontSize',9,...
   'BackgroundColor',[0.8 0.8 0.8],...
   'HorizontalAlignment','left',...
   'String','(ignores dataset in workspace)');

% button copy frames
data.hxs.b(1) = uicontrol(...
    'Parent',data.hxs.main,...
    'Units','normalized',...
    'Position',[2*bs+lbw 0.81 1-(2*bs+lbw)-0.06 0.05],...
    'Style','pushbutton',...
    'Callback',@xwsGUIcbCopyFrame,...
    'Backgroundcolor',[0.8 0.8 0.8 ],...
    'FontSize',9,...
    'FontWeight','bold',...
    'HorizontalAlignment','left',...
    'TooltipString','Execute copy operation for all selected frames.',...
    'String','Copy Frame from Library');

% checkbox break library link
data.hxs.cb(1) = uicontrol(...
    'Parent',data.hxs.main,...
    'Units','normalized',...
    'Position',[2*bs+lbw 0.77 1-(2*bs+lbw) 0.03],...
    'Backgroundcolor',[0.8 0.8 0.8 ],...
    'FontSize',9,...
    'Style','checkbox',...
    'Value',0,...
    'String','Break Library Links');

% % button update frames
% data.hxs.b(2) = uicontrol(...
%     'Parent',data.hxs.main,...
%     'Units','normalized',...
%     'Position',[2*bs+lbw 0.01 1-(2*bs+lbw)-0.06 0.05],...
%     'Style','pushbutton',...
%     'Callback',@xwsGUIcbLibInfoUpdate,...
%     'Backgroundcolor',[0.8 0.8 0.8 ],...
%     'FontSize',9,...
%     'FontWeight','bold',...
%     'HorizontalAlignment','left',...
%     'TooltipString','Update Frame list when using an updated frame library.',...
%     'String','Update Frame List');

% store handles with GUI
guidata(data.hxs.main,data);
return

% =========================================================================

function [xLibrary,cLibDisp] = xwsLibInfo(sBlockPath)
% XWSLIBINFO determine frame library availability and listbox content
%
% Syntax:
%   [xLibrary,cLibDisp] = xwsLibInfo(sBlockPath)
%
% Inputs:
%   sBlockPath - string 
%
% Outputs:
%   xLibrary - (implicit by save file!) structure with information of
%                available frame libraries 
%       .<framename> - struct named by frame
%         .sl        - boolean for availability of open simulink instance of
%                      frame
%         .sfcn      - boolean for availability of s-function instance of
%                      frame
%         .libname   - string with name of simulink library
%   cLibDisp - cell (nx1) with strings of frame listbox content
%
% Example: 
%   [xLibrary,cLibDisp] = xwsLibInfo(sBlockPath)

% get information of frames in xCU and file system library
[cFrame,cFrameBlockPath,bFrameSFcn,xLibrary] = spsFrameInfo(sBlockPath); %#ok<ASGLU>

% create listbox string
cLibDisp = {};
[cFrame,nIdSort] = sort(cFrame);
bFrameSFcn = bFrameSFcn(nIdSort);
for k = 1:length(cFrame)
    sLine = '';
    
    % add ID of usage: open simulink model
    if bFrameSFcn(k)
        sLine =[sLine '  ']; %#ok
    else
        sLine =[sLine 'X ']; %#ok
    end
    
    % add simulink library availability ident
    if isfield(xLibrary,cFrame{k}) && xLibrary.(cFrame{k}).sl
        sLine =[sLine 'sl ']; %#ok
    else
        sLine =[sLine '-  ']; %#ok
    end
    
    % add ID of usage: s-function model
    if bFrameSFcn(k)
        sLine =[sLine 'X ']; %#ok
    else
        sLine =[sLine '  ']; %#ok
    end
    
    % add s-function library availability ident
    if isfield(xLibrary,cFrame{k}) && xLibrary.(cFrame{k}).sfcn
        sLine =[sLine 'sfcn ']; %#ok
    else
        sLine =[sLine '-    ']; %#ok
    end
    
    % add library name
    sLine =[sLine cFrame{k}]; %#ok
    
    % store line
    cLibDisp = [cLibDisp; {sLine}]; %#ok
end

if isempty(cLibDisp)
    cLibDisp = {'-'};
end
return

% =========================================================================

function xwsGUIcbCopyFrame(varargin)
% XWSGUICBCOPYFRAME button callback function copy selected frames from
% library to integration.
%
% Syntax:
%   xwsGUIcbCopyFrame
%
% Example: 
%   xwsGUIcbCopyFrame

% get guidata
data = guidata(gof);

% get GUI settings
if get(data.hxs.r(1),'Value')
    sCopySuffix = 'sl';
end
if get(data.hxs.r(2),'Value')
    sCopySuffix = 'sfcn';
end
cLibDisp = get(data.hxs.lb(1),'String');
nFrameSelection = get(data.hxs.lb(1),'Value');
bBreakLink = get(data.hxs.cb(1),'Value');
if strcmp(cLibDisp{1},'-')
    return
end

% create cell list of selected frames
cFrame = cell(1,numel(nFrameSelection));
for nIdxSelection = 1:numel(nFrameSelection)
    cFrame{nIdxSelection} = cLibDisp{nFrameSelection(nIdxSelection)}(13:end);
end

% copy frames
spsFrameCopy(data.sBlockPath,cFrame,sCopySuffix,bBreakLink,data.xLibrary);

% update display
[xLibrary,cLibDisp] = xwsLibInfo(data.sBlockPath); %#ok<ASGLU> % get new string list for display
GUIcbListboxChangeContent(data.hxs.lb(1),cLibDisp);

% do VTruck update if necessary
if (exist('twt_storeBusSelectorSignals','file') == 2 || exist('twt_storeBusSelectorSignals','file') == 6)&& ...
        ~isempty(find_system(bdroot(data.sBlockPath),'SearchDepth',1,'BlockType','SubSystem','Name','Ctrl')) && ...
        ~isempty(find_system(bdroot(data.sBlockPath),'SearchDepth',1,'BlockType','SubSystem','Name','Veh'))
    disp('Copy operation of frames finished.')
    disp('Invoke of VTruck Bus Selector update...')
    ModelBase = bdroot(data.sBlockPath);
    twt_storeBusSelectorSignals(ModelBase);
    twt_UpdateModel(ModelBase);
    twt_checkBusSelectorSignals(ModelBase,false,'Update main model delays logging and routing');
    disp('BusSelector update of VTruck finished.')
else
    disp('Copy operation of frames finished.')
end
return

% =========================================================================

function xwsGUIcbListbox(varargin)
% XWSGUICBLISTBOX listbox callback function limit selection of listbox on
% available library models.
%
% Syntax:
%   xwsGUIcbListbox
%
% Example: 
%   xwsGUIcbListbox

% get guidata
data = guidata(gof);

% get GUI settings
if get(data.hxs.r(1),'Value')
    CopySuffix = 'sl';
end
if get(data.hxs.r(2),'Value')
    CopySuffix = 'sfcn';
end
cLibDisp = get(data.hxs.lb(1),'String');
nFrameSelection = get(data.hxs.lb(1),'Value');
if strcmp(cLibDisp{1},'-')
    return
end

% check availability
KeepID = true(1,length(nFrameSelection));
for k = 1:length(nFrameSelection)
    sFrame = cLibDisp{nFrameSelection(k)}(13:end);
    KeepID(k) = data.xLibrary.(sFrame).(CopySuffix);
end
nFrameSelection = nFrameSelection(KeepID);

% set limited Selection
if isempty(nFrameSelection)
    set(data.hxs.lb(1),'Value',1,'ListboxTop',1);
else
    set(data.hxs.lb(1),'Value',nFrameSelection);
end
return

% =========================================================================

function GUIcbListboxChangeContent(ListboxHandle,CellContent)
% GUIcbListboxUpdate - change content of a listbox with correct value
% selection handling.
%
% Rainer Frey, TP/PCD, Daimler AG
% 2009
% 
% Input variables:
% ListboxHandle - handle (vector) of listbox
% CellContent   - cell of strings with new listbox content

if isempty(CellContent)
    CellContent = {'-'};
end

for k = 1:length(ListboxHandle)
    % get correct list selection
    Selection = get(ListboxHandle(k),'Value');
    Selection = Selection(Selection<=length(CellContent));
    if isempty(Selection)
        Selection = 1;
    end
    
    set(ListboxHandle(k),'Value',Selection,'String',CellContent);
end
return 

% =========================================================================

function GUIcbRadioButton(varargin)
% GUIcbRadioButton
% Switches radiobuttons and executes passed callback.
% Premise is, that the handles of the other radiobuttons are stored in
% property UserData of currrent radiobutton.
% 
% Example call:
% hf = figure('Position',[100 100 200 50]);
% hr(1) = uicontrol('Parent',hf...
%     ,'Units','normalized','Position',[0 0 1 0.5],...
%     'Style','radiobutton','String','radio 1',...
%     'Callback',@GUIcbRadioButton);
% hr(2) = uicontrol('Parent',hf...
%     ,'Units','normalized','Position',[0 0.5 1 0.5],...
%     'Style','radiobutton','String','radio 2',...
%     'Callback',{@GUIcbRadioButton,@disp,'argument of additional callbackfcn'});
% set(hr,'UserData',hr);
% 
%   See also GUIcbListboxLink, GUIcbFocusEdit, GUIcbDoubleClick.

% change radiobutton selection
hRadioCurrent = gcbo;
hRadioGroup = get(hRadioCurrent,'UserData');
set(hRadioGroup(hRadioGroup~=hRadioCurrent),'Value',0);
set(hRadioCurrent,'Value',1);

% execute subesquent callback functions
if nargin >=3
    feval(varargin{3:end});
end
return

% =========================================================================

function varargout = gof(varargin)
% gof - get object figure returns the figure handle of an object (uicontrol
% or figure) or of the current callback object.
% 
% FigureHandle = gof
% [ObjectHandle,FigureHandle] = gof
% [ObjectHandle,FigureHandle] = gof(ObjectHandle)

if nargin == 0
    ObjectHandle = get(0, 'CallbackObject');
    if isempty(ObjectHandle)
        ObjectHandle = gcf;
    end
else
    ObjectHandle = varargin{1};
end

FigureHandle = ObjectHandle;
while ~strcmp(get(FigureHandle,'Type'),'figure') && ~isempty(get(FigureHandle,'Parent'))
    FigureHandle = get(FigureHandle,'Parent');
end

if nargout < 2
    varargout{1} = FigureHandle;
else
    varargout{1} = ObjectHandle;
    varargout{2} = FigureHandle;
end
return

