function dstStatflowWrapper(hBlock)
% DSTSTATEFLOWWRAPPER create a Simulink block from a Statflow block. (DIVe
% Simulink Transfer package) "Pack a stateflow block into a subsystem in a
% library  with accordingly named ports and parameter mask."
%
% Syntax:
%   dstStatflowWrapper(hBlock)
%
% Inputs:
%   hBlock - handle of stateflow chart with named ports 
%
% Outputs:
%
% Example: 
%   dstStatflowWrapper(hBlock)
%
% See also: sfcPortNameGet, slcBlockInfo
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2014-06-25

% check input
if nargin < 1
    hBlock = gcb;
end

% determine model and save location
sModel = bdroot(hBlock);
sFileName = get_param(sModel,'FileName');
if isempty(sFileName)
    sPath = pwd;
else
    [sPath, sModelName, sModelExtension] = fileparts(sFileName); %#ok<ASGLU>
end

% determine stateflow block information
xBI = slcBlockInfo(hBlock);

% create library
sLibrary = [sModel '_library'];
new_system(sLibrary,'library');
save_system(sLibrary,fullfile(sPath,[sLibrary sModelExtension]));

% add subsystem
add_block('built-in/SubSystem',fullfileSL(sLibrary,xBI.Name));
nPortMax = max(xBI.Ports);
set_param(fullfileSL(sLibrary,xBI.Name),'Position',[150 50 450 50+nPortMax*40]);
set_param(fullfileSL(sLibrary,xBI.Name),'Backgroundcolor','lightBlue');
% add stateflow block
sStateflowPath = fullfileSL(sLibrary,xBI.Name,xBI.Name);
add_block(xBI.BlockPath,sStateflowPath);
hBlock = sStateflowPath;

% resize stateflow block
set_param(hBlock,'Position',[400 50 400+diff(xBI.Position([1,3])) 50+nPortMax*40]);

% reset stateflow block information
xBI = slcBlockInfo(hBlock);

% handle inports
for nIdxPort = 1:xBI.Ports(1)
    % get Stateflow port name
    sName = sfcPortNameGet(hBlock,'Input',nIdxPort);
    
    % add inport 
    hPort = add_block('built-in/Inport', fullfileSL(xBI.Parent,sName),...
        'MakeNameUnique', 'on');
    nPortPos = xBI.PortCon(nIdxPort).Position;
    set_param(hPort,...
        'Position',[nPortPos(1)-215 nPortPos(2)-7 nPortPos(1)-185 nPortPos(2)+7 ]);
    xBlockAdd = slcBlockInfo(hPort);
        add_line(xBI.Parent,[xBlockAdd.PortCon(1).Position; nPortPos]);
end

% handle outports
for nIdxPort = 1:xBI.Ports(2)
    % get Stateflow port name
    sName = sfcPortNameGet(hBlock,'Output',nIdxPort);
    
    % add outport 
    hPort = add_block('built-in/Outport', fullfileSL(xBI.Parent,sName),...
        'MakeNameUnique', 'on');
    nPortPos = xBI.PortCon(xBI.Ports(1)+nIdxPort).Position;
    set_param(hPort,...
        'Position',[nPortPos(1)+185 nPortPos(2)-7 nPortPos(1)+215 nPortPos(2)+7 ]);
    xBlockAdd = slcBlockInfo(hPort);
        add_line(xBI.Parent,[nPortPos; xBlockAdd.PortCon(1).Position]);
end

% get mask and parameter information
hParent = get_param(hBlock,'Parent');
sMaskVariables = get_param(hBlock,'MaskVariables');
if ~isempty(sMaskVariables) % Statflow chart has a parameter mask
    cMaskValues = get_param(hBlock,'MaskValues');
    cMaskPrompts = get_param(hBlock,'MaskPrompts');
    
    set_param(hParent,...
        'Mask','on',...
        'MaskVariables',sMaskVariables,...
        'MaskPrompts',cMaskPrompts,...
        'MaskValues',cMaskValues);
else % no correct parameter mask - try to get parameter from object
%     stateflowBlocks = find_system(bdroot,'LookUnderMasks','all','FollowLinks','on','MaskType','Stateflow')
    oChart = find(sfroot,'-isa','Stateflow.Chart','Path',hBlock);
    oSFParam = find(oChart, 'Scope', 'Parameter');
    cParamName = {};
    sMaskVariables = '';
    for nIdxParam = 1:length(oSFParam)
        cParamName = [cParamName oSFParam(nIdxParam).Name]; %#ok<AGROW>
        sMaskVariables = [sMaskVariables oSFParam(nIdxParam).Name '=@' num2str(nIdxParam) ';']; %#ok<AGROW>
    end
    set_param(hParent,...
        'Mask','on',...
        'MaskVariables',sMaskVariables,...
        'MaskPrompts',cParamName,...
        'MaskValues',cParamName);
end

% save library
open_system(sLibrary);
save_system(sLibrary);
return