function slcEcuSpyAdd(hBlock,hLine,nVerbosity)
% SLCECUSPYADD add ports of selected blocks and lines to an EcuSpy Channel
% list stored with the Matlab instance. The channels can be imported in the
% ECU Spy Generator of DIVe Basic Configurator of DIVe ModelBased to 
%
% Syntax:
%   slcEcuSpyAdd(hBlock,hLine,nVerbosity)
%
% Inputs:
%       hBlock - handle vector of Simulink block or 
%                string with a single Simulink block path or
%                cell with strings of Simulink block pathes
%        hLine - handle vector (1xn) of Simulink signal lines
%   nVerbosity - integer (1x1) if user should be queried for settings
%                0: no query to user, standard settings taken
%                1: query to user, chance to select channels to use, modify
%                   channel name and width
%
% Outputs:
%
% Example: 
%   slcEcuSpyAdd(gcbs,gcl,1)
%
% Subfunctions: escGuiProperties, esuChannelAdaption, getBlockPort,
%   getLinePort
%
% See also: slcBlockInfo, slcLineInfo, structAdd
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2017-02-08
% 
% cell definition
%   cQuery - cell (mx6) with instrument channel information:
%           {:,1} bUse - boolean if port shall be used in Ecu-Spy Generator
%           {:,2} sName - string with name of instrumentation channel
%           {:,3} sBlock - string with blockpath of Simulink block
%           {:,4} sPortType - string with port type of instrumentation channel
%           {:,5} nPortNumber - integer with port number of instrumentation channel
%           {:,6} nVector - integer with vector length of signal

% check input
if nargin < 3
    nVerbosity = 1;
end

% initialize output
cQuery = cell(0,6);

% determine block ports
if ~isempty(hBlock)
    cQueryAdd = getBlockPort(hBlock);
    cQuery = [cQuery; cQueryAdd];
end

% determine line outports
if ~isempty(hLine)
    cQueryAdd = getLinePort(hLine);
    cQuery = [cQuery; cQueryAdd];
end

% cleanup Simulink pathes
cQuery(:,3) = regexprep(cQuery(:,3),{char(10),'<','>'},'');

% ask user for changes adaptions to current save setting
if nVerbosity > 0
    cQuery = esuChannelAdaption(cQuery);
end

% store channel cell with MATLAB instance
if isappdata(0,'EcuSpyChannel')
    cChannel = getappdata(0,'EcuSpyChannel');
else
    cChannel = cell(0,6);
end
cChannel = [cChannel; cQuery];
setappdata(0,'EcuSpyChannel',cChannel);
return

% =========================================================================

function cQuery = esuChannelAdaption(cQuery)
% ESUCHANNELADAPTION ask user in GUI table for correction to parsed channel
% settings.
%
% Syntax:
%   cQuery = esuChannelAdaption(cQuery)
%
% Inputs:
%   cQuery - cell (mx6) with instrument channel information:
%           {:,1} bUse - boolean if port shall be used in Ecu-Spy Generator
%           {:,2} sName - string with name of instrumentation channel
%           {:,3} sBlock - string with blockpath of Simulink block
%           {:,4} sPortType - string with port type of instrumentation channel
%           {:,5} nPortNumber - integer with port number of instrumentation channel
%           {:,6} nVector - integer with vector length of signal
%
% Outputs:
%   cQuery - cell (mx6) with instrument channel information:
%           {:,1} bUse - boolean if port shall be used in Ecu-Spy Generator
%           {:,2} sName - string with name of instrumentation channel
%           {:,3} sBlock - string with blockpath of Simulink block
%           {:,4} sPortType - string with port type of instrumentation channel
%           {:,5} nPortNumber - integer with port number of instrumentation channel
%           {:,6} nVector - integer with vector length of signal
%
% Example: 
%   cQuery = esuChannelAdaption(cQuery)

% get standard properties for GUI elements
data.const.prop = escGuiProperties;

%% main figure
data.hca.main = figure ('Units','pixel',...
   'Position',[60 80 900 550],... 'Position',[120 120 750 550],...
   'NumberTitle','off',...
   'DockControls','off',...
   'MenuBar','none',...
   'Name','Adapt Channel settings',...
   'Tag','ECUSpyChannelAdaption',...
   'Color',data.const.prop.color.default.BackgroundColor,...
   'Visible','on');  
%    'WindowStyle','modal',...

% standard sizes
gap = 0.005;
hb = 0.04; % height button
wb = 0.1; % width button

% table of assgined channels
cTableColWidth = {30,170,60,35,35,500};
cTableColHeader = {'Use','Channel Name','PortType','Port','Width','Channel path in Simulink'}; % text box contents
cTableColHeader = cellfun(@(x)['<html><b>' x '</b></html>'],cTableColHeader,'UniformOutput',false);
cTableColEditable = [true,true,false,false,true,false];
cTableColFormat = {'logical','char','char','numeric','numeric','char'};
data.hca.tb(1) = uitable('Parent',data.hca.main,...
    'Units','normalized',...
    'Position',[gap 2*gap+hb 1-2*gap 1-3*gap-hb],...
    'ColumnFormat',cTableColFormat,...
    'ColumnWidth',cTableColWidth,...
    'ColumnEditable',cTableColEditable,...
    'ColumnName',cTableColHeader,...
    'Data',cQuery(:,[1,2,4,5,6,3]),...
    'Tooltipstring',sprintf(['Parsed settings from your actual selection in the Simulink model.\n' ...
                             'Please adapt channel names and signal width.\n' ...
                             'Select the channels you want to use in EcuSpy Generator and hit OK.']));
%     'RowName',{},...

% button create instrumentation
data.hca.b(1) = uicontrol(...
    'Parent',data.hca.main,...
    data.const.prop.pushbutton,...
    'Position',[1-2*gap-2*wb gap wb hb],...
    'UserData',false,...
    'Callback','set(gcbo,''UserData'',true)',...
    'Fontweight','bold',...
    'TooltipString',['<html>Save instrumentation variant from the actual <br />' ...
                     'channel selections for use in DIVe configurations</html>'],...
    'String','OK');

% button cancel
data.hca.b(2) = uicontrol(...
    'Parent',data.hca.main,...
    data.const.prop.pushbutton,...
    'Position',[1-1*gap-1*wb gap wb hb],...
    'Callback','close(findobj(''Tag'',''ECUSpyChannelAdaption''));',...
    'Fontweight','bold',...
    'TooltipString','Discard all channels',...
    'String','Cancel');

% wait for OK exit
waitfor(data.hca.b(1),'UserData');

% retrieve data from table
if ishandle(data.hca.tb(1))
    cData = get(data.hca.tb(1),'Data');
    cQuery = cData(:,[1,2,6,3,4,5]);
    cQuery = cQuery(cell2mat(cQuery(:,1)),:);
else % figure is already destroyed
    return
end

% close figure
close(data.hca.main);
return

% =========================================================================

function cQuery = getBlockPort(hBlock)
% GETBLOCKPORT determine instrumentation information of all ports of the
% specified blocks.
% Name of instrumentation channel is either signal name of signal connected
% to the port, the port name in case of a subsystem or a generic name made
% up from block name, port type and port number.
%
% Syntax:
%   cQuery = getBlockPort(hBlock)
%
% Inputs:
%   hBlock - handle vector of Simulink block or 
%            string with a single Simulink block path or
%            cell with strings of Simulink block pathes
%
% Outputs:
%   cQuery - cell (mx6) with instrument channel information:
%           {:,1} bUse - boolean if port shall be used in Ecu-Spy Generator
%           {:,2} sName - string with name of instrumentation channel
%           {:,3} sBlock - string with blockpath of Simulink block
%           {:,4} sPortType - string with port type of instrumentation channel
%           {:,5} nPortNumber - integer with port number of instrumentation channel
%           {:,6} nVector - integer with vector length of signal
%
% Example: 
%   cQuery = getBlockPort(gcbs)

% check and transfer input
if ischar(hBlock)
    hBlock = {hBlock};
elseif ishandle(hBlock)
    if numel(hBlock) == 1
        hBlock = {getfullname(hBlock)};
    else
        hBlock = getfullname(hBlock);
    end
else
    error('slcEcuSpyAdd:hBlockEntryUnknown',...
        'The argument 1 "hBlock" is of unknown type');
end

% loop over all specified blocks
cQueryAll = cell(0,6);
for nIdxHandle = 1:numel(hBlock)
    % get basic block info
    xBlock = slcBlockInfo(hBlock{nIdxHandle});
    
    % prepare user cell
    cQuery = cell(sum(xBlock.Ports(1:2)),6);
    % collect inports of blocks
    for nIdxPort = 1:xBlock.Ports(1)
        cQuery{nIdxPort,1} = true;
        cQuery{nIdxPort,2} = sprintf('%s_Inport%03.0f',...
                                xBlock.Name,nIdxPort);
        cQuery{nIdxPort,3} = hBlock{nIdxHandle};
        cQuery{nIdxPort,4} = 'Inport';
        cQuery{nIdxPort,5} = nIdxPort;
        cQuery{nIdxPort,6} = 1;
    end
    % collect outports of blocks
    for nIdxPort = xBlock.Ports(1)+1:xBlock.Ports(1)+xBlock.Ports(2)
        cQuery{nIdxPort,1} = true;
        cQuery{nIdxPort,2} = sprintf('%s_Outport%03.0f',...
                                     xBlock.Name,nIdxPort-xBlock.Ports(1));
        cQuery{nIdxPort,3} = hBlock{nIdxHandle};
        cQuery{nIdxPort,4} = 'Outport';
        cQuery{nIdxPort,5} = nIdxPort-xBlock.Ports(1);
        cQuery{nIdxPort,6} = 1;
    end
    
    % apply priority data channel names to for instrumentation channel
    for nIdxPort = 1:size(cQuery,1)
        % get name of connected line handles
        sNameLine = get_param(...
            xBlock.LineHandles.(cQuery{nIdxPort,4})(cQuery{nIdxPort,5}),'Name');
        
        % get name of ports
        if strcmp(xBlock.BlockType,'SubSystem')
            cPort = find_system(cQuery{nIdxPort,3},...
                'SearchDepth',1,...
                'FollowLinks','on',...
                'LookUnderMasks','all',...
                'BlockType',cQuery{nIdxPort,4},...
                'Port',num2str(cQuery{nIdxPort,5}));
            sNamePort = get_param(cPort{1},'Name');
        else
            sNamePort = xBlock.Name;
        end
        
        % assign name
        if ~isempty(sNameLine)
            cQuery{nIdxPort,2} = sNameLine;
        elseif ~isempty(sNamePort)
            cQuery{nIdxPort,2} = sNamePort;
        end
    end
    cQueryAll = [cQueryAll; cQuery]; %#ok<AGROW>
end % for handles
cQuery = cQueryAll;
return

% =========================================================================

function cQuery = getLinePort(hLine)
% GETLINEPORT determine instrumentation information of all source ports of
% the specified signals.
% Name of instrumentation channel is either signal name of the specified
% signal, the port name in case of a subsystem or a generic name made up
% from block name, port type and port number.
%
% Syntax:
%   cQuery = getLinePort(hLine)
%
% Inputs:
%   hLine - handle vector (1xn) of Simulink signal lines
%
% Outputs:
%   cQuery - cell (mx6) with instrument channel information:
%           {:,1} bUse - boolean if port shall be used in Ecu-Spy Generator
%           {:,2} sName - string with name of instrumentation channel
%           {:,3} sBlock - string with blockpath of Simulink block
%           {:,4} sPortType - string with port type of instrumentation channel
%           {:,5} nPortNumber - integer with port number of instrumentation channel
%           {:,6} nVector - integer with vector length of signal
%
% Example: 
%   cQuery = getLinePort(gcl)

% compress line handles according source port handle
xLine = slcLineInfo(hLine);
[hTrash,nReduce] = unique([xLine.SrcPortHandle]); %#ok<ASGLU>
hLine = hLine(nReduce);

% initialize output
cQuery = cell(numel(hLine),6);

% loop over signal lines
for nIdxPort = 1:numel(hLine)
    % determine source line information
    xLine = slcLineInfo(hLine(nIdxPort));
    xBlock = slcBlockInfo(xLine.SrcBlockHandle);
    
    % generate entry
    cQuery{nIdxPort,1} = true;
    cQuery{nIdxPort,2} = sprintf('%s_Outport%3.0f',...
        xBlock.Name,nIdxPort-xBlock.Ports(1));
    cQuery{nIdxPort,3} = getfullname(xLine.SrcBlockHandle);
    cQuery{nIdxPort,4} = 'Outport';
    cQuery{nIdxPort,5} = get_param(xLine.SrcPortHandle,'PortNumber');
    cQuery{nIdxPort,6} = 1;
    
    % assign name
    sNamePort = get_param(get_param(xLine.SrcPortHandle,'Parent'),'Name');
    if ~isempty(xLine.Name)
        cQuery{nIdxPort,2} = xLine.Name;
    elseif ~isempty(sNamePort)
        cQuery{nIdxPort,2} = sNamePort;
    end
end
return

% =========================================================================

function prop = escGuiProperties
% ESCGUIPROPERTIES defines central standard properties for GUI elements.
%
% Syntax:
%   prop = escGuiProperties
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
