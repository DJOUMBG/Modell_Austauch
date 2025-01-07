function Marc2DIVeWizard(varargin)
% MARC2DIVEWIZARD creates a user GUI which guides through the process of
% ECU MiL dataset creation for MCM/ACM based on an original MARC ECU
% dataset and a matching MiL version of its software.
%
% Syntax:
%   Marc2DIVeWizard
%   Marc2DIVeWizard(hObject,eventdata,hDbc)
%   Marc2DIVeWizard(hObject,eventdata,xModule,sPathContent)
%
% Inputs:
%   varargin - cell (1x3) with following content
%    {1}   hObject    - handle of the timer object
%    {2}   eventdata  - data of event (MATLAB)
%    {3}   hDbc|xModule  - handle of DIVe Basic Configurator Matlab figure
%                          or
%                          struct (1xn) with Module 
%    {4}   sPathContent  - char (1xn) with path of DIVe Content to use for DataSet generation
%
% Example: 
%   Marc2DIVeWizard
%   
%   xTree = dsxRead('C:\dirsync\08Helix\11d_main\com\DIVe\Content\ctrl\mcm\sil\M12_51_00_03_EU_HDEP\Module\std\std.xml');
%   xModule = xTree.Module;
%   xTree = dsxRead('C:\dirsync\08Helix\11d_main\com\DIVe\Content\ctrl\acm\sil\S04_54_01_00\Module\std\std.xml');
%   xModule(2) = xTree.Module;
% 
%   Marc2DIVeWizard('','',xModule,'C:\dirsync\08Helix\11d_main\com\DIVe\Content','rafrey5_C019L0X77195951_d_main')
%
% Subfunctions: allHandle, allchilds, m2dCbBack, m2dCbFileSelect,
% m2dCbFolderSelect, m2dCbNext, m2dGuiProperties
%
% See also: Marc2DIVeFcn, MARCstruct2set 
%
% Author: Rainer Frey, TT/XCI-6, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2016-04-08

% singleton
if ~isempty(findobj('Tag','Marc2DIVeWizard'))
    % bring existing instance to front
    figure(findobj('Tag','Marc2DIVeWizard'));
    return
end

% try to gather state of DIVe basic configurator for ECU version
if nargin == 3 && ishandle(varargin{3})
    data.dbc = varargin{3};
    xData = guidata(data.dbc);
    % get current module setup ID
    nModule = get(xData.hbc.tab(xData.hbc.tabId.Detail).child.p(1).lb(1),'Value');
    cModule = get(xData.hbc.tab(xData.hbc.tabId.Detail).child.p(1).lb(1),'String');

    if ~isempty(cModule) && iscell(cModule) 
        if any(regexpi(cModule{nModule},'mcm')) || any(regexpi(cModule{nModule},'acm'))
        % use currently selected ECU as base
        xModule = xData.cfg.Configuration.ModuleSetup(nModule).Module;
        sBase = fullfile(xData.const.setup.sPathContent,'ctrl',xModule.species,...
            xModule.family,xModule.type,'Data');
        end
    end
end

% input check for DIVeONE external tool start
if nargin >= 4 && isstruct(varargin{3}) && exist(varargin{4},'dir')
    % store input
    data.const.xModule = varargin{3};
    data.const.sContent = varargin{4};
    data.const.sWorkspace = varargin{5};
    
    % quit if no MCM/ACM in Configuration
    if strcmp(data.const.xModule(1).species,'-')
        fprintf(2,'Marc2DIVeWizard(DIVeONE):noXcmInConfiguration - configuration does not contain a MCM or ACM.')
        desQuitClientCleanUp(data.const.sWorkspace);
    end
    
    % selector for MCM/ACM
    if numel(data.const.xModule) > 1
        nSelection = listdlg('ListString',{data.const.xModule.species},...
                             'Name','Starter',...
                             'ListSize',[180 70],...
                             'SelectionMode','single',...
                             'PromptString','Select ECU species',...
                             'InitialValue',1);
        if nSelection > 0
            xModule = data.const.xModule(nSelection);
        else
            fprintf(1,'Marc2DIVeWizard(DIVeONE):userPressedCancel - user cancel in ECU selection dialogue.')
            desQuitClientCleanUp(data.const.sWorkspace);
        end
    end
    % set base directory for DataSets
    sBase = fullfile(varargin{4},'ctrl',xModule.species,...
            xModule.family,xModule.type,'Data'); % folder of Data folder within Module Type
end

% backup for missing base path on standalone call
if ~exist('sBase','var')
    % no base found
    sBase = fullfile(fileparts(fileparts(fileparts(fileparts(mfilename('fullpath'))))),'Content','ctrl');
end

% get standard properties for GUI elements
data.const.prop = m2dGuiProperties;

% intialize Gui step state
data.state.step = 1;
data.state.stepSil = 1;
data.state.mode = 2; % 1: MiL, 2: SiL
data.sil.base = sBase;
switch data.state.mode
    case 1 % start with MiL
        sVis1 = 'on';
        sVis3 = 'off';
        bTogMil = 1;
        bTogSil = 0;
    case 2 % start with SiL
        sVis1 = 'off';
        sVis3 = 'on';
        bTogMil = 0;
        bTogSil = 1;
end

% main figure
data.hmd.main = figure ('Units','pixel',...
   'Position',[180 180 650 420],...
   'NumberTitle','off',...
   'DockControls','off',...
   'MenuBar','none',...
   'Name','MARC2DIVe Wizard for ECU datasets',...
   'Tag','Marc2DIVeWizard',...
   'Color',data.const.prop.color.default.BackgroundColor,...
   'Visible','on');  

% standard sizes
gap = 0.005;

%% headline and togglebuttons
% general information listing
data.hmd.t(1) = uicontrol(...
    'Parent',data.hmd.main,...
    data.const.prop.text,...
    'Position',[gap 1-0.06-gap 0.7 0.06],...
    'HorizontalAlignment','left',...
    'Fontsize',14,...
    'FontWeight','bold',...
    'String','MARC to DIVe Wizard for ECU datasets');

wtb = 0.05; % width of togglebutton
htb = 0.05; % height of togglebuttons
% togglebutton MIL/SIL
data.hmd.tgb(1) = uicontrol(...
    'Parent',data.hmd.main,...
    data.const.prop.togglebutton,...
    'Position',[1-1*gap-2*wtb 1-htb-gap wtb htb],...
    'Callback',{@GUIcbRadioButton,@m2dCbModeToggle,data.hmd.main,[],1},...
    'TooltipString','Switch to MiL dataset generation',...
    'FontWeight','bold',...
    'Value',bTogMil,...
    'String','MiL');

% togglebutton MIL/SIL
data.hmd.tgb(2) = uicontrol(...
    'Parent',data.hmd.main,...
    data.const.prop.togglebutton,...
    'Position',[1-1*gap-1*wtb 1-htb-gap wtb htb],...
    'Callback',{@GUIcbRadioButton,@m2dCbModeToggle,data.hmd.main,[],2},...
    'TooltipString','Switch to SiL dataset generation',...
    'FontWeight','bold',...
    'Value',bTogSil,...
    'String','SiL');
%     'Enable','off',...
set(data.hmd.tgb,'UserData',data.hmd.tgb);

%% Panel Step 1 (1 of 4 MiL)
data.hmd.p(1).main = uipanel(...
    'Parent',data.hmd.main,...
    data.const.prop.uipanel,...
    'Position',[gap 0.06 1-2*gap 1-0.12-gap],...
    'Title','Step 1 of 3',...
    'Visible',sVis1);

% general information
cString = {
    'Preparations in MARC'
    ''
    '1. Load a GC(GK) and AP(VP) in MARC with the dataset you want to use in Simulation.'
    ''
    '2. Ensure that GC(GK) and AP(VP) names fit to the following rules:'
    '      a. use only characters, numbers and underscores (no blanks etc.)'
    '      b. name must start with a character'
    '      c. name must not exceed 63 characters'
    '     If any of the above does not apply, please copy the GC(GK)/AP(VP) and rename it.'
    ''
    '3. Export the MARC AP(VP) dataset into a MATLAB .mat file:'
    '      a. select in the menu bar the menu "Calibrate"("Verstellen") and the menu item "AP Data Export/Import"'
    '      b. change to the tab "MatLab"'
    '      c. choose an export file location via the folder icon at "Export Filename"("Export Dateiname") '
    '         (lower part of the dialogue)'
    '      d. use the "export" button'
    ''
    ''
    ''
    ''
    'Specify the exported *.mat file here:'
    };
data.hmd.p(1).t(1) = uicontrol(...
    'Parent',data.hmd.p(1).main,...
    data.const.prop.text,...
    'Position',[gap 0.075 1-2*gap 1-0.075-gap],...
    'String',cString,...
    'Visible',sVis1);

% edit for mat file specification
data.hmd.p(1).e(1) = uicontrol(...
    'Parent',data.hmd.p(1).main,...
    data.const.prop.edit,...
    'Position',[gap gap 1-0.04-3*gap 0.065],...
    'ForegroundColor',[1 1 1]*0.4, ...
    'HorizontalAlignment','left', ...
    'String','',...
    'Visible',sVis1);

% button select folder
data.hmd.p(1).b(1) = uicontrol(...
    'Parent',data.hmd.p(1).main,...
    data.const.prop.pushbutton,...
    'Position',[1-0.04-1*gap gap 0.04 0.065],...
    'Callback',@m2dCbFileSelect,...
    'Fontweight','bold',...
    'TooltipString','Choose *.mat file from MARC export',...
    'String','...',...
    'Visible',sVis1);

%% Panel Step 2 (2 of 4 MiL)
sVis2 = 'off';
data.hmd.p(2).main = uipanel(...
    'Parent',data.hmd.main,...
    data.const.prop.uipanel,...
    'Position',[gap 0.06 1-2*gap 1-0.12-gap],...
    'Title','Step 2 of 3',...
    'Visible',sVis2);

% general information
cString = {
    'Select a simulation ECU base dataset of a matching software version (from dataClass "mainData")'
    ''
    'The selected base dataset must be of the same software version as the MARC AP(VP) dataset.'
    'Please ensure that the base dataset matches the new one in the following criterias:'
    '1. Same engine platform (e. g. HDEP, MDEG)'
    '2. Same base market for software (e. g. Euro, Nafta)'
    '3. Same sensor package (e. g. same engine OM936DTCEU6)'
    ''
    'Base dataset selection (file system: ...Content.ctrl.<ecu>.mil.<version>.Data.mainData.<dataset>):'
    };
data.hmd.p(2).t(1) = uicontrol(...
    'Parent',data.hmd.p(2).main,...
    data.const.prop.text,...
    'Position',[gap 1-0.39-gap 1-2*gap 0.39],...
    'String',cString,...
    'Visible',sVis2);

% edit for folder path of dataset variant
data.hmd.p(2).e(1) = uicontrol(...
    'Parent',data.hmd.p(2).main,...
    data.const.prop.edit,...
    'Position',[gap 1-0.39-0.065-2*gap 1-0.04-3*gap 0.065],...
    'ForegroundColor',[1 1 1]*0.4, ...
    'HorizontalAlignment','left', ...
    'String','',...
    'Visible',sVis2);

% button select folder
data.hmd.p(2).b(1) = uicontrol(...
    'Parent',data.hmd.p(2).main,...
    data.const.prop.pushbutton,...
    'Position',[1-0.04-1*gap 1-0.39-0.065-2*gap 0.04 0.065],...
    'Callback',@m2dCbFolderSelect,...
    'Fontweight','bold',...
    'TooltipString','Choose dataset folder of simulation ECU dataClass "mainData"',...
    'String','...',...
    'Visible',sVis2);

% general information
cString = {
    'Info'
    'The base dataset is used as a blueprint for the new dataset in DIVe. '
    'Following parts of the base dataset will be used for the new dataset:'
    '1. Compiler Switch settings (see table on right)'
    '2. EEP parameter values'
    '3. PAR setting for existing sensors in the setup'
    '4. Any parameter, which is not included in your dataset.'
    };
data.hmd.p(2).t(2) = uicontrol(...
    'Parent',data.hmd.p(2).main,...
    data.const.prop.text,...
    'Position',[gap gap 0.59 0.50],...
    'String',cString,...
    'Visible',sVis2);

% table of compiler switches
cTableColWidth = {200,20};
cTableColHeader = {'Compiler Switch','Bit'}; % text box contents
cTableColHeader = cellfun(@(x)['<html><b>' x '</b></html>'],cTableColHeader,'UniformOutput',false);
cTableColEditable = [false,false];
cTableColFormat = {'char','numeric'};
% trialData = {'SW_COMP_SWITCH_EURO',1;'SW_COMP_SWITCH_NAFTA',0;'SW_COMP_SWITCH_HDEP',1;'SW_COMP_SWITCH_MDEG',0};

data.hmd.p(2).tb(1) = uitable('Parent',data.hmd.p(2).main,...
    'Units','normalized',...
    'Position',[0.62 gap 0.375 0.50],...
    'Data',{},...
    'ColumnFormat',cTableColFormat,...
    'ColumnWidth',cTableColWidth,...
    'ColumnEditable',cTableColEditable,...
    'ColumnName',cTableColHeader,...
    'RowName',{},...
    'Visible',sVis2);
%     'CellEditCallback',@dbcCbMainPortsSelect,...

%% Panel Step 3 (3 of 4 MiL)
sVis2 = 'off';
data.hmd.p(3).main = uipanel(...
    'Parent',data.hmd.main,...
    data.const.prop.uipanel,...
    'Position',[gap 0.06 1-2*gap 1-0.12-gap],...
    'Title','Step 3 of 3',...
    'Visible',sVis2);

% general information
cString = {
    'Enter dataset name'
    ''
    'Please enter the name of the new dataset with following rules'
    '      a. use only characters, numbers and underscores (no blanks etc.)'
    '      b. name must start with a character'
    '      c. name must not exceed 63 characters'
    ''
    'The dataset name should refer to the MARC AP(VP) name and refer the engine/EATS type:'
    };
data.hmd.p(3).t(1) = uicontrol(...
    'Parent',data.hmd.p(3).main,...
    data.const.prop.text,...
    'Position',[gap 1-0.35-gap 1-2*gap 0.35],...
    'String',cString,...
    'Visible',sVis2);

% edit for folder path of dataset variant
data.hmd.p(3).e(1) = uicontrol(...
    'Parent',data.hmd.p(3).main,...
    data.const.prop.edit,...
    'Position',[gap 1-0.35-0.065-2*gap 1-0.04-3*gap 0.065],...
    'HorizontalAlignment','left', ...
    'String','',...
    'Visible',sVis2);

% % general information
cString = {
    'Your selections so far:'
    };
data.hmd.p(3).t(3) = uicontrol(...
    'Parent',data.hmd.p(3).main,...
    data.const.prop.text,...
    'Position',[gap 0.41 1-2*gap 0.04],...
    'String',cString,...
    'Visible',sVis2);

% table of compiler switches
cTableColWidth = {150,475};
cTableColEditable = [false,false];
cTableColFormat = {'char','char'};
cData = {'MARC GC(GK) Name','';'MARC AP(VP) Name','';'Base dataset',''};

data.hmd.p(3).tb(1) = uitable('Parent',data.hmd.p(3).main,...
    'Units','normalized',...
    'Position',[gap 0.41-gap-0.17 1-2*gap 0.17],...
    'Data',cData,...
    'ColumnFormat',cTableColFormat,...
    'ColumnWidth',cTableColWidth,...
    'ColumnEditable',cTableColEditable,...
    'ColumnName',{},...
    'RowName',{},...
    'Visible',sVis2);

%% Panel Step 4 (4 of 4 MiL)
sVis2 = 'off';
data.hmd.p(4).main = uipanel(...
    'Parent',data.hmd.main,...
    data.const.prop.uipanel,...
    'Position',[gap 0.06 1-2*gap 1-0.12-gap],...
    'Title','Report',...
    'Visible',sVis2);

% GUI placement parameters
th = 0.34; % text box height
tbh = 0.30; % table box height
bh = 0.065; % button height

% general information
cString = {
    'The dataset is generated.'
    ''
    'Please do now:'
    '      1. check the report for important MARC parameters, which are not transferred into the simulation dataset.'
    '      2. check the mcm_data_set_add.m in the new dataset folder for crucial parameter entries'
    '      3. in case of any doubts, please contact your responsible power user'
    ''
    'Summary:'
    };
data.hmd.p(4).t(1) = uicontrol(...
    'Parent',data.hmd.p(4).main,...
    data.const.prop.text,...
    'Position',[gap 1-th-gap 1-2*gap th],...
    'String',cString,...
    'Visible',sVis2);

% table of compiler switches
cTableColWidth = {50,580};
cTableColEditable = [false,false];
cTableColFormat = {'char','numeric'};
cData = {[],'Updated parameters in sMP structure (active parameters in dataset)';...
         [],'Failed parameter updates in sMP structure due to different parameter sizes';...
         [],'Updated parameters in Workspace (E2P/Par/Stateflow)';...
         [],'Parameters in Workspace which can not be updated by MARC dataset';...
         [],'Parameters of base dataset sMP structure not in MARC dataset (E2P/Par)';...
         [],'Parameters of MARC not in base dataset sMP structure (FMM, low level etc. can be some more)'};

data.hmd.p(4).tb(1) = uitable('Parent',data.hmd.p(4).main,...
    'Units','normalized',...
    'Position',[gap 1-th-tbh-3*gap 1-2*gap tbh],...
    'Data',cData,...
    'ColumnFormat',cTableColFormat,...
    'ColumnWidth',cTableColWidth,...
    'ColumnEditable',cTableColEditable,...
    'ColumnName',{},...
    'RowName',{},...
    'Visible',sVis2);

% button select folder
data.hmd.p(4).b(1) = uicontrol(...
    'Parent',data.hmd.p(4).main,...
    data.const.prop.pushbutton,...
    'Position',[gap 1-th-tbh-1*bh-5*gap 0.3 bh],...
    'Callback',@m2dCbReportOpen,...
    'Fontweight','bold',...
    'TooltipString','Open dataset update report in Excel',...
    'String','Open Excel Report',...
    'Visible',sVis2);

% button select folder
data.hmd.p(4).b(2) = uicontrol(...
    'Parent',data.hmd.p(4).main,...
    data.const.prop.pushbutton,...
    'Position',[gap 01-th-tbh-2*bh-6*gap 0.3 bh],...
    'Callback',@m2dCbDatasetAddOpen,...
    'Fontweight','bold',...
    'TooltipString','Open xcm_data_set_add.m in MATLAB editor',...
    'String','Open xcm_data_set_add.m',...
    'Visible',sVis2);

%% Panel Step 5 (1 of 3 SiL)
% sVis3 = 'off';
data.hmd.p(5).main = uipanel(...
    'Parent',data.hmd.main,...
    data.const.prop.uipanel,...
    'Position',[gap 0.06 1-2*gap 1-0.12-gap],...
    'Title','Step 1 of 2',...
    'Visible',sVis3);
% general information
cString = {
    'Preparations in MARC'
    ''
    '1. Load a GC(GK) and AP(VP) in MARC with the dataset you want to use in Simulation.'
    ''
    '2. Export the MARC AP(VP) dataset into a .dcm file:'
    '      a. select in the menu bar the menu "Calibrate"("Verstellen") and the menu item "AP Data Export/Import"'
    '      b. change to the tab "DCM"'
    '      c. choose an export file location via the folder icon at "Export Filename"("Export Dateiname") '
    '         (lower part of the dialogue)'
    '      d. use the "Export" button'
    ''
    '3. Specify the GC(GK) type here:'
    };
data.hmd.p(5).t(1) = uicontrol(...
    'Parent',data.hmd.p(5).main,...
    data.const.prop.text,...
    'Position',[gap 0.075 1-2*gap 1-0.075-gap],...
    'String',cString,...
    'Visible',sVis3);

% radiobutton standard GK
rbt = 0.38; % intermediate position start of radiobuttons
rbh = 0.045; % height of radio buttons
data.hmd.p(5).rb(1) = uicontrol(...
    'Parent',data.hmd.p(5).main,...
    data.const.prop.radiobutton,...
    'Position',[gap+0.02 rbt+gap+rbh 0.4 rbh],...
    'Callback',@GUIcbRadioButton,...
    'TooltipString','Exported .dcm-file is from standard GC(GK)',...
    'Value',1,...
    'String','Standard GC (GK) export',...
    'Visible',sVis3);

% radiobutton E2P GK
data.hmd.p(5).rb(2) = uicontrol(...
    'Parent',data.hmd.p(5).main,...
    data.const.prop.radiobutton,...
    'Position',[gap+0.02 rbt 0.4 rbh],...
    'Callback',@GUIcbRadioButton,...
    'TooltipString','Exported .dcm-file is from E2P GC(GK)',...
    'Value',0,...
    'String','E2P (EEPROM) GC (GK) export',...
    'Visible',sVis3);
set(data.hmd.p(5).rb,'UserData',data.hmd.p(5).rb);

% text for file choosing
data.hmd.p(5).t(2) = uicontrol(...
    'Parent',data.hmd.p(5).main,...
    data.const.prop.text,...
    'Position',[gap 2*gap+0.065 1-0.04-4*gap 0.045],...
    'String','Specify the exported *.dcm file here:');

% edit for mat file specification
data.hmd.p(5).e(1) = uicontrol(...
    'Parent',data.hmd.p(5).main,...
    data.const.prop.edit,...
    'Position',[gap gap 1-0.04-3*gap 0.065],...
    'ForegroundColor',[1 1 1]*0.4, ...
    'HorizontalAlignment','left', ...
    'TooltipString','Choose *.dcm file from MARC export by button on right',...
    'String','',...
    'Visible',sVis3);

% button select folder
data.hmd.p(5).b(1) = uicontrol(...
    'Parent',data.hmd.p(5).main,...
    data.const.prop.pushbutton,...
    'Position',[1-0.04-1*gap gap 0.04 0.065],...
    'Callback',@m2dCbFileSelectDcm,...
    'Fontweight','bold',...
    'TooltipString','Choose *.dcm file from MARC export',...
    'String','...',...
    'Visible',sVis3);

%% Panel Step 6 (2 of 3 SiL)
sVis2 = 'off';
data.hmd.p(6).main = uipanel(...
    'Parent',data.hmd.main,...
    data.const.prop.uipanel,...
    'Position',[gap 0.06 1-2*gap 1-0.12-gap],...
    'Title','Step 2 of 3',...
    'Visible',sVis2);

% general information1

data.hmd.p(6).t(1) = uicontrol(...
    'Parent',data.hmd.p(6).main,...
    data.const.prop.text,...
    'Position',[gap 1-0.045-gap 1-2*gap 0.045],...
    'FontWeight','bold',...
    'String','Specify ECU type/version for software creation',...
    'Visible',sVis2);

cString = {...
    'Please specify a folder of the ECU type/version, ' ...
    'where you want to create the dataset:' ...
    '(e.g. ..\Content\ctrl\mcm\sil\M12_51_00_03_EU_MDEG or below)' ...
    };
data.hmd.p(6).t(2) = uicontrol(...
    'Parent',data.hmd.p(6).main,...
    data.const.prop.text,...
    'Position',[gap 1-0.18-gap 1-2*gap 0.18-0.045],...
    'String',cString,...
    'Visible',sVis2);

% edit folder path of ECU type/version
data.hmd.p(6).e(1) = uicontrol(...
    'Parent',data.hmd.p(6).main,...
    data.const.prop.edit,...
    'Position',[gap 1-0.18-0.065-2*gap 1-0.04-3*gap 0.065],...
    'HorizontalAlignment','left', ...
    'String','',...
    'Visible',sVis2);
set(data.hmd.p(6).e(1));

% button folder path of ECU type/version
data.hmd.p(6).b(1) = uicontrol(...
    'Parent',data.hmd.p(6).main,...
    data.const.prop.pushbutton,...
    'Position',[1-0.04-1*gap 1-0.18-0.065-2*gap 0.04 0.065],...
    'Callback',@m2dCbFolderSelectSil,...
    'Fontweight','bold',...
    'TooltipString','Choose folder of SiL ECU version',...
    'String','...',...
    'Visible',sVis2);

% general information2
data.hmd.p(6).t(3) = uicontrol(...
    'Parent',data.hmd.p(6).main,...
    data.const.prop.text,...
    'Position',[gap 1-0.35-0.045-4*gap 1-2*gap 0.045],...
    'FontWeight','bold',...
    'String','Enter dataset name',...
    'Visible',sVis2);

cString = {'Please enter the name of the new dataset with following rules'
    '      a. use only characters, numbers and underscores (no blanks etc.)'
    '      b. name must start with a character'
    '      c. name must not exceed 63 characters'
    '      d. begin of dataset name should match real dataset coding'
    ''
    'The dataset name should refer to the MARC AP(VP) name and refer the engine/EATS type:'
    '   (e.g. X_M121103_1HL049TR53_PS_OM471FE1_390kW or '
    '    A_S0351050_16FH_HF6H_CI161_OM471FE1_GATS20TE2)'
    };
data.hmd.p(6).t(4) = uicontrol(...
    'Parent',data.hmd.p(6).main,...
    data.const.prop.text,...
    'Position',[gap 1-0.78-4*gap 1-2*gap 0.38],...
    'String',cString,...
    'Visible',sVis2);

% edit for folder path of dataset variant
% data.hmd.p(6).e(2) = uicontrol(...
%     'Parent',data.hmd.p(6).main,...
%     data.const.prop.edit,...
%     'Position',[gap 1-0.78-0.065-4*gap 1-0.04-3*gap 0.065],...
%     'HorizontalAlignment','left', ...
%     'String','',...
%     'Callback',@m2dCbNameCheck,...
%     'Visible',sVis2);
cTableColWidth = {450};
bTableColEditable = true;
cTableColFormat = {'char'};
data.hmd.p(6).tb(1) = uitable(...
    'Parent',data.hmd.p(6).main,...
    'Units','normalized',...
    'Position',[gap gap 0.75 0.2-2*gap],...
    'Data',{},...
    'ColumnFormat',cTableColFormat,...
    'ColumnWidth',cTableColWidth,...
    'ColumnEditable',bTableColEditable,...
    'ColumnName',{},...
    'RowName',{},...
    'CellSelectionCallback',@m2dCbNameCheck,...
    'Tooltipstring','Selected channels for channel list assignment',...
    'Visible',sVis2);

%% Panel Step 7 (3 of 3 SiL)
sVis2 = 'off';
data.hmd.p(7).main = uipanel(...
    'Parent',data.hmd.main,...
    data.const.prop.uipanel,...
    'Position',[gap 0.06 1-2*gap 1-0.12-gap],...
    'Title','Report',...
    'Visible',sVis2);

% GUI placement parameters
th = 0.34; % text box height

% general information
cString = {
    'The dataset was generated successful.'
    ''
    };
data.hmd.p(7).t(1) = uicontrol(...
    'Parent',data.hmd.p(7).main,...
    data.const.prop.text,...
    'Position',[gap 1-th-gap 1-2*gap th],...
    'String',cString,...
    'Visible',sVis2);

%% button group back next cancel
% button back
data.hmd.b(1) = uicontrol(...
    'Parent',data.hmd.main,...
    data.const.prop.pushbutton,...
    'Position',[0.6 gap 0.1 0.05],...
    'Callback',@m2dCbBack,...
    'TooltipString','Go back to previous step',...
    'Enable','off',...
    'String','<< Back');

% button next
data.hmd.b(2) = uicontrol(...
    'Parent',data.hmd.main,...
    data.const.prop.pushbutton,...
    'Position',[0.7+gap gap 0.1 0.05],...
    'Callback',@m2dCbNext,...
    'TooltipString','Proceed to next step',...
    'Enable','off',...
    'String','Next >>');

% button cancel
data.hmd.b(3) = uicontrol(...
    'Parent',data.hmd.main,...
    data.const.prop.pushbutton,...
    'Position',[1-0.1-gap gap 0.1 0.05],...
    'Callback','close(findobj(''Tag'',''Marc2DIVeWizard''));',...
    'TooltipString','Abort current Wizard session without dataset creation',...
    'String','Cancel');
%% end of GUI

% save data with figure
guidata(data.hmd.main,data);
return

% =========================================================================

function m2dCbNext(varargin)
% M2DCBNEXT callback of next button
%
% Syntax:
%   m2dCbNext(varargin)
%
% Inputs:
%   varargin - cell (1x3) with following content
%    {1}   hObject   - handle of the event triggering uicontrol (MATLAB)
%    {2}   eventdata - data of event (MATLAB)

% get data from GUI
data = guidata(gof(varargin{1}));

if data.state.mode == 1 % MiL mode
    % action according step
    switch data.state.step
        case 1
            % standard GUI behavior
            set(allHandle(data.hmd.p(1).main),'Visible','off');
            set(allHandle(data.hmd.p(2).main),'Visible','on');
            set(data.hmd.b(1),'Enable','on');
            set(data.hmd.b(2),'Enable','off');
            data.state.step = 2;
            
        case 2
            % standard GUI behavior
            set(allHandle(data.hmd.p(2).main),'Visible','off');
            set(allHandle(data.hmd.p(3).main),'Visible','on');
            set(data.hmd.b(2),'String','Create',...
                'TooltipString','Create dataset');
            data.state.step = 3;
            
        case 3
            % check name
            sName = get(data.hmd.p(3).e(1),'String');
            if ~isvarname(sName)
                errordlg(['The specified dataset name "' sName ...
                    '"is no valid MATLAB variable name'],'Invalid dataset name','modal')
                return
            end
            
            % dataset variant creation
            sPathSource = get(data.hmd.p(2).e(1),'String');
            sPath = fullfile(fileparts(sPathSource),sName);
            xSum = Marc2DIVeFcn(data.cal,data.base,sPath,sPathSource);
            
            % update the report elements
            cSummary = {numel(xSum.var.Transfer),...
                'Updated parameters in sMP structure (active parameters in dataset)';...
                numel(xSum.var.TransferFail),...
                'Failed parameter updates in sMP structure due to different parameter sizes';...
                numel(xSum.var.WsUpdate),...
                'Updated parameters in Workspace (E2P/Par/Stateflow)';...
                numel(xSum.var.WsNoUpdate),...
                'Parameters in Workspace which can not be updated by MARC dataset';...
                numel(xSum.var.BaseNotInMarc),...
                'Parameters of base dataset sMP structure not in MARC dataset (E2P/Par)';...
                numel(xSum.var.MarcNotInBase),...
                'Parameters of MARC not in base dataset sMP structure (FMM, low level etc. can be some more)'};
            set(data.hmd.p(4).tb(1),'Data',cSummary);
            set(data.hmd.p(4).b(1),'Callback',['winopen(''' fullfile(sPath,'GenerationReport.xlsx') ''');']);
            set(data.hmd.p(4).b(2),'Callback',['open(''' fullfile(sPath,'mcm_data_set_add.m') ''');']);
            
            % invoke database update
            if isfield(data,'dbc') % only if wizard was started from DBC
                % get menu of database update
                xData = guidata(data.dbc);
                cMenu1 = {xData.uim.name};
                bTools = strcmp('Tools',cMenu1);
                hMenu = get(xData.uim(bTools).main,'Children');
                % get function handle of update function
                if verLessThanMATLAB('9.3') % below 9.3 (tested with 9.0, R2016a)
                    hUpdateMenu = findobj(hMenu,'Label','Update Database');
                    hUpdateDB = get(hUpdateMenu,'Callback');
                else % above 9.3, R2017b)
                    hUpdateMenu = findobj(hMenu,'Text','Update Database');
                    hUpdateDB = get(hUpdateMenu,'MenuSelectedFcn');
                end
                % invoke update
                feval(hUpdateDB,data.dbc);
            end
            
            % standard GUI behavior
            set(allHandle(data.hmd.p(3).main),'Visible','off');
            set(allHandle(data.hmd.p(4).main),'Visible','on');
            set(data.hmd.b(1),'Enable','off');
            set(data.hmd.b(2),'String','Close',...
                'TooltipString','Close Wizard',...
                'Callback','close(gof)');
            set(data.hmd.b(3),'Enable','off');
            data.state.step = 4;
    end
    
elseif data.state.mode == 2 % SiL actions
    
    % action according step
    switch data.state.stepSil
        case 1
            % standard GUI behavior
            set(allHandle(data.hmd.p(5).main),'Visible','off');
            set(allHandle(data.hmd.p(6).main),'Visible','on');
            set(data.hmd.b(1),'Enable','on');
            set(data.hmd.b(2),'Enable','off'); % next button 
            data.state.stepSil = 2;
            
            % prefill ECU dataset folder
            nDataType = get(data.hmd.p(5).rb(1),'Value')+2*get(data.hmd.p(5).rb(2),'Value');
            cDataFolder = {'mainData','e2pData'};
            sDefault = fullfile(data.sil.base,cDataFolder{nDataType});
            if exist(sDefault,'dir')
                set(data.hmd.p(6).e(1),'String',sDefault);
                data.sil.sPathData = sDefault;
                set(data.hmd.b(2),'Enable','on'); % next button keep enabled
            else
                % try to get better base folder from dcm file location
                cDcm = strsplit(get(data.hmd.p(5).e(1),'String'),';');
                cPathDcm = strsplit(cDcm{1},filesep);
                if strcmp(cPathDcm{end-3},'Data') && strcmp(cPathDcm{end-7},'ctrl')
                    sDefault = strGlue(cPathDcm(1:end-2),filesep);
                    set(data.hmd.p(6).e(1),'String',sDefault);
                    data.sil.sPathData = sDefault;
                    set(data.hmd.b(2),'Enable','on'); % next button keep enabled
                end
            end

            % preset dcm file name as dataset name 
            sFileDcmAll = get(data.hmd.p(5).e(1),'String');
            cFileDcm = strsplitOwn(sFileDcmAll,';');
            cVariant = cell(size(cFileDcm));
            for nIdxVar = 1:numel(cFileDcm)
                [sTrash,sVariant] = fileparts(cFileDcm{nIdxVar}); %#ok<ASGLU>
                cVariant{nIdxVar} = genvarname(sVariant);
            end
            set(data.hmd.p(6).tb(1),'Data',cVariant);
            
        case 2
            % create dataset
            cName = get(data.hmd.p(6).tb(1),'Data'); 
            % check dataset variant names
            for nIdxVar = 1:numel(cName)
                sPathVariant = fullfile(data.sil.sPathData,cName{nIdxVar});
                if ~isvarname(cName{nIdxVar})
                    errordlg(['The specified dataset name "' cName{nIdxVar} ...
                        '"is no valid MATLAB variable name'],'Invalid dataset name','modal')
                    return
                end
                if exist(sPathVariant,'dir')
                    errordlg(['The specified dataset name "' cName{nIdxVar} ...
                        '"is already used for another dataset variant.'],...
                        'Invalid dataset name','modal')
                    return
                end
            end
            
            % dataset variant creation
            cFileDcm = strsplitOwn(get(data.hmd.p(5).e(1),'String'),';');
            for nIdxVar = 1:numel(cName)
                hWaitbar = waitbar(0,'Creating folder...',...
                    'Name','Convert dcm-file to DIVe xCM sil dataset');
                sPathVariant = fullfile(data.sil.sPathData,cName{nIdxVar});
                mkdir(sPathVariant); % create folder
                [sTrash,sVariant,sExt] = fileparts(cFileDcm{nIdxVar}); %#ok<ASGLU>
                waitbar(0.1,hWaitbar,'Copy dcm-file...');
                copyfile(cFileDcm{nIdxVar},fullfile(sPathVariant,[sVariant,sExt]));
                waitbar(0.2,hWaitbar,'Applying corrections on dcm-file...');
                spsSilDcmCorrection(fullfile(sPathVariant,[sVariant,sExt]));
                %             % create AddData.m
                %             if get(data.hmd.p(5).rb(1),'Value')
                %                 waitbar(0.7,hWaitbar,'Create addional m-file...');
                %                 nFid = fopen(fullfile(sPathVariant,'AddData.m'),'w');
                %                 for nIdxZyl = 1:6;
                %                     fprintf(nFid,'fis_mb_fac_C0%i = 1;\n',nIdxZyl);
                %                 end
                %                 fclose(nFid);
                %             end
                
                % create XML file
                waitbar(0.8,hWaitbar,'Create DIVe XML...');
                if exist('dstXmlDataset','file')
                    dstXmlDataSet(sPathVariant,...
                        {'isStandard','^AddData\.m$';'executeAtInit','';'copyToRunDirectory',''});
                else
                    error('dstXmlDataset.m not available');
                end
                
                % upload to Perforce if started from DIVeONE
                if isfield(data.const,'sWorkspace')
                    
                    % create changelist
                    sDescription = sprintf('MARC2DIVeWizard create variant "%s"',cName{nIdxVar});
                    [sMsg,nStatus] = p4('-c %s --field Description="%s" change -o | p4 change -i',data.const.sWorkspace,sDescription);
                    nChange = sscanf(sMsg,'Change %i');
                    if isempty(nChange) || nStatus
                        fprintf(2,'EcuSpy:m2dCbNext - Changelist creation failed with message:\n%s\n',sMsg);
                        fprintf(2,'<a href="matlab:winopen(''%s'')">Please submit this DataSet manually via P4V</a>\n',sPathVariant);
                        delete(hWait);
                        errordlg('DataSet submit failed in changelist creation - please submit manually via P4V.');
                        return
                    end
                    
                    % add files to changelist
                    [sMsg,nStatus] = p4('-c %s add -c %i %s...',data.const.sWorkspace,nChange,sPathVariant);
                    if nStatus
                        fprintf(2,'EcuSpy:m2dCbNext - adding files to changelist %i failed with message:\n%s\n',nChange,sMsg);
                        fprintf(2,'<a href="matlab:winopen(''%s'')">Please submit this DataSet manually via P4V</a>\n',sPathVariant);
                        delete(hWait);
                        errordlg('DataSet submit failed in adding files - please submit manually via P4V.');
                        return
                    end
                    
                    % submit files
                    [sMsg,nStatus] = p4('-c %s submit -c %i',data.const.sWorkspace,nChange);
                    if nStatus
                        fprintf(2,'EcuSpy:m2dCbNext - DataSet variant submit failed (changelist %i) with message:\n%s\n',nChange,sMsg);
                        fprintf(2,'<a href="matlab:winopen(''%s'')">Please submit this DataSet manually via P4V</a>\n',sPathVariant);
                        delete(hWait);
                        errordlg('DataSet submit failed - please submit manually via P4V.');
                        return
                    end
                end
                
                waitbar(1,hWaitbar);
                close(hWaitbar);
            end
            
            % invoke database update
            if isfield(data,'dbc') % only if wizard was started from DBC
                % get menu of database update
                xData = guidata(data.dbc);
                cMenu1 = {xData.uim.name};
                bTools = strcmp('Tools',cMenu1);
                hMenu = get(xData.uim(bTools).main,'Children');
                % get function handle of update function
                if verLessThanMATLAB('9.3') % below 9.3 (tested with 9.0, R2016a)
                    hUpdateMenu = findobj(hMenu,'Label','Update Database');
                    hUpdateDB = get(hUpdateMenu,'Callback');
                else % above 9.3, R2017b)
                    hUpdateMenu = findobj(hMenu,'Text','Update Database');
                    hUpdateDB = get(hUpdateMenu,'MenuSelectedFcn');
                end
                % invoke update
                feval(hUpdateDB,data.dbc);
            end
            
            % standard GUI behavior
            set(allHandle(data.hmd.p(6).main),'Visible','off');
            set(allHandle(data.hmd.p(7).main),'Visible','on');
            set(data.hmd.b(1),'Enable','off');
            if isfield(data.const,'sWorkspace')
                set(data.hmd.b(2),'String','Close',...
                    'TooltipString','Close Wizard',...
                    'Callback',@m2dCbRestart);
            else
                set(data.hmd.b(2),'String','Close',...
                    'TooltipString','Close Wizard',...
                    'Callback','close(gof)');
            end
            set(data.hmd.b(3),'Enable','off');
            data.state.stepSil = 3;
    end    
end

% save data with GUI
guidata(data.hmd.main,data);
return

% =========================================================================

function m2dCbBack(varargin)
% M2DCBBACK callback of back button
%
% Syntax:
%   m2dCbBack(varargin)
%
% Inputs:
%   varargin - cell (1x3) with following content
%    {1}   hObject   - handle of the event triggering uicontrol (MATLAB)
%    {2}   eventdata - data of event (MATLAB)
%    {3}   nStep - direct entry

% get data from GUI
data = guidata(gof(varargin{1}));

if data.state.mode == 1
    % tweak current step due to switch of state mode
    if nargin > 2
        data.state.step = varargin{3};
    end
    % action according current step
    switch data.state.step
        case 2
            set(allHandle(data.hmd.p(2).main),'Visible','off');
            set(allHandle(data.hmd.p(1).main),'Visible','on');
            set(data.hmd.b(1),'Enable','off');
            data.state.step = 1;
        case 3
            set(allHandle(data.hmd.p(3).main),'Visible','off');
            set(allHandle(data.hmd.p(2).main),'Visible','on');
            set(data.hmd.b(2),'Enable','on');
            set(data.hmd.b(2),'String','Next >>',...
                'TooltipString','Proceed to next step');
            data.state.step = 2;
        case 4
            set(allHandle(data.hmd.p(4).main),'Visible','off');
            set(allHandle(data.hmd.p(3).main),'Visible','on');
            set(data.hmd.b(2),'Enable','on');
            set(data.hmd.b(2),'String','Create',...
                'TooltipString','Create dataset');
            data.state.step = 3;
    end
    
elseif data.state.mode == 2
    % tweak current step due to switch of state mode
    if nargin > 2
        data.state.stepSil = varargin{3};
    end
    % action according current step
    switch data.state.stepSil
        case 2
            set(allHandle(data.hmd.p(6).main),'Visible','off');
            set(allHandle(data.hmd.p(5).main),'Visible','on');
            % check for dcm file
            sEdit = get(data.hmd.p(5).e(1),'String');
            if ~isempty(sEdit) && exist(sEdit,'file')
                set(data.hmd.b(2),'Enable','on');
            else
                set(data.hmd.b(2),'Enable','off');
            end
            set(data.hmd.b(1),'Enable','off');
            data.state.stepSil = 1;
            
        case 3
            set(allHandle(data.hmd.p(7).main),'Visible','off');
            set(allHandle(data.hmd.p(6).main),'Visible','on');
            set(data.hmd.b(1),'Enable','on');
            set(data.hmd.b(2),'Enable','on');
            set(data.hmd.b(2),'String','Create',...
                'TooltipString','Create dataset');
            data.state.stepSil = 2;
            
        case 4 % dummy for toggle
            set(allHandle(data.hmd.p(7).main),'Visible','on');
            set(data.hmd.b(1),'Enable','off');
            set(data.hmd.b(2),'String','Close',...
                'TooltipString','Close Wizard',...
                'Callback','close(gof)');
            set(data.hmd.b(3),'Enable','off');
            data.state.stepSil = 3;

    end
end

% save data with GUI
guidata(data.hmd.main,data);
return

% =========================================================================

function m2dCbModeToggle(varargin)
% M2DCBMODETOGGLE toggle between SiL and MiL Mode.
%
% Syntax:
%   m2dCbModeToggle(varargin)
%
% Inputs:
%   varargin - cell (1x3) with following content
%    {1}   hObject   - handle of the event triggering uicontrol (MATLAB)
%    {2}   eventdata - data of event (MATLAB)
%    {3}   integer (1x1) for mode: 1: MiL, 2: SiL

% get data from GUI
data = guidata(gof(varargin{1}));
nModeNew = varargin{3};

%change mode
data.state.mode = nModeNew;

% save data with GUI
guidata(data.hmd.main,data);

% call update
switch data.state.mode
    case 1
        set(allHandle(data.hmd.p(data.state.stepSil+4).main),'Visible','off');
        set(allHandle(data.hmd.p(data.state.step).main),'Visible','on');
        m2dCbBack(data.hmd.main,[],data.state.step+1);
    case 2
        set(allHandle(data.hmd.p(data.state.step).main),'Visible','off');
        set(allHandle(data.hmd.p(data.state.stepSil+4).main),'Visible','on');
        m2dCbBack(data.hmd.main,[],data.state.stepSil+1);
end    
return

% =========================================================================

function m2dCbFileSelect(varargin)
% M2DCBFILESELECT select a *.mat file and check it for existence of a MARC
% export structure
%
% Syntax:
%   m2dCbFileSelect(varargin)
%
% Inputs:
%   varargin - cell (1x3) with following content
%    {1}   hObject   - handle of the event triggering uicontrol (MATLAB)
%    {2}   eventdata - data of event (MATLAB)

% get data from GUI
data = guidata(gof(varargin{1}));

% get current setting path
sEdit = get(data.hmd.p(1).e(1),'String');
if isempty(sEdit) || ~exist(sEdit,'file')
    sPathMfile = mfilename('fullpath');
    sEdit = fileparts(fileparts(fileparts(fileparts(sPathMfile))));
end

% get file selection
[sFile,sPath] = uigetfile( ...
    {'*.mat','MAT-files (*.mat)'; ...
    '*.*',  'All Files (*.*)'}, ...
    'MARC AP/VP export mat-file',...
    sEdit,...
    'MultiSelect','off');
if isnumeric(sFile)
    return
end
sFilePath = fullfile(sPath,sFile);

if exist(sFilePath,'file')
    % load file message box
    hMsg = waitbar(0,'The MARC dataset is loading - please stand by.',...
        'Name','Loading file...'); 
    pause(0.01);
    drawnow;
    try
        % load file
        xLoad = load(sFilePath);
        % save compressed file
        cField = fieldnames(xLoad);
        save(sFilePath,'-struct','xLoad',cField{:},'-v7');
    catch ME
        close(hMsg);
        errordlg({'Loading of the specified file failed:',ME.message},...
            'Loading failed');
        return
    end
    waitbar(1,hMsg);
    close(hMsg);
    
    % get structure name and calparam structure
    if isfield(xLoad.(cField{1}),'CalParam')
        % assign structure 
        data.cal = xLoad.(cField{1});
        
        % set edit field 
        set(data.hmd.p(1).e(1),'String',sFilePath);
        
        % enable next button
        set(data.hmd.b(2),'Enable','on');
        
        % store MARC dataset info
        data.selection.gk = cField{1};
        data.selection.kkf = sFile(1:end-4);
        set(data.hmd.p(3).e(1),'String',data.selection.kkf);

    else
        set(data.hmd.b(2),'Enable','off');
        errordlg({'The specified file does not contain a MARC structure with field CalParam!',...
            'Please specify a MARC export mat-file.'},'No MARC file');
    end
end

% store data with GUI
guidata(data.hmd.main,data);
return
% =========================================================================

function m2dCbFileSelectDcm(varargin)
% M2DCBFILESELECTDCM select a *.dcm file and check it for existence
%
% Syntax:
%   m2dCbFileSelectDcm(varargin)
%
% Inputs:
%   varargin - cell (1x3) with following content
%    {1}   hObject   - handle of the event triggering uicontrol (MATLAB)
%    {2}   eventdata - data of event (MATLAB)

% get data from GUI
data = guidata(gof(varargin{1}));

% get current setting path
sEdit = get(data.hmd.p(5).e(1),'String');
if isempty(sEdit) || ~exist(sEdit,'file')
    % backup for default location to start file search
    nDataType = get(data.hmd.p(5).rb(1),'Value')+2*get(data.hmd.p(5).rb(2),'Value');
    cDataFolder = {'mainData','e2pData'};
    sDefault = fullfile(data.sil.base,cDataFolder{nDataType});
else
    sDefault = sEdit;
end

% get file selection
[sFile,sPath] = uigetfile( ...
    {'*.dcm','DCM-files (*.dcm)'; ...
    '*.*',  'All Files (*.*)'}, ...
    'MARC AP/VP export dcm-file',...
    sDefault,...
    'MultiSelect','on');
if isnumeric(sFile)
    return
end
if iscell(sFile)
    % multifile selection
    cFile = sFile;
    cFilePath = cellfun(@(x)fullfile(sPath,x),sFile,'UniformOutput',false);
    sFilePath = strGlue(cFilePath,';');
else
    % single file selection
    cFile = {sFile};
    sFilePath = fullfile(sPath,sFile);
end

% check for dcm file
for nIdxFile = 1:numel(cFile)
    if ~strcmpi(cFile{nIdxFile}(end-3:end),'.dcm')
        if ~exist(sEdit,'file')
            set(data.hmd.b(2),'Enable','off');
        end
        errordlg({'The specified file is not a DCM file!',...
            'Please specify a MARC export dcm-file.',cFile{nIdxFile}},'No DCM file');
        return
    end
end

% apply file selection in edit
set(data.hmd.p(5).e(1),'String',sFilePath);

% enable next button
set(data.hmd.b(2),'Enable','on');
return

% =========================================================================

function m2dCbFolderSelect(varargin)
% M2DCBFOLDERSELECT callback to select a dataset variant folder of a
% simulation ECU dataClass "mainData" of mil ECUs.
%
% Syntax:
%   m2dCbFolderSelect(varargin)
%
% Inputs:
%   varargin - cell (1x3) with following content
%    {1}   hObject   - handle of the event triggering uicontrol (MATLAB)
%    {2}   eventdata - data of event (MATLAB)

% get data from GUI
data = guidata(gof(varargin{1}));

% get file selection
sPath = get(data.hmd.p(2).e(1),'String');
if isempty(sPath) || ~exist(sPath,'dir')
    sPathMfile = mfilename('fullpath');
    sPath = fullfile(fileparts(fileparts(fileparts(sPathMfile))),'Content','ctrl','mcm','mil');
end
[sPath] = uigetdir(sPath,'Select the ECU base dataset folder');
if isnumeric(sPath)
    return
end
cPath = pathparts(sPath);

% check folder selection
if ~strcmp('ctrl',cPath{end-6}) || ...
        ~strcmp('mil',cPath{end-4}) || ...
        ~strcmp('Data',cPath{end-2}) || ...
        ~strcmp('mainData',cPath{end-1})
    errordlg(['The selected folder is not a dataset variant folder of an ' ...
        'ECU dataClass "mainData"!'],'No folder in ECU mainData');
    return
end

% get dataset file
sFilePath = fullfile(sPath,[cPath{end-5} '_data_set.mat']);
if exist(sFilePath,'file')
    % load file
    xLoad = load(sFilePath);
    
    % get structure name and calparam structure
    if isfield(xLoad,'sMP')
        % set edit field 
        set(data.hmd.p(2).e(1),'String',sPath);
        
        % enable next button
        set(data.hmd.b(2),'Enable','on');
        
        % determine compiler switches
        cField = fieldnames(xLoad);
        bSwitch = strncmp('SW_COMP_SWITCH',cField,14);
        cSwitch = cField(bSwitch);
        cData = cell(numel(cSwitch),2);
        for nIdxSwitch = 1:numel(cSwitch)
            cData(nIdxSwitch,1) = cSwitch(nIdxSwitch);
            cData{nIdxSwitch,2} = xLoad.(cSwitch{nIdxSwitch});
        end
        set(data.hmd.p(2).tb(1),'Data',cData);
        
        % store loaded base dataset
        data.base = xLoad;
        
        % store base dataset name
        data.selection.base = cPath{end};
        
        % update step3 selection table
        cSelection = get(data.hmd.p(3).tb(1),'Data');
        cSelection{1,2} = data.selection.gk;
        cSelection{2,2} = data.selection.kkf;
        cSelection{3,2} = data.selection.base;
        set(data.hmd.p(3).tb(1),'Data',cSelection);
    else
        errordlg('The specified file does not contain a sMP structure!','No DIVe dataset file');
    end
else
    errordlg({['The selected folder does not contain a ' [cPath{end-5} '_data_set.mat'] ' file!'],...
        'Please check your folder selection.'},'No dataset mat-file');
end

% store data with GUI
guidata(data.hmd.main,data);
return

% =========================================================================

function m2dCbFolderSelectSil(varargin)
% M2DCBFOLDERSELECTSIL callback to select a mcm sil type folder.
%
% Syntax:
%   m2dCbFolderSelectSil(varargin)
%
% Inputs:
%   varargin - cell (1x3) with following content
%    {1}   hObject   - handle of the event triggering uicontrol (MATLAB)
%    {2}   eventdata - data of event (MATLAB)

% get data from GUI
data = guidata(gof(varargin{1}));

% get file selection
sPath = get(data.hmd.p(6).e(1),'String');
if isempty(sPath) || ~exist(sPath,'dir')
    if exist(data.sil.base,'dir')
        sPath = fileparts(data.sil.base);
    else
        sPathMfile = mfilename('fullpath');
        sPath = fullfile(fullfile(fileparts(fileparts(fileparts(sPathMfile)))),...
            'Content','ctrl','mcm','sil');
    end
end
[sPath] = uigetdir(sPath,'Select a folder of the ECU type level');
if isnumeric(sPath)
    return
end
cPath = pathparts(sPath);

% check selection
nSiL = find(strcmp('sil',cPath),1,'last');
nCtrl = find(strcmp('ctrl',cPath),1,'last');
if isempty(nSiL) ||  ...
        isempty(nCtrl) || ....
        nCtrl+2 ~= nSiL || ...
        nSiL == numel(cPath) || ...
        strcmpi('support',cPath{nSiL+1}) || ...
        strcmpi('data',cPath{nSiL+1})
    errordlg('The selected folder is not a mcm/acm.sil type folder!', ...
        'No folder of ECU sil type');
    return
end

% set edit box
set(data.hmd.p(6).e(1),'String',fullfile(cPath{1:nSiL+1}));

% determine main folders
nDataType = get(data.hmd.p(5).rb(1),'Value')+2*get(data.hmd.p(5).rb(2),'Value');
cDataFolder = {'mainData','e2pData'};
sPathData = fullfile(cPath{1:nSiL+1},'Data',cDataFolder{nDataType});
sPathA2L = fullfile(cPath{1:nSiL+1},'Module','std');
cFolder = dirPattern(sPathA2L,'*','folder');
sPathA2L = fullfile(sPathA2L,cFolder{1});
sType = cPath{nSiL+1};

% store settings
data.sil.sPathA2L = sPathA2L;
data.sil.sPathData = sPathData;
data.sil.sType = sType;

% store data with GUI
guidata(data.hmd.main,data);

% set color to standard
set(data.hmd.p(6).e(1),'ForegroundColor',[0 0 0],'BackgroundColor',[1 1 1]);

if isfield(data.sil,'sVariant')
    % enable next button
    set(data.hmd.b(2),'Enable','on');
end
return

% =========================================================================

function m2dCbNameCheck(varargin)
% M2DCBNAMECHECK callback to check dataset name entry
%
% Syntax:
%   m2dCbNameCheck(varargin)
%
% Inputs:
%   varargin - cell (1x3) with following content
%    {1}   hObject   - handle of the event triggering uicontrol (MATLAB)
%    {2}   eventdata - data of event (MATLAB)

% get data from GUI
data = guidata(gof(varargin{1}));

% get file selection
% old/obsolete
% sVariant = get(data.hmd.p(6).e(2),'String');
% if ~isvarname(sVariant)
%     sVariant = genvarname(sVariant);
%     set(data.hmd.p(6).e(2),'String',sVariant);
% end
cData = get(data.hmd.p(6).tb(1),'Data');
sVariant = cData{varargin{2}.Indices(1)};
if ~isvarname(sVariant)
    sVariant = genvarname(sVariant);
    cData{varargin{2}.Indices(1)} = sVariant;
    set(data.hmd.p(6).tb(1),'Data',cData);
end

% TODO
% check of software version against dataset filename?

% store settings
data.sil.sVariant = sVariant;

% store data with GUI
guidata(data.hmd.main,data);

if isfield(data.sil,'sPathData')
    % enable next button
    set(data.hmd.b(2),'Enable','on');
end
return

% =========================================================================

function m2dCbRestart(varargin)
% M2DCBRESTART restart the Wizard GUI to have access to other ECU (ACM) in configuration
%
% Syntax:
%   m2dCbRestart(varargin)
%
% Inputs:
%   varargin - cell (1x3) with following content
%    {1}   hObject   - handle of the event triggering uicontrol (MATLAB)
%    {2}   eventdata - data of event (MATLAB)
%
% Outputs:
%
% Example: 
%   m2dCbRestart(varargin)

% get data from GUI
data = guidata(gof(varargin{1}));

% close Wizard figure
close(data.hmd.main);

% restart Wizard for further DataSet creation with other ECU
Marc2DIVeWizard('','',data.const.xModule,data.const.sContent,data.const.sWorkspace);
return

% =========================================================================

function h = allHandle(h)
% ALLHANDLE return all children handles including the specified one.
%
% Syntax:
%   h = allHandle(h)
%
% Inputs:
%   h - handle of uicontrol
%
% Outputs:
%   h - (mx1) handles of uicontrol and its children
%
% Example: 
%   h = allHandle(gcf)

hAdd = allchilds(h);
h = [h;hAdd];
return

% =========================================================================

function prop = m2dGuiProperties
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

% togglebutton
prop.togglebutton = structAdd(prop.basic,prop.color.default);
prop.togglebutton.Style = 'togglebutton';
prop.togglebutton.HorizontalAlignment = 'center';

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

% =========================================================================

function [hChild] = allchilds(hHandle)
% ALLCHILDS return all children and subsequent children of ui-object with
% specified handle in a single vector.
%
% Syntax:
%   hChild = allchilds(xHandle)
%
% Inputs:
%   hHandle - handle (mx1) to get ui-element children from
%
% Outputs:
%   hChild - handle (mx1) of all children
%
% Example: 
%   hChild = allchilds(gco)
%   set(hChild,'Visible','off')

% initialize handle according MATLAB GUI engine
if verLessThanMATLAB('8.4.0')
    hChild = [];
else
    hChild = gobjects(0);
end

% get Children of handle(s) with exclusion of uiclassictab handles (they
% will be switched through the retouch function, so it would double
% handling
nHandle = length(hHandle);
if nHandle == 1 % single handle input
    if isappdata(hHandle,'uiclassictab') ~= 1
        hChild = get(hHandle,'Children'); % output: vector if single handle, cell if handle vector
    end
else % handle vector input
    bUiclassictab = zeros(1,nHandle); % init flag vector 
    for nIdxHandle = 1:nHandle
        bUiclassictab(1,nIdxHandle) = isappdata(hHandle(nIdxHandle),'uiclassictab'); % identify uiclassictab handles
    end
    xHandlesAdd = get(hHandle(~bUiclassictab),'Children'); % output: vector if single handle, cell if handle vector
    
    % re-arrange cell to vector
    for nIdxHandle = 1:length(xHandlesAdd)
        if ~isempty(xHandlesAdd{nIdxHandle})
            if isempty(hChild)
                hChild = xHandlesAdd{nIdxHandle};
            else
                hChild = [hChild;xHandlesAdd{nIdxHandle}]; %#ok<AGROW>
            end
        end
    end
end
    
% check for further children of handles
if ~isempty(hChild)
    hChildAdd = allchilds(hChild);
    hChild = [hChild ; hChildAdd];
end
return

% =========================================================================

function desQuitClientCleanUp(sClient)
% DESQUITCLIENTCLEANUP end instance and execution, while remove Perforce
% client and checkout.
%
% Syntax:
%   desQuitClientCleanUp(sClient)
%
% Inputs:
%   sClient - string with workspace name
%
% Outputs:
%
% Example: 
%   desQuitClientCleanUp(sClient)

% cleanup Perforce client
desClientDelete(sClient)

% quit Matlab with error code
fprintf(2,'startExternal:dqsQuitClientCleanUp - ending now Matlab session with error code!\n')
quit(2);
return %#ok<UNRCH>

% =========================================================================

function desClientDelete(sClient)
% DESCLIENTDELETE delete client/workspace from Perforce server.
%
% Syntax:
%   desClientDelete(sClient)
%
% Inputs:
%   sClient - string with workspace name
%
% Outputs:
%
% Example: 
%   desClientDelete(sClient)

% ensure client was created by DIVe external tool start
if isempty(regexp(sClient,'DES','once'))
    fprintf(1,'startExternal:dqsClientDelete - Cleanup of client "%s" omitted as it re-used an existing client.\n',sClient);
    return
end

cDes = hlxFormParse(p4('client -o %s',sClient),'Description',char(10),inf,true); %#ok<CHARTEN>
if ~strcmp('Client created by DIVeONE external tool start',cDes{1})
    fprintf(1,'startExternal:dqsClientDelete - Cleanup of client "%s" omitted as it re-used an existing client.\n',sClient);
    return
end

% remove Perforce workspace from server
[sMsg,nStatus] = p4(sprintf('client -d %s',sClient));
if nStatus
    fprintf(2,'startExternal:dqsClientDelete - Cleanup of client "%s" failed with message:\n%s\n',sClient,sMsg);
end
return