function xConfiguration = dcsPltmLogCommon(xCfg,sPathContent)
% DCSPLTMLOGCOMMON expands the DataSet variants of pltm.log.common.signals Modules into Logging
% Signals of platform logging.
%
% Syntax:
%   xConfiguration = dcsPltmLogCommon(xCfg,sPathContent)
%
% Inputs:
%           xCfg - structure with fields: 
%   sPathContent - string 
%
% Outputs:
%   xConfiguration - structure with fields: 
%
% Example: 
%   xConfiguration = dcsPltmLogCommon(xCfg,sPathContent)
%
%
% Subfunctions: applySignalDef, applyTagFilter, createLog, getLogPortAll,
% getSignalDefiniton, parseFileSignal, uniqueDef 
%
% See also: strGlue
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-8485-3325
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2022-03-16

% determine ModuleSetup within configuration
xConfiguration = xCfg.Configuration;
bLog = strncmp('log',{xConfiguration.ModuleSetup.name},3);
xSetup = xConfiguration.ModuleSetup(bLog);

% ensure pltm.log.common.signal structure 
if isempty(xSetup) || ...
        ~(strcmp(xSetup.Module.context,'pltm') && ...
          strcmp(xSetup.Module.species,'log')&& ...
          strcmp(xSetup.Module.family,'common')&& ...
          strcmp(xSetup.Module.type,'signal'))
    % incompatible module detected
    return
end

% create Module.species to ModuleSetup.name table
cSpeciesSetup = [{xCfg.xml.Module.species}' {xCfg.Configuration.ModuleSetup.name}'];

% read dataSet files
cDef = getSignalDefiniton(xSetup,sPathContent);

% add standard/single logging signals from Configuraiton XML
if isfield(xCfg.Configuration.Interface,'Logging')
    cDef = addLogStan(cDef,xCfg.Configuration.Interface.Logging,cSpeciesSetup);
end

% create logging structure in Configuration
if isfield(xConfiguration.Interface,'Signal')
    cSignal = {xConfiguration.Interface.Signal.name};
else
    cSignal = cell(1,0);
end
xConfiguration = createLog(xCfg,cDef,cSpeciesSetup,cSignal);
return

% =========================================================================

function cDef = addLogStan(cDef,xLogging,cSpeciesSetup)
% ADDLOGSTAN join signal definitions for logging from pltm.log DataSets
% with existing logging structure entries.
%
% Syntax:
%   cDef = addLogStan(cDef,xLogging,cSpeciesSetup)
%
% Inputs:
%   cDef - cell (mx2) with logging signal definitons from dataset files
%           {:,1} signal name defintions (or special tags "all", "allinputs"
%           {:,2} species/ModuleSetup name defintions (or special tags "all", "ctrl", ...
%        xLogging - structure (nx1)with fields: 
%           .name     - string with logging signal/port name
%           .modelRef - string with reference to ModuleSpecies.name
%   cSpeciesSetup - cell (nx2) Module.species to ModuleSetup.name mapping
%           {:,1} string with Module.species
%           {:,2} string with ModuleSetup.name 
%        xLogging - structure with fields: 
%
% Outputs:
%   cDef - cell (mx2) with logging signal definitons from dataset files
%           {:,1} signal name defintions (or special tags "all", "allinputs"
%           {:,2} species/ModuleSetup name defintions (or special tags "all", "ctrl", ...
%
% Example: 
%   cDef = addLogStan(cDef,xLogging,cSpeciesSetup)

% check input
if isempty(xLogging)
    return
end

% genereate defintion from existing logging signals
cDefAdd = [{xLogging.name}' {xLogging.modelRef}'];
% replace ModuleSpecies.name from reference by species
cDefAdd(:,2) = regexprep(cDefAdd(:,2),...
                         cellfun(@(x)['^' x '$'],cSpeciesSetup(:,2),'UniformOutput',false),...
                         cSpeciesSetup(:,1));
% join signal definitions
cDef = [cDef; cDefAdd];
return

% =========================================================================

function xConfiguration = createLog(xCfg,cDef,cSpeciesSetup,cSignal)
% CREATELOG recreate logging entries from defintions of datasets of
% pltm.log.common Module.
%
% Syntax:
%   xConfiguration = createLog(xCfg,cDef,cSpeciesSetup,cSignal)
%
% Inputs:
%   xCfg - structure with fields:
%    .Configuration - structure with DIVe Configuration XML content
%    .xml.Module - structure (1xn) with Module XML content
%   cDef - cell (mx2) with logging signal definitons from dataset files
%           {:,1} signal name defintions (or special tags "all", "allinputs"
%           {:,2} species/ModuleSetup name defintions (or special tags "all", "ctrl", ...
%   cSpeciesSetup - cell (nx2) Module.species to ModuleSetup.name mapping
%           {:,1} string with Module.species
%           {:,2} string with ModuleSetup.name 
%   cSignal - cell (1xn) with names of connected signal in Configuration setup
%
% Outputs:
%   xConfiguration - structure with fields: 
%
% Example: 
%   xConfiguration = createLog(xCfg,cDef,cSpeciesSetup)

% shortcuts
xConfiguration = xCfg.Configuration;
xModule = xCfg.xml.Module;

% determine logging information of all ports in configuration
cLog = getLogPortAll(xModule,cSpeciesSetup);

% extract/remove exclude statements
[bLogExclude,cDef] = applyExcludes(cLog,cDef,cSpeciesSetup);

% get logging by special tags ("all",...)
[bLog,cDefSignal] = applyTagFilter(cLog,cDef,cSignal);

% get logging by signal names
bLog = applySignalDef(cLog,bLog,cDefSignal,cSpeciesSetup);
bLog = bLog & ~bLogExclude;

% apply mask on overall logging
cLog = cLog(bLog,:);

% report all non matched, but explicit defined logging signals
reportSignalsUnmatched(cLog,cDef)

% create new logging structure
xConfiguration.Interface.Logging = struct('name',cLog(:,1),'unit',cLog(:,2),'modelRef',cLog(:,3));
return

% =========================================================================

function [bLog,cDef] = applyExcludes(cLog,cDef,cSpeciesSetup)
% APPLYEXCLUDES extract the exclude definitions and re-use logging signal determination logic for
% determination of exlude signals.
%
% Syntax:
%   [bLog,cDef] = applyExcludes(cLog,cDef,cSpeciesSetup)
%
% Inputs:
%   cLog - cell (nx6) with port logging information (all ports in config)
%           {:,1} string with port name
%           {:,2} string with port unit
%           {:,3} string with ModuleSetup name
%           {:,4} string with Module context
%           {:,5} integer (1x1) with port type (1:inport, 2:outport)
%           {:,6} integer (1x1) with Module index 
%   cDef - cell (mx2) with logging signal definitons from dataset files
%           {:,1} signal name defintions (or special tags "all", "allinputs"
%           {:,2} species/ModuleSetup name defintions (or special tags "all", "ctrl", ...
%   cSpeciesSetup - cell (mxn) 
%
% Outputs:
%   bLog - boolean (1x1) 
%   cDef - cell (mx2) with logging signal definitons from dataset files (without definitions of
%          exclude or "-" statements)
%           {:,1} signal name defintions (or special tags "all", "allinputs"
%           {:,2} species/ModuleSetup name defintions (or special tags "all", "ctrl", ...
%
% Example: 
%   [bLog,cDef] = applyExcludes(cLog,cDef,cSpeciesSetup)

% cleanup special character empty entries
cDef = cDef(~cellfun(@isempty,cDef(:,1)),:);

% extract exclude signals by minus
bExcludeMinus = cellfun(@(x)strcmp(x(1),'-'),cDef(:,1)); 
cDefMinus = cDef(bExcludeMinus,:);
for nIdxMinus = 1:size(cDefMinus,1)
    cDefMinus{nIdxMinus,1} = cDefMinus{nIdxMinus,1}(2:end);
end

% extract exclude signals by exclude tag
bExcludeEnd = cellfun(@(x)strncmp('edulcxe',fliplr(strtrim(x)),7),cDef(:,2)); 
cDefEnd = cDef(bExcludeEnd,:);
for nIdxEnd = 1:size(cDefEnd,1)
    cDefEnd{nIdxEnd,2} = strtrim(regexprep(cDefEnd{nIdxEnd,2},'exclude',''));
end
cDefExclude = [cDefMinus; cDefEnd];

% reduce original definitions
cDef = cDef(~(bExcludeMinus|bExcludeEnd),:);

% get logging by special tags ("all",...)
[bLog,cDefSignal] = applyTagFilter(cLog,cDefExclude);

% get logging by signal names
bLog = applySignalDef(cLog,bLog,cDefSignal,cSpeciesSetup);
return

% =========================================================================

function [bLog,cDefSignal] = applyTagFilter(cLog,cDef,cSignal)
% APPLYTAGFILTER mark all ports/signal for logging defined by special tags
% like "all", "allinput", etc.
%
% Syntax:
%   [bLog,cDefSignal] = applyTagFilter(cLog,cDef,cSignal)
%
% Inputs:
%   cLog - cell (nx6) with port logging information (all ports in config)
%           {:,1} string with port name
%           {:,2} string with port unit
%           {:,3} string with ModuleSetup name
%           {:,4} string with Module context
%           {:,5} integer (1x1) with port type (1:inport, 2:outport)
%           {:,6} integer (1x1) with Module index 
%   cDef - cell (mx2) with logging signal definitons
%           {:,1} signal name defintions (or special tags "all", "allinputs"
%           {:,2} species/ModuleSetup name defintions (or special tags "all", "ctrl", ...
%   cSignal - cell (1xn) with names of connected signal in Configuration setup
%
% Outputs:
%         bLog - boolean (nx1) if log entry is used for configuration
%   cDefSignal - cell (mx2) with logging signal definitons (cleaned up)
%           {:,1} signal name defintions (no special tags)
%           {:,2} species name defintions (all filled now)
%
% Example: 
%   [bLog,cDefSignal] = applyTagFilter(cLog,cDef)

% init output
bLog = false(size(cLog,1),1);

% determine inport/outport split
bOutport = cell2mat(cLog(:,6))==2;

% find special tags in cDef and split definition along
[bTagSignal,nTagSignal] = ismember(cDef(:,1),{'all','allinput','alloutput','constinput'});
cTagSpecies = {'','all','bdry','ctrl','human','phys','pltm'};
[bTagSpecies,nTagSpecies] = ismember(cDef(:,2),cTagSpecies);
bNoSpecies = nTagSpecies==1;
bTagWithEmpty = bTagSignal | bTagSpecies;
bTag = bTagWithEmpty & ~bNoSpecies; % remove empty species -> signal processing
cDefTag = cDef(bTag,:); 
nTagSignal = nTagSignal(bTag);
nTagSpecies = nTagSpecies(bTag);
cDefSignal = cDef(~bTagWithEmpty,:);

%% cover special tags
for nIdxDef = 1:size(cDefTag,1)
    % define signal mask
    switch nTagSignal(nIdxDef)
        case 1 % 'all'
            bThisSignal = true(size(cLog,1),1);
        case 2 % 'allinput'
            bThisSignal = ~bOutport;
        case 3 % 'alloutput'
            bThisSignal = bOutport;
        case 4 % 'constinput'
            bThisSignal = ~bOutport & ~ismember(cLog(:,1),cSignal);
        otherwise % signal name
            bThisSignal = strcmp(cDefTag{nIdxDef},cLog(:,1));
            % bThisSignal = ~cellfun(@isempty,regexp(cLog(:,1),cDefTag{nIdxDef},'once'));
    end
            
    % define species mask
    switch nTagSpecies(nIdxDef)
        case 1 % '' <empty> =all?!? tbd.
            bThisSpecies = true(size(cLog,1),1);
        case 2 % 'all'
            bThisSpecies = true(size(cLog,1),1);
        case {3,4,5,6,7} % 'bdry','ctrl','human','phys','pltm'
            bThisSpecies = strcmp(cTagSpecies{nTagSpecies(nIdxDef)},cLog(:,5));
        otherwise % single species / setup name
            bThisSpecies = strcmp(cDefTag{nIdxDef,2},cLog(:,4));
    end
    
    % combine masks
    bThis = bThisSignal & bThisSpecies;
    bLog = bLog | bThis;
end

%% cover missing species tags and add to DefSignal
% cover gaps by outports
cDefNoSpecies = cDef(bNoSpecies,1);
cLogOutport = cLog(bOutport,:);
[bLogOutport,nLogOutport] = ismember(cDefNoSpecies,cLogOutport(:,1));
if isempty(cDefNoSpecies) | ~any(bLogOutport)
    cDefFixOut = cell(0,2);
else
    cDefFixOut = [cDefNoSpecies(bLogOutport,1) cLogOutport(nLogOutport(bLogOutport),4)];
end

% cover leftover gaps by inports
cDefNoSpeciesInport = cDefNoSpecies(~bLogOutport);
cLogInport = cLog(~bOutport,:);
[bLogInport,nLogInport] = ismember(cDefNoSpeciesInport,cLogInport(:,1));
if isempty(cDefNoSpeciesInport) | ~any(bLogInport)
    cDefFixIn = cell(0,2);
else
    cDefFixIn = [cDefNoSpeciesInport(bLogInport,1) cLogInport(nLogInport(bLogInport),4)];
end

% add to other defintions with signal and dedicated species/setup definition
cDefSignal = [cDefSignal; cDefFixOut; cDefFixIn];
return

% =========================================================================

function bLog = applySignalDef(cLog,bLog,cDefSignal,cSpeciesSetup)  
% APPLYSIGNALDEF get need logging signals by defintion of signals and
% species.
%
% Syntax:
%   bLog = applySignalDef(cLog,bLog,cDefSignal,cSpeciesSetup)
%
% Inputs:
%   cLog - cell (nx6) with port logging information (all ports in config)
%           {:,1} string with port name
%           {:,2} string with port unit
%           {:,3} string with ModuleSetup name
%           {:,4} string with Module context
%           {:,5} integer (1x1) with port type (1:inport, 2:outport)
%           {:,6} integer (1x1) with Module index 
%   bLog - boolean (nx1) if log entry is used for configuration
%      cDefSignal - cell (mx2) with logging signal definitons (cleaned up)
%           {:,1} signal name defintions (no special tags)
%           {:,2} species name defintions (all filled now)
%   cSpeciesSetup - cell (nx2) Module.species to ModuleSetup.name mapping
%           {:,1} string with Module.species
%           {:,2} string with ModuleSetup.name 
%
% Outputs:
%   bLog - boolean (nx1) if log entry is used for configuration
%
% Example: 
%   bLog = applySignalDef(cLog,bLog,cDefSignal,cSpeciesSetup)

% determine Modules in definition
cSpeciesUsed = unique(cDefSignal(:,2));
bSpecies = ismember(cSpeciesSetup(:,1),cSpeciesUsed);
nSpecies = find(bSpecies);

% loop over affected species
nIdLogSpecies = cell2mat(cLog(:,7));
for nIdxSpecies = nSpecies'
    % determine singal definitions of this species
    bThisDef = strcmp(cSpeciesSetup{nIdxSpecies,1},cDefSignal(:,2));
    bThisLog = nIdLogSpecies==nIdxSpecies;
    
    % search for signal definitions in scope by regular expression
    sRegexp = strGlue(cDefSignal(bThisDef,1),'|');
    bLogRed = ~cellfun(@isempty,regexp(cLog(bThisLog,1),sRegexp,'once'));
    
    % set found entries for logging
    nLogRed = find(bThisLog);
    nLogRedToFull = nLogRed(bLogRed);
    [bLog(nLogRedToFull)] = deal(true);
    
    % reduce cDefSignal
    cDefSignal = cDefSignal(~bThisDef,:);
end
return

% =========================================================================

function reportSignalsUnmatched(cLog,cDef)
% REPORTSIGNALSUNMATCHED report unmatched signals from pltm.log DataSets to CommandWindow
%
% Syntax:
%   reportSignalsUnmatched(cLog,cDef)
%
% Inputs:
%   cLog - cell (nx6) with port logging information (all ports in config)
%           {:,1} string with port name
%           {:,2} string with port unit
%           {:,3} string with ModuleSetup name
%           {:,4} string with Module context
%           {:,5} integer (1x1) with port type (1:inport, 2:outport)
%           {:,6} integer (1x1) with Module index 
%   cDef - cell (mx2) with logging signal definitons
%           {:,1} signal name defintions (or special tags "all", "allinputs"
%           {:,2} species/ModuleSetup name defintions (or special tags "all", "ctrl", ...
%
% Outputs:
%
% Example: 
%   reportSignalsUnmatched(cLog,cDef)

% remove special tags
bTagSignal = ismember(cDef(:,1),{'all','allinput','alloutput','constinput'});
bTagSpecies = ismember(cDef(:,2), {'all','bdry','ctrl','human','phys','pltm'});
bTag = bTagSignal | bTagSpecies;
cDef = cDef(~bTag,:);

% determine unmatched signals
bMatch = ismember(cDef(:,1),cLog(:,1));
cSignalUnmatched = cDef(~bMatch,:);

% report unmatched
for nIdxSignal = 1:size(cSignalUnmatched,1)
    if isempty(cSignalUnmatched{nIdxSignal,2})
        fprintf(1,['   Log by pltm.log.common (fail): signal "%s" could not be ' ...
            'added, as it is not available in this configuration.\n'],...
            cSignalUnmatched{nIdxSignal,1});
    else
        fprintf(1,['   Log by pltm.log.common (fail): signal "%s" of Module "%s" could not be ' ...
            'added, as it is not available in this configuration.\n'],...
            cSignalUnmatched{nIdxSignal,1},cSignalUnmatched{nIdxSignal,2});
    end
end
return

% =========================================================================

function cLog = getLogPortAll(xModule,cSpeciesSetup)
% GETLOGPORTALL get logging information of all ports from Module XML
% metadata.
% 
% Syntax:
%   cLog = getLogPortAll(xModule,cDef)
%
% Inputs:
%   xModule - structure (1xn) with field of Module XML
%      cDef - cell (mx2) with logging signal definitons
%             {:,1} signal name defintions (or special tags "all", "allinputs"
%             {:,2} species/ModuleSetup name defintions (or special tags "all", "ctrl", ...
%   cSpeciesSetup - cell (nx2) Module.species to ModuleSetup.name mapping
%             {:,1} string with Module.species
%             {:,2} string with ModuleSetup.name 
%
% Outputs:
%   cLog - cell (nx6) with port logging information (all ports in config)
%           {:,1} string with port name
%           {:,2} string with port unit
%           {:,3} string with ModuleSetup name
%           {:,4} string with Module species
%           {:,5} string with Module context
%           {:,6} integer (1x1) with port type (1:inport, 2:outport)
%           {:,7} integer (1x1) with Module index 
%
% Example: 
%   cLog = getLogPortAll(xModule,cDef)

cLog = cell(0,7);
cPort = {'Inport','Outport'};
for nIdxModule = 1:numel(xModule)
    for nIdxPort = 1:2 % for inports and outports
        if isfield(xModule(nIdxModule).Interface,cPort{nIdxPort})
        xPort = xModule(nIdxModule).Interface.(cPort{nIdxPort});
        % collect port info for potential logging
        cLogAdd = [{xPort.name}' ...
            {xPort.unit}' ...
            repmat(cSpeciesSetup(nIdxModule,2),numel(xPort),1) ...
            repmat({xModule(nIdxModule).species},numel(xPort),1) ...
            repmat({xModule(nIdxModule).context},numel(xPort),1) ...
            repmat({nIdxPort},numel(xPort),1) ...
            repmat({nIdxModule},numel(xPort),1)];
        cLog = [cLog; cLogAdd]; %#ok<AGROW>
        end % isfield
    end % for inport/outport
end % for Modules in Configd
return

% =========================================================================

function cDef = getSignalDefiniton(xSetup,sPathContent)
% GETSIGNALDEFINITON determine signal definitions from all  
%
% Syntax:
%   cDef = getSignalDefiniton(xSetup,sPathContent)
%
% Inputs:
%         xSetup - structure with fields: 
%   sPathContent - string 
%
% Outputs:
%   cDef - cell (mx2) with 
%           {:,1}: signal name specifier (name, all , allinput, alloutput)
%           {:,2}: module species specifier
%
% Example: 
%   cDef = getSignalDefiniton(xSetup,sPathContent)

% determine signalRef datasets ~=none
bSignalRef = strcmp('signalRef',{xSetup.DataSet.classType});
xData = xSetup.DataSet(bSignalRef);
bKeep = ~strcmp('none',{xData.variant});
xData = xData(bKeep);

% determine file location
cFile = arrayfun(@(x)fullfile(sPathContent,'pltm','log','common','Data',...
                              'signalRef',x.variant,'signals.txt'),...
                 xData,'UniformOutput',false);
    
% parse files and collect definitions
cDef = cell(0,2);
for nIdxFile = 1:numel(cFile)
    cDefAdd = parseFileSignal(cFile{nIdxFile});
    cDef = [cDef;cDefAdd]; %#ok<AGROW>
end

% ensure unique entries
cDef = uniqueDef(cDef);
return

% =========================================================================

function cDef = parseFileSignal(sFile)
% PARSEFILESIGNAL parse signal definition statements from text file.
%
% Syntax:
%   cDef = parseFileSignal(sFile)
%
% Inputs:
%   sFile - string with filepath of signal text file
%
% Outputs:
%   cDef - cell (mx2) with 
%           {:,1}: signal name specifier (name, all , allinput, alloutput)
%           {:,2}: module species specifier
%
% Example: 
%   cDef = parseFileSignal('C:\dirsync\08Helix\11d_main\com\DIVe\Content\pltm\log\common\Data\signalRef\test\signals.txt')

% read file content
nFid = fopen(sFile,'r');
ccLine = textscan(nFid,'%s','Delimiter',char(10));
fclose(nFid);

% remove comment
cLine = strtrim(regexprep(ccLine{1},'%.*',''));
% remove blank lines
cLine = cLine(~cellfun(@isempty,cLine));

% convert to defintion cell
cDef1 = regexp(cLine,'^[\w\-]+','match','once');
cDef2 = regexp(cLine,'(?<=,)\w+','match','once');
cDef = [cDef1,cDef2];
return

% =========================================================================

function [cDef,nIdKey2Unique] = uniqueDef(cDef)
% UNIQUEDEF limit two column cell to entries, which are unique in the
% combination of the two column values.
%
% Syntax:
%   cDef = uniqueDef(cDef)
%
% Inputs:
%   cDef - cell (mx2) cell with two column key
%
% Outputs:
%            cDef - cell (nx2) with double entries removed
%   nIdKey2Unique - integer (1xm) index to remove doulbe entries from input
%
% Example: 
%   cDef = uniqueDef(cDef)

% create unique key for both fields
cKey = cellfun(@(x,y)[y '__' x],cDef(:,1),cDef(:,2),'UniformOutput',false);
% limit to unique entries and apply to definition cell
[cUnique,nIdKey2Unique] = unique(cKey); %#ok<ASGLU>
cDef = cDef(nIdKey2Unique,:);
return

