function nChange = hlxSdmStamp2HlxChange(nStamp)
% HLXSDMSTAMP2HLXCHANGE converts timestamps of validated collections in
% DIVe SysDM into changelist numbers of DIVe Perforce HelixCore instance.
% Conversion map of original data transfer is pre-parsed in a mat-file. Use
% hlxMapCreate to re-create mapping information from Helix changelist and
% their tagged descriptions.
%
% Syntax:
%   nChange = hlxSdmStamp2HlxChange(nStamp)
%
% Inputs:
%   nStamp - integer (1xm) with SysDM timestamps 
%
% Outputs:
%   nChange - integer (1xm) with Helix Changelist numbers
%
% Example: 
%   nChange = hlxSdmStamp2HlxChange(nStamp)
%
% MAT-files required: nMapSdm2Hlx.mat
%
% See also: nMapSdm2Hlx
%
% Author: Rainer Frey, TP/EAC, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2019-10-25


% check input
if isempty(nStamp)
    nChange = [];
    return
end

% keep static variable in memory
persistent nMapSdm2Hlx 
% load map from mat-file, if necessary
if isempty(nMapSdm2Hlx)
    xLoad = load('nMapSdm2Hlx.mat');
    nMapSdm2Hlx = xLoad.nMapSdm2Hlx;
end

% get Perforce Helix changelist of SysDM timestamp
if numel(nStamp) == 1
    nChange = nMapSdm2Hlx(nMapSdm2Hlx(:,1)==nStamp,2);
else
    [bInMap,nInMap] = ismember(nStamp,nMapSdm2Hlx(:,1)); %#ok<ASGLU>
    nChange = nMapSdm2Hlx(nInMap(bInMap),2);
end

% check consistency
if numel(nChange) < numel(nStamp)
    % determined failed timestamps (usually non-vaildated versions in
    % SysDM)
    if ~exist('bInMap','var')
        bInMap = false;
    end
    nStampFail = find(~bInMap);
    
    persistent cMap %#ok<TLEV> % whole transformation map including gaps
    % load map from mat-file, if necessary
    if isempty(cMap)
        xLoad = load('cMapSdm2Hlx.mat');
        cMap = xLoad.cMap;
    end
    nMapSdm = cell2mat(cMap(:,1));
    
    % found mapping index
    nFound = find(bInMap);
    nMiss = find(~bInMap);
    
    % recreate NAN mapping
    nChangeNew = NaN(size(nStamp));
    nChangeNew(nFound) = nChange(:);
    
    % determine next validated submit
    for nIdxFail = nMiss'
        [bMap,nIdMap] = ismember(nStamp(nIdxFail),nMapSdm);
        if bMap % SysDM timestamp is known in grand mapping
            % get mappings of this collection only
            bCollection = strcmp(cMap{nIdMap,2},cMap(:,2));
            cMapColl = cMap(bCollection,:);
            [cSort,nSort] = sort(cell2mat(cMapColl(:,1))); %#ok<ASGLU>
            cMapColl = cMapColl(nSort,:);
            
            % determine next follow up validated version
            [bMap,nIdMap] = ismember(nStamp(nIdxFail),cell2mat(cMapColl(:,1))); %#ok<ASGLU>
            nNext = find(~cellfun(@isempty,cMapColl(nIdMap+1:end,6)));
            if ~isempty(nNext)
                nChangeNew(nIdxFail) = cMapColl{nIdMap+nNext(1),6};
            else % no validated version available
                fprintf(2,'The SysDM ID "%i" (%s) has no validated version on the migration map!\n',...
                    cMapColl{nIdMap,1},cMapColl{nIdMap,2})
            end
        else
            % SysDM ID is unknown
                fprintf(2,'The SysDM ID "%i" is not on the migration map!\n',...
                    nStamp(nIdxFail));
        end
    end
    
    nChange = nChangeNew;
end
return