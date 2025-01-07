function spsMvaTransfer(sPath,sOption)
% SPSMVATRANSFER checks for the existence of an output file of Uniplot UXX
% format in the specied directory (MVA*.asc) and executes the conversion
% script for MVAPC ATF Converter format in Excel.
%
% Syntax:
%   spsMvaTransfer(sPath,sOption)
%
% Inputs:
%       sPath - string with simulation run directory
%     sOption - string with evaluation option:
%                on: recorder evaluation
%                stationary: recorder evaluation an stationary extraction
%
% Example: 
%   spsMvaTransfer(pwd,'stationary')
%
% See also: spsUniplot2MVA, StoreToDiscSFunc 
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2015-07-01

% check input
if nargin < 2
    sOption = 'on';
end

%% search files
% add co-sim client pathes to check pathes
cClient = dirPattern(sPath,'S*Client*','folder');
cPath = [{sPath} cellfun(@(x)fullfile(sPath,x),cClient,'UniformOutput',false)];

% search for MVA output files in pathes
cMVA = {};
cMARC = {};
cAlias = {};
for nIdxPath = 1:numel(cPath)
    % check for files
    cMVAadd = dirPattern(cPath{nIdxPath},'MVA*.asc','file');
    cHitMarc = regexp(cMVAadd,'MARC','once');
    bMarc = ~cellfun(@isempty,cHitMarc);
    cMARCadd = cMVAadd(bMarc);
    cMVAadd = cMVAadd(~bMarc);
    
    % cobmine path with file
    cMVAadd  = cellfun(@(x)fullfile(sPath,x),cMVAadd,'UniformOutput',false);
    cMARCadd = cellfun(@(x)fullfile(sPath,x),cMARCadd,'UniformOutput',false);
    
    % add to cell list
    cMVA = [cMVA cMVAadd]; %#ok<AGROW>
    cMARC = [cMARC cMARCadd]; %#ok<AGROW>
    
    % check for SiL Alias Files
    cAliasAdd = dirPattern(cPath{nIdxPath},'SiL_Alias_*.csv','file');
    cAliasAdd  = cellfun(@(x)fullfile(sPath,x),cAliasAdd,'UniformOutput',false);
    cAlias = [cAlias cAliasAdd]; %#ok<AGROW>
end

%% prepare alias data channel from Silver SiL results
[cFileMVA,cFileMARC] = spsSilAliasTransfer(cAlias);
cMVA = [cMVA, cFileMVA];
cMARC = [cMARC, cFileMARC];
% cMVA = unique(cMVA);
% cMARC = unique(cMARC);

%% determine MVA attribute header
cMvaNorm = regexpi(cMVA,'.*MVA_.*_norm\.asc$','match','once');
cMvaNorm = cMvaNorm(~cellfun(@isempty,cMvaNorm));
if ~isempty(cMvaNorm)
    [cAttributeName,cAttributeValue] = spsUXXHeaderRead(cMvaNorm{1});
else
    % get header information on old MiL
    [cAttributeName,cAttributeValue] = spsUXXHeaderRead(cMVA{1});
end

%% merge MARC files
if numel(cMARC) > 1
    MpxSources = spsDataChannelMerge(cMARC);
    if ~isempty(cAttributeName)
        MpxSources(1).subset(1).attribute.name = cAttributeName;
        MpxSources(1).subset(1).attribute.value = cAttributeValue;
    end
    spsUxxWrite(MpxSources,fullfile(sPath,'MARC_MultimediaFileMerge.asc'))
%     save(fullfile(sPath,'MARC_MultimediaFile.mat'),'MpxSources');
end

%% merge MVA files
if numel(cMVA) > 1
    sFileMVA = fullfile(sPath,'MVA_collectAll.mat');
    MpxSources = spsDataChannelMerge(cMVA);
    MpxSources(1).name = 'MVA_collectAll';
    MpxSources(1).subset.name = 'MVA_norm_merge';
    MpxSources(1).location.name = 'MVA_collectAll.mat';
    MpxSources(1).location.path = sPath;
    save(sFileMVA,'MpxSources');
elseif numel(cMVA) == 1
    MpxSources = uniread(cMVA{1});
end
    
%% ATF converter preparation for MVA norm content
if ~isempty(cMVA)
    % check for Excel availability
    try
        winqueryreg('name','HKEY_LOCAL_MACHINE','SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\excel.exe');
        sPathExcel = winqueryreg('HKEY_LOCAL_MACHINE','SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\excel.exe','Path');
        if isempty(sPathExcel)
            bExcel = false;
        else
            bExcel = true;
        end
    catch
        bExcel = false;
    end
    % create Excel File
    if bExcel
        spsMVAExcelWrite(MpxSources(1).subset,sPath);
    end
    
    % create ATF write
    spsATFWrite(MpxSources(1).subset,sPath)
end

% reduce data to stationary evaluation
if strcmp(sOption,'stationary')
    % reduce to stationary points
    MpxSources(1) = spsStationaryMpxReduce(MpxSources(1));
    
    % create Excel File
    spsMVAExcelWrite(MpxSources(1).subset,sPath);
    
    % create ATF write
    spsATFWrite(MpxSources(1).subset,sPath)
end
return

% =========================================================================

function [cFileMVA,cFileMARC] = spsSilAliasTransfer(cFile)
% SPSSILALIASTRANSFER transfer the data channels defined in the specified
% files from XCM SiL Silver output files to the MVA or MARC multimedia
% output files.
%
% Syntax:
%   [cFileMVA,cFileMARC] = spsSilAliasTransfer(cFile)
%
% Inputs:
%   cFile - cell (1xm) with filepaths of SiL alias csv-files
%
% Outputs:
%    cFileMVA - cell (1xn) with filepaths of transfer data files to MVA
%   cFileMARC - cell (1xo) with filepaths of transfer data files to MARC/multimedia 
%
% Example: 
%   [cFileMVA,cFileMARC] = spsSilAliasTransfer(cFile)

% init output
cFileMVA = {};
cFileMARC = {};

% loop over all alias files
for nIdxFile = 1:numel(cFile)
    % read alias file
    cAlias = spsSilAliasRead(cFile{nIdxFile});
    if isempty(cAlias)
        continue
    end
    
    % split alias in to MVA and MARC
    bMVA = cellfun(@(x)strcmp(x,upper(x)),cAlias(:,1));
    cMVA = cAlias(bMVA,:);
    cMARC = cAlias(~bMVA,:);
    
    % determine type
    [sPath,sName] = fileparts(cFile{nIdxFile});
    sType = lower(regexpi(sName,'mcm|acm','match','once'));
    
    % read SiL output
    sFileSiL = fullfile(sPath,[sType '_silver_raw.txt']);
    if exist(sFileSiL,'file')
        % secure read of file
        try
            xSource = spsUniread(sFileSiL);
        catch ME
            fprintf(2,'spsUniread failed on file "%s" with: %s\n',sFileSiL,ME.message);
            continue
        end
        % compress subset channels into first subset
        xSource = spsSubsetMerge(xSource);
        
        % add Silver SiL output file to MARC/multimedia files
        cFileMARC = [cFileMARC {sFileSiL}]; %#ok<AGROW>
        
        % write MVA part
        if ~isempty(cMVA)
            [MpxSources,bMatch] = spsMpxSourceCopyLean(xSource,1,cMVA(:,2)');
            [bHit,nHit] = ismember(MpxSources.subset.data.name,cMVA(:,2)');
            nHit = nHit(bHit);
            [MpxSources.subset.data.name(bHit)] = cMVA(nHit,1)';
            
            if any(bMatch)
                sSave = fullfile(sPath,['MVA_' sType '_from_Silver.mat']);
                save(sSave,'MpxSources');
                cFileMVA = [cFileMVA {sSave}]; %#ok<AGROW>
            end
        end
        
        % write MARC part
        if ~isempty(cMARC)
            [MpxSources,bMatch] = spsMpxSourceCopyLean(xSource,1,cMARC(:,2)');
            [bHit,nHit] = ismember(MpxSources.subset.data.name,cMARC(:,2)');
            nHit = nHit(bHit);
            [MpxSources.subset.data.name(bHit)] = cMARC(nHit,1)';
            if any(bMatch)
                sSave = fullfile(sPath,['MVA_' sType '_from_Silver_MARC.mat']);
                save(sSave,'MpxSources');
                cFileMARC = [cFileMARC {sSave}]; %#ok<AGROW>
            end
        end
    else
        fprintf(1,['Postprocessing MVA: A transfer file "%s" was specified, '...
            'but there is no source file "%s".\n'],sName,[sType '_silver_raw.txt']);
    end
end
return

% =========================================================================

function [xSource,bMatch] = spsMpxSourceCopyLean(xSource,nSubset,cChannel)
% SPSMPXSOURCECOPYLEAN lean copy of some data channels from only one Mpx
% source structure subset
%
% Syntax:
%   [xSource,bMatch] = spsMpxSourceCopyLean(xSource,nSubset,cChannel)
%
% Inputs:
%    xSource - structure with fields: 
%    nSubset - integer (1x1) 
%   cChannel - cell (1xn) with strings of channel names
%
% Outputs:
%   xSource - structure with fields: 
%    bMatch - boolean 
%
% Example: 
%   [xSource,bMatch] = spsMpxSourceCopyLean(xSource,nSubset,cChannel)

% match data channels
bMatch = ismember(xSource.subset(nSubset).data.name,cChannel);
bMatch(1) = true; % add ID/Time channel

% reduce data channels
xSource.subset(nSubset).data.name = xSource.subset(nSubset).data.name(bMatch);
xSource.subset(nSubset).data.value = xSource.subset(nSubset).data.value(:,bMatch);

% reduce to single subset
xSource.subset = xSource.subset(nSubset);
return

% =========================================================================

function xSource = spsSubsetMerge(xSource)
% SPSSUBSETMERGE merge data channels of subsequent subsets of a Morphix
% source structure into the first subset. Same time vector of subsets is
% assumed. Cures multiple subsets due to subset conversion by uniread of
% logging channel names, which include "." in the name.
%
% Syntax:
%   xSource = spsSubsetMerge(xSource)
%
% Inputs:
%   xSource - structure with Morphix data format and multiple subsets, but
%             same time channel
%
% Outputs:
%   xSource - structure with Morphix data format and a single subset
%
% Example: 
%   xSource = spsSubsetMerge(xSource)

% loop over subsets
for nIdxSub = 2:numel(xSource.subset)
    % combine data name and value matrix
    xSource.subset(1).data.name = [xSource.subset(1).data.name xSource.subset(nIdxSub).data.name(2:end)];
    xSource.subset(1).data.value = [xSource.subset(1).data.value xSource.subset(nIdxSub).data.value(:,2:end)];
end
return

% =========================================================================

function cAlias = spsSilAliasRead(sFile)
% SPSSILALIASREAD read SiL Alias definition file for transfer to MVA
% output. File is has two columns, separated by comma - no blanks! First
% Column MVA name, second column silver logging name.
%
% Syntax:
%   cAlias = spsSilAliasRead(sFile)
%
% Inputs:
%   sFile - string with alias file path
%
% Outputs:
%   cAlias - cell (mx2) with alias definitions
%            col1: MVA name
%            col2: silver name
%
% Example: 
%   cAlias = spsSilAliasRead(sFile)

% read file
nFid = fopen(sFile,'r');
ccLine = textscan(nFid,'%s','Delimiter','\n');
fclose(nFid);
cLine = ccLine{1}(~cellfun(@isempty,ccLine{1}));

% parse lines
cAlias = cell(numel(cLine),2);
nLine = 0;
for nIdxLine = 1:numel(cLine)
    cSplit = strsplitOwn(cLine{nIdxLine},',');
    if numel(cSplit) > 1
        nLine = nLine + 1;
        cAlias(nLine,1:2) = cSplit(1:2);
    end
end
cAlias = cAlias(1:nLine,:);
cAlias = strtrim(cAlias);
return

% =========================================================================

function xSource = spsDataChannelMerge(cFile)
% SPSDATACHANNELMERGE loads all specified files with uniread and merges the
% data channels of all subsets.
%
% Syntax:
%   xSource = spsDataChannelMerge(cFile)
%
% Inputs:
%   cFile - cell (1xn) with stings of filepaths to merge
%
% Outputs:
%   xSource - structure of Morphix data structure type
%
% Example: 
%   xSource = spsDataChannelMerge(cFile)

% load data
xSource = spsUniread(cFile);

% compress data structure to single subset
for nIdxSource = 1:numel(xSource)
    % Omit first subset of first source
    if nIdxSource == 1
        nStart = 2;
    else
        nStart = 1;
    end
    
    % add data channels of subset to first subset of first source
    for nIdxSubset = nStart:numel(xSource(nIdxSource).subset)
        if size(xSource(nIdxSource).subset(nIdxSubset).data.value,1) == ...
                size(xSource(1).subset(1).data.value,1)
            % create boolean for unique data channels
            bTransfer = ~ismember(xSource(nIdxSource).subset(nIdxSubset).data.name,...
                xSource(1).subset(1).data.name);
            
            % merge header
            xSource(1).subset(1).data.name = ...
                [xSource(1).subset(1).data.name ...
                xSource(nIdxSource).subset(nIdxSubset).data.name(bTransfer)];
            
            % merge data
            xSource(1).subset(1).data.value = ...
                [xSource(1).subset(1).data.value ...
                xSource(nIdxSource).subset(nIdxSubset).data.value(:,bTransfer)];
            
            % delete data from structure to free RAM
            LowRam = structInit(fieldnames(xSource(nIdxSource).subset));
            LowRam(1).name = 'Dummy';
            xSource(nIdxSource).subset(nIdxSubset) = LowRam;
        end
    end
    if nIdxSource > 1
        xSource(nIdxSource) = struct('name',{'Dummy'},'location',{''},'subset',{''});
    end
end
xSource = xSource(1);
return

% =========================================================================

function xSource = spsStationaryMpxReduce(xSource)
% SPSSTATIONARYMPXREDUCE determine stationary setpoints of engine
% measurement and reduce all source data to averaged data for each
% setpoint.
%
% Syntax:
%   xSource = spsStationaryMpxReduce(xSource)
%
% Inputs:
%   xSource - structure with fields: 
%
% Outputs:
%   xSource - structure with fields: 
%
% Example: 
%   xSource = spsStationaryMpxReduce(xSource)


% *************************************************************************
% BEGIN OF ADJUSTMENT DATA

vStdDefFactor = 0.80; % factor, to adjust the captured flanks of the data ID channel
                     % values ranging from 1.4 to 0.6, lower factor, if you
                     % have low flanks on ID channel

% Mode 2:
vPeriod = 30; % averaging period over xData e. g. 30s 
vOffset = 5; % offset period from differential extrema - control offset from maximum changing point
vFilterPeriod = 4; % s period for avaraging filter to apply on data

% END OF ADJUSTMENT DATA
% *************************************************************************

%% get data channels nmot
[vNmot,sNmot] = spsMpxChannelSearch(xSource,{'mec_eng_CrankMean_angVel',...
    'NMOT','NMOTW','mec_eng_CrankResolved_angVel','is1_eng_speed','isp_eng_speed'}); %#ok<NASGU>
if ~isempty(vNmot)
    % determine sample rate
    vSampleNmot = mean(diff(vNmot(:,1)));
    % filter data by symmetric moving average
    vNmot(:,2) = averagesym(vNmot(:,2),vFilterPeriod/vSampleNmot,0);
    % determine setpoint changes seperately on NMOT and MSOLL
    [vTCPosNmot,vPeriodNmot] = spsChannelSetpointIdCreate(vNmot(:,1),vNmot(:,2),vPeriod,vOffset,vStdDefFactor);
else
    vTCPosNmot = [];
end

%% get data channels MSOLL
[vMsoll,sMsoll] = spsMpxChannelSearch(xSource,{'pt_EngTrq_Rq_PT','MSOLL','eng_torque','MEFFW'}); %#ok<NASGU>
if ~isempty(vMsoll)
    % determine sample rate
    vSampleMsoll = mean(diff(vMsoll(:,1)));
    % filter data by symmetric moving average
    vMsoll(:,2) = averagesym(vMsoll(:,2),vFilterPeriod/vSampleMsoll,0);
    % determine setpoint changes seperately on NMOT and MSOLL
    [vTCPosMsoll,vPeriodMsoll] = spsChannelSetpointIdCreate(vMsoll(:,1),vMsoll(:,2),vPeriod,vOffset,vStdDefFactor);
else
    vTCPosMsoll = [];
end

% decide for ID trace
if numel(vTCPosNmot) > numel(vTCPosMsoll)
    vTCPos = vTCPosNmot;
    vPeriod = vPeriodNmot;
else
    vTCPos = vTCPosMsoll;
    vPeriod = vPeriodMsoll;
end
% TODO merge logic?

% split data along data channel for all subsets
for nIdxSource = 1:numel(xSource)
    for nIdxSubset = 1:numel(xSource(nIdxSource).subset)
        vData = xSource(nIdxSource).subset(nIdxSubset).data.value;
        xSource(nIdxSource).subset(nIdxSubset).data.value = NaN(numel(vTCPos),size(vData,2));
        
        % determine time index positions and ranges
        nTCPos = interp1(vData(:,1),1:size(vData,1),vTCPos,'nearest');
        vSample = mean(diff(vData(:,1)));
        nOffset = ceil(vOffset/vSample);
        nPeriod = ceil(vPeriod/vSample);
        
        % create mean values for each setpoint
        for nIdxPos = 1:numel(nTCPos)
            xSource(nIdxSource).subset(nIdxSubset).data.value(nIdxPos,:) = ...
                mean(vData(ceil(max(1,nTCPos(nIdxPos)-nPeriod-nOffset)):...
                           floor(max(1,nTCPos(nIdxPos)-nOffset)),:));
        end % for each extraction position
        
        % add ID channels for stationary measurement
        vIdChannel = [(1:numel(nTCPos))' ...
                      (1:numel(nTCPos))' ...
                      vData(max(1,nTCPos-nPeriod-nOffset),1) ...
                      vData(max(1,nTCPos-nOffset),1) ...
                      vTCPos];
        xSource(nIdxSource).subset(nIdxSubset).data.name = [ ...
            {'LFNR' 'MESPKTNR' 'TimeMeanStart' 'TimeMeanStop' 'TimeSetpointChange'} ...
            xSource(nIdxSource).subset(nIdxSubset).data.name];
        xSource(nIdxSource).subset(nIdxSubset).data.value = [vIdChannel ...
            xSource(nIdxSource).subset(nIdxSubset).data.value];
        
        % change attributes to FU for MVA
        cChange = {'MessTyp','VersuchsTyp','Messung'};
        for nIdxChange = 1:numel(cChange)
            bHit = strcmp(cChange{nIdxChange},xSource(nIdxSource).subset(nIdxSubset).attribute.name);
            if any(bHit)
                [xSource(nIdxSource).subset(nIdxSubset).attribute.value(bHit)] = deal({'FU'});
            else
                xSource(nIdxSource).subset(nIdxSubset).attribute.name = [...
                    xSource(nIdxSource).subset(nIdxSubset).attribute.name cChange(nIdxChange)];
                xSource(nIdxSource).subset(nIdxSubset).attribute.value = [...
                    xSource(nIdxSource).subset(nIdxSubset).attribute.value {'FU'}];
            end
        end
    end % for subset
end % for source
return 

% =========================================================================

function [vChannel,sChannel] = spsMpxChannelSearch(xSource,cSearch)
% SPSMPXCHANNELSEARCH search data channels along a specified priority list
% within a morphix data structure.
%
% Syntax:
%   [vChannel,sChannel] = spsMpxChannelSearch(xSource,cSearch)
%
% Inputs:
%   xSource - structure of Morhpix data structure type
%   cSearch - cell (1xn) with strings of searched data channel and aliases
%
% Outputs:
%   vChannel - vector (nx2) with 1: time data, 2: channel data 
%   sChannel - string with used/found channel name
%
% Example: 
%   [vChannel,sChannel] = spsMpxChannelSearch(xSource,cSearch)

nIndex = zeros(0,4);
% determine channel in 
for nIdxSource = 1:numel(xSource)
    for nIdxSubset = 1:numel(xSource(nIdxSource).subset)
        [bChannel,nChannel] = ismember(cSearch,xSource(nIdxSource).subset(nIdxSubset).data.name);
        nChannel = nChannel(bChannel);
        nHit = find(bChannel);
        if numel(nChannel) > 0
            nIndex = [nIndex; nHit(1) nIdxSource nIdxSubset nChannel(1)]; %#ok<AGROW>
        end
    end
end
if isempty(nIndex)
    vChannel = NaN(0,2);
    sChannel = '';
    return
end

% create output
[nTrash,nSortPrio] = sort(nIndex(:,1)); %#ok<ASGLU> % sort according priority list
nIndex = nIndex(nSortPrio,:);
sChannel = cSearch{nIndex(1,1)};
vChannel = [xSource(nIndex(1,2)).subset(nIndex(1,3)).data.value(:,1) ...
            xSource(nIndex(1,2)).subset(nIndex(1,3)).data.value(:,nIndex(1,4))];
return

% =========================================================================

function [vTimeChangePos,vPeriod] = spsChannelSetpointIdCreate(x,y,vPeriod,vOffset,vStdDefFactor)
% SPSCHANNELSETPOINTIDCREATE create vector
%
% Syntax:
%   [vTimeChangePos,vPeriod] = spsChannelSetpointIdCreate(x,y,vPeriod,vOffset,vStdDefFactor)
%
% Inputs:
%         x - 
%         y - 
%   vPeriod - vector (1x1) 
%   vOffset - vector (1x1) 
%
% Outputs:
%   vTimeChangePos - vector (1x1) 
%          vPeriod - vector (1x1) 
%
% Example: 
%   [vTimeChangePos,vPeriod] = spsChannelSetpointIdCreate(x,y,vPeriod,vOffset,vStdDefFactor)

% classify measurement line ID data channel
IDunique = unique(y);
if length(IDunique) < 0.05*length(y) && length(IDunique) < 85
    % ID channel contains discrete ID data (integer/artificial ID)
    IDdiff = diff(y);
    IDchangePos = find(IDdiff~=0);
else % ID channel is scattered & continuous (derived from measurement channel)
    IDgrad = diff(y) ./ diff(x); % absolute gradient values
    IDchangePos = findRisingEdge(IDgrad,vStdDefFactor);
end
vTimeChangePos = x(IDchangePos);
if numel(vTimeChangePos)<2
    return
end

% remove hold times of less than 70s
vHold = diff(vTimeChangePos);
bSkip = vHold < 70;
while any(bSkip)
    nRemove = find(bSkip,1,'last')+1;
    bKeep = true(size(vTimeChangePos));
    bKeep(nRemove) = false;
    vTimeChangePos = vTimeChangePos(bKeep);
    vHold = diff(vTimeChangePos);
    bSkip = vHold < 70;
end
% vTimeChangePos = vTimeChangePos([true;bKeep]);

% remove front point with insufficient hold time
MeanHold = mean(diff(vTimeChangePos));
vTimeChangePos = vTimeChangePos(vTimeChangePos > 0.8*MeanHold);

% change range determination
vChangeRangeX = max(1e-3,min(min(diff(vTimeChangePos)),vTimeChangePos(1)));
if vPeriod > 0.9*vChangeRangeX-vOffset
    vPeriod = 0.9*(vChangeRangeX-vOffset); % limit averaging period to fit all ranges
    % warn user
    fprintf(2,['spsStationaryMpxReduce - WARNING: the ' ...
        'specied averaging period had to be reduced due ' ...
        ' to low gaps between identified peaks: %f\n'],vPeriod);
end
return 

% =========================================================================

function nPosExtrema = findRisingEdge(vVec,vStdDefFactor)
% findRisingEdge - finds extrema positions in a scattered value vector. Only
% extremas of significant value deviations are taken.
% 
% Input variables:
%          vVec   - vector (1xm) with values to find extrema in
%   vStdDefFactor - real (1x1) with factor in standard deviation as limit of
%                   detected changes
% 
% Ouput variables:
% nPosExtrema    - vector with positions of extrema (min/max) in vector vVec

% points at signal begin to ignore
nCutoffFront = 100;

% normalize on zero and take absolute
vVec = vVec - mean(vVec);
vStdDev = std(vVec(min(nCutoffFront,numel(vVec)):end-min(50,numel(vVec)-1))); % standard deviation
vLimit = vStdDefFactor*vStdDev;
vVec = abs(vVec);

% determine gradients exceeding limit
bLimit = vVec > vLimit;

% derive rising edges of limit violation periods
nPosExtrema = find(bLimit == false & [bLimit(2:end);false] == true);
while numel(nPosExtrema) > 85
    % iterate with higher limit until reasonable number of rising edges is found
    vLimit = vLimit * 1.1;
    bLimit = vVec > vLimit;
    nPosExtrema = find(bLimit == false & [bLimit(2:end);false] == true);
end
% remove points at begin
nPosExtrema = nPosExtrema(nPosExtrema>nCutoffFront);
if numel(nPosExtrema) < 2
    return
end

% check for sufficient hold time at data tail
MeanHold = mean(diff(nPosExtrema));
if length(vVec)-nPosExtrema(end) > 0.6*MeanHold
    nPosExtrema = [nPosExtrema;length(vVec)-floor(0.05*MeanHold)];
end

% remove front point with insufficient hold time
MeanHold = mean(diff(nPosExtrema));
nPosExtrema = nPosExtrema(nPosExtrema > 0.8*MeanHold);

% % debugging output
% fprintf(1,'%i  %f  %f  %f  %f\n',[numel(nPosExtrema) vStdDev vLimit ...
%     max(vVec(min(nCutoffFront,numel(vVec)):end-min(50,numel(vVec)-1)))...
%     mean(vVec(min(nCutoffFront,numel(vVec)):end-min(50,numel(vVec)-1)))]);
return

% =========================================================================

function out = averagesym(A,range,order)
% averagesym - symmetric averaging (filtering) of data with growing range
% at start and end of data and different orders.
% 
% Input variables:
% A     - matrix (mxn), data to be filtered
% range - integer, half range of elements for data to be filtered
% order - integer, order of filter (default: 0 - equals flat weighting)
% 
% Output variables:
% out   - matrix (mxn), filtered data 

% check inputs
if nargin <= 1
    range = 5;
elseif nargin <= 2
    order = 0;
elseif nargin <= 3
    if ~isnumeric(range) || isnan(range) || length(range)>1
        error('averagesym: range must be a single, non-zero, positive number');
    end
    if ~isnumeric(order) || isnan(order) || length(order)>1
        error('averagesym: range must be a single, positive number');
    end
else
    error('averagesym: wrong number of input arguments');
end

% check orientation
if min(size(A))==1 && size(A,1)==1
    A=A';
    TransposeFlag = true;
else
    TransposeFlag = false;
end

% initialize
out = zeros(size(A));
out(1,:) = A(1,:);
out(end,:) = A(end,:);

if order == 0 % fast execution with MATLAB build in function
    % calculate start
    for k = 2:range
        out(k,:) = mean(A(1:2*k-1,:));
    end
    
    % calculate main
    for k = range+1:size(A,1)-range
        out(k,:) = mean(A(k-range:k+range,:));
    end
    
    % calculate end
    for k = 2:range
        out(end-(k-1),:) = mean(A(end-(2*k-2):end,:));
    end
else
    % generate weighting
    weight = [0:1/range:1,1-1/range:-1/range:0].^order; % build symmetric vector [0..1..0]
    weight = weight./sum(weight); % norm weights to 1
    
    % calculate start
    for k = 2:range
        out(k,:) = weight(range+1-(k-1):range+1+(k-1))*A(1:2*k-1,:);
    end
    
    % calculate main
    for k = range+1:size(A,1)-range
        out(k,:) = weight*A(k-range:k+range,:);
    end
    
    % calculate end
    for k = 2:range
        out(end-(k-1),:) = weight(range+1-(k-1):range+1+(k-1))*A(end-(2*k-2):end,:);
    end
end

% retranspose if necessary
if TransposeFlag
    out = out';
end
return

% =========================================================================

function [cAttributeName,cAttributeValue] = spsUXXHeaderRead(sFile)
% SPSUXXHEADERREAD read function for header of UXX files of Uniplot format.
%
% Syntax:
%   [cAttributeName,cAttributeValue] = spsUXXHeaderRead(sFile)
%
% Inputs:
%   sFile - char (1xn) with filename
%
% Outputs:
%    cAttributeName - cell (1xn) with chars of attribute names
%   cAttributeValue - cell (1xn) with values of attributes
%
% Example: 
%   [cAttributeName,cAttributeValue] = spsUXXHeaderRead(sFile)

% init output
cAttributeName = {};
cAttributeValue = {};

% skip if no real file
if exist(sFile,'file')~=2
    return
end

%% read header from file
nFid = fopen(sFile);
sLine = fgetl(nFid);
if ~strcmp(sLine(1:9),'UXX-BEGIN')
    % other format
    disp(['The specified file does not contain a UXX format header: ' sFile]);
    return
end

% read attribute header
bAttribute = true;
nLine = 1;
while bAttribute % read lines until UXX-END or end of file
    sLine = fgetl(nFid);
    nLine = nLine + 1;
    if ~ischar(sLine) || strcmp(sLine(1:7),'UXX-END')
        bAttribute = false;
    else
        % parse line for attribute format: <name> = <value>
        sAttributeName = regexp(sLine,'.+(?=\=)','match','once');
        sAttributeValue = regexp(sLine,'(?<=\=).+','match','once');
        
        % store attribute name
        cAttributeName = [cAttributeName {strtrim(sAttributeName)}]; %#ok<AGROW>
        
        % store attribute value as string or number
        vAttributeValue = str2double(strtrim(sAttributeValue));
        if isnan(vAttributeValue)
            % remove leading and trailing "
            sAttributeValue = regexprep(strtrim(sAttributeValue),{'^"','"$'},{'',''}); 
            cAttributeValue = [cAttributeValue {sAttributeValue}]; %#ok<AGROW>
        else
            cAttributeValue = [cAttributeValue {vAttributeValue}]; %#ok<AGROW>
        end
    end
end

% close file
fclose(nFid);
return