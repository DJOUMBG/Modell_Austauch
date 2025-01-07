function vOut = averagesym(vData,nRange,nOrder)
% AVERAGESYM symmetric averaging (filtering) of data with growing range
% at start and end of data and different orders.
%
% Syntax:
%   vOut = averagesym(vData,nRange,nOrder)
%
% Inputs:
%    vData - matrix (mxn), data to be filtered
%   nRange - integer (1x1) half range of elements for data to be filtered
%   nOrder - integer (1x1) order of filter (default: 0 - equals flat weighting)
%
% Outputs:
%   vOut - matrix (mxn), filtered data 
%
% Example: 
%   vOut = averagesym(vData,nRange,nOrder)
%
% Author: Rainer Frey, TP/EAC, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2007-06-01

% check inputs
if nargin <= 1
    nRange = 5;
elseif nargin <= 2
    nOrder = 0;
elseif nargin <= 3
    if ~isnumeric(nRange) || isnan(nRange) || length(nRange)>1
        error('averagesym: range must be a single, non-zero, positive number');
    end
    if ~isnumeric(nOrder) || isnan(nOrder) || length(nOrder)>1
        error('averagesym: range must be a single, positive number');
    end
else
    error('averagesym: wrong number of input arguments');
end

% check orientation
if min(size(vData))==1 && size(vData,1)==1
    vData=vData';
    bTranspose = true;
else
    bTranspose = false;
end

% initialize
vOut = zeros(size(vData));
vOut(1,:) = vData(1,:);
vOut(end,:) = vData(end,:);

if nOrder == 0 % fast execution with MATLAB build in function
    % calculate start
    for nIdxRange = 2:nRange
        vOut(nIdxRange,:) = mean(vData(1:2*nIdxRange-1,:));
    end
    
    % calculate main
    for nIdxRange = nRange+1:size(vData,1)-nRange
        vOut(nIdxRange,:) = mean(vData(nIdxRange-nRange:nIdxRange+nRange,:));
    end
    
    % calculate end
    for nIdxRange = 2:nRange
        vOut(end-(nIdxRange-1),:) = mean(vData(end-(2*nIdxRange-2):end,:));
    end
else
    % generate weighting
    weight = [0:1/nRange:1,1-1/nRange:-1/nRange:0].^nOrder; % build symmetric vector [0..1..0]
    weight = weight./sum(weight); % norm weights to 1
    
    % calculate start
    for nIdxRange = 2:nRange
        vOut(nIdxRange,:) = weight(nRange+1-(nIdxRange-1):nRange+1+(nIdxRange-1))*vData(1:2*nIdxRange-1,:);
    end
    
    % calculate main
    for nIdxRange = nRange+1:size(vData,1)-nRange
        vOut(nIdxRange,:) = weight*vData(nIdxRange-nRange:nIdxRange+nRange,:);
    end
    
    % calculate end
    for nIdxRange = 2:nRange
        vOut(end-(nIdxRange-1),:) = weight(nRange+1-(nIdxRange-1):nRange+1+(nIdxRange-1))*vData(end-(2*nIdxRange-2):end,:);
    end
end

% retranspose if necessary
if bTranspose
    vOut = vOut';
end
return