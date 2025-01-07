function [bSuccess,sMsg] = pstRecordedMatSignalStructCompare(xResultsA,xResultsB,bChannelMatch,sNameA,sNameB)
% PSTRECORDEDMATSIGNALSTRUCTCOMPARE analyses the difference between two
% result structures, created original from a mat-writer in Silver.
%
%   The results are checked in the following order:
%       1. Not successful, if result A is empty. 
%       2. Not successful, if result B is empty. 
%       3. Successful, if results are identical. 
%       4. Only, if no channel matching for between result A and B allowed: 
%           4.1. Not successful, if the results have different number of channels. 
%           4.2. Not successful, if the results have different channel names. 
%       5. Not successful, if results have different number of values in channels. 
%       6. Only, if channel 'time' was recorded for results: 
%           6.1. Not successful, if results have a diffent time vector channel. 
%       7. Not successful, if results have different values for (some) channels. 
%
%
% Syntax:
%   [bSuccess,sMsg] = pstRecordedMatSignalStructCompare(xResultsA,xResultsB,bChannelMatch,sNameA,sNameB)
%   [bSuccess,sMsg] = pstRecordedMatSignalStructCompare(xResultsA,xResultsB,bChannelMatch)
%   [bSuccess,sMsg] = pstRecordedMatSignalStructCompare(xResultsA,xResultsB)
%
% Inputs:
%       xResultsA - structure with fields: result structure A, with recorded values per channel  
%       xResultsB - structure with fields: result structure B, with recorded values per channel  
%   bChannelMatch - boolean (1x1) (optional): flag to allow channel matching,
%                       means that the checks will be continued if there exists matching channel names    
%          sNameA - string (optional): name of result A 
%          sNameB - string (optional): name of result B 
%
% Outputs:
%   bSuccess - boolean (1x1): flag to indicate if comaprison was successful  
%       sMsg - string: description of differences if any is indicated 
%
% Example: 
%   [bSuccess,sMsg] = pstRecordedMatSignalStructCompare(xResultsA,xResultsB,bChannelMatch,sNameA,sNameB)
%
%
% Subfunctions: checkChannelDiff, getMatchingChannels
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2023-02-24

%% check input arguments

% default values of optional arguments
if nargin < 5
    sNameB = 'result B';
end
if nargin < 4
    sNameA = 'result A';
end
if nargin < 3
    bChannelMatch = false;
end


%% initial actions

% init output
bSuccess = true;
sMsg = '';

% empty structure
if isempty(xResultsA)
    bSuccess = false;
    sMsg = sprintf('No channels was recorded in %s.\n',sNameA);
    return;
end
if isempty(xResultsB)
    bSuccess = false;
    sMsg = sprintf('No channels was recorded in %s.\n',sNameB);
    return;
end

% return if identical
if isequal(xResultsB,xResultsA)
    return;
end


%% sort channels

% get values from structures
cChannelsA = xResultsA.Signals;
cChannelsB = xResultsB.Signals;
vValuesA = xResultsA.Values;
vValuesB = xResultsB.Values;

% order channels
[cChannelsA,nSortIdxA] = sort(cChannelsA);
[cChannelsB,nSortIdxB] = sort(cChannelsB);

% sort values with index
vValuesA = vValuesA(nSortIdxA,:);
vValuesB = vValuesB(nSortIdxB,:);


%% channel names

% check if channel matching is allowed
if bChannelMatch
    % get matching channels
    [cChannels,nIdxA,nIdxB] = intersect(cChannelsA,cChannelsB);
    % delete not used channel values
    vValuesA = vValuesA(nIdxA,:);
    vValuesB = vValuesB(nIdxB,:);
else
    % different number of channels
    if numel(cChannelsA) ~= numel(cChannelsB)
        bSuccess = false;
        sMsg = sprintf('Number of recorded channels differs between %s and %s.\n',...
            sNameA,sNameB);
        return;
    end
    % different names of channels
    if ~isequal(cChannelsA,cChannelsB)
        bSuccess = false;
        sMsg = sprintf('Names of recorded channels differ between %s and %s.\n',...
            sNameA,sNameB);
        return;
    end
    % common channel names
    cChannels = cChannelsA;
end


%% channel value length

% check size of channel matrix
if ~isequal(size(vValuesA,2),size(vValuesB,2))
    bSuccess = false;
    sMsg = sprintf('Number of channel values differs between %s and %s.\n',...
        sNameA,sNameB);
    return;
end


%% compare time vector

% check for channel name time
if ismember('time',cChannels)
    bTimeVec = true;
else
    bTimeVec = false;
end

% check time vector values
if bTimeVec
    % get row index of time
    nTimeIdx = find(ismember(cChannels,'time'));
    % get time vectors from A and B
    vTimeVecA = vValuesA(nTimeIdx,:);
    vTimeVecB = vValuesB(nTimeIdx,:);
    % check if vectors are equal
    if ~isequal(vTimeVecA,vTimeVecB)
        bSuccess = false;
        sMsg = sprintf('Time vector in %s differs from %s.\n',...
            sNameB,sNameA);
        return;
    end
    % common time vector
    vTimeVec = vTimeVecA;
end


%% compare values of channels

sValueReport = '';

for nCh=1:numel(cChannels)
    
    % channel name
    sChannelName = cChannels{nCh};
    
    % values from channel in A and B
    vChannelValsA = vValuesA(nCh,:);
    vChannelValsB = vValuesB(nCh,:);
    
    % check values
    [bDiff,nStartIdx,vValA,vValB] = checkChannelDiff(vChannelValsA,vChannelValsB);
    
    % create report for any difference
    if bDiff
        % create message strings
        sDiffMsg = sprintf('Difference in channel "%s", at index %d',...
            sChannelName,nStartIdx);
        sValDiff = sprintf('%s ~= %s',num2str(vValB,18),num2str(vValA,18));
        % expand message if time vector exists
        if bTimeVec
            sTimeMsg = sprintf(', at time "%s"',...
                num2str(vTimeVec(nStartIdx),18));
        else
            sTimeMsg = '';
        end
        % append report message
        sValueReport = sprintf('%s\t%s%s: %s\n',sValueReport,sDiffMsg,...
            sTimeMsg,sValDiff);
    end
    
end

% create final report
if ~isempty(sValueReport)
    bSuccess = false;
    sMsg = sprintf('Following channels have differences:\n%s',sValueReport);
    return;
end

return

% =========================================================================

function [bDiff,nStartIdx,vValA,vValB] = checkChannelDiff(vChannelValsA,vChannelValsB)

% init output
bDiff = false;
nStartIdx = 0;

% check every single value
for nVal=1:length(vChannelValsA)
    
    % get value from A and B
    vValA = vChannelValsA(nVal);
    vValB = vChannelValsB(nVal);
    
    % check if it is equal
    if ~isequal(vValA,vValB)
        bDiff = true;
        nStartIdx = nVal;
        return;
    end
    
end

return
