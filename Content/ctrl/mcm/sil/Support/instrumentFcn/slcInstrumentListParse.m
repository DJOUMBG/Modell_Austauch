function xChannel = slcInstrumentListParse(hSystem,sExcelFile,nSheet)
% SLCINSTRUMENTLISTPARSE parse an instrumenation list for MCM or ACM ECU
% from Excel into a MATLAB structure and save it to a mat-file.
% 
% Usage:
% 1. Make path of ECU modelset "open" available (addpath)
% 2. Make path of Supportset "instrumentFcn" available (addpath)
% 3. Open ECU library of modelset "open"
% 4. Navigate in model into the ECU model block so you can see the
%    subsystems "Input Extern" and "Output Extern" or specifiy the its path
% 5. execute this function (slcInstrumentListParse) with first argument gcs
%
% Syntax:
%   slcInstrumentListParse(hSystem,sExcelFile,nSheet) % recommended usage
%   xChannel = slcInstrumentListParse(hSystem,sExcelFile,nSheet)
%
% Inputs:
%      hSystem - handle of instrumentation base Simulink system
%                * for ECU this is the subsystem, where "Input Extern" and
%                   "Output Extern" are located
%                * All block path are relative to this system, except paths
%                  of the special OutputMVA blocks (e.g. OutputMVA_MCM)
%                * The subsystem for external storage collection will be
%                  stored here or one level above for ECUs
%   sExcelFile - string with filepath of Excel file with columns:
%                sName, sBlockPath, sPortType, nPort
%       nSheet - integer with ID of Excel sheet
%
% Outputs:
%   xChannel - structure (1xn) for instrumentation with fields: 
%     .sName      - string with signal name in output
%     .sBlockPath - string with blockpath of block to signal
%     .sPortType  - port type of block, which is connected to signal
%     .nPort      - port number of block, which is connected to signal
%
% Example: 
%   slcInstrumentListParse('mcm_mil_P13_13_00_49','C:\dirsync\05VirtualTruck\60Projects\05Thermodynamik\InstrumentationListMVAPC.xlsx',1)
%   xChannel = slcInstrumentListParse(gcs,'C:\dirsync\05VirtualTruck\60Projects\05Thermodynamik\InstrumentationListMVAPC.xlsx',1)
%
% See also: dbread, ismdl, slcBlockpathPartFind, pathpartsSL, fullfileSL
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2014-12-01

% initialize output
xChannel = struct('sName',{},'sBlockPath',{},'sPortType',{},'nPort',{});

%% Input patching
% use current system
if nargin < 1
    hSystem = gcs;
end 
% get list from Excel file selection
if nargin < 2
    xSource = dbread;
elseif nargin == 2
    xSource = dbread(sExcelFile);    
elseif nargin == 3
    xSource = dbread(sExcelFile,nSheet);    
end
if isempty(xSource(1).name), return,end

%% check for correct Simulink level of hSystem
cSubsystemPath = find_system(hSystem,'SearchDepth',1,'FollowLinks','on','BlockType','SubSystem');
cSubsystem = regexp(cSubsystemPath,'[^/]+$','match','once');
if all(ismember({'Input Extern','Output Extern'},cSubsystem))
    % all fine, proceed
elseif any(strcmp(regexp(hSystem,'[^/]+$','match','once'),...
        {'MCM Internal','ACM Internal','Input Extern','Output Extern'}))
    hSystem = fileparts(hSystem);
elseif any(strcmp(regexp(hSystem,'[^/]+$','match','once'),{'mcm1','acm1'})) || ...
        strcmp(hSystem,bdroot(hSystem))
    cSubsystemPath = find_system(hSystem,'SearchDepth',1,'FollowLinks','on',...
        'RegExp','on','BlockType','^SubSystem$','Name','_mil_');
    hSystem = cSubsystemPath{1};
    cSubsystemPath = find_system(hSystem,'SearchDepth',1,'FollowLinks','on','BlockType','SubSystem');
    cSubsystem = regexp(cSubsystemPath,'[^/]+$','match','once');
    if ~all(ismember({'Input Extern','Output Extern'},cSubsystem))
        errordlg({'Sorry, the instrumentation ECU reference level could not be recognized.',...
            'Please specify or navigate to the correct subsystem level of the ECU!'},'Wrong system specified');
    end
end

%% process excel content
nFail = 0;
for nIdxFile = 1:numel(xSource)
    for nIdxSheet = 1:numel(xSource(nIdxFile).subset)
        % take Excel sheet name as ToWorkspace and Goto prefix
        sSheet = regexprep(xSource(nIdxFile).subset(nIdxSheet).name,{' ','\-','\+'},'');
        
        % get IDs of data entries
        bIdName = ismember(xSource(nIdxFile).subset(nIdxSheet).field,{'sName','Signalname','SignalName'});
        if ~any(bIdName)
            disp(['ERROR: There is no SignalName column in sheet ' xSource(nIdxFile).subset(nIdxSheet).name ' of file ' xSource(nIdxFile).name]);
        end
        bIdBlockPath = ismember(xSource(nIdxFile).subset(nIdxSheet).field,{'sBlockPath','BlockPath'});
        if ~any(bIdBlockPath)
            disp(['ERROR: There is no BlockPath column in sheet ' xSource(nIdxFile).subset(nIdxSheet).name ' of file ' xSource(nIdxFile).name]);
        end
        bIdPortType = ismember(xSource(nIdxFile).subset(nIdxSheet).field,{'sPortType','PortType'});
        if ~any(bIdPortType)
            disp(['ERROR: There is no PortType column in sheet ' xSource(nIdxFile).subset(nIdxSheet).name ' of file ' xSource(nIdxFile).name]);
        end
        bIdPort = ismember(xSource(nIdxFile).subset(nIdxSheet).field,{'nPort','PortNumber'});
        if ~any(bIdPort)
            disp(['ERROR: There is no PortNumber column in sheet ' xSource(nIdxFile).subset(nIdxSheet).name ' of file ' xSource(nIdxFile).name]);
        end
        % added by aoverfe - 2016-07-04
        bIdOrigPortName = ismember(xSource(nIdxFile).subset(nIdxSheet).field,{'nPort','OriginalPortname'});
        if ~any(bIdOrigPortName)
            disp(['Warning: There is no OriginalPortname column in sheet ' xSource(nIdxFile).subset(nIdxSheet).name ' of file ' xSource(nIdxFile).name]);
        end
        
        
        % assign measurement channels
        PortMismatchWrnList = {}; % initialize List for Portname mismatch added by aoverfe - 2016-07-04
        bKeep = true(1,size(xSource(nIdxFile).subset(nIdxSheet).value,1)); 
        for nIdxItem = 1:size(xSource(nIdxFile).subset(nIdxSheet).value,1)
            cLine = xSource(nIdxFile).subset(nIdxSheet).value(nIdxItem,:);
            
            %% comfort patching
            % signalname: combine all empty/inheritance variants
            if isempty(cLine{1,bIdName}) || ...
                    isnumeric(cLine{1,bIdName}) || ...
                    (ischar(cLine{1,bIdName}) && strcmp(cLine{1,bIdName},'-1'))
                sName = '';
            else
                sName = cLine{1,bIdName};
            end
            
            % blockpath: find specified endpart of blockpath in model
            if ~isempty(regexp(cLine{1,bIdBlockPath},'.*OutputMVA\w*/','match','once'))
                % special handling of OutputMVA_MCM and OutputMVA_ACM signals 
                sOutputMVA = regexp(cLine{1,bIdBlockPath},'.*OutputMVA\w*/','match','once'); % get first part of path 
                sOutputMVABlock = regexp(sOutputMVA,'OutputMVA\w*','match','once'); % get name of OutputMVA block 
                sBlockPath = fullfileSL(sOutputMVABlock,cLine{1,bIdBlockPath}(numel(sOutputMVA)+1:end));
                
                % check existence of OutputMVA_xCM signal
                slcLoadEnsure('OutputMVA',0);
                if ismdl('OutputMVA')
                    if ~ismdl(fullfileSL('OutputMVA',sBlockPath))
                        sBlockPath = '';
                    end
                end
                
            elseif ismdl(fullfileSL(get_param(hSystem,'Parent'),...
                                get_param(hSystem,'Name'),...
                                cLine{1,bIdBlockPath}))
                % specified blockpath is good to use
                sBlockPath = cLine{1,bIdBlockPath};
                % get full path of parent of port - necessary for getting port information later on
                sBlockPathFull = fullfileSL(get_param(hSystem,'Parent'),...
                                get_param(hSystem,'Name'),...
                                cLine{1,bIdBlockPath});
                            
            else
                % search for block path as backup
                sBlockPath = slcBlockpathPartFind(hSystem,cLine{1,bIdBlockPath});
                
                % check for wrong base path
                if ~isempty(sBlockPath) && strcmpi('nlib',sBlockPath(1:4))
                    % remove entry Nlib and blockname
                    cPath = pathpartsSL(sBlockPath);
                    sBlockPath = fullfileSL(cPath(3:end));
                end
            end
            
            % Port type default: Outport
            if isempty(cLine{1,3})
                sPortType = 'Outport';
            else
                sPortType = cLine{1,3};
            end
            
            % Port number default: 1
            if ischar(cLine{1,4})
                nPort = str2double(cLine{1,4});
            end
            if isempty(nPort) || isnan(nPort)
                nPort = 1;
            end
            
            % inherit signal name from port
            if isempty(sName)
                % get port path
                cPortPath = find_system(sBlockPath,...
                    'LookUnderMasks','all',...
                    'FollowLinks','on',...
                    'SearchDepth',1,...
                    'BlockType',sPortType,...
                    'Port',num2str(nPort));
                
                % get port name
                sPortName = get_param(cPortPath{1},'Name');
                
                % apply name corrections for use as signal
                sName = regexprep(sPortName,{'\(','\)','_get','_read',' '},'');
            end   
            
            % compare current port name to given/original port name (added by aoverfe - 2016-07-04)
            if any(bIdOrigPortName) && ~isempty(cLine{1,bIdOrigPortName})
                % get port path
                cPortPath = find_system(sBlockPathFull,...
                    'LookUnderMasks','all',...
                    'FollowLinks','on',...
                    'SearchDepth',1,...
                    'BlockType',sPortType,...
                    'Port',num2str(nPort));

                % get port name
                if ~isempty(cPortPath)
                    sPortName = get_param(cPortPath{1},'Name');

                    if strcmp(sPortName(end),' ')
                        sPortName(end) = '';
                    end

                    % compare name to given port name and throw Warning message if mismatched
                    if ~strcmp(cLine{1,bIdOrigPortName},sPortName)
                        PortMismatchWrnList{end+1} = ['Port name mismatch for Signal: ' ...
                            cLine{1,bIdName} ' : ' cLine{1,bIdBlockPath} ' - ' ...
                            cLine{1,bIdPortType} ' - ' cLine{1,bIdPort}]; %#ok<AGROW>
                    end
                else
                    PortMismatchWrnList{end+1} = ['Port name mismatch for Signal: ' ...
                        cLine{1,bIdName} ' : ' cLine{1,bIdBlockPath} ' - ' ...
                        cLine{1,bIdPortType} ' - ' cLine{1,bIdPort}]; %#ok<AGROW>
                end
            end
            
            % status messages
            if ~ismember(sPortType,{'Inport','Outport'})
                disp(['Invalid port type "' sPortType '" for data channel ' sName ...
                    ' (Channel' sprintf('% 3.0f',nIdxItem) ' of sheet "' ...
                    xSource(nIdxFile).subset(nIdxSheet).name '" in file "'...
                    xSource(nIdxFile).name '")']);
                nFail = nFail + 1;
                bKeep(nIdxItem) = false;
            else
                if isempty(sBlockPath)
                    % block not found
                    fprintf(2,['Block path verification failed for data channel %s'  ...
                        ' (Channel %3.0f of sheet "%s" in file "%s")\n'],....
                        sName,nIdxItem,...
                        xSource(nIdxFile).subset(nIdxSheet).name,...
                        xSource(nIdxFile).name);
                    nFail = nFail + 1;
                    bKeep(nIdxItem) = false;
                else
                    % check block for specified port
                    if strcmp(sBlockPath(1:9),'OutputMVA')
                        sBlockPathFull = fullfileSL('OutputMVA',sBlockPath);
                    else
                        sBlockPathFull = fullfileSL(get_param(hSystem,'Parent'),...
                            get_param(hSystem,'Name'),sBlockPath);
                    end
                    if ismdl(sBlockPathFull)
                        xBI = slcBlockInfo(sBlockPathFull);
                    else
                        xBI.PortHandles = struct('Inport',{[]},'Outport',{[]});
                    end
                    if nPort > numel(xBI.PortHandles.(sPortType))
                        fprintf(2,['Port number (%1.0f) exceeds available %ss ' ...
                            '(%1.0f) for data channel %s (Channel %3.0f of ' ...
                            'sheet "%s" in file "%s")\n'],...
                            nPort,sPortType,numel(xBI.PortHandles.(sPortType)),...
                            sName,nIdxItem,...
                            xSource(nIdxFile).subset(nIdxSheet).name,...
                            xSource(nIdxFile).name);
                        nFail = nFail + 1;
                        bKeep(nIdxItem) = false;
                    end
                end % if isempty(sBlockPath)
            end % if ~ismember(sPortType,{'Inport','Outport'})

            %% create data channel entry
            xChannel(nIdxItem) = struct('sName',sName,...
                'sBlockPath',sBlockPath,...
                'sPortType',sPortType,...
                'nPort',nPort); 
        end % for all lines
        % remove invalid data channels
        xChannel = xChannel(bKeep);
    end % for all sheets
end % for all files
disp([num2str(nFail) ' data channels failed the verification process and can not be succesful instrumented.']);

% issue warning due to portname mismatches (added by aoverfe - 2016-07-04)
if ~isempty(PortMismatchWrnList)
    warndlg('At least one Portname mismatch in Instrument List. Please have a look at the command window!')
    for nIdxMismatch = 1:numel(PortMismatchWrnList)
        fprintf(2,'   %s\n',PortMismatchWrnList{nIdxMismatch});
    end
end

% store channels to file, if in interactive mode
if nargout == 0
    % try to determine storage location in DIVe model based
    sFilePath = slcFileLibraryGet(hSystem);
    cPathMdl = pathparts(fileparts(sFilePath));
    sPathChannel = fullfile(cPathMdl{1:end-3},'Support','instrument');

       
    % get save file location
    if isdir(sPathChannel) 
        [sFileSave,sPathSave] = uiputfile('*.mat','Select save file name',fullfile(sPathChannel,[sSheet '.mat']));
    else
        [sFileSave,sPathSave] = uiputfile('*.mat','Select save file name',[sSheet '.mat']);
    end
    % save file
    if ~isempty(sFileSave) && ~isnumeric(sFileSave)
        save(fullfile(sPathSave,sFileSave),'xChannel');
    end
end
return


% =========================================================================
% == linked from file: slcBlockpathPartFind.m 
% =========================================================================


function sBlock = slcBlockpathPartFind(hSystem,sBlockpathPart)
% SLCBLOCKPATHPARTFIND find a block only by the end part of its full
% blockpath. Use this function to find the same model part in different
% model names
%
% Syntax:
%   sBlock = slcBlockpathPartFind(sBlockpathPart)
%
% Inputs:
%          hSystem - handle or string with blockpath of system to be
%                    searched
%   sBlockpathPart - string with ending part of the full block path
%
% Outputs:
%   sBlock - string with full block path
%
% Example: 
%   sBlock = slcBlockpathPartFind(gcs,'Subsystem/Scope')
%
%
% Other m-files required: pathpartsSL, fullfileSL
%
% See also: pathpartsSL, fullfileSL, find_system  
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2013-03-26

% initialize output
sBlock = '';

% decompose blockpath
cPath = pathpartsSL(sBlockpathPart);

if numel(cPath) > 1
    % create end part of parent blockpath
    sParentPart = fullfileSL(cPath(1:end-1));
    
    % search with parent identification
    cParentResult = find_system(hSystem,...
        'RegExp','on',...
        'FollowLinks','on',...
        'LookUnderMasks','all',...
        'Parent',[sParentPart '$'],...
        'Name',['^' cPath{end} '$']);
%         'BlockType','SubSystem',...
else
    % search without parent
    cParentResult = find_system(hSystem,...
        'RegExp','on',...
        'FollowLinks','on',...
        'LookUnderMasks','all',...
        'Name',cPath{end});
%         'BlockType','SubSystem',...
end

% create fullpath
if numel(cParentResult) == 1
    sBlock = cParentResult{1};
elseif numel(cParentResult) == 0
%     disp(['CAUTION: slcBlockpathPartFind found no result for the searchpath ''' sBlockpathPart ''''])
else
    sBlock = cParentResult{1};
    disp(['CAUTION: slcBlockpathPartFind found more than one result for the searchpath ''' sBlockpathPart ''''])
end
return
