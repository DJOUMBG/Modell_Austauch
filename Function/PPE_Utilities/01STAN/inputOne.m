function sAnswer = inputOne(cPrompt,sTitle,hReference,sDefault)
% INPUTONE replacement for inputdlg in use of a single requested input.
% Special features like :
%  - <enter> in the edit box triggers the OK button.
%  - Dialogue can open in the middle of a specified MATLAB GUI handle
% 
% Syntax:
%   sAnswer = inputOne(cPrompt,sTitle,hReference,sDefault)
%
% Inputs:
%      cPrompt - cell (1xn) cell with strings of prompt lines
%       sTitle - string with figure title
%   hReference - handle of reference figure (dialogue will be placed in the
%                center of the reference figure, if no reference figure it
%                will be in the middle of monitor 1 
%     sDefault - string with default value
%
% Outputs:
%   sAnswer - string with user input (empty if cancel is pressed)
%
% Example: 
%   sAnswer = inputOne('Single prompt:','Figure title is example')
%   hRef = figure; sAnswer = inputOne({'First line of two line prompt','second line:'},'Example2',hRef,'ThisIsTheDefaultValue')
%
% Subfunctions: inputGuiProperties
%
% See also: structAdd
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-8485-3325
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2017-01-18

% init output
sAnswer = [];

% input check
if nargin < 1
    cPrompt = 'Input:';
end
if ~iscell(cPrompt)
    cPrompt = {cPrompt};
end
if nargin < 2
    sTitle = '';
end
if nargin < 3
    hReference = [];
end
if nargin < 4
    sDefault = '';
else
    if iscell(sDefault)
        sDefault = sDefault{1};
    end
end

% determine position of reference GUI
if nargin > 2 && ~isempty(hReference) && ishandle(hReference)
    sUnits = get(hReference,'Units');
    set(hReference,'Units','Pixels');
    nRef = get(hReference,'Position');
    set(hReference,'Units',sUnits);
else
    % get middle of screensize
    nPositionMonitor = get(0,'MonitorPositions');
    nRef = nPositionMonitor(1,:);
end

% determine width requirement due to prompt text
nLineMax = max(cellfun(@numel,cPrompt));
nLineMax = max(nLineMax,numel(sDefault));

%% dialogue GUI
% basic uicontrol properties
xProp = inputGuiProperties;

% basic GUI parameters
gap = 2; % standard gap
plh = 15; % standard line height
deh = 4; % difference of edit line height to plh
pbw = 56; % pushbutton width 
pbh = 23; % pushbutton width
nPos = [300 300 ...
        max(max(nLineMax)*8+2*gap,175) ...
        numel(cPrompt)*(gap+plh)+3*gap+plh+deh+pbh];
nPos = [nRef(1:2)+0.5*(nRef(3:4)-nPos(3:4)) nPos(3:4)];

% create dialogue figure
hStruct.main = figure ('Units','pixel',...
    'Position',nPos,...
    'NumberTitle','off',...
    'DockControls','off',...
    'MenuBar','none',...
    'Name',sTitle,...
    'Tag','inputOne',...
    'WindowStyle','modal',...
    'UserData',-1,...
    'Visible','off',...
    'Color',xProp.color.default.BackgroundColor);

% text 
nLine = [numel(cPrompt) numel(cPrompt)]; % absolute line of lower element limit and lines for height
hStruct.t(1) = uicontrol(...
    'Parent',hStruct.main,...
    xProp.text,...
    'Position',[gap nPos(4)-nLine(1)*(plh+gap) nPos(3)-2*gap nLine(2)*(plh+gap)-gap],...
    'String',cPrompt);

% edit optional regexp
hStruct.e(1) = uicontrol(...
    'Parent',hStruct.main,...
    xProp.edit,...
    'Position',[gap 2*gap+pbh nPos(3)-2*gap plh+deh],...
    'HorizontalAlignment','left', ...
    'Callback','guidata(gcf,2);set(gcf,''UserData'',2);',...
    'String',sDefault);

% button adapt
hStruct.b(1) = uicontrol(...
    'Parent',hStruct.main,...
    xProp.pushbutton,...
    'Position',[nPos(3)-2*(gap+pbw) gap pbw pbh],...
    'Callback','guidata(gcf,1);set(gcf,''UserData'',1);',...
    'String','OK');

% button cancel
hStruct.b(2) = uicontrol(...
    'Parent',hStruct.main,...
    xProp.pushbutton,...
    'Position',[nPos(3)-1*(gap+pbw) gap pbw pbh],...
    'Callback','guidata(gcf,0);set(gcf,''UserData'',0);',...
    'UserData',hStruct.e(1),...
    'String','Cancel');

% make figure visible
set(hStruct.main,'Visible','on');

% set focus on edit
uicontrol(hStruct.e(1))

% waitfor deletion of GUI
waitfor(hStruct.main,'UserData');

% left edit window after entering input
if ishandle(hStruct.main) && get(hStruct.main,'UserData') == 2
    % create & start timer to account for cancel or ok button press 
    hTimer = timer('Name','InputOneTimer'...
        ,'ExecutionMode','singleShot'...
        ,'StartDelay',0.2 ...
        ,'TimerFcn',{@cbTimerFcn,hStruct.main}...
        );
    start(hTimer);
    
    % wait with further execution
    waitfor(hStruct.main,'UserData');
    
    % cleanup timer
    stop(hTimer);
    delete(hTimer);
end

%% dialogue action
% proceed with output generation
if ishandle(hStruct.main) 
    if get(hStruct.main,'UserData') == 1
        % get input
        sAnswer = get(hStruct.e(1),'String');
    end
    
    % close GUI
    close(hStruct.main);
end
return

% =========================================================================

function cbTimerFcn(obj, event, hMain) %#ok<INUSL>
% if dialogue still exists
if ishandle(hMain)
    % check ident value
    n = get(hMain,'UserData');
    if n == 2
        % trigger ok action
        set(hMain,'UserData',1);
    end
end
return

% =========================================================================

function prop = inputGuiProperties
% INPUTGUIPROPERTIES defines central standard properties for GUI elements.
%
% Syntax:
%   prop = inputGuiProperties
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

%% common properties
prop.basic.Units = 'pixels';
prop.basic.FontName = 'arial';
prop.basic.FontSize = 9;

% pushbutton
prop.pushbutton = structAdd(prop.basic,prop.color.default);
prop.pushbutton.Style = 'pushbutton';
prop.pushbutton.HorizontalAlignment = 'center';

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
